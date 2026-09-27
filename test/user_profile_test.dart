import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_user_profile.dart';

void main() {
  group('UserProfile & RN02 Freemium Quotas Unit Tests', () {
    test('calculates correct quota ratios and limit flags', () {
      final profile = MockUserProfile.defaultProfile;

      expect(profile.maxPiecesQuota, equals(30));
      expect(profile.maxDailyLooksQuota, equals(5));

      expect(profile.isDailyLooksQuotaReached, isTrue);
      expect(profile.isPiecesQuotaReached, isFalse); // 28 < 30

      final hitProfile = profile.copyWith(registeredPiecesCount: 30);
      expect(hitProfile.isPiecesQuotaReached, isTrue);
    });
  });
}
