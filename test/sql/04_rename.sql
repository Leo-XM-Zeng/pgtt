----
-- Regression test to Global Temporary Table implementation
--
-- Test on renaming GTT using ALTER TABLE ... RENAME TO ...
--
-- Renaming a GGT when the temporary table has already been
-- created is not allowed and must be done in a new session.
--
----

-- Create a GTT like table
CREATE /*GLOBAL*/ TEMPORARY TABLE t_glob_temptable1 (id integer, lbl text) ON COMMIT PRESERVE ROWS;

CREATE INDEX ON pgtt_schema.t_glob_temptable1 (id);
CREATE INDEX ON pgtt_schema.t_glob_temptable1 (lbl);

-- Look at Global Temporary Table definition
SELECT nspname, relname, preserved, code FROM pgtt_schema.pg_global_temp_tables;

-- A "template" unlogged table should exists
SELECT a.attname,
  pg_catalog.format_type(a.atttypid, a.atttypmod),
  (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid, true) for 128)
   FROM pg_catalog.pg_attrdef d
   WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef),
  a.attnotnull,
  pg_catalog.col_description(a.attrelid, a.attnum)
FROM pg_catalog.pg_attribute a
WHERE a.attrelid = (
        SELECT c.oid FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE c.relname = 't_glob_temptable1' AND n.nspname = 'pgtt_schema'
        ) AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;

-- With indexes defined
SELECT c2.relname, i.indisprimary, i.indisunique, pg_catalog.pg_get_indexdef(i.indexrelid, 0, true),
  pg_catalog.pg_get_constraintdef(con.oid, true), contype
FROM pg_catalog.pg_class c, pg_catalog.pg_class c2, pg_catalog.pg_index i
  LEFT JOIN pg_catalog.pg_constraint con ON (conrelid = i.indrelid AND conindid = i.indexrelid AND contype IN ('p','u','x'))
WHERE c.oid = (
        SELECT c.oid FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE c.relname = 't_glob_temptable1' AND n.nspname = 'pgtt_schema'
        ) AND c.oid = i.indrelid AND i.indexrelid = c2.oid
ORDER BY i.indisprimary DESC, c2.relname;

-- Rename the table
ALTER TABLE t_glob_temptable1 RENAME TO t_glob_temptable2;

-- Look at Global Temporary Table definition
SELECT nspname, relname, preserved, code FROM pgtt_schema.pg_global_temp_tables;

-- A "template" unlogged table should exists
SELECT a.attname,
  pg_catalog.format_type(a.atttypid, a.atttypmod),
  (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid, true) for 128)
   FROM pg_catalog.pg_attrdef d
   WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef),
  a.attnotnull,
  pg_catalog.col_description(a.attrelid, a.attnum)
FROM pg_catalog.pg_attribute a
WHERE a.attrelid = (
        SELECT c.oid FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE c.relname = 't_glob_temptable2' AND n.nspname = 'pgtt_schema'
        ) AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;

-- With indexes still defined
SELECT c2.relname, i.indisprimary, i.indisunique, pg_catalog.pg_get_indexdef(i.indexrelid, 0, true),
  pg_catalog.pg_get_constraintdef(con.oid, true), contype
FROM pg_catalog.pg_class c, pg_catalog.pg_class c2, pg_catalog.pg_index i
  LEFT JOIN pg_catalog.pg_constraint con ON (conrelid = i.indrelid AND conindid = i.indexrelid AND contype IN ('p','u','x'))
WHERE c.oid = (
        SELECT c.oid FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE c.relname = 't_glob_temptable2' AND n.nspname = 'pgtt_schema'
        ) AND c.oid = i.indrelid AND i.indexrelid = c2.oid
ORDER BY i.indisprimary DESC, c2.relname;

-- With the first insert a temporary table is created and the row inseterd
SET pgtt.enabled TO on;
INSERT INTO t_glob_temptable2 VALUES (1, 'One');

-- Look if we have two tables now
SELECT regexp_replace(n.nspname, '\d+', 'x', 'g'), c.relname FROM pg_class c JOIN pg_namespace n ON (c.relnamespace=n.oid) WHERE relname = 't_glob_temptable2';

-- The table doesn't exist anymore
SET pgtt.enabled TO off;
\d t_glob_temptable1;
SET pgtt.enabled TO on;

INSERT INTO t_glob_temptable2 VALUES (2, 'two');

SELECT * FROM t_glob_temptable2 WHERE id = 2;

-- Rename the table when the temporary table has already been created is not allowed
ALTER TABLE t_glob_temptable2 RENAME TO t_glob_temptable1;

\c - -

ALTER TABLE t_glob_temptable2 RENAME TO t_glob_temptable1;

-- Look if the renaming is effective
SELECT n.nspname, c.relname FROM pg_class c JOIN pg_namespace n ON (c.relnamespace=n.oid) WHERE relname = 't_glob_temptable1';

-- Reconnect and drop it
\c - -
-- Cleanup
DROP TABLE t_glob_temptable1;
