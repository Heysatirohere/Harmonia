import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/supabase/supabase_config.dart';
import 'data/services/supabase_auth_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/auth/auth_scope.dart';
import 'presentation/screens/auth_gate.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surfaceCanvas,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicialização do Supabase (Auth, Storage & Database)
  await SupabaseConfig.initialize();

  runApp(const HarmoniaApp());
}

class HarmoniaApp extends StatelessWidget {
  final AuthRepository? authRepository;

  const HarmoniaApp({super.key, this.authRepository});

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      repository: authRepository ?? SupabaseAuthService(),
      child: MaterialApp(
        title: 'HarmonIA',
        debugShowCheckedModeBanner: false,
        theme: appThemeData,
        home: const AuthGate(),
      ),
    );
  }
}
