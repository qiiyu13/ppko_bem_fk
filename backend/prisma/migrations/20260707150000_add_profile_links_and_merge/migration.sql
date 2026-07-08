-- AlterTable
ALTER TABLE "family_profiles" ADD COLUMN     "merged_into_id" TEXT,
ALTER COLUMN "nik" DROP NOT NULL;

-- CreateTable
CREATE TABLE "profile_links" (
    "id" TEXT NOT NULL,
    "profile_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'family',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "profile_links_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "profile_links_user_id_idx" ON "profile_links"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "profile_links_profile_id_user_id_key" ON "profile_links"("profile_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "family_profiles_nik_key" ON "family_profiles"("nik");

-- CreateIndex
CREATE INDEX "family_profiles_merged_into_id_idx" ON "family_profiles"("merged_into_id");

-- AddForeignKey
ALTER TABLE "family_profiles" ADD CONSTRAINT "family_profiles_merged_into_id_fkey" FOREIGN KEY ("merged_into_id") REFERENCES "family_profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "profile_links" ADD CONSTRAINT "profile_links_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "family_profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "profile_links" ADD CONSTRAINT "profile_links_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
