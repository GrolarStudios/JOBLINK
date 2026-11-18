import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/pages/main/komanda/core/komanda_box_names.dart';

final GetIt sl = GetIt.instance;

/// ===========================================================
/// Inicialización GLOBAL de la aplicación.
/// Aquí NO se abre ninguna caja del restaurante.
/// ===========================================================
Future<void> init() async {
  await Hive.initFlutter();

  await _openGlobalBoxes();

  _registerGlobalDependencies();
}

/// ===========================================================
/// Solo cajas globales.
/// ===========================================================
Future<void> _openGlobalBoxes() async {
  await _openBoxIfNeeded(KomandaBoxNames.session);
  await _openBoxIfNeeded('notificationsBox');
  await _openBoxIfNeeded('userBox');
}

/// ===========================================================
Future<void> _openBoxIfNeeded(String name) async {
  if (!Hive.isBoxOpen(name)) {
    await Hive.openBox(name);
  }
}

/// ===========================================================
/// Dependencias GLOBALS.
/// NO registrar Repository, Bloc ni DataSource aquí.
/// ===========================================================
void _registerGlobalDependencies() {
  // De momento puede quedar vacío.
}
