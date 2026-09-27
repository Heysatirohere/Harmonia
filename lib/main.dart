import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_colors.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surfaceCanvas,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HarmoniaApp());
}

class HarmoniaApp extends StatelessWidget {
  const HarmoniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HarmonIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.surfaceCanvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentTerracotta,
          primary: AppColors.accentTerracotta,
          surface: AppColors.surfaceCanvas,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const MainNavigationScreen(),
    );
  }
}
