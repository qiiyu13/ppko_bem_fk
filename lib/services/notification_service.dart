import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/platform_util.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are shown by the OS automatically via FCM.
  // No action needed here unless custom processing is required.
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  static const _localCacheKey = 'cached_notifications';
  static const _enabledKey = 'notifications_enabled';

  final ValueNotifier<int> unreadCount = ValueNotifier(0);
  final ValueNotifier<List<NotificationModel>> notifications =
      ValueNotifier([]);
  final ValueNotifier<bool> enabled = ValueNotifier(true);

  final _localNotif = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _loadLocalCache();
    await _loadEnabled();
    if (PlatformUtil.firebaseAvailable && !kIsWeb && enabled.value) {
      await _initFcm();
    }
    fetchFromApi();
  }

  Future<void> _loadEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_enabledKey) ?? true;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (_) {}

    if (!PlatformUtil.firebaseAvailable || kIsWeb) return;

    try {
      if (value) {
        await _initFcm();
      } else {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {}
  }

  Future<void> _initFcm() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await registerFcmToken(token);

      FirebaseMessaging.instance.onTokenRefresh.listen(registerFcmToken);
    }

    // Foreground messages → show local notification + add to feed
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Tapped from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTappedMessage);
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotif.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    const channel = AndroidNotificationChannel(
      'mediku_notifications',
      'MEDIKU Notifikasi',
      description: 'Jadwal dan hasil skrining',
      importance: Importance.high,
    );
    final plugin = _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(channel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (!enabled.value) return;
    final notif = _remoteToModel(message);
    addLocal(notif);

    final n = message.notification;
    if (n != null) {
      _localNotif.show(
        id: message.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'mediku_notifications',
            'MEDIKU Notifikasi',
            channelDescription: 'Jadwal dan hasil skrining',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  void _handleTappedMessage(RemoteMessage message) {
    final notif = _remoteToModel(message);
    markRead(notif.id);
  }

  NotificationModel _remoteToModel(RemoteMessage message) {
    final data = message.data;
    return NotificationModel(
      id: data['notificationId'] ?? message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? data['title'] ?? '',
      body: message.notification?.body ?? data['body'] ?? '',
      type: NotificationModel.parseTypeString(data['type'] ?? ''),
      createdAt: message.sentTime ?? DateTime.now(),
      data: data,
    );
  }

  Future<void> registerFcmToken(String token) async {
    try {
      await ApiService.post(
        '/notifications/register-token',
        data: {'fcmToken': token},
      );
    } catch (_) {}
  }

  Future<void> fetchFromApi() async {
    try {
      final response = await ApiService.get('/notifications');
      final List<dynamic> raw = response.data['data'] ?? [];
      final fetched = raw
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _merge(fetched);
    } catch (_) {}
  }

  void addLocal(NotificationModel notif) {
    final current = List<NotificationModel>.from(notifications.value);
    if (current.any((n) => n.id == notif.id)) return;
    current.insert(0, notif);
    notifications.value = current;
    _updateUnread();
    _saveLocalCache();
  }

  Future<void> markAllRead() async {
    for (final n in notifications.value) {
      n.isRead = true;
    }
    notifications.value = List.from(notifications.value);
    unreadCount.value = 0;
    _saveLocalCache();
    try {
      await ApiService.post('/notifications/mark-all-read', data: {});
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    final idx = notifications.value.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    notifications.value[idx].isRead = true;
    notifications.value = List.from(notifications.value);
    _updateUnread();
    _saveLocalCache();
    try {
      await ApiService.post('/notifications/$id/read', data: {});
    } catch (_) {}
  }

  void _merge(List<NotificationModel> fetched) {
    final existingIds = {for (final n in notifications.value) n.id};
    final merged = List<NotificationModel>.from(notifications.value);
    for (final n in fetched) {
      if (!existingIds.contains(n.id)) merged.add(n);
    }
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifications.value = merged;
    _updateUnread();
    _saveLocalCache();
  }

  void _updateUnread() {
    unreadCount.value = notifications.value.where((n) => !n.isRead).length;
  }

  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localCacheKey);
      if (raw == null) return;
      final List<dynamic> list = jsonDecode(raw) as List;
      notifications.value = list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _updateUnread();
    } catch (_) {}
  }

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        notifications.value.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_localCacheKey, encoded);
    } catch (_) {}
  }

  static Future<void> clearCache() async {
    final instance = NotificationService.instance;
    instance.notifications.value = [];
    instance.unreadCount.value = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localCacheKey);
    } catch (_) {}
  }
}
