import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_store_parity.dart';
import 'package:harmonia_mvp/models/store_parity_result.dart';

void main() {
  group('StoreParityResult Unit Tests (RF08/RF09)', () {
    test('sample result contains valid store garment and parity matches', () {
      final sample = MockStoreParity.sample;
      expect(sample.storeGarment.name, contains('Blazer Linho'));
      expect(sample.globalParityScore, greaterThanOrEqualTo(0.8));
      expect(sample.matches, isNotEmpty);
      expect(sample.matches.first.harmonyScore, greaterThan(0.9));
    });
  });
}
