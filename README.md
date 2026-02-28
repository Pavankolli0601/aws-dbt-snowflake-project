AWS DBT Snowflake Project

End-to-end analytics pipeline built with AWS S3 → Snowflake → dbt, implementing a Bronze → Silver → Gold architecture with incremental models, SCD Type 2 snapshots, model contracts, and CI validation.

Stack

dbt-core 1.10.19

dbt-snowflake 1.10.7

dbt-utils 1.3.3

Snowflake

AWS S3

Status

Builds successfully with dbt build

29 tests passing

1 intentional warning (source_tests)

Architecture
Project Structure
Layer	Path	Purpose
Bronze	models/bronze/	Incremental raw ingestion from staging with merge logic
Silver	models/silver/	Cleaned and standardized models with rolling-window lookback
Gold	models/gold/	Analytics-ready models (OBT) with enforced contracts
Snapshots	snapshots/	SCD Type 2 dimensions (dim_bookings, dim_hosts, dim_listings)
Macros	macros/	Reusable SQL utilities
Tests	tests/	Schema and singular tests
Data Modeling
Bronze

Incremental models using merge strategy

Business-key based idempotent loads

Silver

Standardized data

Incremental with rolling lookback (vars.lookback_days, default 3)

Relationships enforced via tests

Gold

One Big Table (OBT) for reporting

Enforced dbt model contract

IDs (BOOKING_ID, LISTING_ID, HOST_ID) stored as VARCHAR (UUID-compatible)

BOOKING_DATE stored as DATE

Snapshots

SCD Type 2 implementation

Historical tracking of booking and listing changes

Running the Project
Install Dependencies
pip install -r requirements.txt
Configure Environment Variables

Required variables:

SNOWFLAKE_ACCOUNT
SNOWFLAKE_USER
SNOWFLAKE_PASSWORD
SNOWFLAKE_ROLE
SNOWFLAKE_WAREHOUSE
SNOWFLAKE_DATABASE

Optional:

SNOWFLAKE_SCHEMA (default: dbt_schema)

Set them via:

Shell export

.env file (do not commit)

scripts/set_env.sh (not committed)

GitHub Secrets (for CI)

Create local profile:

cp profiles.yml.example profiles.yml
Build and Test
make deps
make build

Available commands:

Command	Action
make deps	Install dbt packages
make build	Run models + tests
make run	Run models only
make test	Run tests only
make snapshot	Run snapshots
make lint	SQLFluff lint
make docs	Generate dbt docs

Override incremental lookback:

dbt build --vars 'lookback_days: 7'
Data Quality

Unique and not-null constraints on primary keys

Relationship tests between fact and dimension models

Source-level validation tests

29 tests passing

1 intentional warning demonstrating anomaly detection

CI (GitHub Actions)
Pull Requests / Push to main

dbt deps

dbt compile

dbt build

dbt test

sqlfluff lint

Upload artifacts (manifest.json, run_results.json)

Daily Job

dbt deps

dbt source freshness

dbt test

All Snowflake credentials are stored securely as GitHub repository secrets.

Security

profiles.yml is not committed

Credentials managed via environment variables only

target/, dbt_packages/, .venv/ are ignored

package-lock.yml committed for reproducible installs

If credentials were ever committed:

Rotate them in Snowflake

Remove from git history

Reconfigure using environment variables

Key Features Demonstrated

End-to-end AWS → Snowflake → dbt pipeline

Incremental merge-based ingestion

Rolling-window late-arriving data handling

Star-schema style Gold layer

SCD Type 2 snapshots

Enforced dbt model contracts

Automated CI validation

Reproducible dependency management

This project reflects production-style data modeling practices using the modern data stack.