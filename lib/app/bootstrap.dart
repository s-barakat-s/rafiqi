import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/app/app.dart';

void bootstrapMainApp() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const TasbeehApp());
}
