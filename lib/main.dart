import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:secure_qr/camera_page.dart';
import 'package:secure_qr/theme_service.dart';
import 'package:secure_qr/scan_history_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ThemeService.init();
  await ScanHistoryService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
  
  static void setTheme(BuildContext context, bool isDark) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?._setTheme(isDark);
  }
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = ThemeService.isDarkTheme;

  void _setTheme(bool isDark) {
    setState(() {
      _isDarkTheme = isDark;
    });
    ThemeService.setDarkTheme(isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure QR',
      theme: ThemeService.getTheme(_isDarkTheme),
      home: const CameraPage(),
    );
  }
}
