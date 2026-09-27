import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/mocks/mock_community_feed.dart';
import 'package:harmonia_mvp/presentation/screens/community_feed_screen.dart';

void main() {
  group('Community Feed Tests (RF14/RF15 & RN05)', () {
    test('mock posts have valid properties and privacy flags', () {
      final posts = MockCommunityFeed.posts;
      expect(posts, isNotEmpty);
      expect(posts.first.isPublic, isTrue);
      expect(posts.first.garmentHotspots, isNotEmpty);
    });

    testWidgets('CommunityFeedScreen renders editorial gallery and filter chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CommunityFeedScreen(),
        ),
      );

      expect(find.text('Editorial Gallery'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Meu Biótipo'), findsOneWidget);

      // Tap filter chip
      await tester.tap(find.text('Meu Biótipo'));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
