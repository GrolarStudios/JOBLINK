import 'package:hive_flutter/hive_flutter.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox('notificationsBox');
    await Hive.openBox('userBox');
  }
}