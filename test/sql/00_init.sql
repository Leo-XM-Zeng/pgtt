/*
 * Must be executed before all regression test.
 */

-- Create the PostgreSQL extension
CREATE EXTENSION pgtt;

-- Set session_preload_libraries
DO $$
BEGIN
    EXECUTE format('ALTER DATABASE %I SET session_preload_libraries = ''pgtt''', current_database());
END
$$;

-- Create a regular table with some rows
CREATE TABLE source (id serial PRIMARY KEY, c2 varchar(50) UNIQUE NOT NULL, lbl varchar DEFAULT '-');
COMMENT ON TABLE source IS 'Table used to demonstrate GTT create as feature';
COMMENT ON COLUMN source.id IS 'auto generated column';
CREATE INDEX ON source(lbl);
INSERT INTO source VALUES (1,'one'), (2,'two'),(3,'three');
