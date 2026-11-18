import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'notification_model.dart';

// Top-level function obligatoria por Firebase
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializa Hive si no lo está
  await Hive.initFlutter();
  Hive.registerAdapter(NotificationModelAdapter());
  final box = await Hive.openBox<NotificationModel>('notifications');

  final notification = NotificationModel(
    title: message.notification?.title ?? 'Sin título',
    body: message.notification?.body ?? 'Sin cuerpo',
    date: DateTime.now(),
  );

  // Guardar en Hive
  await box.add(notification);

  // Inicializar notificaciones locales
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings =
  InitializationSettings(android: androidSettings, iOS: iosSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Mostrar notificación local
  flutterLocalNotificationsPlugin.show(
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
