#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    SELECT 'CREATE DATABASE n8n' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n')\gexec
    SELECT 'CREATE DATABASE certa' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'certa')\gexec
    SELECT 'CREATE DATABASE nocodb' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'nocodb')\gexec
    GRANT ALL PRIVILEGES ON DATABASE n8n TO certa;
    GRANT ALL PRIVILEGES ON DATABASE certa TO certa;
    GRANT ALL PRIVILEGES ON DATABASE nocodb TO certa;
EOSQL
