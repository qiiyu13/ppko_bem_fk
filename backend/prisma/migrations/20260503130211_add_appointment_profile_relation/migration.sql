-- AddForeignKey
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "family_profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;
