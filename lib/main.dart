import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/app_state.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SmartCageApp(),
    ),
  );
}

class SmartCageApp extends StatelessWidget {
  const SmartCageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChirpGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue600,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.slate50,
        textTheme: GoogleFonts.interTextTheme(),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return state.onboardingComplete
        ? const MainShell()
        : const OnboardingScreen();
  }
}
