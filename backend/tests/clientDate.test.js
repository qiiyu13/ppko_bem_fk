const { parseClientDate } = require('../src/utils/clientDate');

describe('parseClientDate', () => {
  it('anchors timezone-less ISO strings to WIB (+07:00)', () => {
    const d = parseClientDate('2026-06-12T10:00:00.000');
    expect(d.toISOString()).toBe('2026-06-12T03:00:00.000Z');
  });

  it('leaves UTC-designated strings alone', () => {
    const d = parseClientDate('2026-06-12T03:00:00.000Z');
    expect(d.toISOString()).toBe('2026-06-12T03:00:00.000Z');
  });

  it('leaves offset-designated strings alone', () => {
    const d = parseClientDate('2026-06-12T10:00:00+07:00');
    expect(d.toISOString()).toBe('2026-06-12T03:00:00.000Z');
  });

  it('passes Date instances and null through', () => {
    const now = new Date();
    expect(parseClientDate(now)).toBe(now);
    expect(parseClientDate(null)).toBeNull();
  });
});
