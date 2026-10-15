import 'dart:typed_data';

import '../../models/user_style_profile.dart';
import '../models/colorimetry_result.dart';
import '../models/style_profile.dart';

/// Falha ao ler ou salvar o perfil, com mensagem pronta para exibição
class StyleProfileFailure implements Exception {
  final String message;

  const StyleProfileFailure(this.message);

  @override
  String toString() => message;
}

/// Contrato do perfil de estilo do usuário autenticado (RF02, RF18)
abstract class StyleProfileRepository {
  Future<StyleProfile> fetch();

  /// Atualização parcial: campos nulos permanecem como estão (RF02, RF18, RN05)
  Future<StyleProfile> update({
    BodySilhouetteType? silhouette,
    SeasonalPaletteType? palette,
    bool? isPublic,
  });

  /// Teste de colorimetria por selfie (RF02); a selfie não é guardada e a cartela não muda sozinha
  Future<ColorimetryResult> analyzeSelfie(Uint8List bytes, String fileName);
}
