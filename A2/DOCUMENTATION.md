# MLOps ETL Pipeline - Detailed Implementation Documentation

## 📋 Table of Contents
1. [Introduction](#introduction)
2. [Architecture Deep Dive](#architecture-deep-dive)
3. [Implementation Details](#implementation-details)
4. [Testing Procedures](#testing-procedures)
5. [Deployment Guide](#deployment-guide)
6. [Troubleshooting](#troubleshooting)
7. [Performance Optimization](#performance-optimization)
8. [Lessons Learned](#lessons-learned)

---

## Introduction

This document provides comprehensive implementation details for the MLOps ETL pipeline project. It covers technical decisions, code explanations, testing strategies, and operational guidelines.

### Project Scope
- Build reproducible ETL pipeline for NASA APOD data
- Implement data versioning with DVC
- Deploy using Docker and Astronomer-compatible setup
- Ensure data integrity across multiple storage systems

### Technology Stack
| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Orchestrator | Apache Airflow | 2.7.3 | Workflow management |
| Database | PostgreSQL | 15 | Relational storage |
| Data Versioning | DVC | 3.x | Data lineage |
| Containerization | Docker | 24.x | Deployment |
| Language | Python | 3.11 | Pipeline code |
| Package Manager | pip | Latest | Dependency management |

---

## Architecture Deep Dive

### System Components

#### 1. Airflow Webserver
- **Purpose**: Web UI for DAG management and monitoring
- **Port**: 8080
- **Resources**: 2GB RAM minimum
- **Dependencies**: PostgreSQL metadata DB

#### 2. Airflow Scheduler
- **Purpose**: Task scheduling and execution
- **Resources**: 2GB RAM minimum
- **Configuration**: 
  - DAG parsing interval: 30s
  - Max active runs: 1 per DAG

#### 3. PostgreSQL Database
- **Purpose**: 
  - Airflow metadata storage
  - APOD data storage
- **Port**: 5432
- **Storage**: Persistent volume

#### 4. DVC Integration
- **Storage Backend**: Local filesystem
- **Remote Location**: `/opt/airflow/dvc-remote`
- **Auto-staging**: Enabled

### Data Flow Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         External Sources                         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  NASA APOD API                                             │ │
│  │  https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY     │ │
│  └────────────────────┬───────────────────────────────────────┘ │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        │ HTTP GET Request
                        │ Returns JSON
                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                      Airflow Scheduler                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Task 1: extract_data                                      │ │
│  │  - PythonOperator                                          │ │
│  │  - Fetches JSON from API                                   │ │
│  │  - Stores in XCom                                          │ │
│  └────────────────────┬───────────────────────────────────────┘ │
│                       │                                          │
│  ┌────────────────────▼───────────────────────────────────────┐ │
│  │  Task 2: transform_data                                    │ │
│  │  - PythonOperator                                          │ │
│  │  - Reads from XCom                                         │ │
│  │  - Transforms to DataFrame                                 │ │
│  │  - Stores in XCom                                          │ │
│  └────────────────────┬───────────────────────────────────────┘ │
│                       │                                          │
│         ┌─────────────┴─────────────┐                          │
│         │                           │                          │
│  ┌──────▼─────────────┐  ┌──────────▼────────────┐           │
│  │ Task 3a:           │  │ Task 3b:              │           │
│  │ load_to_postgres   │  │ load_to_csv           │           │
│  │ - PythonOperator   │  │ - PythonOperator      │           │
│  └──────┬─────────────┘  └──────────┬────────────┘           │
│         │                           │                          │
│         │    ┌──────────────────────┘                          │
│         └────┤                                                 │
│  ┌───────────▼────────────────────────────────────────────┐   │
│  │  Task 4: version_data_with_dvc                         │   │
│  │  - BashOperator                                        │   │
│  │  - Executes: dvc add data/apod_data.csv               │   │
│  └────────────────────┬───────────────────────────────────┘   │
│                       │                                        │
│  ┌────────────────────▼───────────────────────────────────┐   │
│  │  Task 5: commit_to_git                                 │   │
│  │  - BashOperator                                        │   │
│  │  - Executes: git add + git commit                      │   │
│  └────────────────────┬───────────────────────────────────┘   │
└───────────────────────┼────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                      Data Storage Layer                          │
│                                                                  │
│  ┌─────────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  PostgreSQL     │  │  CSV File    │  │  DVC Remote      │  │
│  │  apod_data      │  │  apod_data   │  │  Storage         │  │
│  │  table          │  │  .csv        │  │  (versioned)     │  │
│  └─────────────────┘  └──────────────┘  └──────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                         Git Repository                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Tracked Files:                                            │ │
│  │  - dags/nasa_apod_etl_dag.py                              │ │
│  │  - data/apod_data.csv.dvc (metadata only)                 │ │
│  │  - .dvc/config                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

---

## Implementation Details

### Task 1: Data Extraction

**File**: `dags/nasa_apod_etl_dag.py`

**Implementation**:
```python
def extract_apod_data(**context):
    """
    Extract data from NASA APOD API.
    
    Returns:
        dict: Raw JSON response from API
    """
    import requests
    from datetime import datetime
    
    # API endpoint
    url = "https://api.nasa.gov/planetary/apod"
    params = {
        'api_key': 'DEMO_KEY',
        'date': datetime.now().strftime('%Y-%m-%d')
    }
    
    # Make request with retry logic
    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            # Log success
            print(f"Successfully extracted APOD data for {data.get('date')}")
            return data
            
        except requests.RequestException as e:
            if attempt == max_retries - 1:
                raise Exception(f"Failed to fetch APOD data after {max_retries} attempts: {str(e)}")
            print(f"Attempt {attempt + 1} failed, retrying...")
            time.sleep(2 ** attempt)  # Exponential backoff
```

**Key Design Decisions**:
1. **Retry Logic**: Implements exponential backoff for API reliability
2. **Timeout**: 10-second timeout prevents hanging requests
3. **Error Handling**: Descriptive error messages for debugging
4. **Logging**: Prints extraction status for monitoring

### Task 2: Data Transformation

**Implementation**:
```python
def transform_apod_data(**context):
    """
    Transform raw APOD data into structured format.
    
    Returns:
        dict: Cleaned and structured data
    """
    import pandas as pd
    from datetime import datetime
    
    # Retrieve data from XCom
    ti = context['ti']
    raw_data = ti.xcom_pull(task_ids='extract_data')
    
    if not raw_data:
        raise ValueError("No data received from extraction task")
    
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
    assert not df['date'].isna().any(), "Date field cannot be null"
    assert not df['title'].isna().any(), "Title field cannot be null"
    
    print(f"Transformed data: {len(df)} records")
    print(f"Columns: {list(df.columns)}")
    
    return transformed_data
```

**Key Design Decisions**:
1. **Default Values**: Handles missing optional fields gracefully
2. **DataFrame Creation**: Validates data structure
3. **Quality Checks**: Assertions ensure data integrity
4. **Timestamp**: Adds extraction timestamp for audit trail

### Task 3a: Load to PostgreSQL

**Implementation**:
```python
def load_to_postgres(**context):
    """
    Load transformed data into PostgreSQL database.
    """
    import psycopg2
    from psycopg2.extras import execute_values
    
    ti = context['ti']
    data = ti.xcom_pull(task_ids='transform_data')
    
    # Database connection parameters
    conn_params = {
        'host': 'postgres',
        'port': 5432,
        'dbname': 'airflow',
        'user': 'airflow',
        'password': 'airflow'
    }
    
    try:
        # Establish connection
        conn = psycopg2.connect(**conn_params)
        cursor = conn.cursor()
        
        # Prepare insert query (upsert to handle duplicates)
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
        print(f"Successfully loaded data for {data['date']} into PostgreSQL")
        
    except Exception as e:
        if conn:
            conn.rollback()
        raise Exception(f"Failed to load data to PostgreSQL: {str(e)}")
        
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
```

**Key Design Decisions**:
1. **UPSERT Logic**: Prevents duplicate entries, updates existing records
2. **Transaction Management**: Rollback on failure ensures consistency
3. **Connection Pooling**: Properly closes connections
4. **Error Propagation**: Raises exceptions for Airflow to handle

### Task 3b: Load to CSV

**Implementation**:
```python
def load_to_csv(**context):
    """
    Load transformed data into CSV file.
    Appends to existing file or creates new one.
    """
    import pandas as pd
    import os
    from pathlib import Path
    
    ti = context['ti']
    data = ti.xcom_pull(task_ids='transform_data')
    
    # CSV file path
    csv_path = '/opt/airflow/data/apod_data.csv'
    
    # Convert to DataFrame
    df = pd.DataFrame([data])
    
    # Check if file exists
    if os.path.exists(csv_path):
        # Read existing data
        existing_df = pd.read_csv(csv_path)
        
        # Remove duplicate dates and append new data
        existing_df = existing_df[existing_df['date'] != data['date']]
        df = pd.concat([existing_df, df], ignore_index=True)
        
        # Sort by date
        df = df.sort_values('date', ascending=False)
    
    # Write to CSV
    df.to_csv(csv_path, index=False)
    
    print(f"Successfully loaded data to CSV: {csv_path}")
    print(f"Total records in CSV: {len(df)}")
```

**Key Design Decisions**:
1. **Append Mode**: Accumulates historical data
2. **Duplicate Handling**: Removes duplicates based on date
3. **Sorting**: Maintains chronological order
4. **Idempotency**: Re-running pipeline produces same result

### Task 4: DVC Versioning

**Implementation**:
```python
version_data_with_dvc = BashOperator(
    task_id='version_data_with_dvc',
    bash_command="""
    cd /opt/airflow && \
    dvc add data/apod_data.csv && \
    echo "DVC versioning completed for apod_data.csv"
    """,
    dag=dag
)
```

**Key Design Decisions**:
1. **Working Directory**: Ensures correct DVC context
2. **Single File Tracking**: Versions only the CSV output
3. **Logging**: Confirms successful execution
4. **Metadata Generation**: Creates `.dvc` file automatically

### Task 5: Git Commit

**Implementation**:
```python
commit_to_git = BashOperator(
    task_id='commit_to_git',
    bash_command="""
    cd /opt/airflow && \
    git add data/apod_data.csv.dvc data/.gitignore .dvc/config && \
    git commit -m "Update APOD data version - $(date +%Y-%m-%d)" || echo "No changes to commit" && \
    echo "Git commit completed"
    """,
    dag=dag
)
```

**Key Design Decisions**:
1. **Selective Staging**: Only tracks DVC metadata, not actual data
2. **Date-based Commits**: Descriptive commit messages
3. **Graceful Handling**: Doesn't fail if no changes exist
4. **Multiple Files**: Commits all DVC-related files

### DAG Configuration

**Complete DAG Structure**:
```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

# Default arguments
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

# DAG definition
dag = DAG(
    'nasa_apod_etl_pipeline',
    default_args=default_args,
    description='ETL pipeline for NASA APOD data with DVC versioning',
    schedule_interval='@daily',  # Run once per day
    catchup=False,  # Don't backfill
    max_active_runs=1,  # One run at a time
    tags=['nasa', 'etl', 'dvc', 'mlops']
)

# Task definitions
extract_task = PythonOperator(
    task_id='extract_data',
    python_callable=extract_apod_data,
    dag=dag
)

transform_task = PythonOperator(
    task_id='transform_data',
    python_callable=transform_apod_data,
    dag=dag
)

load_postgres_task = PythonOperator(
    task_id='load_to_postgres',
    python_callable=load_to_postgres,
    dag=dag
)

load_csv_task = PythonOperator(
    task_id='load_to_csv',
    python_callable=load_to_csv,
    dag=dag
)

dvc_task = BashOperator(
    task_id='version_data_with_dvc',
    bash_command='cd /opt/airflow && dvc add data/apod_data.csv',
    dag=dag
)

git_task = BashOperator(
    task_id='commit_to_git',
    bash_command='cd /opt/airflow && git add data/apod_data.csv.dvc && git commit -m "Update APOD data" || echo "No changes"',
    dag=dag
)

# Task dependencies
extract_task >> transform_task >> [load_postgres_task, load_csv_task] >> dvc_task >> git_task
```

---

## Testing Procedures

### Unit Testing

**Test Extract Function**:
```python
import pytest
from unittest.mock import patch, Mock

def test_extract_apod_data_success():
    """Test successful API extraction."""
    mock_response = Mock()
    mock_response.json.return_value = {
        'date': '2025-11-13',
        'title': 'Test Image',
        'url': 'https://example.com/image.jpg'
    }
    mock_response.status_code = 200
    
    with patch('requests.get', return_value=mock_response):
        result = extract_apod_data()
        assert result['date'] == '2025-11-13'
        assert 'title' in result

def test_extract_apod_data_retry():
    """Test retry logic on failure."""
    with patch('requests.get', side_effect=requests.RequestException("API Error")):
        with pytest.raises(Exception):
            extract_apod_data()
```

### Integration Testing

**Test End-to-End Pipeline**:
```bash
# Trigger DAG manually
docker-compose exec airflow-webserver \
    airflow dags test nasa_apod_etl_pipeline 2025-11-13

# Check task states
docker-compose exec airflow-webserver \
    airflow tasks states-for-dag-run nasa_apod_etl_pipeline manual__2025-11-13
```

### Data Validation

**PostgreSQL Validation**:
```sql
-- Check row count
SELECT COUNT(*) FROM apod_data;

-- Check latest entry
SELECT * FROM apod_data ORDER BY date DESC LIMIT 1;

-- Check for duplicates
SELECT date, COUNT(*) 
FROM apod_data 
GROUP BY date 
HAVING COUNT(*) > 1;

-- Validate data types
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'apod_data';
```

**CSV Validation**:
```python
import pandas as pd

# Load CSV
df = pd.read_csv('/opt/airflow/data/apod_data.csv')

# Check shape
print(f"Shape: {df.shape}")

# Check for nulls
print(f"Null values:\n{df.isnull().sum()}")

# Check duplicates
print(f"Duplicates: {df.duplicated(subset=['date']).sum()}")

# Verify date format
pd.to_datetime(df['date'])  # Should not raise error
```

**DVC Validation**:
```bash
# Check DVC status
dvc status

# Verify .dvc file
cat data/apod_data.csv.dvc

# Check DVC cache
dvc cache dir

# Verify data integrity
dvc checkout data/apod_data.csv
```

---

## Deployment Guide

### Local Development Deployment

**Step 1: Environment Setup**
```bash
# Navigate to project directory
cd /workspaces/mlops/A2

# Create .env file
cat > .env << EOF
AIRFLOW_UID=$(id -u)
AIRFLOW_GID=0
_AIRFLOW_WWW_USER_USERNAME=admin
_AIRFLOW_WWW_USER_PASSWORD=admin
POSTGRES_USER=airflow
POSTGRES_PASSWORD=airflow
POSTGRES_DB=airflow
EOF
```

**Step 2: Build Containers**
```bash
# Build custom Airflow image
docker-compose build --no-cache

# Start all services
docker-compose up -d

# Check container status
docker-compose ps
```

**Step 3: Initialize Airflow**
```bash
# Initialize Airflow database
docker-compose exec airflow-webserver airflow db init

# Create admin user (if not auto-created)
docker-compose exec airflow-webserver airflow users create \
    --username admin \
    --password admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com
```

**Step 4: Initialize DVC**
```bash
# Enter container
docker-compose exec airflow-webserver bash

# Initialize DVC
cd /opt/airflow
dvc init --no-scm
dvc remote add -d local /opt/airflow/dvc-remote
dvc config core.autostage true

# Verify DVC configuration
dvc remote list
dvc config --list

exit
```

**Step 5: Configure Git**
```bash
# Configure Git in container
docker-compose exec airflow-webserver bash

git config --global user.name "MLOps Pipeline"
git config --global user.email "mlops@example.com"

# Initialize Git repository (if not already)
cd /opt/airflow
git init
git add .
git commit -m "Initial commit"

exit
```

**Step 6: Enable DAG**
```bash
# List DAGs
docker-compose exec airflow-webserver airflow dags list

# Unpause DAG
docker-compose exec airflow-webserver \
    airflow dags unpause nasa_apod_etl_pipeline
```

### Production Deployment (Astronomer)

**Step 1: Install Astronomer CLI**
```bash
curl -sSL https://install.astronomer.io | sudo bash -s
```

**Step 2: Initialize Astronomer Project**
```bash
cd /workspaces/mlops/A2
astro dev init
```

**Step 3: Configure Astronomer**
```yaml
# Edit astro.yml
astronomer:
  name: nasa-apod-etl
  description: NASA APOD ETL Pipeline with DVC
  version: 1.0.0
  
airflow:
  image: quay.io/astronomer/astro-runtime:11.0.0
  
# Edit Dockerfile
FROM quay.io/astronomer/astro-runtime:11.0.0
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
```

**Step 4: Deploy to Astronomer**
```bash
# Login to Astronomer
astro login

# Deploy to Astronomer Cloud
astro deploy

# Or run locally with Astronomer
astro dev start
```

---

## Troubleshooting

### Issue 1: Airflow Webserver Not Starting

**Symptoms**:
- Container exits immediately
- Port 8080 not accessible
- Error: "Could not create admin user"

**Solution**:
```bash
# Check logs
docker-compose logs airflow-webserver

# Reset database
docker-compose down -v
docker-compose up -d postgres
sleep 10
docker-compose up airflow-init
docker-compose up -d

# Verify database
docker-compose exec postgres psql -U airflow -c "\dt"
```

### Issue 2: DVC Commands Fail

**Symptoms**:
- "dvc: command not found"
- "DVC is not initialized"
- "Remote storage not configured"

**Solution**:
```bash
# Verify DVC installation
docker-compose exec airflow-webserver which dvc
docker-compose exec airflow-webserver dvc version

# Re-initialize DVC
docker-compose exec airflow-webserver bash
cd /opt/airflow
rm -rf .dvc
dvc init
dvc remote add -d local /opt/airflow/dvc-remote
exit

# Check DVC configuration
docker-compose exec airflow-webserver dvc config --list
```

### Issue 3: PostgreSQL Connection Failed

**Symptoms**:
- "could not connect to server"
- "password authentication failed"
- Task fails at postgres loading step

**Solution**:
```bash
# Check Postgres container
docker-compose ps postgres
docker-compose logs postgres

# Test connection
docker-compose exec postgres psql -U airflow -d airflow -c "SELECT 1;"

# Verify connection parameters in DAG match docker-compose.yml

# Restart Postgres
docker-compose restart postgres
```

### Issue 4: Git Commit Fails

**Symptoms**:
- "nothing to commit"
- "permission denied"
- "unable to create file"

**Solution**:
```bash
# Check Git configuration
docker-compose exec airflow-webserver git config --list

# Fix permissions
docker-compose exec airflow-webserver bash
chmod -R 755 /opt/airflow/data
chown -R airflow:root /opt/airflow/data
exit

# Verify Git status
docker-compose exec airflow-webserver git status
```

### Issue 5: DAG Import Errors

**Symptoms**:
- DAG not appearing in UI
- "Broken DAG" icon
- Import errors in logs

**Solution**:
```bash
# Check DAG file syntax
docker-compose exec airflow-webserver python /opt/airflow/dags/nasa_apod_etl_dag.py

# View DAG import errors
docker-compose exec airflow-webserver airflow dags list-import-errors

# Check scheduler logs
docker-compose logs airflow-scheduler | grep ERROR
```

---

## Performance Optimization

### 1. Parallel Task Execution
- Load to Postgres and CSV in parallel
- Configure `max_active_runs_per_dag = 1`
- Set appropriate `pool` for tasks

### 2. Resource Allocation
```yaml
# docker-compose.yml optimizations
services:
  airflow-webserver:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### 3. Connection Pooling
```python
# Use Airflow connections instead of hardcoded credentials
from airflow.providers.postgres.hooks.postgres import PostgresHook

def load_to_postgres(**context):
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    conn = pg_hook.get_conn()
    # ... rest of code
```

### 4. XCom Optimization
- Pass only necessary data through XCom
- Use XCom backend (S3/GCS) for large datasets
- Clean up old XCom entries

### 5. DVC Performance
```bash
# Use DVC cache to speed up operations
dvc config cache.type hardlink

# Enable parallel transfers
dvc config core.jobs 4
```

---

## Lessons Learned

### 1. Orchestration Mastery
- **Task Dependencies**: Proper dependency management prevents race conditions
- **Idempotency**: Design tasks to be safely re-runnable
- **Error Handling**: Implement retry logic with exponential backoff
- **XCom Usage**: Understand XCom size limitations and use appropriately

### 2. Data Integrity
- **UPSERT Operations**: Prevent duplicate entries in database
- **Transaction Management**: Use transactions for atomic operations
- **Parallel Loading**: Ensure consistency across multiple storage systems
- **Data Validation**: Add quality checks at each stage

### 3. Data Lineage
- **DVC Integration**: Version data separately from code
- **Git Workflow**: Track metadata, not actual data files
- **Reproducibility**: Link code version to data version
- **Metadata Management**: Keep .dvc files in version control

### 4. Containerized Deployment
- **Dependency Management**: Specify exact versions in requirements.txt
- **Environment Variables**: Use .env for configuration
- **Volume Mounts**: Persist data across container restarts
- **Health Checks**: Implement proper health checks for containers

### 5. Operational Excellence
- **Monitoring**: Use Airflow UI and logs for observability
- **Alerting**: Configure failure notifications
- **Documentation**: Maintain comprehensive documentation
- **Testing**: Implement unit and integration tests

---

## Appendix

### A. Sample API Response
```json
{
  "date": "2025-11-13",
  "explanation": "What's happening to that meteor?...",
  "hdurl": "https://apod.nasa.gov/apod/image/2511/meteor_hd.jpg",
  "media_type": "image",
  "service_version": "v1",
  "title": "Meteor Over Mountains",
  "url": "https://apod.nasa.gov/apod/image/2511/meteor.jpg",
  "copyright": "Photographer Name"
}
```

### B. PostgreSQL Schema
```sql
CREATE TABLE IF NOT EXISTS apod_data (
    id SERIAL PRIMARY KEY,
    date DATE UNIQUE NOT NULL,
    title VARCHAR(500) NOT NULL,
    explanation TEXT,
    url TEXT,
    hdurl TEXT,
    media_type VARCHAR(50),
    copyright VARCHAR(500),
    extracted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_apod_date ON apod_data(date);
CREATE INDEX idx_apod_media_type ON apod_data(media_type);
```

### C. DVC Configuration
```yaml
# .dvc/config
[core]
    remote = local
    autostage = true
['remote "local"']
    url = /opt/airflow/dvc-remote
```

### D. Useful Commands Cheat Sheet
```bash
# Airflow
airflow dags list
airflow dags trigger nasa_apod_etl_pipeline
airflow tasks test nasa_apod_etl_pipeline extract_data 2025-11-13
airflow dags backfill nasa_apod_etl_pipeline -s 2025-11-01 -e 2025-11-13

# DVC
dvc status
dvc diff
dvc checkout
dvc pull
dvc push

# Docker
docker-compose up -d
docker-compose down
docker-compose logs -f airflow-scheduler
docker-compose restart airflow-webserver

# PostgreSQL
psql -U airflow -d airflow
\dt
\d apod_data
SELECT COUNT(*) FROM apod_data;
```

---

**Document Version**: 1.0  
**Last Updated**: November 13, 2025  
**Maintained By**: MLOps Team
