# MLOps ETL Pipeline - NASA APOD Data Integration

## 📋 Project Overview

This project implements a complete MLOps data ingestion pipeline that extracts data from NASA's Astronomy Picture of the Day (APOD) API, transforms it, and loads it into both PostgreSQL and CSV storage. The pipeline includes data versioning with DVC and code versioning with Git, all orchestrated using Apache Airflow in a containerized environment.

### Key Technologies
- **Apache Airflow**: Workflow orchestration
- **Astronomer**: Airflow deployment and management
- **DVC (Data Version Control)**: Data versioning and lineage
- **PostgreSQL**: Relational database storage
- **Docker**: Containerization
- **Python**: Core programming language

## 🎯 Learning Objectives

1. **Orchestration Mastery**: Build complex, dependent workflows using Apache Airflow
2. **Data Integrity**: Implement concurrent data loading to multiple storage systems
3. **Data Lineage**: Use DVC with Git for versioning and traceability
4. **Containerized Deployment**: Deploy production-ready Docker images with all dependencies

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Airflow DAG (ETL Pipeline)              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1: Extract                                            │
│  ┌─────────────────────────────────────────┐              │
│  │  Fetch data from NASA APOD API          │              │
│  │  (https://api.nasa.gov/planetary/apod)  │              │
│  └─────────────────┬───────────────────────┘              │
│                    │                                        │
│  Step 2: Transform │                                        │
│  ┌─────────────────▼───────────────────────┐              │
│  │  Extract fields: date, title, url, etc. │              │
│  │  Convert to pandas DataFrame             │              │
│  └─────────────────┬───────────────────────┘              │
│                    │                                        │
│  Step 3: Load      │                                        │
│  ┌─────────────────▼───────────┬───────────────────────┐  │
│  │  Load to PostgreSQL         │  Load to CSV file     │  │
│  └─────────────────┬───────────┴───────────┬───────────┘  │
│                    │                         │              │
│                    └──────────┬──────────────┘              │
│  Step 4: DVC       │                                        │
│  ┌─────────────────▼───────────────────────┐              │
│  │  Version CSV with DVC (apod_data.csv.dvc)│             │
│  └─────────────────┬───────────────────────┘              │
│                    │                                        │
│  Step 5: Git       │                                        │
│  ┌─────────────────▼───────────────────────┐              │
│  │  Commit .dvc metadata to GitHub         │              │
│  └─────────────────────────────────────────┘              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
A2/
├── README.md                      # This file
├── DOCUMENTATION.md               # Detailed working documentation
├── Dockerfile                     # Custom Airflow image with dependencies
├── docker-compose.yml             # Multi-container setup
├── requirements.txt               # Python dependencies
├── packages.txt                   # System-level dependencies
├── .env                           # Environment variables
├── .gitignore                     # Git ignore patterns
├── .dvcignore                     # DVC ignore patterns
├── dags/
│   └── nasa_apod_etl_dag.py      # Main Airflow DAG
├── plugins/
│   └── (custom operators if needed)
├── data/
│   ├── apod_data.csv             # Generated CSV (DVC tracked)
│   └── apod_data.csv.dvc         # DVC metadata
├── logs/
│   └── (Airflow execution logs)
├── postgres-init/
│   └── init.sql                  # PostgreSQL schema initialization
└── dvc-remote/
    └── (local DVC storage)
```

## 🚀 Pipeline Workflow

### Step 1: Data Extraction (E)
- Connects to NASA APOD API endpoint
- Retrieves daily astronomy picture data in JSON format
- API: `https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY`

### Step 2: Data Transformation (T)
- Parses JSON response
- Extracts fields: `date`, `title`, `url`, `explanation`, `media_type`, `hdurl`
- Converts to pandas DataFrame for easy manipulation

### Step 3: Data Loading (L)
- **Parallel Loading** to ensure data consistency:
  - **PostgreSQL**: Inserts into `apod_data` table
  - **CSV File**: Writes to `data/apod_data.csv`

### Step 4: Data Versioning (DVC)
- Executes `dvc add data/apod_data.csv`
- Generates `apod_data.csv.dvc` metadata file
- Tracks data changes and ensures reproducibility

### Step 5: Code Versioning (Git)
- Commits `.dvc` metadata file to Git
- Links pipeline code to exact data version
- Enables full pipeline reproducibility

## 🛠️ Setup Instructions

### Prerequisites
- Docker and Docker Compose installed
- Git installed
- GitHub account and repository access
- 8GB+ RAM recommended for Airflow

### Installation Steps

1. **Clone the Repository**
```bash
cd /workspaces/mlops/A2
```

2. **Configure Environment Variables**
```bash
# Copy and edit .env file
cp .env.example .env
# Edit with your configuration
```

3. **Initialize Airflow**
```bash
# Create necessary directories
mkdir -p ./logs ./plugins ./data ./dvc-remote

# Set proper permissions
echo -e "AIRFLOW_UID=$(id -u)" > .env
```

4. **Build and Start Containers**
```bash
docker-compose build
docker-compose up -d
```

5. **Initialize DVC**
```bash
# Enter Airflow webserver container
docker-compose exec airflow-webserver bash

# Initialize DVC
cd /opt/airflow
dvc init
dvc remote add -d local /opt/airflow/dvc-remote
dvc config core.autostage true
exit
```

6. **Configure Git**
```bash
# Set up Git credentials in container
docker-compose exec airflow-webserver bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
exit
```

7. **Access Airflow UI**
- URL: http://localhost:8080
- Default credentials: admin/admin

8. **Enable and Trigger DAG**
- Navigate to Airflow UI
- Find `nasa_apod_etl_pipeline` DAG
- Toggle to enable
- Click "Trigger DAG" to run

## 🔍 Testing and Validation

### 1. Verify Airflow DAG Execution
```bash
# Check DAG status
docker-compose exec airflow-webserver airflow dags list
docker-compose exec airflow-webserver airflow dags state nasa_apod_etl_pipeline
```

### 2. Verify PostgreSQL Data
```bash
# Connect to Postgres
docker-compose exec postgres psql -U airflow -d airflow

# Query data
SELECT * FROM apod_data ORDER BY date DESC LIMIT 5;
\q
```

### 3. Verify CSV File
```bash
# Check CSV file contents
docker-compose exec airflow-webserver cat /opt/airflow/data/apod_data.csv
```

### 4. Verify DVC Tracking
```bash
# Check DVC status
docker-compose exec airflow-webserver bash
cd /opt/airflow
dvc status
dvc diff
ls -la data/apod_data.csv.dvc
exit
```

### 5. Verify Git Commits
```bash
# Check Git history
docker-compose exec airflow-webserver git log --oneline -5
```

## 📊 Monitoring and Logs

### View Airflow Logs
```bash
# Task logs
docker-compose logs airflow-webserver
docker-compose logs airflow-scheduler

# Specific DAG logs
docker-compose exec airflow-webserver airflow tasks logs nasa_apod_etl_pipeline extract_data 2025-11-13
```

### View Container Status
```bash
docker-compose ps
docker-compose stats
```

## 🐛 Troubleshooting

### Common Issues

1. **Port Already in Use**
```bash
# Change ports in docker-compose.yml or stop conflicting services
sudo lsof -i :8080
```

2. **Permission Denied**
```bash
# Fix directory permissions
sudo chown -R $(id -u):$(id -g) ./logs ./data
```

3. **DVC Remote Not Accessible**
```bash
# Verify DVC remote configuration
docker-compose exec airflow-webserver dvc remote list
docker-compose exec airflow-webserver dvc remote modify local url /opt/airflow/dvc-remote
```

4. **PostgreSQL Connection Failed**
```bash
# Check Postgres logs
docker-compose logs postgres
# Verify connection string in Airflow connections
```

5. **Git Authentication Issues**
```bash
# Use SSH keys or personal access tokens
# Mount .ssh directory in docker-compose.yml
```

## 🔐 Security Considerations

1. **API Keys**: Never commit API keys to Git. Use environment variables.
2. **Database Credentials**: Store in `.env` file, exclude from Git.
3. **SSH Keys**: Mount securely, never include in Docker image.
4. **Airflow Connections**: Use Airflow's connection management UI.

## 📈 Future Enhancements

1. **Incremental Loading**: Load only new data instead of full refresh
2. **Data Quality Checks**: Add Great Expectations for data validation
3. **Alerting**: Configure email/Slack alerts for pipeline failures
4. **Cloud Deployment**: Deploy to AWS MWAA or GCP Composer
5. **Data Lake Integration**: Add S3/GCS as additional storage target
6. **CI/CD Pipeline**: Automate testing and deployment
7. **Monitoring**: Integrate Prometheus and Grafana

## 📚 Key Learnings

### Orchestration Mastery
- DAG design principles and task dependencies
- Error handling and retry strategies
- XCom for inter-task communication

### Data Integrity
- Concurrent data loading patterns
- Transaction management in ETL
- Idempotent pipeline design

### Data Lineage
- DVC for data versioning
- Git for code versioning
- Reproducible pipeline execution

### Containerized Deployment
- Multi-stage Docker builds
- Docker Compose orchestration
- Environment management
- Dependency isolation

## 🤝 Contributing

This is an educational project. For improvements:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly
4. Submit a pull request

## 📝 License

Educational project - MIT License

## 👥 Author

MLOps Assignment 2 - ETL Pipeline with Airflow, DVC, and PostgreSQL

## 📞 Support

For issues or questions:
- Check logs: `docker-compose logs`
- Review Airflow UI task logs
- Consult DOCUMENTATION.md for detailed implementation notes

---

**Last Updated**: November 13, 2025
**Airflow Version**: 2.7.3
**Python Version**: 3.11
