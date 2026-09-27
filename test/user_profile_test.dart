import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_user_profile.dart';
import 'package:harmonia_mvp/models/user_profile.dart';

void main() {
  group('UserProfile Model & Freemium Quota Unit Tests (RF18 & RN02)', () {
    test('UserProfile calculates freemium limit ratios and detects caps (RN02)', () {
      const profile = UserProfile(
        id: 'u1',
        name: 'Helena',
        email: 'h@test.com',
        handle: '@h',
        bodyType: 'Ampulheta',
        colorPalette: 'Outono Suave',
        paletteColors: [Colors.red, Colors.green],
        isPremium: false,
        registeredPiecesCount: 24,
        maxPiecesLimit: 30,
        dailyAiLooksUsed: 4,
        maxDailyAiLooksLimit: 5,
      );

      expect(profile.piecesRatio, closeTo(0.8, 0.01));
      expect(profile.dailyLooksRatio, closeTo(0.8, 0.01));
      expect(profile.hasReachedPiecesLimit, isFalse);
      expect(profile.hasReachedDailyLooksLimit, isFalse);
      expect(profile.hasReachedAnyFreemiumLimit, isFalse);
    });

    test('RN02: Detects when Freemium limits are reached at 30 pieces or 5 looks', () {
      final limitReachedUser = MockUserProfile.limitReachedUser;

      expect(limitReachedUser.registeredPiecesCount, 30);
      expect(limitReachedUser.dailyAiLooksUsed, 5);
      expect(limitReachedUser.hasReachedPiecesLimit, isTrue);
      expect(limitReachedUser.hasReachedDailyLooksLimit, isTrue);
      expect(limitReachedUser.hasReachedAnyFreemiumLimit, isTrue);
    });

    test('Premium user bypasses freemium limits (RN02)', () {
      final premiumUser = MockUserProfile.premiumUser;

      expect(premiumUser.isPremium, isTrue);
      expect(premiumUser.registeredPiecesCount, 42); // > 30
      expect(premiumUser.dailyAiLooksUsed, 12);      // > 5
      expect(premiumUser.hasReachedPiecesLimit, isFalse);
      expect(premiumUser.hasReachedDailyLooksLimit, isFalse);
      expect(premiumUser.hasReachedAnyFreemiumLimit, isFalse);
    });

    test('UserProfile copyWith correctly updates properties', () {
      final defaultUser = MockUserProfile.defaultUser;
      final updated = defaultUser.copyWith(
        name: 'Helena M.',
        bodyType: 'Retângulo',
        isPublicProfile: false,
      );

      expect(updated.name, 'Helena M.');
      expect(updated.bodyType, 'Retângulo');
      expect(updated.isPublicProfile, isFalse);
      expect(updated.email, defaultUser.email);
    });
  });
}
