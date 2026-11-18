import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../injection_container.dart' as di;
import 'firebase_initializer.dart';
import 'hive_initializer.dart';
import 'notification_initializer.dart';

class AppInitializer {
  static Future<bool> loadInitialTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false;
  }

  static Future<void> initializeDeferred() async {
    try {
      var sw = Stopwatch()..start();
      await FirebaseInitializer.initialize();
      log('FirebaseInitializer: ${sw.elapsedMilliseconds} ms');

      sw = Stopwatch()..start();
      await HiveInitializer.initialize();
      log('HiveInitializer: ${sw.elapsedMilliseconds} ms');

      sw = Stopwatch()..start();
      await di.init();
      log('di.init: ${sw.elapsedMilliseconds} ms');

      if (!kIsWeb) {
        sw = Stopwatch()..start();
        await NotificationInitializer.initialize();
        log('NotificationInitializer: ${sw.elapsedMilliseconds} ms');

        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
        );
      }
    } catch (e, s) {
      log('Error en initializeDeferred: $e');
      log('$s');
    }
  }
}