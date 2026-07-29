INSERT INTO companies (code, name)
VALUES ('acme', 'Acme Company')
ON CONFLICT (code) DO NOTHING;
