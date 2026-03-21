import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Starting app...');
  try {
    await dotenv.load(fileName: '.env');
    print('Env loaded successfully');
    print('GEMINI_API_KEY=${dotenv.env['GEMINI_API_KEY']}');
  } catch (e) {
    print('Error loading .env file: $e');
  }
  print('Running app');
  runApp(
    const ProviderScope(
      child: BKMobileApp(),
    ),
  );
}

class BKMobileApp extends StatelessWidget {
  const BKMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BK Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
