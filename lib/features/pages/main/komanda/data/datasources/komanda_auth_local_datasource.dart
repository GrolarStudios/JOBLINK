import 'package:hive_flutter/hive_flutter.dart';

import '../../core/komanda_box_names.dart';
import '../../domain/entities/komanda_session.dart';

class KomandaAuthLocalDataSource {
  Future<Box<dynamic>> _box() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(KomandaBoxNames.session)) {
      await Hive.openBox(KomandaBoxNames.session);
    }
    return Hive.box(KomandaBoxNames.session);
  }

  Future<void> saveSession(KomandaSession session) async {
    final box = await _box();
    await box.put('active', session.toMap());
    await box.put('lastUsername', session.username);
  }

  Future<KomandaSession?> getSession() async {
    final box = await _box();
    final value = box.get('active');
    if (value is! Map) return null;
    final session = KomandaSession.fromMap(value);
    return session.isValid ? session : null;
  }

  Future<String?> getLastUsername() async {
    final box = await _box();
    return box.get('lastUsername')?.toString();
  }

  Future<void> clearActiveSession() async {
    final box = await _box();
    await box.delete('active');
  }
}
