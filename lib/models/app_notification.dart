/// Tingkat kepentingan sebuah pengingat.
enum AppNotificationLevel { info, warning, danger }

/// Satu pengingat in-app.
///
/// [id] dibuat stabil per bulan/kondisi supaya status "sudah dibaca" tidak
/// hilang setiap kali layar dibuka ulang.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.level,
    this.actionTab,
  });

  final String id;
  final String title;
  final String message;
  final AppNotificationLevel level;

  /// Tab MainShell yang dibuka saat kartu diketuk (2 = Analisis, 3 = Plan).
  final int? actionTab;
}
