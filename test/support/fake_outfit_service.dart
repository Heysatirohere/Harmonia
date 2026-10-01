import 'package:harmonia_mvp/data/services/outfit_api_service.dart';
import 'package:harmonia_mvp/domain/models/recommended_look.dart';
import 'package:harmonia_mvp/mocks/mock_clothes.dart';
import 'package:harmonia_mvp/models/clothing_item.dart';
import 'package:harmonia_mvp/models/store_parity_result.dart';

/// Motor de looks em memória para testes de widget
class FakeOutfitService extends OutfitApiService {
  final List<RecommendedLook> looks;
  OutfitException? failure;
  final List<String> occasions = [];

  /// Clima enviado em cada geração, na ordem
  final List<({double temperature, bool isRaining})> climates = [];

  /// Feedback registrado (RF13): id → (look, ação); [feedbackFailure] simula falha ao registrar
  final Map<String, (RecommendedLook, LookFeedbackAction)> feedback = {};
  OutfitException? feedbackFailure;
  int _feedbackSeq = 0;

  /// Peças enviadas para paridade, na ordem
  final List<ClothingItem> parityRequests = [];

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
    climates.add((temperature: temperatureCelsius, isRaining: isRaining));
    final queued = failure;
    if (queued != null) {
      failure = null;
      throw queued;
    }
    return looks;
  }

  @override
  Future<StoreParityResult> analyzeStoreParity({required ClothingItem storeGarment, String occasion = 'CASUAL'}) async {
    parityRequests.add(storeGarment);
    final queued = failure;
    if (queued != null) {
      failure = null;
      throw queued;
    }
    return StoreParityResult(
      storeGarment: storeGarment,
      ihePercentage: 86,
      isStronglyRecommended: true,
      paletteHarmony: 0.9,
      looksEvaluated: 2,
      strongLooks: 1,
      matches: [
        ParityMatchItem(
          closetItem: mockClothes[1],
          ihePercentage: 86,
          chromaticScore: 0.9,
          morphologicalScore: 0.85,
          isStronglyRecommended: true,
          rationale: 'Cores em harmonia com a sua cartela.',
        ),
      ],
    );
  }

  @override
  Future<String> sendLookFeedback(RecommendedLook look, LookFeedbackAction action) async {
    final queued = feedbackFailure;
    if (queued != null) {
      feedbackFailure = null;
      throw queued;
    }
    final id = 'fb-${++_feedbackSeq}';
    feedback[id] = (look, action);
    return id;
  }

  @override
  Future<void> undoLookFeedback(String feedbackId) async {
    feedback.remove(feedbackId);
  }
}
