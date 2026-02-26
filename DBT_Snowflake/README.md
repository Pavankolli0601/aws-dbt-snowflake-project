### AWS + Snowflake + dbt Data Pipeline

## About This Project

In this project, I built an end-to-end data pipeline using AWS, Snowflake, and dbt to simulate a real-world analytics workflow.

The goal was to take raw Airbnb-style booking data stored in Amazon S3 and transform it into analytics-ready tables using a structured Bronze → Silver → Gold architecture.

This project focuses on performance, scalability, and clean data modeling practices.

## What I Built

1. Data Ingestion (AWS → Snowflake)
	•	Uploaded CSV files to Amazon S3
	•	Created an IAM role to securely connect Snowflake to S3
	•	Loaded raw data into the STAGING schema in Snowflake
	•	Organized warehouse structure using separate schemas:
	•	BRONZE
	•	SILVER
	•	GOLD

2. Bronze Layer
This layer pulls raw data from STAGING and applies minimal transformation.
	•	Implemented incremental loading
	•	Used timestamp logic to process only new records
	•	Designed for performance and scalability

The goal here is to preserve raw structure while optimizing load performance.

3. Silver Layer
This is where business logic is applied.
	•	Cleaned and standardized data
	•	Enforced unique keys
	•	Created derived columns (e.g., total booking amount)
	•	Used custom dbt macros to keep SQL reusable and clean
	•	Continued using incremental models for efficiency

This layer prepares the data for analytics.

4. Gold Layer
This is the analytics-ready layer.

I implemented:
	•	Star schema design
	•	Dimension tables:
	•	DIM_BOOKINGS
	•	DIM_HOSTS
	•	DIM_LISTINGS
	•	FACT table
	•	One Big Table (OBT) for simplified reporting

This structure is optimized for BI tools and reporting queries.

5. Snapshots (SCD Type 2)
To track historical changes, I implemented dbt snapshots.
	•	Timestamp-based strategy
	•	Tracks updates over time
	•	Supports slowly changing dimensions

This allows historical analysis instead of overwriting records.

6. Data Quality
	•	Implemented custom source tests
	•	Added validation checks on booking amount
	•	Configured test severity levels

This ensures early detection of bad or unexpected data.

## Project Structure

# models/
	•	bronze/
	•	silver/
	•	gold/
	•	sources/

snapshots/
macros/
tests/
dbt_project.yml

# How to Run

Install dependencies:

pip install dbt-core dbt-snowflake

# Run transformations:

dbt run

Run snapshots:

dbt snapshot

Run tests:

dbt test


## What This Project Demonstrates
	•	End-to-end data pipeline design
	•	AWS S3 integration with Snowflake
	•	Incremental data processing
	•	Star schema modeling
	•	SCD Type 2 implementation
	•	Custom dbt macro development
	•	Data quality testing
	•	Modern data stack best practices

### This project reflects how a real-world analytics pipeline is structured using the modern data stack.
