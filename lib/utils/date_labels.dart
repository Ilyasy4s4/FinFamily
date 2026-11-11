const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// 3 Nov 2026
String formatDate(DateTime date) =>
    '${date.day} ${_bulan[date.month - 1]} ${date.year}';

/// "Hari ini", "Kemarin", "2 hari lalu", atau tanggal untuk yang lebih lama.
String relativeDay(DateTime date, DateTime now) {
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  if (diff < 7) return '$diff hari lalu';
  return formatDate(day);
}

const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

/// "November 2026"
String monthName(DateTime date) => '${_bulanPanjang[date.month - 1]} ${date.year}';
