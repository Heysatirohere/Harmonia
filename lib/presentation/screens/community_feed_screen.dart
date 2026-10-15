import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/demo/demo_mode.dart';
import '../../data/services/community_api_service.dart';
import '../../models/community_post.dart';
import '../../models/user_style_profile.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../widgets/editorial_feed_card.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/photo_capture.dart';
import '../widgets/share_outfit_sheet.dart';

/// Feed Comunitário "Editorial Gallery" (RF14/RF15) sobre a tapeçaria noir (AGENTS.md 7.4)
///
/// Recortes da Seção 3.5.3: mesmo biótipo, mesma cartela, ocasião, salvos e os próprios looks,
/// mais a busca na legenda e nas tags. Só aparecem posts públicos de perfis públicos (RN05).
class CommunityFeedScreen extends StatefulWidget {
  final CommunityApiService? service;
  final PhotoCapture? capturePhoto;

  const CommunityFeedScreen({super.key, this.service, this.capturePhoto});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

/// Cada chip é um recorte do feed, com ou sem ocasião
typedef _FeedChip = ({String label, FeedFilter filter, String? occasion});

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  static const List<_FeedChip> _chips = [
    (label: 'Todos', filter: FeedFilter.all, occasion: null),
    (label: 'Meu biótipo', filter: FeedFilter.bodyShape, occasion: null),
    (label: 'Minha cartela', filter: FeedFilter.palette, occasion: null),
    (label: 'Casual', filter: FeedFilter.all, occasion: 'CASUAL'),
    (label: 'Trabalho', filter: FeedFilter.all, occasion: 'TRABALHO'),
    (label: 'Festa', filter: FeedFilter.all, occasion: 'FESTA'),
    (label: 'Gala', filter: FeedFilter.all, occasion: 'GALA'),
    (label: 'Salvos', filter: FeedFilter.saved, occasion: null),
    (label: 'Meus looks', filter: FeedFilter.mine, occasion: null),
  ];

  late final CommunityApiService _service = widget.service ?? CommunityApiService();
  final TextEditingController _search = TextEditingController();

  List<CommunityPost> _posts = [];
  DateTime? _nextBefore;
  int _chipIndex = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  /// Cada carga ganha um número; respostas de uma carga antiga (filtro trocado no meio) são ignoradas
  int _generation = 0;

  static List<CommunityPost> get _demoPosts => [
    CommunityPost(
      id: 'demo-feed-1',
      authorName: 'Camila Rossi',
      authorBodyShape: BodySilhouetteType.ampulheta,
      authorPalette: SeasonalPaletteType.outonoQuente,
      imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1080&q=80',
      caption:
          'Composição de alfaiataria em linho terracota com pantalona fluida. Silhueta estruturada para reunião de conselho.',
      occasion: 'TRABALHO',
      styleTags: const ['Alfaiataria', 'ESG', 'Terracota'],
      ihePercentage: 94.0,
      pieces: const [
        PostPiece(
          id: 'p1',
          category: 'Partes de cima',
          name: 'Blazer de linho terracota',
          imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&q=80',
          color: Color(0xFFC86D51),
          labLabel: 'L* 54 · a* 32 · b* 28',
        ),
        PostPiece(
          id: 'p2',
          category: 'Partes de baixo',
          name: 'Pantalona fluida off-white',
          imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=600&q=80',
          color: Color(0xFFE9E4D6),
          labLabel: 'L* 90 · a* 1 · b* 7',
        ),
      ],
      likeCount: 42,
      likedByMe: true,
      savedByMe: true,
      isPublic: true,
      isMine: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CommunityPost(
      id: 'demo-feed-2',
      authorName: 'Helena Duarte',
      authorBodyShape: BodySilhouetteType.retangulo,
      authorPalette: SeasonalPaletteType.veraoFrio,
      imageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1080&q=80',
      caption: 'Seda esmeralda e lã fria. Contraste tonal sutil para a vernissage da Bienal.',
      occasion: 'FESTA',
      styleTags: const ['Seda', 'Esmeralda', 'Editorial'],
      ihePercentage: 91.0,
      pieces: const [
        PostPiece(
          id: 'p3',
          category: 'Partes de cima',
          name: 'Regata de seda esmeralda',
          imageUrl: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=600&q=80',
          color: Color(0xFF1C3120),
          labLabel: 'L* 20 · a* -15 · b* 8',
        ),
      ],
      likeCount: 28,
      likedByMe: false,
      savedByMe: false,
      isPublic: true,
      isMine: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
    ),
  ];

  _FeedChip get _chip => _chips[_chipIndex];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _service.fetchFeed(filter: _chip.filter, occasion: _chip.occasion, query: _search.text);
      if (!mounted || generation != _generation) return;
      setState(() {
        _posts = page.posts.isEmpty && kDemoMode ? _demoPosts : page.posts;
        _nextBefore = page.nextBefore;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        if (kDemoMode) {
          _posts = _demoPosts;
        } else {
          _error = e is CommunityException ? e.message : 'Não foi possível carregar o feed.';
        }
      });
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final before = _nextBefore;
    if (before == null || _loadingMore || _loading) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await _service.fetchFeed(
        filter: _chip.filter,
        occasion: _chip.occasion,
        query: _search.text,
        before: before,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _posts = [..._posts, ...page.posts];
        _nextBefore = page.nextBefore;
      });
    } on CommunityException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _selectChip(int index) {
    if (index == _chipIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _chipIndex = index);
    _load();
  }

  /// Curtir e salvar mudam na hora; se a API recusar, volta ao que era e avisa
  Future<void> _toggle(CommunityPost post, {required bool like}) async {
    final updated = like
        ? post.copyWith(likedByMe: !post.likedByMe, likeCount: post.likeCount + (post.likedByMe ? -1 : 1))
        : post.copyWith(savedByMe: !post.savedByMe);
    _replace(post.id, updated);
    try {
      if (like) {
        await _service.setLiked(post.id, updated.likedByMe);
      } else {
        await _service.setSaved(post.id, updated.savedByMe);
        // Tirar dos salvos enquanto o recorte "Salvos" está aberto tira o post da lista
        if (!updated.savedByMe && _chip.filter == FeedFilter.saved && mounted) {
          setState(() => _posts = _posts.where((p) => p.id != post.id).toList());
        }
      }
    } on CommunityException catch (e) {
      _replace(post.id, post);
      _showMessage(e.message);
    }
  }

  void _replace(String id, CommunityPost post) {
    if (!mounted) return;
    setState(() => _posts = [for (final p in _posts) p.id == id ? post : p]);
  }

  Future<void> _confirmDelete(CommunityPost post) async {
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.tapestryNoir.withValues(alpha: 0.6),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paperBone,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLarge)),
        title: Text('Apagar publicação', style: AppTypography.displayEditorial().copyWith(fontSize: 22)),
        content: Text(
          'A foto sai do feed e do armazenamento, junto com as curtidas e os salvos dela.',
          style: AppTypography.bodyReading(color: AppColors.inkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: AppTypography.uiHeadline(color: AppColors.inkSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCinnabar,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSmall)),
            ),
            child: Text('Apagar', style: AppTypography.uiHeadline(color: AppColors.ivoryText)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.delete(post.id);
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _posts = _posts.where((p) => p.id != post.id).toList());
      _showMessage('Publicação apagada.');
    } on CommunityException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _share() async {
    final post = await ShareOutfitSheet.show(
      context,
      service: _service,
      capturePhoto: widget.capturePhoto,
    );
    if (post == null || !mounted) return;
    HapticFeedback.mediumImpact();
    _showMessage(post.isPublic ? 'Look publicado na comunidade.' : 'Look salvo em "Meus looks".');
    // O post novo é o mais recente: entra no topo de "Todos" e de "Meus looks"
    if (_chip.filter == FeedFilter.all && _chip.occasion == null && _search.text.trim().isEmpty ||
        _chip.filter == FeedFilter.mine) {
      setState(() => _posts = [post, ..._posts]);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.tapestryNoir,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: AppTypography.bodySmall(color: AppColors.ivoryText)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: RoomScene(
        room: AtelierRoom.tapestryNoir,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 800) _loadMore();
            return false;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: RoomHeader(
                  eyebrow: 'Comunidade • RF14/RF15',
                  title: 'Editorial',
                  subtitle: 'Inspirações de quem compartilha seu estilo',
                  room: AtelierRoom.tapestryNoir,
                  trailing: RoomIconButton(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Compartilhar look',
                    filled: true,
                    onTap: _share,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _SearchField(controller: _search, onSubmitted: (_) => _load())),
              SliverToBoxAdapter(
                child: FilterChipsBar(
                  categories: [for (final chip in _chips) chip.label],
                  selectedIndex: _chipIndex,
                  onCategorySelected: _selectChip,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              if (_posts.isEmpty)
                SliverToBoxAdapter(child: _buildPlaceholder())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                  sliver: SliverList.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return EditorialFeedCard(
                        key: ValueKey(post.id),
                        post: post,
                        onLikeToggle: () => _toggle(post, like: true),
                        onSaveToggle: () => _toggle(post, like: false),
                        onDelete: post.isMine ? () => _confirmDelete(post) : null,
                      );
                    },
                  ),
                ),
              if (_loadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Center(
                      child: Text('Carregando mais looks…', style: AppTypography.bodySmall(color: AppColors.ivoryMuted)),
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 96)),
            ],
          ),
        ),
      ),
    );
  }

  /// Carregando, erro ou recorte vazio, com o texto certo para cada recorte
  Widget _buildPlaceholder() {
    final searching = _search.text.trim().isNotEmpty;
    final (String title, String message, bool canRetry) = switch ((_loading, _error)) {
      (true, _) => ('Abrindo a galeria…', 'Reunindo os looks da comunidade.', false),
      (false, final String error) => ('O ateliê não respondeu', error, true),
      _ when searching => ('Nada encontrado', 'Nenhum look com "${_search.text.trim()}" neste recorte.', false),
      _ => switch (_chip.filter) {
          FeedFilter.bodyShape || FeedFilter.palette => (
              'Ninguém por aqui ainda',
              'Ainda não há looks de quem tem o seu perfil. Se você não completou o perfil, faça isso em Perfil.',
              false,
            ),
          FeedFilter.saved => ('Seu moodboard está vazio', 'Toque no marcador de um look para guardá-lo aqui.', false),
          FeedFilter.mine => ('Você ainda não publicou', 'Toque em + para compartilhar o seu primeiro look.', false),
          FeedFilter.all => ('A galeria está vazia', 'Seja a primeira pessoa a compartilhar um look.', false),
        },
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, AppSpacing.tightGap, AppSpacing.pageMargin, 0),
      child: AnimatedOpacity(
        opacity: _loading ? 0.7 : 1.0,
        duration: AppMotion.medium,
        curve: AppMotion.editorialDecel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.subtitleCuratorial(color: AppColors.ivoryText)),
            const SizedBox(height: AppSpacing.tightGap),
            Text(message, style: AppTypography.bodyReading(color: AppColors.ivoryMuted)),
            if (canRetry) ...[
              const SizedBox(height: 20),
              RoomIconButton(icon: Icons.refresh, label: 'Tentar de novo', onTap: _load),
            ],
          ],
        ),
      ),
    );
  }
}

/// Busca na legenda e nas tags (RF15): linha capilar marfim sobre a Sala
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _SearchField({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 0, AppSpacing.pageMargin, 16),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        maxLength: 60,
        cursorColor: AppColors.gildedLeaf,
        style: AppTypography.bodyReading(color: AppColors.ivoryText),
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          hintText: 'Buscar por legenda ou tag',
          hintStyle: AppTypography.bodyReading(color: AppColors.ivoryMuted),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.ivoryMuted),
          prefixIconConstraints: const BoxConstraints(minWidth: 28),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.hairlineIvory)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gildedLeaf)),
        ),
      ),
    );
  }
}
