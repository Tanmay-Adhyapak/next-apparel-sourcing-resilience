-- Verify schema creation. Expect staging, core, analytics and qc.

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('staging', 'core', 'analytics', 'qc')
ORDER BY schema_name;
