import '../../models/user_style_profile.dart';

/// Perfil morfocromático salvo do usuário e uso da cota Freemium (RF02, RF18, RN02)
///
/// Biótipo e cartela alimentam os pilares S_bio e S_cor do IHE no backend.
/// Ambos ficam nulos até o onboarding ser concluído.
class StyleProfile {
  final BodySilhouetteType? silhouette;
  final SeasonalPaletteType? palette;
  final int itemsCount;
  final int maxItems;
  final int looksToday;
  final int maxDailyLooks;
  final bool isPremium;
  final bool isPublic;

  const StyleProfile({
    this.silhouette,
    this.palette,
    this.itemsCount = 0,
    this.maxItems = 30,
    this.looksToday = 0,
    this.maxDailyLooks = 5,
    this.isPremium = false,
    this.isPublic = true,
  });

  factory StyleProfile.fromJson(Map<String, dynamic> json) {
    return StyleProfile(
      silhouette: BodySilhouetteExtension.fromApiKey(json['body_shape'] as String?),
      palette: SeasonalPaletteExtension.fromApiKey(json['seasonal_palette'] as String?),
      itemsCount: json['items_count'] as int? ?? 0,
      maxItems: json['max_items_allowed'] as int? ?? 30,
      looksToday: json['looks_generated_today'] as int? ?? 0,
      maxDailyLooks: json['max_daily_looks_allowed'] as int? ?? 5,
      isPremium: json['is_premium'] as bool? ?? false,
      isPublic: json['is_public'] as bool? ?? true,
    );
  }

  /// Onboarding concluído quando biótipo e cartela estão definidos
  bool get isComplete => silhouette != null && palette != null;

  bool get isItemsQuotaReached => !isPremium && itemsCount >= maxItems;
  bool get isDailyLooksQuotaReached => !isPremium && looksToday >= maxDailyLooks;

  double get itemsRatio => maxItems == 0 ? 0 : (itemsCount / maxItems).clamp(0.0, 1.0);
  double get dailyLooksRatio => maxDailyLooks == 0 ? 0 : (looksToday / maxDailyLooks).clamp(0.0, 1.0);

  StyleProfile copyWith({
    BodySilhouetteType? silhouette,
    SeasonalPaletteType? palette,
    int? itemsCount,
    int? looksToday,
    bool? isPremium,
    bool? isPublic,
  }) {
    return StyleProfile(
      silhouette: silhouette ?? this.silhouette,
      palette: palette ?? this.palette,
      itemsCount: itemsCount ?? this.itemsCount,
      maxItems: maxItems,
      looksToday: looksToday ?? this.looksToday,
      maxDailyLooks: maxDailyLooks,
      isPremium: isPremium ?? this.isPremium,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
