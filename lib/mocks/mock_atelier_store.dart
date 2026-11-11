import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import '../data/services/community_api_service.dart';
import '../data/services/outfit_api_service.dart';
import '../domain/models/account.dart';
import '../domain/models/colorimetry_result.dart';
import '../domain/models/recommended_look.dart';
import '../domain/models/style_profile.dart';
import '../domain/repositories/auth_repository.dart';
import '../models/circular_listing.dart';
import '../models/clothing_item.dart';
import '../models/community_post.dart';
import '../models/garment_segmentation.dart';
import '../models/store_parity_result.dart';
import '../models/user_style_profile.dart';
import '../models/wardrobe_analytics.dart';
import '../models/wardrobe_gap.dart';
import '../models/weather_context.dart';
import 'mock_gap_analysis.dart';

/// Estado em memória completo do HarmonIA para apresentações e testes 100% offline.
///
/// Substitui todas as chamadas de rede (FastAPI, Supabase Auth/DB/Storage e Open-Meteo)
/// por operações interativas em memória, permitindo testar todas as funcionalidades
/// do aplicativo sem depender de servidor externo.
class MockAtelierStore {
  static final MockAtelierStore instance = MockAtelierStore._internal();
  factory MockAtelierStore() => instance;
  MockAtelierStore._internal() {
    reset();
  }

  /// PNG transparente 1x1 válido usado como fallback sintético de imagem/câmera
  static final Uint8List syntheticPngBytes = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  final StreamController<Account?> _authController = StreamController<Account?>.broadcast();
  Account? _account;
  late StyleProfile _profile;
  late List<ClothingItem> _clothes;
  late List<CommunityPost> _posts;
  final Map<String, RecommendedLook> _approvedByFeedbackId = {};
  final Map<String, RecommendedLook> _discardedByFeedbackId = {};
  final Set<String> _discardedSignatures = {};
  int _scanCounter = 0;
  int _selfieCounter = 0;

  /// Restaura todos os dados para o estado inicial de demonstração
  void reset() {
    _account = Account(
      id: 'demo-user-harmonia',
      email: 'clara.monteiro@harmonia.atelier',
      fullName: 'Clara Monteiro',
      createdAt: DateTime(2026, 2, 14),
    );
    _clothes = List<ClothingItem>.from(_initialClothes);
    _profile = StyleProfile(
      silhouette: BodySilhouetteType.ampulheta,
      palette: SeasonalPaletteType.outonoQuente,
      itemsCount: _clothes.length,
      maxItems: 30,
      looksToday: 2,
      maxDailyLooks: 5,
      isPremium: false,
      isPublic: true,
      dailyNotifications: true,
      rotationAlerts: true,
    );
    _posts = List<CommunityPost>.from(_initialPosts);
    _approvedByFeedbackId.clear();
    _discardedByFeedbackId.clear();
    _discardedSignatures.clear();
    _scanCounter = 0;
    _selfieCounter = 0;
  }

  // ===========================================================================
  // 1. AUTENTICAÇÃO & CONTA (RF01, RF18, RN04)
  // ===========================================================================

  Account? get currentAccount => _account;

  Stream<Account?> get accountChanges => _authController.stream;

  Future<Account> signIn({required String email, required String password}) async {
    final trimmedEmail = email.trim().isEmpty ? 'clara.monteiro@harmonia.atelier' : email.trim();
    final namePrefix = trimmedEmail.split('@').first.replaceAll('.', ' ');
    final formattedName = namePrefix
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    _account = Account(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      email: trimmedEmail,
      fullName: _account?.fullName ?? (formattedName.isEmpty ? 'Clara Monteiro' : formattedName),
      createdAt: DateTime.now(),
    );
    _authController.add(_account);
    return _account!;
  }

  Future<SignUpOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _account = Account(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      fullName: fullName.trim().isEmpty ? 'Novo Ateliê' : fullName.trim(),
      createdAt: DateTime.now(),
    );
    // Deixa o perfil incompleto para demonstrar o Onboarding Morfocromático após cadastro
    _profile = StyleProfile(
      silhouette: null,
      palette: null,
      itemsCount: _clothes.length,
      maxItems: 30,
      looksToday: 0,
      maxDailyLooks: 5,
      isPremium: false,
      isPublic: true,
    );
    _authController.add(_account);
    return SignUpOutcome.signedIn;
  }

  Future<bool> updateAccountProfile({String? fullName, String? email}) async {
    final current = _account ??
        Account(
          id: 'demo-user-harmonia',
          email: 'clara.monteiro@harmonia.atelier',
          fullName: 'Clara Monteiro',
          createdAt: DateTime(2026, 2, 14),
        );
    _account = current.copyWith(
      fullName: fullName?.trim().isNotEmpty == true ? fullName!.trim() : current.fullName,
      email: email?.trim().isNotEmpty == true ? email!.trim() : current.email,
    );
    _authController.add(_account);
    return false;
  }

  Future<void> signOut() async {
    _account = null;
    _authController.add(null);
  }

  Future<void> deleteAccount() async {
    reset();
    _account = null;
    _authController.add(null);
  }

  // ===========================================================================
  // 2. PERFIL DE ESTILO & COLORIMETRIA SELFIE (RF02, RF18, RN02, RN05)
  // ===========================================================================

  StyleProfile get profile => _profile.copyWith(itemsCount: _clothes.length);

  StyleProfile updateStyleProfile({
    BodySilhouetteType? silhouette,
    SeasonalPaletteType? palette,
    bool? isPublic,
    bool? isPremium,
    bool? dailyNotifications,
    bool? rotationAlerts,
  }) {
    _profile = _profile.copyWith(
      silhouette: silhouette ?? _profile.silhouette,
      palette: palette ?? _profile.palette,
      itemsCount: _clothes.length,
      isPublic: isPublic ?? _profile.isPublic,
      isPremium: isPremium ?? _profile.isPremium,
      dailyNotifications: dailyNotifications ?? _profile.dailyNotifications,
      rotationAlerts: rotationAlerts ?? _profile.rotationAlerts,
    );
    return profile;
  }

  ColorimetryResult analyzeSelfie() {
    const sampleResults = [
      ColorimetryResult(
        palette: SeasonalPaletteType.outonoQuente,
        skinColor: Color(0xFFD8A47F),
        undertone: 'QUENTE',
        depth: 'MEDIA',
        intensity: 'SUAVE',
      ),
      ColorimetryResult(
        palette: SeasonalPaletteType.invernoVivo,
        skinColor: Color(0xFFE5C1B8),
        undertone: 'FRIO',
        depth: 'PROFUNDA',
        intensity: 'BRILHANTE',
      ),
      ColorimetryResult(
        palette: SeasonalPaletteType.primaveraClara,
        skinColor: Color(0xFFF1CFB3),
        undertone: 'QUENTE',
        depth: 'CLARA',
        intensity: 'BRILHANTE',
      ),
      ColorimetryResult(
        palette: SeasonalPaletteType.veraoSuave,
        skinColor: Color(0xFFE2BFA8),
        undertone: 'FRIO',
        depth: 'MEDIA',
        intensity: 'SUAVE',
      ),
    ];
    final result = sampleResults[_selfieCounter % sampleResults.length];
    _selfieCounter++;
    return result;
  }

  // ===========================================================================
  // 3. CLIMA LOCAL (RF16)
  // ===========================================================================

  WeatherContext get weather => const WeatherContext(
        city: 'São Paulo, SP',
        temperature: 22.0,
        tempMin: 17.0,
        tempMax: 25.0,
        conditionType: WeatherConditionType.partlyCloudy,
        conditionLabel: 'Parcialmente nublado',
        windKmH: 12.0,
        humidityPercentage: 58,
        rainProbability: 15,
        thermalAmplitudeLabel: 'Moderada (8°C)',
        recommendationBadge: 'Clima ameno: peças de meia-estação',
        sOcasionRationale:
            'Hoje entre 17°C e 25°C, com vento de 12 km/h, 58% de umidade e 15% de chance de chuva. Peças de meia-estação resolvem o dia.',
      );

  // ===========================================================================
  // 4. ACERVO VIRTUAL, SEGMENTAÇÃO IA & SAÚDE ESG (RF03–RF06, 3.2.2, 3.5.4)
  // ===========================================================================

  List<ClothingItem> get clothes => List<ClothingItem>.unmodifiable(_clothes);

  List<ClothingItem> getClothingItems({
    String? category,
    double? minFormality,
    double? maxFormality,
  }) {
    return _clothes.where((item) {
      if (category != null && category.isNotEmpty && category != 'Todos' && item.category != category) {
        return false;
      }
      final f = item.formalityScore ?? 0.5;
      if (minFormality != null && f < minFormality) return false;
      if (maxFormality != null && f > maxFormality) return false;
      return true;
    }).toList();
  }

  ClothingItem addClothingItem(ClothingItem item) {
    final fallbackUrl = switch (item.category) {
      'Partes de baixo' =>
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&auto=format&fit=crop&q=80',
      'Calçados' =>
        'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800&auto=format&fit=crop&q=80',
      'Peças únicas' =>
        'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=800&auto=format&fit=crop&q=80',
      _ => 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop&q=80',
    };
    final created = item.copyWith(
      id: item.id.isEmpty ? 'item-${DateTime.now().millisecondsSinceEpoch}' : item.id,
      imageUrl: item.imageUrl.isEmpty ? fallbackUrl : item.imageUrl,
      iheScore: item.iheScore ?? 91,
      price: item.price ?? 289.90,
      daysIdle: 0,
      disposalStatus: item.disposalStatus ?? 'ACTIVE',
      season: item.season ?? 'Meia-estação',
      capsules: item.capsules.isEmpty ? const ['Casual', 'Trabalho'] : item.capsules,
    );
    _clothes = [created, ..._clothes.where((i) => i.id != created.id)];
    return created;
  }

  ClothingItem? updateClothingItem(ClothingItem item) {
    final idx = _clothes.indexWhere((i) => i.id == item.id);
    if (idx == -1) {
      _clothes = [item, ..._clothes];
      return item;
    }
    final copy = List<ClothingItem>.from(_clothes);
    copy[idx] = item;
    _clothes = copy;
    return item;
  }

  bool deleteClothingItem(String itemId) {
    final before = _clothes.length;
    _clothes = _clothes.where((i) => i.id != itemId).toList();
    return _clothes.length < before || true;
  }

  GarmentSegmentation segmentGarment(Uint8List imageBytes) {
    const suggestions = [
      (
        suggestion: GarmentSuggestion(
          category: 'Partes de cima',
          name: 'Camisa de Linho Terracota',
          pattern: 'Liso',
          season: 'Meia-estação',
          thermalCategory: 'LEVE',
          cutType: 'Estruturado',
          formality: 0.72,
          confidence: 0.94,
        ),
        colors: [
          GarmentColor(l: 54, a: 32, b: 28, hex: '#C86D51', percentage: 74, name: 'Terracota'),
          GarmentColor(l: 90, a: 1, b: 7, hex: '#E9E4D6', percentage: 26, name: 'Marfim'),
        ],
      ),
      (
        suggestion: GarmentSuggestion(
          category: 'Peças únicas',
          name: 'Vestido Midi Seda Esmeralda',
          pattern: 'Liso',
          season: 'Todas',
          thermalCategory: 'MEDIA',
          cutType: 'Acinturado',
          formality: 0.85,
          confidence: 0.96,
        ),
        colors: [
          GarmentColor(l: 24, a: -16, b: 8, hex: '#1C3120', percentage: 82, name: 'Esmeralda'),
          GarmentColor(l: 72, a: 8, b: 36, hex: '#D4AE5C', percentage: 18, name: 'Ouro Velho'),
        ],
      ),
      (
        suggestion: GarmentSuggestion(
          category: 'Partes de baixo',
          name: 'Calça Pantalona Alfaiataria Areia',
          pattern: 'Liso',
          season: 'Todas',
          thermalCategory: 'MEDIA',
          cutType: 'Cintura Alta',
          formality: 0.78,
          confidence: 0.92,
        ),
        colors: [
          GarmentColor(l: 86, a: 3, b: 11, hex: '#DECBB7', percentage: 88, name: 'Areia Quente'),
          GarmentColor(l: 45, a: 6, b: 12, hex: '#706B65', percentage: 12, name: 'Carvão Suave'),
        ],
      ),
    ];

    final chosen = suggestions[_scanCounter % suggestions.length];
    _scanCounter++;
    return GarmentSegmentation(
      cutoutPng: imageBytes.isEmpty ? syntheticPngBytes : imageBytes,
      width: 600,
      height: 800,
      colors: chosen.colors,
      processingMs: 420,
      styleEmbedding: List<double>.filled(512, 0.044),
      suggestion: chosen.suggestion,
    );
  }

  WardrobeAnalytics getAnalytics() {
    final total = _clothes.length;
    final active = _clothes.where((i) => (i.daysIdle ?? 10) < 30).length;
    final idle30 = _clothes.where((i) => (i.daysIdle ?? 0) >= 30 && (i.daysIdle ?? 0) < 60).length;
    final idle60 = _clothes.where((i) => (i.daysIdle ?? 0) >= 60 && (i.daysIdle ?? 0) < 90).length;
    final dormantList = _clothes.where((i) => (i.daysIdle ?? 0) >= 90).toList();
    final neverWorn = _clothes.where((i) => i.usageRate == 0).length;
    final totalWears = _clothes.fold<int>(0, (sum, i) => sum + i.usageRate);
    final totalValue = _clothes.fold<double>(0, (sum, i) => sum + (i.price ?? 280.0));
    final avgCpu = totalWears > 0 ? totalValue / totalWears : 24.50;
    final circularCount = _clothes.where((i) => i.disposalStatus == 'SELL').length;
    final donatedCount = _clothes.where((i) => i.disposalStatus == 'DONATE').length;

    return WardrobeAnalytics(
      totalPieces: total,
      activePiecesCount: active,
      idle30DaysCount: idle30,
      idle60DaysCount: idle60,
      idle90DaysCount: dormantList.length,
      neverWornCount: neverWorn,
      totalWears: totalWears,
      totalWardrobeValue: totalValue,
      averageCostPerUse: avgCpu,
      circularItemsCount: circularCount,
      donatedItemsCount: donatedCount,
      colorDistribution: const [
        DominantColorShare(
          colorName: 'Terracota & Terras',
          color: Color(0xFFB8361E),
          percentage: 35.0,
          count: 4,
          labCoordinates: 'L* 48.0 · a* 31.0 · b* 25.0',
        ),
        DominantColorShare(
          colorName: 'Neutros & Marfim',
          color: Color(0xFFE9E4D6),
          percentage: 30.0,
          count: 3,
          labCoordinates: 'L* 88.0 · a* 2.0 · b* 8.0',
        ),
        DominantColorShare(
          colorName: 'Verdes & Botânicos',
          color: Color(0xFF2E4732),
          percentage: 20.0,
          count: 2,
          labCoordinates: 'L* 30.0 · a* -14.0 · b* 11.0',
        ),
        DominantColorShare(
          colorName: 'Carvão & Noite',
          color: Color(0xFF1A1817),
          percentage: 15.0,
          count: 1,
          labCoordinates: 'L* 14.2 · a* 0.5 · b* -0.8',
        ),
      ],
      dormantItems: [
        for (final item in dormantList)
          DormantGarment(
            item: item,
            daysIdle: item.daysIdle ?? 112,
            wearCount: item.usageRate,
            costPerUse: item.costPerUse ?? 145.0,
          ),
      ],
    );
  }

  List<CircularListing> getCircularMarketplace({String? category}) {
    final ownListings = _clothes
        .where((i) => i.disposalStatus == 'SELL')
        .map((i) => CircularListing.fromClothingItem(i, isOwnListing: true));
    final all = <String, CircularListing>{
      for (final own in ownListings) own.itemId: own,
      for (final demo in CircularListing.demoListings) demo.itemId: demo,
    }.values.toList();

    if (category != null && category.isNotEmpty && category != 'Todos') {
      return all.where((l) => l.category == category).toList();
    }
    return all;
  }

  // ===========================================================================
  // 5. MOTOR DE LOOKS, PARIDADE DE PROVADOR & LACUNAS (RF07–RF13)
  // ===========================================================================

  List<RecommendedLook> generateDailyOutfits({
    String occasion = 'CASUAL',
    String? anchorItemId,
  }) {
    final tops = _clothes.where((i) => i.category == 'Partes de cima').toList();
    final bottoms = _clothes.where((i) => i.category == 'Partes de baixo').toList();
    final shoes = _clothes.where((i) => i.category == 'Calçados').toList();
    final onePieces = _clothes.where((i) => i.category == 'Peças únicas').toList();

    final anchor = anchorItemId != null
        ? _clothes.where((i) => i.id == anchorItemId).firstOrNull
        : null;

    final candidates = <RecommendedLook>[];

    if (anchor != null) {
      final anchorItems = <ClothingItem>[
        anchor,
        if (anchor.category != 'Partes de cima' && anchor.category != 'Peças únicas' && tops.isNotEmpty)
          tops.first,
        if (anchor.category != 'Partes de baixo' && anchor.category != 'Peças únicas' && bottoms.isNotEmpty)
          bottoms.first,
        if (anchor.category != 'Calçados' && shoes.isNotEmpty) shoes.first,
      ];
      candidates.add(
        RecommendedLook(
          items: anchorItems,
          ihePercentage: 95,
          sCor: 0.96,
          sBio: 0.94,
          sOcasion: 0.95,
          sCos: 0.95,
          isStronglyRecommended: true,
          stylingAdvice:
              'Composição construída em torno de "${anchor.name}": harmonia cromática ΔE ótima com sua cartela e equilíbrio de silhueta.',
          occasion: occasion,
        ),
      );
    }

    if (tops.isNotEmpty && bottoms.isNotEmpty && shoes.isNotEmpty) {
      candidates.add(
        RecommendedLook(
          items: [tops[0], bottoms[0], shoes[0]],
          ihePercentage: 94,
          sCor: 0.95,
          sBio: 0.92,
          sOcasion: 0.94,
          sCos: 0.95,
          isStronglyRecommended: true,
          stylingAdvice: switch (occasion) {
            'TRABALHO' =>
              'Alfaiataria em linho terracota com pantalona fluida off-white: presença executiva com leveza térmica.',
            'NOITE' || 'FESTA' || 'GALA' =>
              'Contraste nobre entre terracota profundo e marfim acetinado, alongando a linha vertical da silhueta.',
            _ =>
              'Blazer de linho terracota com pantalona off-white e mocassim artesanal: harmonia primorosa para o seu biótipo e cartela.',
          },
          occasion: occasion,
        ),
      );
    }

    if (onePieces.isNotEmpty && shoes.isNotEmpty) {
      candidates.add(
        RecommendedLook(
          items: [onePieces.first, shoes.last],
          ihePercentage: 92,
          sCor: 0.93,
          sBio: 0.94,
          sOcasion: 0.90,
          sCos: 0.91,
          isStronglyRecommended: true,
          stylingAdvice:
              'Peça única acinturada em seda esmeralda combinada com loafer marfim: linha contínua que valoriza o biótipo.',
          occasion: occasion,
        ),
      );
    }

    if (tops.length > 1 && bottoms.length > 1 && shoes.isNotEmpty) {
      candidates.add(
        RecommendedLook(
          items: [tops[1], bottoms[1], shoes.last],
          ihePercentage: 88,
          sCor: 0.89,
          sBio: 0.86,
          sOcasion: 0.90,
          sCos: 0.88,
          isStronglyRecommended: true,
          stylingAdvice:
              'Seda areia com lã fria carvão: contraste tonal moderado e caimento estruturado para transição dia-noite.',
          occasion: occasion,
        ),
      );
    }

    return candidates.where((l) => !_discardedSignatures.contains(_signatureOf(l))).toList();
  }

  String _signatureOf(RecommendedLook look) =>
      '${look.occasion}:${look.items.map((i) => i.id).join(',')}';

  String recordLookFeedback(RecommendedLook look, LookFeedbackAction action) {
    final id = 'feedback-${DateTime.now().millisecondsSinceEpoch}';
    if (action == LookFeedbackAction.approved) {
      _approvedByFeedbackId[id] = look;
      // Incrementa o uso das peças aprovadas em memória
      final approvedIds = look.items.map((i) => i.id).toSet();
      _clothes = [
        for (final item in _clothes)
          if (approvedIds.contains(item.id))
            item.copyWith(usageRate: item.usageRate + 1, daysIdle: 0)
          else
            item,
      ];
    } else {
      _discardedByFeedbackId[id] = look;
      _discardedSignatures.add(_signatureOf(look));
    }
    return id;
  }

  void undoLookFeedback(String feedbackId) {
    _approvedByFeedbackId.remove(feedbackId);
    final discarded = _discardedByFeedbackId.remove(feedbackId);
    if (discarded != null) {
      _discardedSignatures.remove(_signatureOf(discarded));
    }
  }

  StoreParityResult analyzeStoreParity(ClothingItem storeGarment) {
    final matches = _clothes.take(3).map((closetItem) {
      return ParityMatchItem(
        closetItem: closetItem,
        ihePercentage: closetItem.iheScore ?? 91,
        chromaticScore: 0.94,
        morphologicalScore: 0.91,
        isStronglyRecommended: true,
        rationale: 'Sinergia cromática CIE L*a*b* e equilíbrio de proporções com "${closetItem.name}".',
      );
    }).toList();

    return StoreParityResult(
      storeGarment: storeGarment,
      ihePercentage: 93,
      isStronglyRecommended: true,
      paletteHarmony: 0.95,
      stylingAdvice:
          'Excelente aquisição: a peça testada no provador destrava ${matches.length} combinações de alta harmonia (IHE ≥ 88%) com o seu acervo atual.',
      looksEvaluated: _clothes.length,
      strongLooks: matches.length,
      matches: matches,
    );
  }

  WardrobeGapReport getWardrobeGaps({String occasion = 'CASUAL'}) {
    return WardrobeGapReport(
      occasion: occasion,
      baselineIhe: 78.4,
      gaps: MockGapAnalysis.gaps,
    );
  }

  // ===========================================================================
  // 6. FEED COMUNITÁRIO EDITORIAL & MOODBOARDS (RF14, RF15, RN05)
  // ===========================================================================

  CommunityFeedPage fetchFeed({
    FeedFilter filter = FeedFilter.all,
    String? occasion,
    String? query,
  }) {
    final q = query?.trim().toLowerCase() ?? '';
    final filtered = _posts.where((post) {
      if (filter == FeedFilter.mine && !post.isMine) return false;
      if (filter == FeedFilter.saved && !post.savedByMe) return false;
      if (filter == FeedFilter.bodyShape &&
          post.authorBodyShape != (_profile.silhouette ?? BodySilhouetteType.ampulheta)) {
        return false;
      }
      if (filter == FeedFilter.palette &&
          post.authorPalette != (_profile.palette ?? SeasonalPaletteType.outonoQuente)) {
        return false;
      }
      if (occasion != null && occasion.isNotEmpty && post.occasion != occasion) {
        return false;
      }
      if (q.isNotEmpty) {
        final inCaption = post.caption.toLowerCase().contains(q);
        final inAuthor = post.authorName.toLowerCase().contains(q);
        final inTags = post.styleTags.any((t) => t.toLowerCase().contains(q));
        if (!inCaption && !inAuthor && !inTags) return false;
      }
      return true;
    }).toList();

    return CommunityFeedPage(posts: filtered, nextBefore: null);
  }

  CommunityPost publishPost({
    required String caption,
    required String occasion,
    List<String> styleTags = const [],
    String? feedbackId,
    bool? isPublic,
  }) {
    final approvedLook = feedbackId != null ? _approvedByFeedbackId[feedbackId] : null;
    final sourceItems = approvedLook?.items ?? _clothes.take(2).toList();
    final post = CommunityPost(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      authorName: _account?.displayName ?? 'Clara Monteiro',
      authorBodyShape: _profile.silhouette ?? BodySilhouetteType.ampulheta,
      authorPalette: _profile.palette ?? SeasonalPaletteType.outonoQuente,
      imageUrl: sourceItems.firstOrNull?.imageUrl.isNotEmpty == true
          ? sourceItems.first.imageUrl
          : 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1080&q=80',
      caption: caption,
      occasion: occasion,
      styleTags: styleTags.isEmpty ? const ['Ateliê', 'Harmonia'] : styleTags,
      ihePercentage: (approvedLook?.ihePercentage ?? 93).toDouble(),
      pieces: [
        for (final (idx, item) in sourceItems.indexed)
          PostPiece(
            id: item.id,
            category: item.category,
            name: item.name,
            imageUrl: item.imageUrl,
            color: item.dominantColor,
            labLabel: item.labColorSpace,
            brand: item.brandOrProvenance,
            fabric: item.consciousNote ?? 'Linho & Seda Natural',
            hotspotX: 0.35 + (idx * 0.22).clamp(0.0, 0.45),
            hotspotY: 0.32 + (idx * 0.25).clamp(0.0, 0.50),
          ),
      ],
      likeCount: 1,
      likedByMe: true,
      savedByMe: false,
      isPublic: isPublic ?? _profile.isPublic,
      isMine: true,
      createdAt: DateTime.now(),
    );
    _posts = [post, ..._posts];
    return post;
  }

  void setPostLiked(String postId, bool liked) {
    _posts = [
      for (final p in _posts)
        if (p.id == postId)
          p.copyWith(
            likedByMe: liked,
            likeCount: (p.likeCount + (liked && !p.likedByMe ? 1 : (!liked && p.likedByMe ? -1 : 0)))
                .clamp(0, 99999),
          )
        else
          p,
    ];
  }

  void setPostSaved(String postId, bool saved, {String? boardName}) {
    _posts = [
      for (final p in _posts)
        if (p.id == postId)
          p.copyWith(
            savedByMe: saved,
            savedBoardName: saved ? (boardName ?? p.savedBoardName ?? 'Referências de Cor') : null,
          )
        else
          p,
    ];
  }

  CommunityPost updatePostVisibility(String postId, {required bool isPublic}) {
    CommunityPost? updated;
    _posts = [
      for (final p in _posts)
        if (p.id == postId) (updated = p.copyWith(isPublic: isPublic)) else p,
    ];
    return updated ?? _posts.first;
  }

  void deletePost(String postId) {
    _posts = _posts.where((p) => p.id != postId).toList();
  }

  // ===========================================================================
  // DADOS INICIAIS DE DEMONSTRAÇÃO
  // ===========================================================================

  static const List<ClothingItem> _initialClothes = [
    ClothingItem(
      id: 'item-1',
      name: 'Blazer Desestruturado em Linho',
      category: 'Partes de cima',
      dominantColor: Color(0xFFA34836),
      labColorSpace: 'L* 58.4, a* 28.2, b* 24.1',
      labL: 58.4,
      labA: 28.2,
      labB: 24.1,
      formalityScore: 0.78,
      usageRate: 18,
      daysIdle: 3,
      price: 480.0,
      colorFamily: 'Vermelhos',
      pattern: 'Liso',
      season: 'Meia-estação',
      thermalCategory: 'MEDIA',
      cutType: 'Acinturado',
      disposalStatus: 'ACTIVE',
      capsules: ['Trabalho', 'Casual'],
      imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Ateliê Sustentável • Linho Puro',
      isConsciousFashion: true,
      consciousNote: '100% Linho Orgânico',
      iheScore: 94,
    ),
    ClothingItem(
      id: 'item-2',
      name: 'Camisa Regata Seda Areia',
      category: 'Partes de cima',
      dominantColor: Color(0xFFD9CDBF),
      labColorSpace: 'L* 82.1, a* 4.3, b* 11.8',
      labL: 82.1,
      labA: 4.3,
      labB: 11.8,
      formalityScore: 0.65,
      usageRate: 24,
      daysIdle: 5,
      price: 290.0,
      colorFamily: 'Neutros',
      pattern: 'Liso',
      season: 'Verão',
      thermalCategory: 'LEVE',
      cutType: 'Decote V',
      disposalStatus: 'ACTIVE',
      capsules: ['Trabalho', 'Casual', 'Viagem'],
      imageUrl: 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Brechó Vintage Paulistano',
      isConsciousFashion: true,
      consciousNote: 'Segunda Mão Certificada',
      iheScore: 89,
    ),
    ClothingItem(
      id: 'item-3',
      name: 'Pantalona Flutuante Off-White',
      category: 'Partes de baixo',
      dominantColor: Color(0xFFF3EFEA),
      labColorSpace: 'L* 94.0, a* 1.2, b* 3.5',
      labL: 94.0,
      labA: 1.2,
      labB: 3.5,
      formalityScore: 0.75,
      usageRate: 15,
      daysIdle: 7,
      price: 390.0,
      colorFamily: 'Neutros',
      pattern: 'Liso',
      season: 'Todas',
      thermalCategory: 'MEDIA',
      cutType: 'Cintura Alta',
      disposalStatus: 'ACTIVE',
      capsules: ['Trabalho', 'Festa'],
      imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Alfaiataria Botânica',
      isConsciousFashion: true,
      consciousNote: 'Algodão Agroecológico',
      iheScore: 95,
    ),
    ClothingItem(
      id: 'item-4',
      name: 'Sobrecamisa Sarja Verde Oliva',
      category: 'Partes de cima',
      dominantColor: Color(0xFF4B5842),
      labColorSpace: 'L* 38.6, a* -12.4, b* 14.8',
      labL: 38.6,
      labA: -12.4,
      labB: 14.8,
      formalityScore: 0.45,
      usageRate: 31,
      daysIdle: 14,
      price: 340.0,
      colorFamily: 'Verdes',
      pattern: 'Liso',
      season: 'Meia-estação',
      thermalCategory: 'MEDIA',
      cutType: 'Reto',
      disposalStatus: 'ACTIVE',
      capsules: ['Casual', 'Viagem'],
      imageUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Acervo Circular • 31 usos',
      isConsciousFashion: true,
      consciousNote: 'Cânhamo Sustentável',
      iheScore: 86,
    ),
    ClothingItem(
      id: 'item-5',
      name: 'Calça Alfaiataria Carvão Lã Fria',
      category: 'Partes de baixo',
      dominantColor: Color(0xFF1A1817),
      labColorSpace: 'L* 14.2, a* 0.5, b* -0.8',
      labL: 14.2,
      labA: 0.5,
      labB: -0.8,
      formalityScore: 0.88,
      usageRate: 29,
      daysIdle: 42,
      price: 520.0,
      colorFamily: 'Neutros',
      pattern: 'Liso',
      season: 'Inverno',
      thermalCategory: 'PESADA',
      cutType: 'Cintura Alta',
      disposalStatus: 'ACTIVE',
      capsules: ['Trabalho'],
      imageUrl: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Sob Medida • 5 anos de acervo',
      isConsciousFashion: false,
      iheScore: 82,
    ),
    ClothingItem(
      id: 'item-6',
      name: 'Moccasin Couro Amaciado Carvão',
      category: 'Calçados',
      dominantColor: Color(0xFF706B65),
      labColorSpace: 'L* 45.3, a* 6.1, b* 12.0',
      labL: 45.3,
      labA: 6.1,
      labB: 12.0,
      formalityScore: 0.70,
      usageRate: 42,
      daysIdle: 2,
      price: 460.0,
      colorFamily: 'Terrosos',
      pattern: 'Liso',
      season: 'Todas',
      thermalCategory: 'MEDIA',
      cutType: 'Estruturado',
      disposalStatus: 'ACTIVE',
      capsules: ['Trabalho', 'Casual'],
      imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Manufatura Artesanal Local',
      isConsciousFashion: true,
      consciousNote: 'Couro Vegetal Curtido',
      iheScore: 90,
    ),
    ClothingItem(
      id: 'item-7',
      name: 'Trench Coat Terracota Editorial',
      category: 'Partes de cima',
      dominantColor: Color(0xFFA34836),
      labColorSpace: 'L* 48.7, a* 32.1, b* 27.4',
      labL: 48.7,
      labA: 32.1,
      labB: 27.4,
      formalityScore: 0.85,
      usageRate: 2,
      daysIdle: 118, // Peça adormecida (>90 dias) para demonstrar reativação e Brechó Circular no Dashboard ESG!
      price: 680.0,
      colorFamily: 'Terrosos',
      pattern: 'Liso',
      season: 'Inverno',
      thermalCategory: 'PESADA',
      cutType: 'Acinturado',
      disposalStatus: 'ACTIVE',
      capsules: ['Viagem', 'Noite'],
      imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Edição Limitada Ateliê',
      isConsciousFashion: true,
      consciousNote: 'Tingimento Botânico a Seco',
      iheScore: 94,
    ),
    ClothingItem(
      id: 'item-8',
      name: 'Loafer Minimalista Marfim',
      category: 'Calçados',
      dominantColor: Color(0xFFEBE5DC),
      labColorSpace: 'L* 91.2, a* 2.1, b* 6.7',
      labL: 91.2,
      labA: 2.1,
      labB: 6.7,
      formalityScore: 0.72,
      usageRate: 20,
      daysIdle: 9,
      price: 380.0,
      colorFamily: 'Neutros',
      pattern: 'Liso',
      season: 'Todas',
      thermalCategory: 'LEVE',
      cutType: 'Reto',
      disposalStatus: 'ACTIVE',
      capsules: ['Casual', 'Trabalho'],
      imageUrl: 'https://images.unsplash.com/photo-1560343776-97e7d202ff0e?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Design Autoral Nacional',
      isConsciousFashion: true,
      consciousNote: 'Solado Reciclado ESG',
      iheScore: 88,
    ),
    ClothingItem(
      id: 'item-9',
      name: 'Vestido Midi Seda Esmeralda',
      category: 'Peças únicas',
      dominantColor: Color(0xFF1C3120),
      labColorSpace: 'L* 22.4, a* -15.2, b* 8.4',
      labL: 22.4,
      labA: -15.2,
      labB: 8.4,
      formalityScore: 0.90,
      usageRate: 6,
      daysIdle: 19,
      price: 590.0,
      colorFamily: 'Verdes',
      pattern: 'Liso',
      season: 'Todas',
      thermalCategory: 'MEDIA',
      cutType: 'Acinturado',
      disposalStatus: 'ACTIVE',
      capsules: ['Festa', 'Noite'],
      imageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Ateliê Seda Pura • Certificação OEKO',
      isConsciousFashion: true,
      consciousNote: 'Seda de Casulo Ético',
      iheScore: 93,
    ),
    ClothingItem(
      id: 'item-10',
      name: 'Saia Midi Plissada Ocre Dourado',
      category: 'Partes de baixo',
      dominantColor: Color(0xFF9C7438),
      labColorSpace: 'L* 52.0, a* 12.0, b* 38.0',
      labL: 52.0,
      labA: 12.0,
      labB: 38.0,
      formalityScore: 0.74,
      usageRate: 1,
      daysIdle: 104, // Segunda peça adormecida para demonstração no Dashboard ESG
      price: 360.0,
      colorFamily: 'Terrosos',
      pattern: 'Liso',
      season: 'Meia-estação',
      thermalCategory: 'LEVE',
      cutType: 'Evasê',
      disposalStatus: 'ACTIVE',
      capsules: ['Festa', 'Casual'],
      imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800&auto=format&fit=crop&q=80',
      brandOrProvenance: 'Curadoria Vintage • Tecido Recuperado',
      isConsciousFashion: true,
      consciousNote: 'Upcycling Têxtil',
      iheScore: 91,
    ),
  ];

  static final List<CommunityPost> _initialPosts = [
    CommunityPost(
      id: 'demo-feed-1',
      authorName: 'Camila Rossi',
      authorBodyShape: BodySilhouetteType.ampulheta,
      authorPalette: SeasonalPaletteType.outonoQuente,
      imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1080&q=80',
      caption:
          'Composição de alfaiataria em linho terracota com pantalona fluida. Silhueta estruturada para reunião de conselho.',
      occasion: 'TRABALHO',
      styleTags: const ['Alfaiataria', 'ESG', 'Terracota'],
      ihePercentage: 94.0,
      pieces: const [
        PostPiece(
          id: 'p1',
          category: 'Partes de cima',
          name: 'Blazer de linho terracota',
          imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&q=80',
          color: Color(0xFFC86D51),
          labLabel: 'L* 54 · a* 32 · b* 28',
          brand: 'Ateliê Sustentável',
          fabric: '100% Linho Orgânico',
          hotspotX: 0.42,
          hotspotY: 0.34,
        ),
        PostPiece(
          id: 'p2',
          category: 'Partes de baixo',
          name: 'Pantalona fluida off-white',
          imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=600&q=80',
          color: Color(0xFFE9E4D6),
          labLabel: 'L* 90 · a* 1 · b* 7',
          brand: 'Alfaiataria Botânica',
          fabric: 'Algodão Agroecológico',
          hotspotX: 0.54,
          hotspotY: 0.68,
        ),
      ],
      likeCount: 42,
      likedByMe: true,
      savedByMe: true,
      savedBoardName: 'Alfaiataria',
      isPublic: true,
      isMine: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CommunityPost(
      id: 'demo-feed-2',
      authorName: 'Helena Duarte',
      authorBodyShape: BodySilhouetteType.retangulo,
      authorPalette: SeasonalPaletteType.veraoFrio,
      imageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1080&q=80',
      caption: 'Seda esmeralda e lã fria. Contraste tonal sutil para a vernissage da Bienal.',
      occasion: 'FESTA',
      styleTags: const ['Seda', 'Esmeralda', 'Editorial'],
      ihePercentage: 91.0,
      pieces: const [
        PostPiece(
          id: 'p3',
          category: 'Peças únicas',
          name: 'Vestido midi de seda esmeralda',
          imageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80',
          color: Color(0xFF1C3120),
          labLabel: 'L* 20 · a* -15 · b* 8',
          brand: 'Ateliê Seda Pura',
          fabric: 'Seda Certificada OEKO',
          hotspotX: 0.48,
          hotspotY: 0.45,
        ),
      ],
      likeCount: 28,
      likedByMe: false,
      savedByMe: false,
      isPublic: true,
      isMine: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    CommunityPost(
      id: 'demo-feed-3',
      authorName: 'Clara Monteiro',
      authorBodyShape: BodySilhouetteType.ampulheta,
      authorPalette: SeasonalPaletteType.outonoQuente,
      imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=1080&q=80',
      caption: 'Cápsula de meia-estação em tons terrosos e linho cru. 100% acervo circular.',
      occasion: 'CASUAL',
      styleTags: const ['Cápsula', 'Linho', 'OutonoQuente'],
      ihePercentage: 95.0,
      pieces: const [
        PostPiece(
          id: 'p4',
          category: 'Partes de cima',
          name: 'Camisa Regata Seda Areia',
          imageUrl: 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600&q=80',
          color: Color(0xFFD9CDBF),
          labLabel: 'L* 82 · a* 4 · b* 12',
          brand: 'Brechó Vintage Paulistano',
          fabric: 'Seda Pura Recuperada',
          hotspotX: 0.46,
          hotspotY: 0.36,
        ),
      ],
      likeCount: 19,
      likedByMe: true,
      savedByMe: true,
      savedBoardName: 'Cápsula Minimal',
      isPublic: true,
      isMine: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
