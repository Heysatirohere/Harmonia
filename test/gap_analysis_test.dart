import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_gap_analysis.dart';

void main() {
  group('GapAnalysis & RN03 Unit Tests', () {
    test('WardrobeGap.availableProducts strictly filters out out-of-stock items (RN03)', () {
      final gap = MockGapAnalysis.gaps.first;
      expect(gap.suggestedProducts.length, equals(3));
      
      // availableProducts should only include inStock == true items (2 items)
      expect(gap.availableProducts.length, equals(2));
      expect(gap.availableProducts.any((p) => p.inStock == false), isFalse);
    });
  });
}
