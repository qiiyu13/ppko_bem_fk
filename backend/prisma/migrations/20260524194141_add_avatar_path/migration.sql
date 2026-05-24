-- AlterTable
ALTER TABLE "family_profiles" ADD COLUMN     "avatar_path" TEXT;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "avatar_path" TEXT;

-- CreateIndex
CREATE INDEX "appointments_type_idx" ON "appointments"("type");

-- CreateIndex
CREATE INDEX "notifications_user_id_is_read_idx" ON "notifications"("user_id", "is_read");

-- CreateIndex
CREATE INDEX "regions_parent_id_idx" ON "regions"("parent_id");

-- CreateIndex
CREATE INDEX "regions_name_idx" ON "regions"("name");
