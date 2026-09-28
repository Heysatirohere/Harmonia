import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';

/// Serviço de Storage de Fotos de Roupas no Supabase (RF03, RF04)
class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  SupabaseClient? get _client => SupabaseConfig.client;

  /// Faz o upload dos bytes da imagem PNG com canal alfa para o bucket 'wardrobe-items'
  Future<String?> uploadClothingImage({
    required Uint8List imageBytes,
    required String fileName,
    String contentType = 'image/png',
  }) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseStorage] Cliente Supabase não inicializado.');
      return null;
    }

    try {
      final storage = client.storage.from(SupabaseConfig.wardrobeBucket);
      final filePath = 'garments/$fileName';

      await storage.uploadBinary(
        filePath,
        imageBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      final publicUrl = storage.getPublicUrl(filePath);
      debugPrint('[SupabaseStorage] Upload realizado com sucesso: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseStorage] Erro no upload de imagem: $e');
      return null;
    }
  }

  /// Retorna a URL pública de uma peça armazenada
  String? getPublicUrl(String filePath) {
    final client = _client;
    if (client == null) return null;
    return client.storage.from(SupabaseConfig.wardrobeBucket).getPublicUrl(filePath);
  }

  /// Exclui uma imagem do bucket
  Future<bool> deleteClothingImage(String filePath) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.storage.from(SupabaseConfig.wardrobeBucket).remove([filePath]);
      debugPrint('[SupabaseStorage] Arquivo removido: $filePath');
      return true;
    } catch (e) {
      debugPrint('[SupabaseStorage] Erro ao excluir imagem: $e');
      return false;
    }
  }
}
