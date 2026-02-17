"""
Downloads the Olist dataset from Kaggle and loads it into PostgreSQL.

Prerequisites:
    - PostgreSQL running locally
    - Kaggle API credentials (~/.kaggle/kaggle.json)
    - pip install -r requirements.txt

Usage:
    python setup.py
"""
import os
import subprocess
import pandas as pd
from sqlalchemy import create_engine, text

DATA_DIR = "data"
DB_URL = os.getenv("DATABASE_URL", "postgresql://localhost/olist")


def download_dataset():
    if os.path.exists(os.path.join(DATA_DIR, "olist_orders_dataset.csv")):
        print("Data already downloaded.")
        return

    print("Downloading Olist dataset from Kaggle...")
    os.makedirs(DATA_DIR, exist_ok=True)
    subprocess.run(
        "kaggle datasets download -d olistbr/brazilian-ecommerce "
        f"-p {DATA_DIR} --unzip",
        shell=True, check=True
    )
    print("Done.")


def create_database():
    admin_engine = create_engine("postgresql://localhost/postgres")
    with admin_engine.connect() as conn:
        conn.execution_options(isolation_level="AUTOCOMMIT")
        result = conn.execute(text("SELECT 1 FROM pg_database WHERE datname = 'olist'"))
        if not result.fetchone():
            conn.execute(text("CREATE DATABASE olist"))
            print("Created database 'olist'.")
        else:
            print("Database 'olist' already exists.")
    admin_engine.dispose()


def load_schema():
    engine = create_engine(DB_URL)
    with engine.connect() as conn:
        with open("schema.sql") as f:
            for statement in f.read().split(";"):
                stmt = statement.strip()
                if stmt:
                    conn.execute(text(stmt))
        conn.commit()
    print("Schema created.")
    engine.dispose()


def load_data():
    engine = create_engine(DB_URL)

    table_map = {
        "olist_customers_dataset.csv": "customers",
        "olist_sellers_dataset.csv": "sellers",
        "olist_products_dataset.csv": "products",
        "olist_orders_dataset.csv": "orders",
        "olist_order_items_dataset.csv": "order_items",
        "olist_order_payments_dataset.csv": "order_payments",
        "olist_order_reviews_dataset.csv": "order_reviews",
        "olist_geolocation_dataset.csv": "geolocation",
    }

    for csv_file, table_name in table_map.items():
        path = os.path.join(DATA_DIR, csv_file)
        if not os.path.exists(path):
            print(f"  Skipping {csv_file} (not found)")
            continue

        df = pd.read_csv(path)

        # Rename columns to match schema
        df.columns = [c.replace("olist_", "").strip() for c in df.columns]

        # Dedup geolocation (has many dupes per zip code)
        if table_name == "geolocation":
            df = df.drop_duplicates(subset=["geolocation_zip_code_prefix"])

        with engine.connect() as conn:
            count = conn.execute(text(f"SELECT COUNT(*) FROM {table_name}")).scalar()
            if count > 0:
                print(f"  {table_name}: already loaded ({count:,} rows)")
                continue

        df.to_sql(table_name, engine, if_exists="append", index=False)
        print(f"  {table_name}: loaded {len(df):,} rows")

    engine.dispose()


if __name__ == "__main__":
    download_dataset()
    create_database()
    load_schema()
    load_data()
    print("\nSetup complete. Connect with: psql -d olist")
