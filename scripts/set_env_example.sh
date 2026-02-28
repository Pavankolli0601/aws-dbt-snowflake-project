#!/usr/bin/env bash
# Example: set Snowflake env vars before running dbt.
# Copy to set_env.sh, fill in values, and run: source scripts/set_env.sh
# Do NOT commit set_env.sh if it contains real values.

export SNOWFLAKE_ACCOUNT="${SNOWFLAKE_ACCOUNT:-your_account}"
export SNOWFLAKE_USER="${SNOWFLAKE_USER:-your_username}"
export SNOWFLAKE_PASSWORD="${SNOWFLAKE_PASSWORD:-}"
export SNOWFLAKE_ROLE="${SNOWFLAKE_ROLE:-ACCOUNTADMIN}"
export SNOWFLAKE_WAREHOUSE="${SNOWFLAKE_WAREHOUSE:-COMPUTE_WH}"
export SNOWFLAKE_DATABASE="${SNOWFLAKE_DATABASE:-AIRBNB}"
export SNOWFLAKE_SCHEMA="${SNOWFLAKE_SCHEMA:-dbt_schema}"
