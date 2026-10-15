import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/supabase/supabase_config.dart';
import 'data/services/style_profile_api_service.dart';
import 'data/services/supabase_auth_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/style_profile_repository.dart';
import 'presentation/auth/auth_scope.dart';
import 'presentation/profile/style_profile_scope.dart';
import 'presentation/screens/auth_gate.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // todas as Salas são escuras
      // Barra do sistema contínua com a EditorialNavBar (tapeçaria noir)
      systemNavigationBarColor: AppColors.tapestryNoir,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicialização do Supabase (Auth, Storage & Database)
  await SupabaseConfig.initialize();

  runApp(const HarmoniaApp());
}

class HarmoniaApp extends StatelessWidget {
  final AuthRepository? authRepository;
  final StyleProfileRepository? styleProfileRepository;

  const HarmoniaApp({super.key, this.authRepository, this.styleProfileRepository});

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      repository: authRepository ?? SupabaseAuthService(),
      child: StyleProfileScope(
        repository: styleProfileRepository ?? StyleProfileApiService(),
        child: MaterialApp(
          title: 'HarmonIA',
          debugShowCheckedModeBanner: false,
          theme: appThemeData,
          home: const AuthGate(),
        ),
      ),
    );
  }
}
