"""
NASA APOD ETL Pipeline with DVC Versioning
===========================================

This DAG implements a complete ETL pipeline that:
1. Extracts data from NASA's Astronomy Picture of the Day (APOD) API
2. Transforms the JSON data into a structured format
3. Loads data into both PostgreSQL and CSV file
4. Versions the CSV file using DVC
5. Commits the DVC metadata to Git

Author: MLOps Team
Date: November 13, 2025
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import logging

# Configure logging
logger = logging.getLogger(__name__)

# Default arguments for the DAG
default_args = {
    'owner': 'mlops-team',
    'depends_on_past': False,
    'start_date': datetime(2025, 11, 13),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(minutes=30)
}

# ============================================================================
# TASK FUNCTIONS
# ============================================================================

def extract_apod_data(**context):
    """
    Extract data from NASA APOD API.
    
    This function fetches the daily astronomy picture data from NASA's API
    with retry logic and error handling.
    
    Returns:
        dict: Raw JSON response from the API
    
    Raises:
        Exception: If API request fails after all retries
    """
    import requests
    import time
    from datetime import datetime
    
    # API endpoint and parameters
    url = "https://api.nasa.gov/planetary/apod"
    params = {
        'api_key': 'DEMO_KEY',  # Use environment variable in production
        'date': datetime.now().strftime('%Y-%m-%d')
    }
    
    logger.info(f"Fetching APOD data from {url}")
    logger.info(f"Parameters: {params}")
    
    # Retry logic with exponential backoff
    max_retries = 3
    for attempt in range(max_retries):
        try:
            logger.info(f"Attempt {attempt + 1} of {max_retries}")
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            logger.info(f"Successfully extracted APOD data for {data.get('date')}")
            logger.info(f"Title: {data.get('title')}")
            logger.info(f"Media Type: {data.get('media_type')}")
            
            return data
            
        except requests.RequestException as e:
            logger.error(f"Attempt {attempt + 1} failed: {str(e)}")
            if attempt == max_retries - 1:
                raise Exception(f"Failed to fetch APOD data after {max_retries} attempts: {str(e)}")
            
            # Exponential backoff
            wait_time = 2 ** attempt
            logger.info(f"Waiting {wait_time} seconds before retry...")
            time.sleep(wait_time)


def transform_apod_data(**context):
    """
    Transform raw APOD data into structured format.
    
    This function extracts relevant fields from the raw API response,
    adds metadata, and validates the data structure.
    
    Returns:
        dict: Cleaned and structured data
    
    Raises:
        ValueError: If no data received from extraction task
        AssertionError: If data quality checks fail
    """
    import pandas as pd
    from datetime import datetime
    
    # Retrieve data from XCom
    ti = context['ti']
    raw_data = ti.xcom_pull(task_ids='extract_data')
    
    if not raw_data:
        raise ValueError("No data received from extraction task")
    
    logger.info("Starting data transformation")
    logger.info(f"Raw data keys: {list(raw_data.keys())}")
    
    # Select and transform fields
    transformed_data = {
        'date': raw_data.get('date'),
        'title': raw_data.get('title', 'N/A'),
        'explanation': raw_data.get('explanation', 'N/A'),
        'url': raw_data.get('url', 'N/A'),
        'hdurl': raw_data.get('hdurl', 'N/A'),
        'media_type': raw_data.get('media_type', 'image'),
        'copyright': raw_data.get('copyright', 'Public Domain'),
        'extracted_at': datetime.now().isoformat()
    }
    
    # Create DataFrame for validation
    df = pd.DataFrame([transformed_data])
    
    # Data quality checks
    logger.info("Performing data quality checks")
    assert not df['date'].isna().any(), "Date field cannot be null"
    assert not df['title'].isna().any(), "Title field cannot be null"
    assert df['media_type'].isin(['image', 'video']).all(), "Invalid media type"
    
    logger.info(f"Transformed data: {len(df)} records")
    logger.info(f"Columns: {list(df.columns)}")
    logger.info("Data quality checks passed")
    
    return transformed_data


def load_to_postgres(**context):
    """
    Load transformed data into PostgreSQL database.
    
    This function connects to the PostgreSQL database and performs an
    UPSERT operation to prevent duplicate entries.
    
    Raises:
        Exception: If database connection or insert operation fails
    """
    import psycopg2
    from psycopg2 import sql
    
    ti = context['ti']
    data = ti.xcom_pull(task_ids='transform_data')
    
    logger.info("Starting PostgreSQL load operation")
    
    # Database connection parameters
    conn_params = {
        'host': 'postgres',
        'port': 5432,
        'dbname': 'airflow',
        'user': 'airflow',
        'password': 'airflow'
    }
    
    conn = None
    cursor = None
    
    try:
        # Establish connection
        logger.info("Connecting to PostgreSQL database")
        conn = psycopg2.connect(**conn_params)
        cursor = conn.cursor()
        
        # Prepare UPSERT query (handles duplicates)
        query = """
            INSERT INTO apod_data 
            (date, title, explanation, url, hdurl, media_type, copyright, extracted_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (date) 
            DO UPDATE SET
                title = EXCLUDED.title,
                explanation = EXCLUDED.explanation,
                url = EXCLUDED.url,
                hdurl = EXCLUDED.hdurl,
                media_type = EXCLUDED.media_type,
                copyright = EXCLUDED.copyright,
                extracted_at = EXCLUDED.extracted_at;
        """
        
        # Execute insert
        logger.info(f"Inserting data for date: {data['date']}")
        cursor.execute(query, (
            data['date'],
            data['title'],
            data['explanation'],
            data['url'],
            data['hdurl'],
            data['media_type'],
            data['copyright'],
            data['extracted_at']
        ))
        
        conn.commit()
        logger.info(f"Successfully loaded data for {data['date']} into PostgreSQL")
        
        # Verify insertion
        cursor.execute("SELECT COUNT(*) FROM apod_data WHERE date = %s", (data['date'],))
        count = cursor.fetchone()[0]
        logger.info(f"Verification: {count} record(s) found for {data['date']}")
        
    except Exception as e:
        if conn:
            conn.rollback()
            logger.error("Transaction rolled back due to error")
        logger.error(f"Failed to load data to PostgreSQL: {str(e)}")
        raise Exception(f"PostgreSQL load failed: {str(e)}")
        
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
            logger.info("Database connection closed")


def load_to_csv(**context):
    """
    Load transformed data into CSV file.
    
    This function appends data to an existing CSV file or creates a new one.
    It handles duplicate dates by replacing old entries with new ones.
    
    Raises:
        Exception: If CSV write operation fails
    """
    import pandas as pd
    import os
    from pathlib import Path
    
    ti = context['ti']
    data = ti.xcom_pull(task_ids='transform_data')
    
    logger.info("Starting CSV load operation")
    
    # CSV file path
    csv_path = '/opt/airflow/data/apod_data.csv'
    
    try:
        # Convert to DataFrame
        df = pd.DataFrame([data])
        logger.info(f"Created DataFrame with shape: {df.shape}")
        
        # Check if file exists
        if os.path.exists(csv_path):
            logger.info(f"CSV file exists, reading existing data")
            existing_df = pd.read_csv(csv_path)
            logger.info(f"Existing data shape: {existing_df.shape}")
            
            # Remove duplicate dates and append new data
            existing_df = existing_df[existing_df['date'] != data['date']]
            df = pd.concat([existing_df, df], ignore_index=True)
            
            # Sort by date (most recent first)
            df = df.sort_values('date', ascending=False)
            logger.info(f"Merged and sorted data shape: {df.shape}")
        else:
            logger.info("Creating new CSV file")
        
        # Write to CSV
        df.to_csv(csv_path, index=False)
        logger.info(f"Successfully loaded data to CSV: {csv_path}")
        logger.info(f"Total records in CSV: {len(df)}")
        
        # Verify file
        if os.path.exists(csv_path):
            file_size = os.path.getsize(csv_path)
            logger.info(f"CSV file size: {file_size} bytes")
        
    except Exception as e:
        logger.error(f"Failed to load data to CSV: {str(e)}")
        raise Exception(f"CSV load failed: {str(e)}")


# ============================================================================
# DAG DEFINITION
# ============================================================================

# Create the DAG
dag = DAG(
    'nasa_apod_etl_pipeline',
    default_args=default_args,
    description='ETL pipeline for NASA APOD data with DVC versioning',
    schedule_interval='@daily',  # Run once per day at midnight
    catchup=False,  # Don't backfill past runs
    max_active_runs=1,  # Only one run at a time
    tags=['nasa', 'etl', 'dvc', 'mlops', 'data-versioning']
)

# ============================================================================
# TASK DEFINITIONS
# ============================================================================

# Task 1: Extract data from NASA APOD API
extract_task = PythonOperator(
    task_id='extract_data',
    python_callable=extract_apod_data,
    provide_context=True,
    dag=dag,
    doc_md="""
    ## Extract Data Task
    
    Fetches daily astronomy picture data from NASA's APOD API.
    
    **Endpoint**: https://api.nasa.gov/planetary/apod
    
    **Features**:
    - Automatic retry with exponential backoff
    - 10-second timeout for requests
    - Detailed logging
    """
)

# Task 2: Transform the raw data
transform_task = PythonOperator(
    task_id='transform_data',
    python_callable=transform_apod_data,
    provide_context=True,
    dag=dag,
    doc_md="""
    ## Transform Data Task
    
    Transforms raw API response into structured format.
    
    **Operations**:
    - Extract relevant fields
    - Add extraction timestamp
    - Validate data quality
    - Handle missing values
    """
)

# Task 3a: Load data to PostgreSQL
load_postgres_task = PythonOperator(
    task_id='load_to_postgres',
    python_callable=load_to_postgres,
    provide_context=True,
    dag=dag,
    doc_md="""
    ## Load to PostgreSQL Task
    
    Loads transformed data into PostgreSQL database.
    
    **Features**:
    - UPSERT operation (no duplicates)
    - Transaction management
    - Verification after insert
    """
)

# Task 3b: Load data to CSV
load_csv_task = PythonOperator(
    task_id='load_to_csv',
    python_callable=load_to_csv,
    provide_context=True,
    dag=dag,
    doc_md="""
    ## Load to CSV Task
    
    Saves transformed data to CSV file.
    
    **Features**:
    - Append to existing file
    - Handle duplicates
    - Sort by date
    """
)

# Task 4: Version data with DVC
dvc_task = BashOperator(
    task_id='version_data_with_dvc',
    bash_command="""
    cd /opt/airflow && \
    echo "Current directory: $(pwd)" && \
    echo "Checking DVC status before adding..." && \
    dvc status || true && \
    echo "Adding CSV file to DVC..." && \
    dvc add data/apod_data.csv && \
    echo "DVC status after adding:" && \
    dvc status && \
    echo "DVC versioning completed for apod_data.csv" && \
    ls -lh data/apod_data.csv* && \
    echo "DVC file contents:" && \
    cat data/apod_data.csv.dvc
    """,
    dag=dag,
    doc_md="""
    ## Version Data with DVC Task
    
    Tracks the CSV file with DVC for data versioning.
    
    **Operations**:
    - `dvc add data/apod_data.csv`
    - Generates `.dvc` metadata file
    - Shows status and file details
    """
)

# Task 5: Commit DVC metadata to Git
git_task = BashOperator(
    task_id='commit_to_git',
    bash_command="""
    cd /opt/airflow && \
    echo "Configuring Git..." && \
    git config --global user.name "MLOps Pipeline" && \
    git config --global user.email "mlops@example.com" && \
    git config --global --add safe.directory /opt/airflow && \
    echo "Initializing Git repository if needed..." && \
    git init || echo "Git already initialized" && \
    echo "Current Git status:" && \
    git status || true && \
    echo "Staging DVC files..." && \
    git add data/apod_data.csv.dvc data/.gitignore .dvc/config .dvc/.gitignore || true && \
    echo "Committing changes..." && \
    git commit -m "Update APOD data version - $(date +%Y-%m-%d_%H-%M-%S)" || echo "No changes to commit" && \
    echo "Latest Git log:" && \
    git log --oneline -3 || true && \
    echo "Git commit completed successfully"
    """,
    dag=dag,
    doc_md="""
    ## Commit to Git Task
    
    Commits DVC metadata files to Git repository.
    
    **Operations**:
    - Configure Git user
    - Stage `.dvc` files
    - Commit with timestamp
    - Display commit log
    """
)

# ============================================================================
# TASK DEPENDENCIES
# ============================================================================

# Define the pipeline flow
# Extract -> Transform -> [Load to Postgres, Load to CSV] -> DVC -> Git
extract_task >> transform_task >> [load_postgres_task, load_csv_task] >> dvc_task >> git_task

# Optional: Add documentation
dag.doc_md = """
# NASA APOD ETL Pipeline

This DAG implements a complete ETL pipeline with data versioning capabilities.

## Pipeline Flow

```
extract_data
    ↓
transform_data
    ↓
    ├─→ load_to_postgres
    └─→ load_to_csv
         ↓
    version_data_with_dvc
         ↓
    commit_to_git
```

## Features

- **Data Extraction**: Fetches daily astronomy data from NASA's APOD API
- **Data Transformation**: Cleans and structures the data
- **Dual Loading**: Saves to both PostgreSQL and CSV simultaneously
- **Data Versioning**: Uses DVC to track data changes
- **Code Versioning**: Commits DVC metadata to Git

## Configuration

- **Schedule**: Daily at midnight
- **Retries**: 2 attempts with 5-minute delay
- **Timeout**: 30 minutes per task
- **Concurrency**: 1 active run at a time

## Monitoring

Check task logs in Airflow UI for detailed execution information.
"""
