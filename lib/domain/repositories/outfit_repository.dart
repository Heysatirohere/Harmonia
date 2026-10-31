import '../../data/services/outfit_api_service.dart' show LookFeedbackAction;
import '../../models/clothing_item.dart';
import '../../models/store_parity_result.dart';
import '../../models/wardrobe_gap.dart';
import '../models/recommended_look.dart';

/// Contrato de domínio do Motor de Looks, IHE, Paridade e Lacunas (RF07–RF13, Seção 8 AGENTS.md)
abstract class OutfitRepository {
  Future<List<RecommendedLook>> generateDailyOutfits({
    String occasion = 'CASUAL',
    double temperatureCelsius = 22.0,
    bool isRaining = false,
    int limit = 5,
    String? anchorItemId,
  });

  Future<String> sendLookFeedback(RecommendedLook look, LookFeedbackAction action);

  Future<void> undoLookFeedback(String feedbackId);

  Future<StoreParityResult> analyzeStoreParity({
    required ClothingItem storeGarment,
    String occasion = 'CASUAL',
  });

  Future<WardrobeGapReport> getWardrobeGaps({String occasion = 'CASUAL'});

  Future<Map<String, dynamic>?> calculateIhe(Map<String, dynamic> payload);
}
