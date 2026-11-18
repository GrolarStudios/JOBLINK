import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final StreamController<NotificationModel> _notificationStreamController =
  StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get notificationStream =>
      _notificationStreamController.stream;

  late Box<NotificationModel> _box;

  /// Reemplaza esto por tu VAPID KEY pública de Firebase
  static const String _webVapidKey = 'TU_VAPID_KEY_PUBLICA';

  /// Inicializa Hive, permisos y notificaciones
  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NotificationModelAdapter());
    }

    _box = await Hive.openBox<NotificationModel>('notifications');

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kIsWeb) {
        try {
          final String? token = await _messaging.getToken(
            vapidKey: _webVapidKey,
          );
          debugPrint('FCM Web Token: $token');
        } catch (e) {
          debugPrint('Firebase Messaging no soportado en web: $e');
        }

        // En web no usamos flutter_local_notifications
        return;
      }

      final String? token = await _messaging.getToken();
      debugPrint('FCM Mobile Token: $token');
    } catch (e) {
      debugPrint('Error al inicializar Firebase Messaging: $e');
    }

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notificación presionada: ${response.payload}');
      },
    );
  }

  /// Guardar notificación y mostrar local
  Future<void> saveNotification(NotificationModel notification) async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NotificationModelAdapter());
    }

    if (!Hive.isBoxOpen('notifications')) {
      _box = await Hive.openBox<NotificationModel>('notifications');
    } else {
      _box = Hive.box<NotificationModel>('notifications');
    }

    await _box.add(notification);

    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.add(notification);
    }

    // En web no mostrar notificación local con este plugin
    if (kIsWeb) return;

    await _localNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'Notificaciones',
          channelDescription: 'Canal de notificaciones',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  List<NotificationModel> getAllNotifications() {
    if (!Hive.isBoxOpen('notifications')) return [];
    return _box.values.toList().reversed.toList();
  }

  Future<void> clearAll() async {
    if (Hive.isBoxOpen('notifications')) {
      await _box.clear();
    }
  }

  void dispose() {
    _notificationStreamController.close();
  }
}