import 'dart:typed_data';

import 'package:harmonia_mvp/domain/models/colorimetry_result.dart';
import 'package:harmonia_mvp/domain/models/style_profile.dart';
import 'package:harmonia_mvp/domain/repositories/style_profile_repository.dart';
import 'package:harmonia_mvp/models/user_style_profile.dart';

/// Perfil de estilo em memória para testes de widget
class FakeStyleProfileRepository implements StyleProfileRepository {
  StyleProfile profile;
  StyleProfileFailure? nextFailure;
  final List<String> calls = [];

  /// Resultado de [analyzeSelfie]; nulo simula rosto fora do oval
  ColorimetryResult? colorimetry;

  FakeStyleProfileRepository({StyleProfile? profile}) : profile = profile ?? const StyleProfile();

  /// Perfil com onboarding concluído
  factory FakeStyleProfileRepository.completed() => FakeStyleProfileRepository(
        profile: const StyleProfile(
          silhouette: BodySilhouetteType.ampulheta,
          palette: SeasonalPaletteType.outonoQuente,
          itemsCount: 12,
          looksToday: 2,
        ),
      );

  void _throwIfQueued() {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
  }

  @override
  Future<StyleProfile> fetch() async {
    calls.add('fetch');
    _throwIfQueued();
    return profile;
  }

  @override
  Future<StyleProfile> update({
    BodySilhouetteType? silhouette,
    SeasonalPaletteType? palette,
    bool? isPublic,
  }) async {
    calls.add('update');
    _throwIfQueued();
    profile = profile.copyWith(silhouette: silhouette, palette: palette, isPublic: isPublic);
    return profile;
  }

  @override
  Future<ColorimetryResult> analyzeSelfie(Uint8List bytes, String fileName) async {
    calls.add('analyzeSelfie');
    _throwIfQueued();
    final result = colorimetry;
    if (result == null) throw const StyleProfileFailure('Não encontramos o rosto no centro da foto.');
    return result;
  }
}
