class GarmentHotspot {
  final String name;
  final String brand;
  final String fabric;
  final String colorHex;
  final double xRatio;
  final double yRatio;

  const GarmentHotspot({
    required this.name,
    required this.brand,
    required this.fabric,
    required this.colorHex,
    required this.xRatio,
    required this.yRatio,
  });
}

class CommunityPost {
  final String id;
  final String authorName;
  final String authorAvatarUrl;
  final String authorBiotype;
  final String authorColorPalette;
  final String outfitTitle;
  final String outfitImageUrl;
  final double iheScore;
  final int likeCount;
  final bool isLiked;
  final bool isSaved;
  final List<String> tags;
  final bool isPublic; // RN05 Privacy flag
  final List<GarmentHotspot> garmentHotspots;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.authorBiotype,
    required this.authorColorPalette,
    required this.outfitTitle,
    required this.outfitImageUrl,
    required this.iheScore,
    required this.likeCount,
    this.isLiked = false,
    this.isSaved = false,
    required this.tags,
    this.isPublic = true,
    required this.garmentHotspots,
    required this.createdAt,
  });

  CommunityPost copyWith({
    bool? isLiked,
    int? likeCount,
    bool? isSaved,
    bool? isPublic,
  }) {
    return CommunityPost(
      id: id,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorBiotype: authorBiotype,
      authorColorPalette: authorColorPalette,
      outfitTitle: outfitTitle,
      outfitImageUrl: outfitImageUrl,
      iheScore: iheScore,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      tags: tags,
      isPublic: isPublic ?? this.isPublic,
      garmentHotspots: garmentHotspots,
      createdAt: createdAt,
    );
  }
}
