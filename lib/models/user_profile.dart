import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Modelo de Perfil de Usuário & Governança de Assinatura (RF18 & RN02)
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String handle;
  final String? avatarUrl;
  final String bodyType;        // Ex: 'Ampulheta', 'Retângulo', 'Triângulo Invertido'
  final String colorPalette;    // Ex: 'Outono Suave', 'Inverno Frio'
  final List<Color> paletteColors;
  final bool isPremium;
  final int registeredPiecesCount; // Acervo atual
  final int maxPiecesLimit;        // RN02: 30 peças para Freemium
  final int dailyAiLooksUsed;      // Combinações geradas hoje
  final int maxDailyAiLooksLimit;  // RN02: 5 looks por dia para Freemium
  final bool isPublicProfile;      // RN05

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.handle,
    this.avatarUrl,
    required this.bodyType,
    required this.colorPalette,
    required this.paletteColors,
    this.isPremium = false,
    required this.registeredPiecesCount,
    this.maxPiecesLimit = 30,
    required this.dailyAiLooksUsed,
    this.maxDailyAiLooksLimit = 5,
    this.isPublicProfile = true,
  });

  /// Regra de Negócio RN02: Verificação do teto de peças no plano Freemium
  bool get hasReachedPiecesLimit =>
      !isPremium && registeredPiecesCount >= maxPiecesLimit;

  /// Regra de Negócio RN02: Verificação do teto diário de combinações IA
  bool get hasReachedDailyLooksLimit =>
      !isPremium && dailyAiLooksUsed >= maxDailyAiLooksLimit;

  /// Verificação se qualquer limite Freemium foi atingido (RN02)
  bool get hasReachedAnyFreemiumLimit =>
      hasReachedPiecesLimit || hasReachedDailyLooksLimit;

  /// Proporções normalizadas (0.0 a 1.0) para réguas analíticas
  double get piecesRatio => isPremium
      ? 1.0
      : (registeredPiecesCount / maxPiecesLimit).clamp(0.0, 1.0);

  double get dailyLooksRatio => isPremium
      ? 1.0
      : (dailyAiLooksUsed / maxDailyAiLooksLimit).clamp(0.0, 1.0);

  UserProfile copyWith({
    String? name,
    String? email,
    String? handle,
    String? bodyType,
    String? colorPalette,
    List<Color>? paletteColors,
    bool? isPremium,
    int? registeredPiecesCount,
    int? dailyAiLooksUsed,
    bool? isPublicProfile,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl,
      bodyType: bodyType ?? this.bodyType,
      colorPalette: colorPalette ?? this.colorPalette,
      paletteColors: paletteColors ?? this.paletteColors,
      isPremium: isPremium ?? this.isPremium,
      registeredPiecesCount:
          registeredPiecesCount ?? this.registeredPiecesCount,
      maxPiecesLimit: maxPiecesLimit,
      dailyAiLooksUsed: dailyAiLooksUsed ?? this.dailyAiLooksUsed,
      maxDailyAiLooksLimit: maxDailyAiLooksLimit,
      isPublicProfile: isPublicProfile ?? this.isPublicProfile,
    );
  }
}
