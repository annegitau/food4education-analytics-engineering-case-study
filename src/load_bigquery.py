from pathlib import Path
from google.cloud import bigquery


# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

PROJECT_ID = "f4e-analytics-case-study"
DATASET_ID = "f4e_raw"

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

client = bigquery.Client(project=PROJECT_ID)


# ---------------------------------------------------------
# Source-to-table configuration
# Explicit schemas prevent unexpected type inference.
# ---------------------------------------------------------

TABLE_CONFIGS = {
    "schools": {
        "file": "schools.csv",
        "schema": [
            bigquery.SchemaField("school_id", "STRING"),
            bigquery.SchemaField("school_name", "STRING"),
            bigquery.SchemaField("county", "STRING"),
            bigquery.SchemaField("kitchen_id", "STRING"),
            bigquery.SchemaField("eligible_learners", "INTEGER"),
        ],
    },

    "meal_production": {
        "file": "meal_production.csv",
        "schema": [
            bigquery.SchemaField("service_date", "DATE"),
            bigquery.SchemaField("kitchen_id", "STRING"),
            bigquery.SchemaField("meals_prepared", "INTEGER"),
        ],
    },

    "deliveries": {
        "file": "deliveries.csv",
        "schema": [
            bigquery.SchemaField("delivery_id", "STRING"),
            bigquery.SchemaField("service_date", "DATE"),
            bigquery.SchemaField("kitchen_id", "STRING"),
            bigquery.SchemaField("school_id", "STRING"),
            bigquery.SchemaField("meals_dispatched", "INTEGER"),
            bigquery.SchemaField("meals_received", "INTEGER"),
        ],
    },

    "tap2eat_transactions": {
        "file": "tap2eat_transactions.csv",
        "schema": [
            bigquery.SchemaField("transaction_id", "STRING"),
            bigquery.SchemaField("student_id", "STRING"),
            bigquery.SchemaField("school_id", "STRING"),
            bigquery.SchemaField("tap_timestamp", "TIMESTAMP"),
            bigquery.SchemaField("meal_qty", "INTEGER"),
            bigquery.SchemaField("status", "STRING"),
        ],
    },

    "payments": {
        "file": "payments.csv",
        "schema": [
            bigquery.SchemaField("payment_id", "STRING"),
            bigquery.SchemaField("student_id", "STRING"),
            bigquery.SchemaField("school_id", "STRING"),
            bigquery.SchemaField("payment_timestamp", "TIMESTAMP"),
            bigquery.SchemaField("amount_kes", "INTEGER"),
            bigquery.SchemaField("method", "STRING"),
        ],
    },
}


# ---------------------------------------------------------
# Load one CSV into BigQuery
# ---------------------------------------------------------

def load_table(table_name, config):

    file_path = DATA_DIR / config["file"]
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"

    if not file_path.exists():
        raise FileNotFoundError(f"Source file not found: {file_path}")

    job_config = bigquery.LoadJobConfig(
        schema=config["schema"],
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    print(f"Loading {config['file']} -> {table_id}")

    with open(file_path, "rb") as source_file:
        load_job = client.load_table_from_file(
            source_file,
            table_id,
            job_config=job_config,
        )

    # Wait for BigQuery load job to finish.
    load_job.result()

    table = client.get_table(table_id)

    print(f"✓ Loaded {table.num_rows:,} rows")


# ---------------------------------------------------------
# Pipeline entry point
# ---------------------------------------------------------

def main():

    print("\nF4E RAW DATA INGESTION")
    print("----------------------")
    print(f"Project : {PROJECT_ID}")
    print(f"Dataset : {DATASET_ID}\n")

    for table_name, config in TABLE_CONFIGS.items():
        load_table(table_name, config)

    print("\n✓ All raw tables loaded successfully.\n")


if __name__ == "__main__":
    main()