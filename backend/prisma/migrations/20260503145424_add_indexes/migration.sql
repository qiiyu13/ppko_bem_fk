-- CreateIndex
CREATE INDEX "appointments_user_id_idx" ON "appointments"("user_id");

-- CreateIndex
CREATE INDEX "appointments_profile_id_idx" ON "appointments"("profile_id");

-- CreateIndex
CREATE INDEX "appointments_date_idx" ON "appointments"("date");

-- CreateIndex
CREATE INDEX "articles_author_id_idx" ON "articles"("author_id");

-- CreateIndex
CREATE INDEX "articles_is_published_idx" ON "articles"("is_published");

-- CreateIndex
CREATE INDEX "articles_publish_date_idx" ON "articles"("publish_date");

-- CreateIndex
CREATE INDEX "chat_conversations_user_id_idx" ON "chat_conversations"("user_id");

-- CreateIndex
CREATE INDEX "chat_conversations_last_activity_at_idx" ON "chat_conversations"("last_activity_at");

-- CreateIndex
CREATE INDEX "chat_messages_conversation_id_idx" ON "chat_messages"("conversation_id");

-- CreateIndex
CREATE INDEX "chat_messages_created_at_idx" ON "chat_messages"("created_at");

-- CreateIndex
CREATE INDEX "family_profiles_user_id_idx" ON "family_profiles"("user_id");

-- CreateIndex
CREATE INDEX "health_metrics_profile_id_idx" ON "health_metrics"("profile_id");

-- CreateIndex
CREATE INDEX "health_metrics_type_idx" ON "health_metrics"("type");

-- CreateIndex
CREATE INDEX "health_metrics_recorded_at_idx" ON "health_metrics"("recorded_at");

-- CreateIndex
CREATE INDEX "medical_screenings_profile_id_idx" ON "medical_screenings"("profile_id");

-- CreateIndex
CREATE INDEX "medical_screenings_screened_by_idx" ON "medical_screenings"("screened_by");

-- CreateIndex
CREATE INDEX "medical_screenings_ird_category_idx" ON "medical_screenings"("ird_category");

-- CreateIndex
CREATE INDEX "medical_screenings_screening_at_idx" ON "medical_screenings"("screening_at");

-- CreateIndex
CREATE INDEX "residents_region_id_idx" ON "residents"("region_id");
