import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../mocks/mock_community_feed.dart';
import '../../models/community_post.dart';
import '../widgets/editorial_feed_card.dart';
import '../widgets/share_outfit_sheet.dart';

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
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCanvas,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editorial Gallery',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'INSPIRAÇÕES DA COMUNIDADE (RF14/RF15)',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textPrimary),
            onPressed: () => ShareOutfitSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filterChips.map((chip) {
                final isSelected = _selectedFilter == chip;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(chip),
                    selected: isSelected,
                    onSelected: (_) => _onFilterSelected(chip),
                    selectedColor: AppColors.surfaceRaised,
                    backgroundColor: AppColors.surfaceCanvas,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.iheGold : AppColors.borderSubtle,
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Feed List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}
