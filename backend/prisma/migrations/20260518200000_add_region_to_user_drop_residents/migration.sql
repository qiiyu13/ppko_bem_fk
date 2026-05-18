-- Drop residents table
DROP TABLE IF EXISTS "residents";

-- Add region_id to users
ALTER TABLE "users" ADD COLUMN "region_id" TEXT;

-- Add foreign key constraint
ALTER TABLE "users" ADD CONSTRAINT "users_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "regions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Add index
CREATE INDEX "users_region_id_idx" ON "users"("region_id");
