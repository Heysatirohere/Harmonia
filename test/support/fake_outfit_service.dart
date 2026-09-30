import 'package:harmonia_mvp/data/services/outfit_api_service.dart';
import 'package:harmonia_mvp/domain/models/recommended_look.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';

/// Motor de looks em memória para testes de widget
class FakeOutfitService extends OutfitApiService {
  final List<RecommendedLook> looks;
  OutfitException? failure;
  final List<String> occasions = [];

  FakeOutfitService(this.looks, {this.failure});

  /// Dois looks do acervo de exemplo, o primeiro com IHE alto
  factory FakeOutfitService.sample() => FakeOutfitService([
        RecommendedLook(
          items: [mockClothes[0], mockClothes[1]],
          ihePercentage: 88,
          sCor: 0.9,
          sBio: 0.85,
          sOcasion: 0.9,
          sCos: 0.8,
          isStronglyRecommended: true,
          stylingAdvice: 'Tons terrosos em diálogo com a sua cartela.',
          occasion: 'CASUAL',
        ),
        RecommendedLook(
          items: [mockClothes[2]],
          ihePercentage: 64,
          sCor: 0.6,
          sBio: 0.7,
          sOcasion: 0.6,
          sCos: 0.6,
          isStronglyRecommended: false,
          stylingAdvice: 'Composição versátil para o clima do dia.',
          occasion: 'CASUAL',
        ),
      ]);

  @override
  Future<List<RecommendedLook>> generateDailyOutfits({
    String occasion = 'CASUAL',
    double temperatureCelsius = 22.0,
    bool isRaining = false,
    int limit = 5,
  }) async {
    occasions.add(occasion);
    final queued = failure;
    if (queued != null) {
      failure = null;
      throw queued;
    }
    return looks;
  }
}
