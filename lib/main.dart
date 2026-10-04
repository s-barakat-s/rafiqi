import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tasbeh/app/bootstrap.dart';
import 'package:tasbeh/features/tasbeeh/presentation/overlay/tasbeeh_overlay_app.dart';

Future<void> main() async {
  await bootstrapMainApp();
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  runApp(const TasbeehOverlayApp());
}
    