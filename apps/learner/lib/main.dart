import 'package:flutter/material.dart';

import 'app.dart';
import 'app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Saved preferences are read before the first frame, so the app never
  // flashes the default language or text size before correcting itself.
  final settings = await AppSettings.load();
  runApp(EvidenceGymApp(settings: settings));
}
