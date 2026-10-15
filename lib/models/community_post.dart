import 'dart:ui';

import '../core/color/lab_color.dart';
import 'user_style_profile.dart';

/// Peça do look publicado (vem do look aprovado que originou o post)
class PostPiece {
  final String id;
  final String category;
  final String name;
  final String imageUrl;
  final Color color;
  final String labLabel;

  const PostPiece({
    required this.id,
    required this.category,
    required this.name,
    required this.imageUrl,
    required this.color,
    required this.labLabel,
  });

  factory PostPiece.fromJson(Map<String, dynamic> json) {
    final l = (json['dominant_l'] as num).toDouble();
    final a = (json['dominant_a'] as num).toDouble();
    final b = (json['dominant_b'] as num).toDouble();
    final category = json['category'] as String;
    return PostPiece(
      id: json['id'] as String,
      category: category,
      name: (json['subcategory'] as String?) ?? category,
      imageUrl: json['image_url'] as String,
      color: labToColor(l, a, b),
      labLabel: formatLab(l, a, b),
    );
  }
}

/// Publicação do feed comunitário (RF14) como a API devolve
class CommunityPost {
  final String id;
  final String authorName;
  final BodySilhouetteType? authorBodyShape;
  final SeasonalPaletteType? authorPalette;
  final String imageUrl;
  final String caption;
  final String occasion; // Chave do motor (ex.: TRABALHO)
  final List<String> styleTags;
  final double? ihePercentage; // Só em posts de um look aprovado
  final List<PostPiece> pieces;
  final int likeCount;
  final bool likedByMe;
  final bool savedByMe;
  final bool isPublic; // RN05
  final bool isMine;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.authorName,
    this.authorBodyShape,
    this.authorPalette,
    required this.imageUrl,
    required this.caption,
    required this.occasion,
    this.styleTags = const [],
    this.ihePercentage,
    this.pieces = const [],
    this.likeCount = 0,
    this.likedByMe = false,
    this.savedByMe = false,
    this.isPublic = true,
    this.isMine = false,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      authorName: json['author_name'] as String,
      authorBodyShape: BodySilhouetteExtension.fromApiKey(json['author_body_shape'] as String?),
      authorPalette: SeasonalPaletteExtension.fromApiKey(json['author_palette'] as String?),
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String,
      occasion: json['occasion'] as String,
      styleTags: (json['style_tags'] as List).cast<String>(),
      ihePercentage: (json['ihe_percentage'] as num?)?.toDouble(),
      pieces: (json['pieces'] as List).map((p) => PostPiece.fromJson(p as Map<String, dynamic>)).toList(),
      likeCount: json['like_count'] as int,
      likedByMe: json['liked_by_me'] as bool,
      savedByMe: json['saved_by_me'] as bool,
      isPublic: json['is_public'] as bool,
      isMine: json['is_mine'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Ocasião para leitura (TRABALHO -> Trabalho)
  String get occasionLabel => occasion.isEmpty ? '' : occasion[0] + occasion.substring(1).toLowerCase();

  /// Ex.: "Ampulheta • Outono Quente"; vazio se o autor não definiu o perfil
  String get authorTraits =>
      [authorBodyShape?.displayName, authorPalette?.displayName].whereType<String>().join(' • ');

  /// Selo ✦ Look Fortemente Recomendado (IHE >= 75%, Seção 5.3)
  bool get isStronglyRecommended => (ihePercentage ?? 0) >= 75;

  CommunityPost copyWith({bool? likedByMe, int? likeCount, bool? savedByMe}) {
    return CommunityPost(
      id: id,
      authorName: authorName,
      authorBodyShape: authorBodyShape,
      authorPalette: authorPalette,
      imageUrl: imageUrl,
      caption: caption,
      occasion: occasion,
      styleTags: styleTags,
      ihePercentage: ihePercentage,
      pieces: pieces,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
      isPublic: isPublic,
      isMine: isMine,
      createdAt: createdAt,
    );
  }
}

/// Uma página do feed; [nextBefore] nulo quando acabou
class CommunityFeedPage {
  final List<CommunityPost> posts;
  final DateTime? nextBefore;

  const CommunityFeedPage({required this.posts, this.nextBefore});

  factory CommunityFeedPage.fromJson(Map<String, dynamic> json) {
    final next = json['next_before'] as String?;
    return CommunityFeedPage(
      posts: (json['posts'] as List).map((p) => CommunityPost.fromJson(p as Map<String, dynamic>)).toList(),
      nextBefore: next == null ? null : DateTime.parse(next),
    );
  }
}
