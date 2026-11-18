import 'package:flutter/material.dart';

import 'app.dart';
import 'injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa dependencias globales.
  // NO abre las cajas de cada restaurante.
  await di.init();

  runApp(const MyApp());
}