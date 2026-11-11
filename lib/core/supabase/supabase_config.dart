import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../demo/demo_mode.dart';

/// Configuração e Gerenciamento do Cliente Supabase no Flutter
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://usryimqxgdmjlpfiuvod.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzcnlpbXF4Z2RtamxwZml1dm9kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1NDE5OTcsImV4cCI6MjEwNjExNzk5N30.tvXCmwuzdLFU6iICaIYjiZciJ7m3SYxuOCoQf6OMkXI',
  );
  static const String anonKey = supabaseAnonKey;
  static const String wardrobeBucket = 'wardrobe-items';

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Retorna a instância do cliente Supabase se inicializado
  static SupabaseClient? get client {
    if (kDemoMode || !_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Inicializa o SDK oficial do Supabase (ignorado no modo offline/demo)
  static Future<void> initialize() async {
    if (kDemoMode) {
      debugPrint('[Supabase] Modo Demo Offline ativo — servidor externo desconectado.');
      return;
    }
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('[Supabase] Conectado com sucesso ao projeto $supabaseUrl');
    } catch (e) {
      debugPrint('[Supabase] Aviso: Inicialização não concluída (ambiente de teste ou offline): $e');
    }
  }
}
