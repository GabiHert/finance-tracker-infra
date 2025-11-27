-- Finance Tracker - PostgreSQL Initialization Script
-- Version: 1.0 | Milestone 1
-- This script runs on first database initialization

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create application user with limited privileges (if not using root)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user WITH LOGIN PASSWORD 'app_password';
    END IF;
END
$$;

-- Grant privileges to app_user on the database
GRANT ALL PRIVILEGES ON DATABASE finance_tracker TO app_user;

-- Set default search path
ALTER DATABASE finance_tracker SET search_path TO public;

-- Create schema for application tables (optional, using public for MVP)
-- CREATE SCHEMA IF NOT EXISTS app;
-- GRANT ALL ON SCHEMA app TO app_user;

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'Finance Tracker database initialized successfully';
    RAISE NOTICE 'UUID extension: enabled';
    RAISE NOTICE 'PGCrypto extension: enabled';
END
$$;
