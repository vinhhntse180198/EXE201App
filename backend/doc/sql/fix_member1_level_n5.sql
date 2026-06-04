-- member1 (id=30): placement_results_app = N5, users.level_id phải là 1 (N5).
UPDATE "users"
SET "level_id" = 1, "updated_at" = NOW()
WHERE "id" = 30;
