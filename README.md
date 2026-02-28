# AWS S3 → Snowflake → dbt Data Engineering Project

An end-to-end analytics pipeline built using AWS S3, Snowflake, and dbt, implementing a production-style Bronze → Silver → Gold architecture with incremental models, SCD Type 2 snapshots, data quality tests, and CI validation.

---

## Tech Stack

- dbt-core 1.11.x
- dbt-snowflake 1.11.x
- dbt-utils 1.3.3
- Snowflake
- AWS S3
- SQLFluff (linting)
- GitHub Actions (CI/CD)

---

## Project Status

- Successfully builds with `dbt build`
- Bronze, Silver, and Gold layers fully operational
- Incremental models working
- Snapshots implemented (SCD Type 2)
- Data quality tests passing
- CI workflow configured

---

# Architecture

This project follows the Medallion Architecture pattern.

| Layer     | Path              | Purpose |
|------------|------------------|----------|
| Bronze     | models/bronze/   | Raw ingestion using incremental merge logic |
| Silver     | models/silver/   | Cleaned and standardized transformations |
| Gold       | models/gold/     | Analytics-ready dimensional models + OBT |
| Snapshots  | snapshots/       | SCD Type 2 historical tracking |
| Macros     | macros/          | Reusable SQL utilities |
| Tests      | tests/           | Schema and singular data tests |

---

# Data Modeling Strategy

## Bronze Layer

- Incremental models using merge strategy
- Idempotent loads using business keys
- Safe re-runs
- Raw ingestion from staging

Models:
- bronze_bookings
- bronze_hosts
- bronze_listings

---

## Silver Layer

- Standardized and cleaned data
- Incremental models with rolling lookback window
- Relationship tests enforced

Override lookback window:

```
dbt build --vars 'lookback_days: 7'
```

Default lookback: 3 days

---

## Gold Layer

Analytics-ready dimensional models:

- dim_bookings
- dim_hosts
- dim_listings
- fact
- obt (One Big Table)

Features:
- Star-schema modeling
- Enforced dbt model contracts
- Primary key validations
- Reporting-ready structure

Data types:
- IDs stored as VARCHAR (UUID compatible)
- BOOKING_DATE stored as DATE

---

## Snapshots (SCD Type 2)

Implements historical tracking for:

- Bookings
- Hosts
- Listings

Features:
- Valid-from / valid-to timestamps
- Change detection
- Historical state preservation

---

# Running the Project

## 1. Install Dependencies

```
pip install -r requirements.txt
```

## 2. Configure Environment Variables

Required:

- SNOWFLAKE_ACCOUNT
- SNOWFLAKE_USER
- SNOWFLAKE_PASSWORD
- SNOWFLAKE_ROLE
- SNOWFLAKE_WAREHOUSE
- SNOWFLAKE_DATABASE

Optional:

- SNOWFLAKE_SCHEMA

You can configure using:

- .env file (not committed)
- Shell export
- GitHub repository secrets (CI)

---

## 3. Create Local Profile

```
cp profiles.yml.example profiles.yml
```

---

## 4. Install dbt Packages

```
dbt deps
```

---

## 5. Build the Project

```
dbt build
```

---

# Makefile Commands

| Command         | Description |
|----------------|------------|
| make deps      | Install dbt packages |
| make build     | Run models + tests |
| make run       | Run models only |
| make test      | Run tests only |
| make snapshot  | Run snapshots |
| make lint      | Run SQLFluff |
| make docs      | Generate dbt documentation |

---

# Data Quality

Implemented validations:

- Unique and not-null tests on primary keys
- Relationship tests between fact and dimensions
- Source-level validation tests
- Enforced contracts in Gold layer

All validations executed via:

```
dbt test
```

---

# CI/CD (GitHub Actions)

On Pull Request / Push to main:

- dbt deps
- dbt compile
- dbt build
- dbt test
- sqlfluff lint
- Upload artifacts (manifest.json, run_results.json)

Optional scheduled workflow:

- dbt source freshness
- dbt test

Snowflake credentials are securely stored as GitHub repository secrets.

---

# Security

- profiles.yml is not committed
- Credentials managed via environment variables
- .env ignored
- target/, dbt_packages/, .venv/ ignored
- No hardcoded secrets in repository

If credentials are exposed:
1. Rotate them in Snowflake
2. Remove from git history
3. Reconfigure using environment variables

---

# Key Features Demonstrated

- End-to-end AWS → Snowflake → dbt pipeline
- Incremental merge-based ingestion
- Rolling-window late-arriving data handling
- Medallion architecture (Bronze → Silver → Gold)
- SCD Type 2 snapshots
- Enforced model contracts
- Automated CI validation
- Production-style data engineering practices

---

# Summary

This project demonstrates a production-ready modern data stack implementation using Snowflake, dbt, and AWS S3. It showcases scalable architecture, reliable incremental processing, historical tracking, automated testing, and CI-driven validation — reflecting real-world data engineering best practices.