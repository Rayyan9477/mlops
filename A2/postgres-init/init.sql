-- PostgreSQL Initialization Script for NASA APOD Data
-- This script creates the necessary table for storing APOD data

-- Connect to the airflow database
\c airflow

-- Create the apod_data table
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_apod_date ON apod_data(date);
CREATE INDEX IF NOT EXISTS idx_apod_media_type ON apod_data(media_type);
CREATE INDEX IF NOT EXISTS idx_apod_created_at ON apod_data(created_at);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to automatically update the updated_at column
DROP TRIGGER IF EXISTS update_apod_data_updated_at ON apod_data;
CREATE TRIGGER update_apod_data_updated_at
    BEFORE UPDATE ON apod_data
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON TABLE apod_data TO airflow;
GRANT USAGE, SELECT ON SEQUENCE apod_data_id_seq TO airflow;

-- Display confirmation message
DO $$
BEGIN
    RAISE NOTICE 'NASA APOD database schema initialized successfully!';
    RAISE NOTICE 'Table: apod_data';
    RAISE NOTICE 'Indexes: idx_apod_date, idx_apod_media_type, idx_apod_created_at';
    RAISE NOTICE 'Triggers: update_apod_data_updated_at';
END $$;
