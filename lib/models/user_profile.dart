class UserProfile {
  final String id;
  final String name;
  final String email;
  final String biotype;
  final String colorPalette;
  final List<String> colorSwatchHexes;
  final int registeredPiecesCount;
  final int maxPiecesQuota;
  final int dailyLooksGeneratedCount;
  final int maxDailyLooksQuota;
  final bool isPremium;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.biotype,
    required this.colorPalette,
    required this.colorSwatchHexes,
    required this.registeredPiecesCount,
    this.maxPiecesQuota = 30, // RN02: 30 pieces max freemium
    required this.dailyLooksGeneratedCount,
    this.maxDailyLooksQuota = 5, // RN02: 5 daily looks max freemium
    this.isPremium = false,
  });

  bool get isPiecesQuotaReached => !isPremium && registeredPiecesCount >= maxPiecesQuota;
  bool get isDailyLooksQuotaReached => !isPremium && dailyLooksGeneratedCount >= maxDailyLooksQuota;

  double get piecesRatio => (registeredPiecesCount / maxPiecesQuota).clamp(0.0, 1.0);
  double get dailyLooksRatio => (dailyLooksGeneratedCount / maxDailyLooksQuota).clamp(0.0, 1.0);

  UserProfile copyWith({
    String? name,
    String? email,
    String? biotype,
    String? colorPalette,
    int? registeredPiecesCount,
    int? dailyLooksGeneratedCount,
    bool? isPremium,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      biotype: biotype ?? this.biotype,
      colorPalette: colorPalette ?? this.colorPalette,
      colorSwatchHexes: colorSwatchHexes,
      registeredPiecesCount: registeredPiecesCount ?? this.registeredPiecesCount,
      maxPiecesQuota: maxPiecesQuota,
      dailyLooksGeneratedCount: dailyLooksGeneratedCount ?? this.dailyLooksGeneratedCount,
      maxDailyLooksQuota: maxDailyLooksQuota,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
