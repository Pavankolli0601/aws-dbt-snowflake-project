# Step 1 — All Current Errors and Root Causes

Captured from: `dbt clean` → `dbt deps` → `dbt parse` → `dbt run` → `dbt test`  
(Using project venv: `.venv/bin/dbt`)

---

## 1. ERROR — dbt run: model `obt` fails

**Message:**
```
Database Error in model obt (models/gold/obt.sql)
100038 (22018): DML operation to table ... GOLD.OBT failed on column BOOKING_ID with error:
Numeric value 'ef0bd262-f88d-477f-aeba-9c69cc72c051' is not recognized
```

**File:** `models/gold/obt.sql` (and contract in `models/gold/schema.yml`)

**Root cause:** BOOKING_ID, LISTING_ID, and HOST_ID are **UUIDs (strings)** in source data. The OBT was changed to cast them to `NUMBER(38, 0)` and the contract was set to `number(38, 0)`. Snowflake cannot cast UUID strings to NUMBER, so the insert fails. The contract and SQL must use **string** for these ID columns to match the actual data.

---

## 2. ERROR — dbt test: `not_null_obt_HOST_ID` fails

**Message:**
```
Database Error in test not_null_obt_HOST_ID (models/gold/schema.yml)
000904 (42000): SQL compilation error: invalid identifier 'HOST_ID'
```

**File:** `models/gold/schema.yml` (test definition); test runs against table `gold.obt`.

**Root cause:** The OBT model did not build successfully (see #1), so the `gold.obt` table either does not exist or is from an older run without the `HOST_ID` column. Fixing the OBT run (reverting ID types to string so the model succeeds) will create the table with `HOST_ID` and resolve this test failure.

---

## 3. WARNING — dbt run: numeric precision

**Message:**
```
Detected columns with numeric type and unspecified precision/scale:
['TOTAL_AMOUNT', 'SERVICE_FEE', 'CLEANING_FEE', 'ACCOMMODATES', 'BEDROOMS', 'BATHROOMS', 'PRICE_PER_NIGHT', 'RESPONSE_RATE']
```

**File:** Contract / model `models/gold/obt.sql` (contract in `models/gold/schema.yml`).

**Root cause:** Those columns are typed as `number` in the contract without precision/scale. dbt/Snowflake warns that this can lead to unintended rounding. Optional for release: specify e.g. `number(38, 2)` for amounts and appropriate types for others.

---

## 4. WARNING — dbt test: `source_tests` (286 rows)

**Message:**
```
Warning in test source_tests (tests/source_tests.sql)
Got 286 results, configured to warn if != 0
```

**File:** `tests/source_tests.sql`

**Root cause:** Singular test returns rows where `BOOKING_AMOUNT < 200`; 286 rows match. The test is configured as `warn`, so it is working as designed. Not a code bug; either accept the warning or tighten the business rule.

---

## 5. WARNING — dbt parse: generic test deprecation (2 occurrences)

**Message:**
```
MissingArgumentsPropertyInGenericTestDeprecation: Arguments to generic tests should be nested under the `arguments` property.
```

**File:** `models/silver/schema.yml` (both `relationships` tests).

**Root cause:** In dbt 1.10+, arguments for generic tests (e.g. `to`, `field` for `relationships`) must be under an `arguments:` key. Current format is deprecated and will break in a future version.

---

## 6. Environment — system `dbt` fails (Python 3.14)

**Message:**
```
mashumaro.exceptions.UnserializableField: Field "schema" of type Optional[str] in JSONObjectSchema is not serializable
```
(When running `dbt` from system PATH, e.g. Python 3.14.)

**File:** N/A (dbt CLI import failure).

**Root cause:** System Python 3.14 and/or system-installed dbt-core use a mashumaro version incompatible with Python 3.14. Use the project virtualenv: `.venv/bin/dbt` or `make deps` / `make build` / `make test` so dbt runs with the project’s Python 3.12 and pinned dbt.

---

## Summary: true root causes (non-duplicate)

| # | Root cause | Fix |
|---|------------|-----|
| 1 | IDs are UUID (string) in data; OBT casts them to NUMBER | Revert OBT SQL and contract to **string** for BOOKING_ID, LISTING_ID, HOST_ID. Keep BOOKING_DATE::DATE. |
| 2 | OBT table missing or stale because run failed | Same as #1: fix OBT run so table has HOST_ID. |
| 3 | Contract uses unspecified numeric precision | Optional: set precision/scale for numeric columns in gold schema. |
| 4 | Business rule warning (286 rows) | Accept or change rule in source_tests.sql. |
| 5 | relationships test format deprecated | Move `to`/`field` under `arguments:` in silver/schema.yml. |
| 6 | System dbt on Python 3.14 | Use `.venv/bin/dbt` or Makefile; document in README. |

---

## Commands used

```bash
cd "/Users/pavankumarreddykolli/Desktop/Air BnB Data Project/DBT_Snowflake/aws_dbt_snowflake_project"
.venv/bin/dbt clean
.venv/bin/dbt deps
.venv/bin/dbt parse
.venv/bin/dbt run
.venv/bin/dbt test
```

---

## Fixes applied (release mode)

| # | Fix |
|---|-----|
| 1 & 2 | **OBT IDs:** Reverted to string in contract (`models/gold/schema.yml`). In SQL (`models/gold/obt.sql`) use `::VARCHAR` for BOOKING_ID, LISTING_ID, HOST_ID so contract type matches; keep `BOOKING_DATE::DATE`. |
| 5 | **relationships tests:** In `models/silver/schema.yml`, nested `to` and `field` under `arguments:` for both relationships tests (dbt 1.10 format). |
| Parse | Deprecation warnings for relationships are resolved after the YAML update. |

**Result:** `dbt run` and `dbt test` complete successfully. One remaining warning: `source_tests` (286 rows with BOOKING_AMOUNT &lt; 200), by design.
