# MongoDB Configuration for MLOps Application

## Database Information
- Database Name: mlops
- Default Port: 27017
- Collections: users

## Indexes
- users.email: unique index for email field

## Environment Variables
Set these in your Docker Compose or Kubernetes configuration:
- MONGO_INITDB_DATABASE=mlops
