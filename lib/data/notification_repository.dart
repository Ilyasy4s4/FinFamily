import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';

/// Status "sudah dibaca" untuk pusat notifikasi in-app.
/// Disimpan per ruang, hanya di memori seperti repository lain.
class NotificationRepository extends ChangeNotifier {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  final Map<String, Set<String>> _readBySpace = {};

  bool isRead(String space, String id) =>
      _readBySpace[space]?.contains(id) ?? false;

  void markRead(String space, String id) {
    final read = _readBySpace.putIfAbsent(space, () => <String>{});
    if (read.add(id)) notifyListeners();
  }

  void markAllRead(String space, Iterable<String> ids) {
    final read = _readBySpace.putIfAbsent(space, () => <String>{});
    var changed = false;
    for (final id in ids) {
      if (read.add(id)) changed = true;
    }
    if (changed) notifyListeners();
  }

  int unreadCount(String space, List<AppNotification> items) =>
      items.where((item) => !isRead(space, item.id)).length;

  void reset() {
    _readBySpace.clear();
    notifyListeners();
  }
}
