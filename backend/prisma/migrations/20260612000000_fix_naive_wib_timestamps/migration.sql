-- The mobile screening form used to send screeningAt as a timezone-less local
-- WIB (UTC+7) ISO string; the API parsed it in the container's UTC zone, so
-- those instants landed ~7h ahead of reality. Rows stamped server-side are
-- correct UTC. created_at is always server-side and correct, and the form
-- always sends "now", so shifted rows are exactly the ones where the stored
-- event time sits ~7h after created_at. A ±10min tolerance absorbs clock skew
-- and upload latency.

UPDATE medical_screenings
SET screening_at = screening_at - INTERVAL '7 hours'
WHERE screening_at - created_at
      BETWEEN INTERVAL '6 hours 50 minutes' AND INTERVAL '7 hours 10 minutes';

-- Health metrics created by the screening cascade inherited the same shifted
-- timestamp into recorded_at.
UPDATE health_metrics
SET recorded_at = recorded_at - INTERVAL '7 hours'
WHERE recorded_at - created_at
      BETWEEN INTERVAL '6 hours 50 minutes' AND INTERVAL '7 hours 10 minutes';
