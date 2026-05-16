class IndonesianDate {
  IndonesianDate._();

  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const _fullMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static String shortMonth(int month) => _shortMonths[month - 1];

  static String fullMonth(int month) => _fullMonths[month - 1];

  /// Format: '15 Januari 2024'
  static String format(DateTime date) =>
      '${date.day} ${fullMonth(date.month)} ${date.year}';
}
