# Full Technical Audit — AWS DBT Snowflake Project

**Project:** AWS DBT Snowflake Project  
**Stack:** AWS S3, Snowflake, dbt  
**Architecture:** Bronze → Silver → Gold  
**Audit date:** 2026-02-28

---

## Step 1 — Repository Analysis

### 1.1 Project structure (summary)

```
aws_dbt_snowflake_project/
├── analyses/           # explore.sql, loop.sql, if_else.sql (ad-hoc)
├── macros/
│   ├── generate_schema_name.sql
│   ├── multiply.sql
│   ├── tag.sql
│   └── trimmer.sql
├── models/
│   ├── bronze/         # bronze_bookings, bronze_hosts, bronze_listings
│   ├── silver/         # silver_bookings, silver_hosts, silver_listings
│   ├── gold/
│   │   ├── obt.sql     # One Big Table (table)
│   │   └── ephemeral/ # bookings, hosts, listings, fact (ephemeral)
│   └── sources/
│       └── sources.yml
├── snapshots/          # dim_bookings, dim_hosts, dim_listings (SCD2)
├── tests/
│   └── source_tests.sql
├── dbt_project.yml
├── profiles.yml        # ⚠️ Contains real credentials — must not be committed
├── profiles.yml.example
└── .gitignore
```

**Missing:** `packages.yml`, model-level `schema.yml`, `.github/workflows/`, `README` run instructions aligned with project.

### 1.2 dbt and adapter versions

- **dbt:** 1.10.19 (from `target/manifest.json`).
- **Adapter:** dbt-snowflake (seen in .venv as 1.10.7; project does not pin in `packages.yml`).

**Recommendation:** Add `packages.yml` to pin dbt and adapter versions for reproducible builds.

### 1.3 Schema configuration

| Layer    | dbt config              | Resolved schema (with current macro) |
|----------|-------------------------|--------------------------------------|
| Default  | —                       | `target.schema` → `dbt_schema`       |
| Bronze   | `+schema: bronze`       | `bronze`                             |
| Silver   | `+schema: silver`       | `silver`                             |
| Gold     | `+schema: gold`         | `gold`                               |
| Snapshots| `target_schema='gold'`  | `AIRBNB.GOLD` (hardcoded DB)         |

**Sources:** `database: AIRBNB`, `schema: staging` — hardcoded in `models/sources/sources.yml`.

### 1.4 dbt_project.yml

- **Verdict:** Largely correct.
- **Findings:**
  - `model-paths`, `snapshot-paths`, `macro-paths`, `test-paths` are set.
  - Bronze/Silver/Gold have `+materialized: table` and `+schema` set.
  - Gold ephemeral folder has `+materialized: ephemeral`.
  - **Missing:** `vars`, `dispatch` for macro namespacing, `docs` config, `query-comment` for observability.

---

## Step 2 — Correctness & Safety Checks

### 2.1 ref() targets

| ref()               | Target file                          | Exists |
|---------------------|--------------------------------------|--------|
| `ref('bronze_bookings')`  | models/bronze/bronze_bookings.sql   | ✅     |
| `ref('bronze_hosts')`     | models/bronze/bronze_hosts.sql       | ✅     |
| `ref('bronze_listings')` | models/bronze/bronze_listings.sql   | ✅     |
| `ref('silver_bookings')` | models/silver/silver_bookings.sql   | ✅     |
| `ref('silver_hosts')`    | models/silver/silver_hosts.sql      | ✅     |
| `ref('silver_listings')` | models/silver/silver_listings.sql   | ✅     |
| `ref('obt')`             | models/gold/obt.sql                 | ✅     |
| `ref('bookings')`        | models/gold/ephemeral/bookings.sql  | ✅     |
| `ref('hosts')`           | models/gold/ephemeral/hosts.sql     | ✅     |
| `ref('listings')`        | models/gold/ephemeral/listings.sql  | ✅     |

All `ref()` targets exist. **Note:** `ref('fact')` is never used; `fact.sql` is dead code.

### 2.2 source() definitions

- **sources.yml** defines `staging` with tables `listings`, `bookings`, `hosts`.
- All `source('staging', ...)` references use these names — **match**.

**Missing:** `loaded_at` (or similar) for source freshness; no `freshness` or `loaded_at_field` in sources.

### 2.3 Hardcoded database/schema/warehouse/role

| File                          | Issue |
|-------------------------------|--------|
| `models/sources/sources.yml`  | `database: AIRBNB` hardcoded. |
| `snapshots/dim_bookings.sql`  | `target_database='AIRBNB'` hardcoded. |
| `snapshots/dim_hosts.sql`     | `target_database='AIRBNB'` hardcoded. |
| `snapshots/dim_listings.sql`  | `target_database='AIRBNB'` hardcoded. |
| `models/gold/ephemeral/fact.sql` | `AIRBNB.GOLD.OBT`, `AIRBNB.GOLD.DIM_*` and raw table names (not `ref()`). |

**Correct approach:** Use `target.database` (e.g. in vars or in macro) and `ref()` for all model references.

### 2.4 Credentials / secrets

- **profiles.yml** contains:
  - `account: WDOGKVX-UTC81757`
  - `user: PAVANKOLLI0601`
  - `password: Sublime@06010601`
- **.gitignore** includes `profiles.yml`, so it *should* not be committed.
- **Risk:** If the repo was ever cloned or shared with profiles.yml, credentials are exposed. Use `env_var()` for password (and ideally account/user) and never commit profiles.yml.

### 2.5 Snapshot configuration (SCD2)

| Snapshot      | unique_key  | updated_at       | Issue |
|---------------|-------------|------------------|--------|
| dim_bookings  | BOOKING_ID  | CREATED_AT       | ✅ Grain correct. |
| dim_hosts     | HOST_NAME   | HOST_CREATED_AT  | ❌ **HOST_NAME is not unique.** Two hosts can share a name; SCD2 can merge wrong rows. Use HOST_ID. |
| dim_listings  | LISTING_ID  | LISTING_CREATED_AT | ✅ Grain correct. |

**dim_hosts:** Ephemeral `hosts` (and OBT) do not expose `HOST_ID` today. You need to add `HOST_ID` to OBT and to the ephemeral `hosts`, then set `unique_key='HOST_ID'` in the snapshot.

**Snapshot source:** All three snapshots select from ephemeral models that ultimately read from `obt`. That is valid (ephemeral is inlined), but run order must be: models → snapshots.

---

## Step 3 — Data Modeling Review

### 3.1 Bronze

- **Transformation:** Minimal (pass-through from staging). ✅
- **Incremental:** Uses `CREATED_AT > (SELECT COALESCE(MAX(CREATED_AT), '1900-01-01') FROM {{ this }})`.
  - **Issue 1:** No `unique_key`. Default incremental strategy is `append`, so re-loaded staging rows create **duplicates** in bronze.
  - **Issue 2:** Watermark on `CREATED_AT` only is safe only if staging is append-only and `CREATED_AT` is strictly increasing per source. If staging can have updates (same business key, new CREATED_AT), you still get duplicates without merge.
- **Recommendation:** Add `unique_key` and use `merge` strategy (e.g. `unique_key='BOOKING_ID'` for bronze_bookings, and equivalent for hosts/listings) so re-runs are idempotent.

### 3.2 Silver

- **silver_bookings:**
  - Has `unique_key='BOOKING_ID'` — good.
  - **Missing incremental filter:** No `{% if is_incremental() %} WHERE ... {% endif %}` on the source. So every run reads **full** `bronze_bookings` and merges; correct but expensive.
  - **Recommendation:** Add `WHERE CREATED_AT > (SELECT COALESCE(MAX(CREATED_AT), '1900-01-01') FROM {{ this }})` in incremental runs to limit source scan.
- **silver_hosts / silver_listings:** Have both `unique_key` and incremental filter — good.

### 3.3 Gold

- **OBT:**
  - Single fact grain: one row per booking (from silver_bookings). ✅
  - Joins to listings and hosts via LISTING_ID and HOST_ID — correct.
  - **Issue:** `HOST_ID` is excluded from the select (`h.* EXCLUDE (HOST_ID, CREATED_AT)`). So OBT does **not** expose `HOST_ID`, which hurts star-style reporting and forces dim_hosts to use `HOST_NAME` as key.
  - **Recommendation:** Add `l.HOST_ID AS HOST_ID` (or keep from listing) and expose it in OBT so gold has a proper host FK.
- **Ephemeral bookings/hosts/listings:** Subsets of OBT for snapshot sources — OK.
- **fact.sql (ephemeral):**
  - Hardcoded `AIRBNB.GOLD.*`, join to dims on `HOST_NAME` (not key), and **no model references it** — dead code and not environment-agnostic.
  - Either remove or refactor to use `ref('obt')`, `ref('dim_listings')`, `ref('dim_hosts')` and join on LISTING_ID / HOST_ID.

### 3.4 Incremental summary

| Model           | unique_key   | Incremental filter on source | Strategy (default) |
|----------------|-------------|------------------------------|---------------------|
| bronze_*       | ❌ none     | ✅ CREATED_AT                 | append → risk of duplicates |
| silver_bookings| ✅ BOOKING_ID | ❌ no                         | merge ✅ |
| silver_hosts   | ✅ HOST_ID  | ✅ CREATED_AT                 | merge ✅ |
| silver_listings| ✅ LISTING_ID | ✅ CREATED_AT                 | merge ✅ |

### 3.5 Fanout / grain / surrogate keys

- **OBT grain:** One row per booking — no fanout.
- **Star schema:** No materialized fact table; OBT is the main gold table. Snapshots produce DIM_* in gold; no separate FACT_BOOKINGS with FKs to dims.
- **Surrogate keys:** Not used. All keys are natural (BOOKING_ID, LISTING_ID, HOST_ID). Acceptable for this size; for larger scale or SCD2 dims, surrogate keys in gold can help.

---

## Step 4 — Testing & Data Quality

### 4.1 Current tests

- **Generic/singular:** `tests/source_tests.sql` — custom SQL that warns when `BOOKING_AMOUNT < 200` (business rule).
- **Config:** `severity='warn',)` — trailing comma may be invalid in some dbt versions; use `severity: 'warn'` and no trailing comma.
- **Schema tests on models:** None (no `schema.yml` defining tests on models).

### 4.2 Missing high-value tests

- **unique:** BOOKING_ID (silver_bookings, bronze_bookings), LISTING_ID (silver_listings, bronze_listings), HOST_ID (silver_hosts, bronze_hosts).
- **not_null:** Core FKs and date fields (e.g. BOOKING_ID, LISTING_ID, CREATED_AT, BOOKING_DATE).
- **relationships:** silver_bookings.LISTING_ID → silver_listings.LISTING_ID; silver_listings.HOST_ID → silver_hosts.HOST_ID; silver_bookings.BOOKING_ID → gold OBT.
- **accepted_values:** e.g. BOOKING_STATUS in `('confirmed', 'cancelled', ...)` if applicable.

### 4.3 Source freshness

- No `freshness` or `loaded_at_field` in `sources.yml`. Add a `loaded_at` (or equivalent) column in staging and define freshness so `dbt source freshness` can detect stale data.

### 4.4 schema.yml and tests — examples

See section **Deliverables** below for patch-ready `models/schema.yml` (or per-folder schema files) with tests and docs.

---

## Step 5 — Performance Optimization

- **Heavy joins:** OBT does two LEFT JOINs (bookings → listings → hosts). Reasonable; ensure LISTING_ID and HOST_ID are used in join keys (already are).
- **CTEs:** No long unnecessary CTE chains.
- **Bronze/Silver:** Full table scan on bronze in silver_bookings every run — add incremental filter on CREATED_AT.
- **Clustering (Snowflake):** For large tables, consider `cluster_by = ['BOOKING_DATE']` on OBT and clustering keys on LISTING_ID/HOST_ID for dims. Add in model config where beneficial.
- **Materialization:** Bronze/Silver as incremental tables is appropriate. OBT as table is fine; if it grows very large, consider incremental (e.g. by BOOKING_DATE) or partitioning.

---

## Step 6 — CI/CD & Production Readiness

- **Current state:** No `.github/workflows/` — no CI.
- **Recommended:** Add a workflow that runs `dbt deps`, `dbt compile`, `dbt build` (or `dbt run` + `dbt test`), and optionally `dbt docs generate`. Use secrets for Snowflake credentials. Optionally add Slim CI with state comparison and artifact upload (manifest, run_results).

See **Deliverables** for ready-to-use workflow YAML.

- **SQLFluff:** Add `.sqlfluff` and run in CI for SQL style.
- **Pre-commit:** Optional pre-commit config for dbt compile, SQLFluff, and YAML checks.
- **Artifacts:** Upload `target/manifest.json`, `target/run_results.json` (and `target/catalog.json` if used) as workflow artifacts.

---

## Step 7 — Portfolio Enhancement Suggestions

1. **Observability:** Use `query-comment` in dbt_project to tag runs with job name and invocation ID; consider dbt_artifacts or similar for run history.
2. **Governance:** Add `meta` and `tags` to models; document owner and PII columns in schema.yml.
3. **Model contracts:** Add `contract: enforced` and `columns` to key models (e.g. silver and gold) so breaking changes are caught at build time.
4. **Documentation:** One schema.yml (or per-layer) with descriptions for all models and key columns; `dbt docs generate` and host (e.g. GitHub Pages or internal).
5. **Scalability:** Document incremental strategy and clustering in README; add vars for batch dates or limits for testing.
6. **Production realism:** README with env vars (e.g. `SNOWFLAKE_*`), required schemas (STAGING, BRONZE, SILVER, GOLD), and run order (dbt run → dbt snapshot → dbt test).
7. **Secrets:** Replace all credentials in profiles with `env_var()` and document in README.
8. **dbt packages:** Add `packages.yml` and pin dbt-core and dbt-snowflake.

---

## Final Deliverables Format

### ✅ Must-Fix Issues

1. **profiles.yml — credentials**
   - **Path:** `profiles.yml`
   - **Problem:** Real account, user, and password in file. If repo is public or shared, credentials are exposed.
   - **Fix:** Use `env_var('SNOWFLAKE_PASSWORD')` (and optionally account/user). Ensure `profiles.yml` is in `.gitignore` and never committed. See `profiles.yml.example` patch below.

2. **Snapshot dim_hosts — unique_key**
   - **Path:** `snapshots/dim_hosts.sql`
   - **Problem:** `unique_key='HOST_NAME'` is not unique; SCD2 can produce wrong history.
   - **Fix:** Add HOST_ID to OBT and to ephemeral `hosts`, then set `unique_key='HOST_ID'` in snapshot. (Code patches below.)

3. **OBT — expose HOST_ID**
   - **Path:** `models/gold/obt.sql`
   - **Problem:** HOST_ID is excluded; gold layer has no host FK for star schema and forces dim_hosts to use HOST_NAME.
   - **Fix:** Add `l.HOST_ID AS HOST_ID` in the SELECT.

4. **fact.sql — hardcoded DB and dead code**
   - **Path:** `models/gold/ephemeral/fact.sql`
   - **Problem:** Uses `AIRBNB.GOLD.*` and no `ref()`; not referenced by any model; not environment-agnostic.
   - **Fix:** Either remove fact.sql or refactor to use `ref('obt')`, `ref('dim_listings_snapshot')`, `ref('dim_hosts_snapshot')` and join on LISTING_ID/HOST_ID. Prefer refs and env-agnostic pattern.

5. **Silver_bookings — incremental filter**
   - **Path:** `models/silver/silver_bookings.sql`
   - **Problem:** No incremental filter; every run reads full bronze_bookings.
   - **Fix:** Add `{% if is_incremental() %} WHERE CREATED_AT > (SELECT COALESCE(MAX(CREATED_AT), '1900-01-01') FROM {{ this }}) {% endif %}`.

6. **Bronze — idempotent incremental**
   - **Path:** `models/bronze/bronze_bookings.sql` (and hosts, listings similarly)
   - **Problem:** No unique_key; append-only causes duplicates on re-load.
   - **Fix:** Add `unique_key` (e.g. BOOKING_ID) so merge strategy is used; ensure staging has that key.

7. **Test config syntax**
   - **Path:** `tests/source_tests.sql`
   - **Problem:** `severity='warn',)` — trailing comma.
   - **Fix:** Use `severity: 'warn'` (or `severity='warn'`) and remove trailing comma.

8. **Snapshots — target_database**
   - **Path:** `snapshots/dim_*.sql`
   - **Problem:** `target_database='AIRBNB'` hardcoded.
   - **Fix:** Use `target_database=target.database` or a var (e.g. `var('database')`) so different environments work.

### ⚠️ Risks / Technical Debt

- **generate_schema_name:** Overrides default and does not prefix custom schema with target.schema (e.g. `bronze` not `dbt_schema_bronze`). Intentional but worth documenting; multi-environment deployments may expect prefixed schemas.
- **No packages.yml:** dbt and adapter versions not pinned; builds can drift.
- **No model-level schema.yml:** No documentation or generic tests on models; harder to maintain and onboard.
- **Ephemeral fact:** fact.sql is unused; either remove or integrate into a materialized mart.
- **Source freshness:** Staging has no freshness defined; stale data not detected.

### 🚀 High-Impact Improvements

- Add `packages.yml` and pin dbt-core and dbt-snowflake.
- Add schema.yml (or one per layer) with descriptions, columns, unique/not_null/relationships/accepted_values tests.
- Add source freshness and `loaded_at` in sources.
- Add GitHub Actions workflow: dbt deps, dbt build, dbt test, with Snowflake secrets.
- Replace all hardcoded `AIRBNB` with `target.database` or vars.
- Add SQLFluff and run in CI; optional pre-commit.
- Document run order and env vars in README; add model contracts on silver/gold for key columns.

### 📦 Suggested 3-PR Plan

- **PR1 — Critical fixes:**  
  Fix credentials (env vars), snapshot dim_hosts unique_key (add HOST_ID to OBT and ephemeral hosts), OBT HOST_ID, silver_bookings incremental filter, bronze unique_key, source_tests.sql config, snapshot target_database, and remove or refactor fact.sql.

- **PR2 — Testing & documentation:**  
  Add packages.yml; add schema.yml with model/column descriptions and tests (unique, not_null, relationships, accepted_values); add source freshness; fix/expand README.

- **PR3 — CI/CD & performance:**  
  Add GitHub Actions workflow (dbt deps, build, test), SQLFluff config and CI step, optional pre-commit, artifact upload; add clustering/config for large-table performance where needed.

---

---

## Applied Patches (from this audit)

The following fixes have been applied in the repo:

| Item | File(s) changed |
|------|------------------|
| OBT expose HOST_ID | `models/gold/obt.sql` |
| Silver_bookings incremental filter | `models/silver/silver_bookings.sql` |
| Bronze unique_key (merge) | `models/bronze/bronze_*.sql` |
| Snapshot dim_hosts unique_key=HOST_ID + HOST_ID in select | `snapshots/dim_hosts.sql`, `models/gold/ephemeral/hosts.sql` |
| Snapshots remove target_database | `snapshots/dim_*.sql` |
| fact.sql refactor (refs + HOST_ID) | `models/gold/ephemeral/fact.sql` |
| source_tests config | `tests/source_tests.sql` |
| Sources database → target.database, descriptions | `models/sources/sources.yml` |
| Schema + tests (bronze, silver, gold) | `models/*/schema.yml` |
| packages.yml (dbt_utils) | `packages.yml` |
| CI workflow | `.github/workflows/dbt.yml` |
| SQLFluff config | `.sqlfluff` |
| profiles.example env_var | `profiles.yml.example` |
| requirements.txt | `requirements.txt` |

**You must still:** Move real credentials out of `profiles.yml` and use env vars (see `profiles.yml.example`). Ensure `profiles.yml` is in `.gitignore` and never committed.

---

*End of technical audit.*
