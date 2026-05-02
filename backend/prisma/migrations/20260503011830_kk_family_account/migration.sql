-- DropIndex
DROP INDEX "users_nik_key";

-- AlterTable
ALTER TABLE "users"
  DROP COLUMN "nik",
  DROP COLUMN "name",
  DROP COLUMN "gender",
  DROP COLUMN "birth_date",
  DROP COLUMN "blood_type",
  DROP COLUMN "address",
  ADD COLUMN     "kk_number" TEXT NOT NULL DEFAULT '',
  ADD COLUMN     "responsible_name" TEXT NOT NULL DEFAULT '';

-- CreateIndex
CREATE UNIQUE INDEX "users_kk_number_key" ON "users"("kk_number");
