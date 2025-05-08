
-- Best Practice
REVOKE CREATE ON SCHEMA puclib FROM PUBLIC;
REVOKE ALL ON DATABASE DGIPS FROM PUBLIC;
REVOKE ALL ON DATABASE DM    FROM PUBLIC;

-- *********************************************************************************************
-- Read-Only Role
-- *********************************************************************************************
-- Create Read-only role for each DB
CREATE ROLE rReadOnlyDGIPS;
CREATE ROLE rReadOnlyDM;

-- Give access to the Database to each Role
GRANT CONNECT ON DATABASE DGIPS TO rReadOnlyDGIPS;
GRANT CONNECT ON DATABASE DM    TO rReadOnlyDM;

-- Create Schemas
-- They are created

-- Give access to the schema
GRANT USAGE ON SCHEMA schdgips TO rReadOnlyDGIPS;
GRANT USAGE ON SCHEMA schdm    TO rReadOnlyDM;

-- Give SELECT permissions on all tables of schema
GRANT SELECT ON ALL TABLES IN SCHEMA schdgips TO rReadOnlyDGIPS;
GRANT SELECT ON ALL TABLES IN SCHEMA schdm    TO rReadOnlyDM;

-- 
ALTER DEFAULT PRIVILEGIES IN SCHEMA schdgips GRANT SELECT ON TABLES TO rReadOnlyDGIPS;
ALTER DEFAULT PRIVILEGIES IN SCHEMA schdm    GRANT SELECT ON TABLES TO rReadOnlyDM;

-- *********************************************************************************************
-- Read-Write Role
-- *********************************************************************************************
-- Create Read-only role for each DB
CREATE ROLE rReadWriteDGIPS;
CREATE ROLE rReadWriteDM;

-- Give access to the Database to each Role
GRANT CONNECT ON DATABASE DGIPS TO rReadWriteDGIPS;
GRANT CONNECT ON DATABASE DM    TO rReadWriteDM;

-- Give access to the schema
GRANT USAGE, CREATE ON SCHEMA schdgips TO rReadWriteDGIPS;
GRANT USAGE, CREATE ON SCHEMA schdm    TO rReadWriteDM;

-- Give all permissions (no DELETE) on all tables of schema
GRANT SELECT, INSERT, UPDATE         ON ALL TABLES IN SCHEMA schdgips TO rReadWriteDGIPS;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA schdm    TO rReadWriteDM;

-- 
ALTER DEFAULT PRIVILEGIES IN SCHEMA schdgips GRANT SELECT, INSERT, UPDATE         ON TABLES TO rReadWriteDGIPS;
ALTER DEFAULT PRIVILEGIES IN SCHEMA schdm    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO rReadWriteDM;

-- Also need to give privileges to Sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA schdgips TO rReadWriteDGIPS;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA schdm    TO rReadWriteDM;


-- *********************************************************************************************
-- Users
-- *********************************************************************************************
CREATE USER aroust WITH PASSWORD 'usr.aroust.1981'
CREATE USER biuser WITH PASSWORD 'usr.biuser.1981!*'

-- Grant priviles to users
GRANT rReadWriteDGIPS TO aroust; 
GRANT rReadOnlyDM     TO aroust;


CREATE ROLE aroust WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  ENCRYPTED PASSWORD 'SCRAM-SHA-256$4096:Z1HcnkCIbtBE0gohDuuW8w==$NVtJqjWcKo0xWa+1JQXEI+zhsuvhjWM2hymAsQJ8keE=:QV8nRy3wHAFrOOCFW6CbK6ycPKQhPSBSOFPb2iwyjJ8=';

GRANT readwrite TO aroust;