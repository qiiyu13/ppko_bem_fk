-- AlterTable: make kk_number nullable
ALTER TABLE "users" ALTER COLUMN "kk_number" DROP NOT NULL;

-- AlterTable: add username column
ALTER TABLE "users" ADD COLUMN "username" VARCHAR(50);

-- CreateIndex
CREATE UNIQUE INDEX "users_username_key" ON "users"("username");
