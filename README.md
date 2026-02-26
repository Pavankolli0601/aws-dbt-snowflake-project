# Air BnB Data Project

An end-to-end data pipeline for Airbnb-style booking data using **AWS**, **Snowflake**, and **dbt**.

## Repository structure

- **`DBT_Snowflake/`** – dbt project (Bronze → Silver → Gold) with Snowflake
- **`Source_file/`** – Sample CSV data (listings, hosts, bookings)
- **`snoaflake-dbt.png`** – Architecture / reference diagram

## Quick start

1. **Clone and enter the dbt project**
   ```bash
   cd DBT_Snowflake/aws_dbt_snowflake_project
   ```

2. **Configure Snowflake**
   - Copy `profiles.yml.example` to `profiles.yml`
   - Set `SNOWFLAKE_PASSWORD` in your environment, or edit `profiles.yml` (do not commit it)
   ```bash
   cp profiles.yml.example profiles.yml
   export SNOWFLAKE_PASSWORD='your_password'
   ```

3. **Install and run dbt**
   ```bash
   pip install dbt-core dbt-snowflake
   dbt run
   dbt snapshot
   dbt test
   ```

For more detail, see [DBT_Snowflake/README.md](DBT_Snowflake/README.md).

## License

Use and modify as needed for your own environment.
