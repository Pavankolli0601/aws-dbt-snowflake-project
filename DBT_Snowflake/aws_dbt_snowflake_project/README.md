# AWS DBT Snowflake Project

Data pipeline: **AWS S3 → Snowflake (staging) → dbt** with **Bronze → Silver → Gold** layers.

**Stack:** dbt-core 1.10.19, dbt-snowflake 1.10.7, dbt-utils 1.3.3.  
**Status:** Project builds with `dbt build`; 29 tests pass, 1 intentional warn (`source_tests`).

---

## Quick start

```bash
pip install -r requirements.txt
cp profiles.yml.example profiles.yml   # then set env vars (see below)
make deps
make build
```

Set [environment variables](#how-to-set-environment-variables-safely) before running. `dbt build` runs models and tests.

| Make target     | Command                |
|-----------------|------------------------|
| `make deps`     | `dbt deps`             |
| `make build`    | `dbt build`            |
| `make test`     | `dbt test`             |
| `make lint`     | `sqlfluff lint`        |
| `make run`      | `dbt run`              |
| `make snapshot` | `dbt snapshot`        |
| `make docs`     | `dbt docs generate`    |
| `make all`      | deps + build + lint     |

Override incremental lookback (default 3 days): `dbt run --vars 'lookback_days: 7'` or `dbt build --vars 'lookback_days: 7'`.

---

## Project structure

| Layer    | Path              | Description |
|----------|-------------------|-------------|
| Bronze   | `models/bronze/`  | Raw incremental tables from staging; merge by business key. |
| Silver   | `models/silver/`  | Cleaned models; incremental with rolling-window lookback. |
| Gold     | `models/gold/`    | One Big Table (OBT) plus ephemeral models for snapshots. |
| Snapshots| `snapshots/`      | SCD2: dim_bookings, dim_hosts, dim_listings. |
| Macros   | `macros/`         | Reusable SQL (e.g. `multiply`, `tag`). |
| Tests    | `tests/`          | Singular and schema tests. |

**Gold layer:** OBT enforces a dbt model contract. IDs (`BOOKING_ID`, `LISTING_ID`, `HOST_ID`) are stored as VARCHAR (UUID-compatible); `BOOKING_DATE` is stored as DATE. Snapshots dim_bookings and dim_listings also have enforced contracts.

**Config:** `vars.lookback_days` (default `3`) in `dbt_project.yml` for incremental lookback.

---

## How to set environment variables safely

Do not put Snowflake credentials in `profiles.yml` or commit them. Use environment variables only.

**Required:** `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`.  
**Optional:** `SNOWFLAKE_SCHEMA` (default `dbt_schema`).

**Option 1 — .env (do not commit):** Create `.env` with `export SNOWFLAKE_ACCOUNT=...` etc., then `source .env` before running dbt.

**Option 2 — Shell:** `export SNOWFLAKE_ACCOUNT=...` (and the rest) in your session.

**Option 3 — Script:** Copy `scripts/set_env_example.sh` to `scripts/set_env.sh`, set values (do not commit `set_env.sh`), then `source scripts/set_env.sh`.

Then: `cp profiles.yml.example profiles.yml` and run `make build`.

**CI/CD:** Store each value as a repository secret; reference in the workflow. Do not log or echo secrets.

---

## CI (GitHub Actions)

| Trigger        | Job       | Steps |
|----------------|-----------|--------|
| Push/PR to main| `dbt-pr`  | dbt deps → compile → build → test → sqlfluff lint; upload manifest and run_results. |
| Daily 06:00 UTC| `dbt-daily` | dbt deps → source freshness → test. |

Secrets: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`.

---

## If `profiles.yml` was ever committed

1. Rotate credentials in Snowflake.
2. Remove from history: `git filter-repo --path profiles.yml --invert-paths --force` (or BFG).
3. Ensure `.gitignore` includes `profiles.yml` and `.env`; recreate `profiles.yml` from the example and use env vars only.
