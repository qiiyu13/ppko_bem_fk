-- CreateIndex
CREATE INDEX "medical_screenings_profile_id_screening_at_idx" ON "medical_screenings"("profile_id", "screening_at" DESC);
