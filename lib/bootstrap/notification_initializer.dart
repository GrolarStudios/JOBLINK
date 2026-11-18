import 'package:flutter/foundation.dart';
import 'firebase_messaging_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../features/tools/notification/data/models/notification_model.dart';
import '../features/tools/notification/data/models/notification_service.dart';

class NotificationInitializer {
  static Future<void> initialize() async {
    /// En web, por ahora no inicializamos Firebase Messaging al arrancar
    /// porque retrasa el inicio y puede fallar por service worker / VAPID.
    if (kIsWeb) {
      debugPrint('⚠️ NotificationInitializer omitido en web');
      return;
    }

    final notificationService = NotificationService();
    await notificationService.init();

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleMessage(message, notificationService);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage, notificationService);
      }

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleMessage(message, notificationService);
      });

      final token = await messaging.getToken();

      if (token != null) {
        debugPrint('FCM Token: $token');
      } else {
        debugPrint('No se pudo obtener token FCM');
      }
    } catch (e, s) {
      debugPrint('❌ Firebase Messaging no disponible: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  static void _handleMessage(
      RemoteMessage message,
      NotificationService notificationService,
      ) {
    try {
      final notification = NotificationModel(
        title: message.notification?.title ?? "Sin título",
        body: message.notification?.body ?? "Sin contenido",
        date: DateTime.now(),
      );

      notificationService.saveNotification(notification);

      debugPrint('📩 Notificación guardada: ${notification.title}');
    } catch (e) {
      debugPrint('Error procesando mensaje: $e');
    }
  }
}