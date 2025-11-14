# Quick Start Guide - NASA APOD ETL Pipeline

## 🚀 Quick Setup (5 Minutes)

### Prerequisites
- Docker & Docker Compose installed
- 8GB+ RAM available
- 10GB+ disk space

### Step 1: Navigate to Project Directory
```bash
cd /workspaces/mlops/A2
```

### Step 2: Run Setup Script
```bash
chmod +x setup.sh test.sh
./setup.sh
```

This script will:
- ✅ Check prerequisites
- ✅ Create directory structure
- ✅ Configure environment variables
- ✅ Build Docker images
- ✅ Start all services
- ✅ Initialize Airflow, PostgreSQL, DVC, and Git

### Step 3: Access Airflow UI
Wait 1-2 minutes for services to start, then open:
- **URL**: http://localhost:8080
- **Username**: `admin`
- **Password**: `admin`

### Step 4: Enable and Trigger DAG
1. Find `nasa_apod_etl_pipeline` in the DAG list
2. Toggle the switch to **ON** (unpause)
3. Click the **Play** button (▶) to trigger the DAG

### Step 5: Monitor Execution
- Watch task status in the DAG graph view
- Click on tasks to view logs
- Wait for all tasks to turn green (success)

### Step 6: Verify Results

**Run Automated Tests:**
```bash
./test.sh
```

**Manual Verification:**

**Check PostgreSQL Data:**
```bash
docker-compose exec postgres psql -U airflow -d airflow -c "SELECT * FROM apod_data ORDER BY date DESC LIMIT 5;"
```

**Check CSV File:**
```bash
docker-compose exec airflow-webserver cat /opt/airflow/data/apod_data.csv
```

**Check DVC Status:**
```bash
docker-compose exec airflow-webserver bash -c "cd /opt/airflow && dvc status"
```

**Check Git Commits:**
```bash
docker-compose exec airflow-webserver bash -c "cd /opt/airflow && git log --oneline -5"
```

## 📊 What Each Task Does

### Task 1: Extract Data
- Fetches today's astronomy picture data from NASA API
- Handles retries and timeouts
- Logs API response

### Task 2: Transform Data
- Extracts relevant fields (date, title, explanation, URLs)
- Validates data quality
- Adds extraction timestamp

### Task 3: Load Data (Parallel)
- **3a**: Inserts data into PostgreSQL (UPSERT to handle duplicates)
- **3b**: Appends data to CSV file (removes duplicates, sorts by date)

### Task 4: Version with DVC
- Tracks CSV file with DVC
- Creates `.dvc` metadata file
- Stores actual data in DVC remote storage

### Task 5: Commit to Git
- Stages DVC metadata files
- Commits to Git repository
- Links code version to data version

## 🛠️ Useful Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f airflow-scheduler
docker-compose logs -f airflow-webserver
docker-compose logs -f postgres
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart airflow-webserver
```

### Stop Services
```bash
docker-compose down
```

### Start Services
```bash
docker-compose up -d
```

### Execute Airflow Commands
```bash
# List all DAGs
docker-compose exec airflow-webserver airflow dags list

# Trigger DAG manually
docker-compose exec airflow-webserver airflow dags trigger nasa_apod_etl_pipeline

# Check DAG status
docker-compose exec airflow-webserver airflow dags state nasa_apod_etl_pipeline

# View task logs
docker-compose exec airflow-webserver airflow tasks logs nasa_apod_etl_pipeline extract_data 2025-11-13
```

### Database Commands
```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U airflow -d airflow

# Inside psql:
\dt                                          # List tables
\d apod_data                                 # Describe table
SELECT COUNT(*) FROM apod_data;              # Count records
SELECT * FROM apod_data ORDER BY date DESC;  # View data
\q                                           # Quit
```

### DVC Commands
```bash
# Enter container
docker-compose exec airflow-webserver bash

# DVC commands
cd /opt/airflow
dvc status           # Check tracking status
dvc diff             # Show changes
dvc push             # Push to remote (if configured)
dvc pull             # Pull from remote
dvc checkout         # Checkout specific version

exit
```

## 🐛 Troubleshooting

### Problem: Airflow UI not accessible
```bash
# Check if container is running
docker-compose ps

# Check logs
docker-compose logs airflow-webserver

# Restart
docker-compose restart airflow-webserver
```

### Problem: DAG not appearing
```bash
# Check for import errors
docker-compose exec airflow-webserver airflow dags list-import-errors

# Check DAG file syntax
docker-compose exec airflow-webserver python /opt/airflow/dags/nasa_apod_etl_dag.py

# Restart scheduler
docker-compose restart airflow-scheduler
```

### Problem: Database connection error
```bash
# Check Postgres status
docker-compose ps postgres

# Test connection
docker-compose exec postgres pg_isready -U airflow

# Restart database
docker-compose restart postgres
```

### Problem: DVC commands fail
```bash
# Re-initialize DVC
docker-compose exec airflow-webserver bash -c "
cd /opt/airflow && \
dvc init --no-scm && \
dvc remote add -d local /opt/airflow/dvc-remote && \
dvc config core.autostage true
"
```

### Problem: Port already in use
```bash
# Check what's using port 8080
sudo lsof -i :8080

# Kill the process or change port in docker-compose.yml
# Edit docker-compose.yml and change "8080:8080" to "8081:8080"
```

## 📈 Expected Output

### Successful DAG Run
All tasks should show **green** (success) status:
1. ✅ extract_data
2. ✅ transform_data
3. ✅ load_to_postgres
4. ✅ load_to_csv
5. ✅ version_data_with_dvc
6. ✅ commit_to_git

### Sample PostgreSQL Data
```
 date       | title                      | media_type | extracted_at
------------+----------------------------+------------+---------------------------
 2025-11-13 | Meteor Over Mountains      | image      | 2025-11-13T10:30:45.123456
```

### Sample CSV Content
```csv
date,title,explanation,url,hdurl,media_type,copyright,extracted_at
2025-11-13,Meteor Over Mountains,"What's happening to that meteor?...",https://...,https://...,image,Photographer Name,2025-11-13T10:30:45.123456
```

### Sample DVC File (.dvc)
```yaml
outs:
- md5: abc123def456...
  size: 1234
  path: apod_data.csv
```

### Sample Git Commit
```
abc1234 Update APOD data version - 2025-11-13_10-30-45
def5678 Update APOD data version - 2025-11-12_10-30-45
```

## 🎯 Success Criteria

- [x] All Docker containers running
- [x] Airflow UI accessible
- [x] DAG executes without errors
- [x] Data in PostgreSQL (verified with query)
- [x] CSV file created and populated
- [x] `.dvc` metadata file generated
- [x] Git commit created with DVC metadata

## 📚 Next Steps

1. **Schedule**: The DAG runs daily at midnight by default
2. **Monitoring**: Check Airflow UI daily for failed runs
3. **Data Analysis**: Query PostgreSQL or analyze CSV file
4. **Versioning**: Track data changes through Git history
5. **Scaling**: Modify schedule or add more data sources

## 🆘 Getting Help

- Check logs: `docker-compose logs -f`
- View task logs in Airflow UI
- Review DOCUMENTATION.md for detailed explanations
- Check troubleshooting section in README.md

---

**Estimated Setup Time**: 5-10 minutes  
**First DAG Run**: ~2 minutes  
**Daily Runs**: Automatic at midnight
