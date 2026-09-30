import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/app/app.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

typedef AppRunner = void Function(Widget app);

Future<void> bootstrapMainApp({AppRunner runApplication = runApp}) async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await AppPreferencesRepository.instance.initialize();
  runApplication(const TasbeehApp());
}
