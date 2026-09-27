import '../models/user_profile.dart';

class MockUserProfile {
  static final UserProfile defaultProfile = UserProfile(
    id: 'user_01',
    name: 'Helena von Suttner',
    email: 'helena.suttner@harmonia.app',
    biotype: 'Ampulheta',
    colorPalette: 'Outono Suave',
    colorSwatchHexes: const ['#A34836', '#4B5842', '#D9CDBF', '#B88E3E'],
    registeredPiecesCount: 28, // Near limit (30)
    dailyLooksGeneratedCount: 5, // At limit (5)
    isPremium: false,
  );
}
