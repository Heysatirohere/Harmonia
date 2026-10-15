import 'dart:typed_data';

import 'package:harmonia_mvp/data/services/community_api_service.dart';
import 'package:harmonia_mvp/models/community_post.dart';

/// Pedido de publicação recebido pelo serviço falso
typedef PublishRequest = ({
  Uint8List photo,
  String caption,
  String occasion,
  List<String> styleTags,
  String? feedbackId,
  bool? isPublic,
});

/// Feed em memória para testes de widget; [failure] simula a API fora do ar na próxima chamada
class FakeCommunityService extends CommunityApiService {
  /// Posts por recorte; a chave é (filtro, ocasião, busca)
  final Map<(FeedFilter, String?, String), List<CommunityPost>> feeds;

  /// Segunda página devolvida quando `before` é passado
  final List<CommunityPost> nextPage;
  final DateTime? firstPageNextBefore;

  CommunityException? failure;
  final List<({FeedFilter filter, String? occasion, String query, DateTime? before})> fetches = [];
  final List<PublishRequest> published = [];
  final List<(String, bool)> likes = [];
  final List<(String, bool)> saves = [];
  final List<String> deleted = [];

  FakeCommunityService(this.feeds, {this.nextPage = const [], this.firstPageNextBefore, this.failure});

  void _throwIfQueued() {
    final queued = failure;
    if (queued != null) {
      failure = null;
      throw queued;
    }
  }

  @override
  Future<CommunityFeedPage> fetchFeed({
    FeedFilter filter = FeedFilter.all,
    String? occasion,
    String? query,
    DateTime? before,
  }) async {
    final q = query?.trim() ?? '';
    fetches.add((filter: filter, occasion: occasion, query: q, before: before));
    _throwIfQueued();
    if (before != null) return CommunityFeedPage(posts: nextPage);
    return CommunityFeedPage(posts: feeds[(filter, occasion, q)] ?? const [], nextBefore: firstPageNextBefore);
  }

  @override
  Future<CommunityPost> publish({
    required Uint8List photo,
    required String caption,
    required String occasion,
    List<String> styleTags = const [],
    String? feedbackId,
    bool? isPublic,
  }) async {
    _throwIfQueued();
    published.add((
      photo: photo,
      caption: caption,
      occasion: occasion,
      styleTags: styleTags,
      feedbackId: feedbackId,
      isPublic: isPublic,
    ));
    return samplePost(id: 'novo', caption: caption, occasion: occasion, isMine: true, isPublic: isPublic ?? true);
  }

  @override
  Future<void> setLiked(String postId, bool liked) async {
    _throwIfQueued();
    likes.add((postId, liked));
  }

  @override
  Future<void> setSaved(String postId, bool saved) async {
    _throwIfQueued();
    saves.add((postId, saved));
  }

  @override
  Future<void> delete(String postId) async {
    _throwIfQueued();
    deleted.add(postId);
  }
}

CommunityPost samplePost({
  String id = 'p1',
  String caption = 'Linho cru para o escritório',
  String occasion = 'TRABALHO',
  bool isMine = false,
  bool isPublic = true,
  int likeCount = 3,
  bool likedByMe = false,
  bool savedByMe = false,
  double? ihe,
  List<PostPiece> pieces = const [],
}) {
  return CommunityPost(
    id: id,
    authorName: 'Ana Souza',
    imageUrl: '',
    caption: caption,
    occasion: occasion,
    styleTags: const ['Minimal'],
    ihePercentage: ihe,
    pieces: pieces,
    likeCount: likeCount,
    likedByMe: likedByMe,
    savedByMe: savedByMe,
    isPublic: isPublic,
    isMine: isMine,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  );
}

/// PNG de 1x1 válido: o preview da folha decodifica a foto de verdade
final samplePhotoBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
