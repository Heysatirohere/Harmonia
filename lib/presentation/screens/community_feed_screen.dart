import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../mocks/mock_community_feed.dart';
import '../../models/community_post.dart';
import '../../theme/app_theme.dart';
import '../atelier/atelier_room.dart';
import '../atelier/atelier_widgets.dart';
import '../atelier/room_scene.dart';
import '../widgets/editorial_feed_card.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/share_outfit_sheet.dart';

/// Feed Comunitário "Editorial Gallery" (RF14/RF15) sobre a tapeçaria noir (AGENTS.md 7.4)
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  late List<CommunityPost> _posts;
  String _selectedFilter = 'Todos';

  final List<String> _filterChips = [
    'Todos',
    'Meu Biótipo',
    'Minha Cartela',
    'Trabalho',
    'Gala',
    'Casual Chic',
  ];

  @override
  void initState() {
    super.initState();
    _posts = List.from(MockCommunityFeed.posts);
  }

  void _onFilterSelected(String chip) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFilter = chip;
    });
  }

  List<CommunityPost> get _filteredPosts {
    if (_selectedFilter == 'Todos') return _posts;
    if (_selectedFilter == 'Meu Biótipo') {
      return _posts.where((p) => p.authorBiotype == 'Ampulheta').toList();
    }
    if (_selectedFilter == 'Minha Cartela') {
      return _posts.where((p) => p.authorColorPalette.contains('Outono')).toList();
    }
    return _posts.where((p) => p.tags.contains(_selectedFilter)).toList();
  }

  void _toggleLike(int index) {
    final post = _filteredPosts[index];
    final updated = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );

    final realIndex = _posts.indexWhere((p) => p.id == post.id);
    if (realIndex != -1) {
      setState(() {
        _posts[realIndex] = updated;
      });
    }
  }

  void _toggleSave(int index) {
    final post = _filteredPosts[index];
    final updated = post.copyWith(isSaved: !post.isSaved);

    final realIndex = _posts.indexWhere((p) => p.id == post.id);
    if (realIndex != -1) {
      setState(() {
        _posts[realIndex] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPosts;

    return Scaffold(
      backgroundColor: AppColors.tapestryNoir,
      body: RoomScene(
        room: AtelierRoom.tapestryNoir,
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
                  onTap: () => ShareOutfitSheet.show(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FilterChipsBar(
                categories: _filterChips,
                selectedIndex: _filterChips.indexOf(_selectedFilter),
                onCategorySelected: (index) => _onFilterSelected(_filterChips[index]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final post = filtered[index];
                  return EditorialFeedCard(
                    post: post,
                    onLikeToggle: () => _toggleLike(index),
                    onSaveToggle: () => _toggleSave(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
