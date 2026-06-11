// Mobile clients (pre-UTC-fix builds) send local WIB wall-clock ISO strings
// with no timezone designator; `new Date()` would parse those in the server's
// zone (UTC in the container), storing instants 7 hours ahead of reality.
// Anchor designator-less ISO strings to Asia/Jakarta (+07:00, no DST) so old
// app versions keep producing correct instants.
const HAS_TZ_DESIGNATOR = /(Z|[+-]\d{2}:?\d{2})$/i;
const ISO_DATETIME = /^\d{4}-\d{2}-\d{2}T/;

const parseClientDate = (value) => {
  if (value == null || value instanceof Date) return value;
  const s = String(value).trim();
  if (ISO_DATETIME.test(s) && !HAS_TZ_DESIGNATOR.test(s)) {
    return new Date(`${s}+07:00`);
  }
  return new Date(s);
};

module.exports = { parseClientDate };
