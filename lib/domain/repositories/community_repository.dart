import 'dart:typed_data';

import '../../data/services/community_api_service.dart' show FeedFilter;
import '../../models/community_post.dart';

/// Contrato de domínio da Comunidade Editorial & Moodboards (RF14, RF15, RN05, Seção 8 AGENTS.md)
abstract class CommunityRepository {
  Future<CommunityFeedPage> fetchFeed({
    FeedFilter filter = FeedFilter.all,
    String? occasion,
    String? query,
    DateTime? before,
  });

  Future<CommunityPost> publish({
    required Uint8List photo,
    required String caption,
    required String occasion,
    List<String> styleTags = const [],
    String? feedbackId,
    bool? isPublic,
  });

  Future<void> setLiked(String postId, bool liked);

  Future<void> setSaved(String postId, bool saved, {String? boardName});

  Future<CommunityPost> updatePostVisibility(String postId, {required bool isPublic});

  Future<void> delete(String postId);
}
