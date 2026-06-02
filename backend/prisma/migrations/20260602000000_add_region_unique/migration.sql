-- Collapse pre-existing duplicate regions before enforcing uniqueness.
-- Duplicates can exist because register previously did a non-atomic
-- find-then-create on (type, name, parent_id): two concurrent registrations in
-- the same RW/RT could both miss the find and both insert.
--
-- For each group of rows sharing (type, name, parent_id) with a non-null
-- parent_id, keep the oldest row, repoint child regions and users onto it, then
-- delete the rest. Looped so RT-level collisions newly exposed by collapsing a
-- duplicate RW are resolved on the next pass. Rows with parent_id IS NULL
-- (villages) are left untouched: the unique index treats NULLs as distinct, so
-- they never conflict.
DO $$
DECLARE
  collapsed integer;
BEGIN
  CREATE TEMP TABLE _region_dups (dup_id text, keep_id text) ON COMMIT DROP;
  LOOP
    TRUNCATE _region_dups;
    INSERT INTO _region_dups (dup_id, keep_id)
    SELECT id, keep_id FROM (
      SELECT id,
             first_value(id) OVER (
               PARTITION BY type, name, parent_id
               ORDER BY created_at, id
             ) AS keep_id
      FROM regions
      WHERE parent_id IS NOT NULL
    ) g
    WHERE id <> keep_id;

    SELECT count(*) INTO collapsed FROM _region_dups;
    EXIT WHEN collapsed = 0;

    UPDATE regions r SET parent_id = d.keep_id
      FROM _region_dups d WHERE r.parent_id = d.dup_id;
    UPDATE users u SET region_id = d.keep_id
      FROM _region_dups d WHERE u.region_id = d.dup_id;
    DELETE FROM regions WHERE id IN (SELECT dup_id FROM _region_dups);
  END LOOP;
END $$;

-- CreateIndex
CREATE UNIQUE INDEX "regions_type_name_parent_id_key" ON "regions"("type", "name", "parent_id");
