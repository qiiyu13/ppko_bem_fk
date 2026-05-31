-- Enable trigram matching so case-insensitive substring search (ILIKE '%term%')
-- can use a GIN index instead of a full sequential scan.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Patient search in admin.getPatients filters on these columns with
-- `contains` + `mode: insensitive`. GIN trigram indexes make those fast.
CREATE INDEX IF NOT EXISTS "users_responsible_name_trgm"
  ON "users" USING gin ("responsible_name" gin_trgm_ops);

CREATE INDEX IF NOT EXISTS "users_kk_number_trgm"
  ON "users" USING gin ("kk_number" gin_trgm_ops);

CREATE INDEX IF NOT EXISTS "family_profiles_name_trgm"
  ON "family_profiles" USING gin ("name" gin_trgm_ops);
