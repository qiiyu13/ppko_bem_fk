class ScheduleStatus {
  /// Effective end time of an appointment. [notesTime] may be a range like
  /// "08:00 - 10:00" or a single "08:00"; the last time found is used. Falls
  /// back to the date's own time component when no time string is present.
  static DateTime endDateTime(DateTime date, String notesTime) {
    final matches = RegExp(r'(\d{1,2}):(\d{2})').allMatches(notesTime).toList();
    if (matches.isNotEmpty) {
      final last = matches.last;
      final h = int.parse(last.group(1)!);
      final m = int.parse(last.group(2)!);
      return DateTime(date.year, date.month, date.day, h, m);
    }
    return date;
  }

  /// Whether the appointment has already finished relative to [now].
  static bool isPast(DateTime date, String notesTime, DateTime now) {
    return now.isAfter(endDateTime(date, notesTime));
  }
}
