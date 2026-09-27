import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/user_profile.dart';

/// Mocks de Perfil de Usuário & Monitor Freemium (RF18 & RN02)
class MockUserProfile {
  MockUserProfile._();

  /// Perfil Padrão Freemium (24/30 peças, 4/5 combinações IA hoje)
  static UserProfile get defaultUser => const UserProfile(
        id: 'user_01',
        name: 'Helena Vasconcelos',
        email: 'helena.v@harmonia.app',
        handle: '@helenav',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        bodyType: 'Ampulheta',
        colorPalette: 'Outono Suave',
        paletteColors: [
          Color(0xFFA34836), // Terracota
          Color(0xFFD9CDBF), // Sand
          Color(0xFF4B5842), // Olive
          Color(0xFF2B2625), // Carvão
        ],
        isPremium: false,
        registeredPiecesCount: 24, // 24 de 30 peças (RN02)
        dailyAiLooksUsed: 4,      // 4 de 5 looks hoje (RN02)
        isPublicProfile: true,
      );

  /// Perfil Freemium com Teto Atingido (30/30 peças, 5/5 looks - RN02 Alerta)
  static UserProfile get limitReachedUser => const UserProfile(
        id: 'user_02',
        name: 'Helena Vasconcelos',
        email: 'helena.v@harmonia.app',
        handle: '@helenav',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        bodyType: 'Ampulheta',
        colorPalette: 'Outono Suave',
        paletteColors: [
          Color(0xFFA34836),
          Color(0xFFD9CDBF),
          Color(0xFF4B5842),
        ],
        isPremium: false,
        registeredPiecesCount: 30, // 30 de 30 (RN02 Teto Atingido)
        dailyAiLooksUsed: 5,      // 5 de 5 (RN02 Teto Atingido)
        isPublicProfile: true,
      );

  /// Perfil Assinante Premium Ilimitado
  static UserProfile get premiumUser => const UserProfile(
        id: 'user_03',
        name: 'Helena Vasconcelos',
        email: 'helena.v@harmonia.app',
        handle: '@helenav',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        bodyType: 'Ampulheta',
        colorPalette: 'Outono Suave',
        paletteColors: [
          Color(0xFFA34836),
          Color(0xFFD9CDBF),
          Color(0xFF4B5842),
        ],
        isPremium: true,
        registeredPiecesCount: 42,
        dailyAiLooksUsed: 12,
        isPublicProfile: true,
      );
}
