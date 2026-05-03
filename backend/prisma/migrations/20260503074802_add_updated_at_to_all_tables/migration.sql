/*
  Warnings:

  - You are about to alter the column `kk_number` on the `users` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(16)`.
  - Added the required column `updated_at` to the `appointments` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `chat_messages` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `family_profiles` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `health_metrics` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `medical_screenings` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `regions` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `residents` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "appointments" ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "chat_messages" ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "family_profiles" ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "health_metrics" ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "medical_screenings" ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "regions" ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "residents" ADD COLUMN     "updated_at" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "users" ALTER COLUMN "kk_number" DROP DEFAULT,
ALTER COLUMN "kk_number" SET DATA TYPE VARCHAR(16),
ALTER COLUMN "responsible_name" DROP DEFAULT;
