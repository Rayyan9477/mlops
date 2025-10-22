// MongoDB initialization script
db = db.getSiblingDB('mlops');

// Create users collection with indexes
db.createCollection('users');
db.users.createIndex({ email: 1 }, { unique: true });

print('MongoDB initialized successfully for MLOps application');
