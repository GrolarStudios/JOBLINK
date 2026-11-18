import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/utils/firebase_options.dart';
import '../features/tools/notification/data/models/notification_model.dart';
import '../features/tools/notification/data/models/notification_service.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  /// En web no usamos este flujo.
  if (kIsWeb) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!Hive.isAdapterRegistered(0)) {
    // Solo si tu NotificationModel usa TypeAdapter con id 0.
    // Si el registro ya lo haces en otro lado, puedes quitar esto.
  }

  await Hive.initFlutter();

  if (!Hive.isBoxOpen('notificationsBox')) {
    await Hive.openBox('notificationsBox');
  }

  final service = NotificationService();

  final notification = NotificationModel(
    title: message.notification?.title ?? "Sin título",
    body: message.notification?.body ?? "Sin contenido",
    date: DateTime.now(),
  );

  await service.saveNotification(notification);
}