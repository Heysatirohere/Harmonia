import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
<<<<<<< HEAD
=======
import '../../core/theme/app_typography.dart';
>>>>>>> feat/social-feed-rf14-rf15
import '../../mocks/mock_community_feed.dart';
import '../../models/community_post.dart';
import '../widgets/editorial_feed_card.dart';
import '../widgets/share_outfit_sheet.dart';

<<<<<<< HEAD
=======
/// Tela do Feed Comunitário Editorial ("Editorial Gallery" - RF14 & RF15)
///
/// Apresenta inspirações de estilo com busca ativa, filtros multicritério por
/// Biótipo, Cartela Sazonal e Ocasião, e suporte a publicação com chave RN05.
>>>>>>> feat/social-feed-rf14-rf15
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
<<<<<<< HEAD
  late List<CommunityPost> _posts;
  String _selectedFilter = 'Todos';

  final List<String> _filterChips = [
    'Todos',
    'Meu Biótipo',
    'Minha Cartela',
    'Trabalho',
    'Gala',
    'Casual Chic',
=======
  final TextEditingController _searchController = TextEditingController();
  late List<CommunityPost> _allPosts;
  late List<CommunityPost> _filteredPosts;

  String _selectedFilterCategory = 'Todos';
  final List<String> _filterCategories = [
    'Todos',
    'Ampulheta',
    'Retângulo',
    'Outono Suave',
    'Outono Quente',
    'Trabalho & Ateliê',
    'Lazer Casual',
>>>>>>> feat/social-feed-rf14-rf15
  ];

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
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
=======
    _allPosts = List.from(MockCommunityFeed.posts);
    _filteredPosts = List.from(_allPosts);
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredPosts = _allPosts.where((post) {
        // Filtro RN05: no feed comunitário, exibe apenas posts públicos
        if (!post.isPublic) return false;

        // Filtro de Busca por Texto
        final matchesQuery = query.isEmpty ||
            post.title.toLowerCase().contains(query) ||
            post.editorialDescription.toLowerCase().contains(query) ||
            post.author.name.toLowerCase().contains(query) ||
            post.bodyType.toLowerCase().contains(query) ||
            post.colorPalette.toLowerCase().contains(query) ||
            post.occasionTag.toLowerCase().contains(query);

        // Filtro de Chips Categorizados
        final matchesCategory = _selectedFilterCategory == 'Todos' ||
            post.bodyType == _selectedFilterCategory ||
            post.colorPalette == _selectedFilterCategory ||
            post.occasionTag == _selectedFilterCategory;

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFilterCategory = category;
    });
    _applyFilters();
  }

  void _openShareSheet() async {
    HapticFeedback.mediumImpact();
    final publishedPost = await ShareOutfitSheet.show(
      context,
      onPublish: (newPost) {
        setState(() {
          _allPosts.insert(0, newPost);
        });
        _applyFilters();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                Icon(
                  newPost.isPublic ? Icons.public : Icons.lock_outline,
                  color: AppColors.iheGold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newPost.isPublic
                        ? 'Inspiração publicada no Feed Comunitário!'
                        : 'Look salvo como privado no seu acervo (RN05).',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.surfaceCanvas,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (publishedPost != null) {
      _applyFilters();
>>>>>>> feat/social-feed-rf14-rf15
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openShareSheet,
        backgroundColor: AppColors.accentTerracotta,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
        label: Text(
          'Partilhar Look',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. BARRA SUPERIOR EDITORIAL
            SliverToBoxAdapter(
              child: _buildEditorialHeader(),
            ),

            // 2. BUSCA POR BIÓTIPO, CARTELA E OCASIÃO (RF15)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Buscar por biótipo, cartela (ex: Outono), ocasião...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceRaised,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.borderSubtle, width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.borderSubtle, width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.iheGold, width: 1.0),
                    ),
                  ),
                ),
              ),
            ),

            // 3. CHIPS HORIZONTAIS DE FILTRO (RF15 - AppMotion.editorialDecel)
            SliverToBoxAdapter(
              child: _buildFilterChips(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 4. GRELHA / LISTA EDITORIAL DE POSTS (RF14)
            _filteredPosts.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.filter_vintage_outlined,
                              size: 40, color: AppColors.accentSand),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma inspiração encontrada',
                            style: AppTypography.editorialTitleSmall(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tente ajustar o termo de busca ou redefinir os filtros por biótipo e cartela.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = _filteredPosts[index];
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.decelerate,
                          child: EditorialFeedCard(
                            key: ValueKey(post.id),
                            post: post,
                            onTapAuthor: () {
                              HapticFeedback.lightImpact();
                            },
                          ),
                        );
                      },
                      childCount: _filteredPosts.length,
                    ),
                  ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HarmonIA',
                style: AppTypography.editorialTitleLarge().copyWith(
                  fontSize: 28,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'FEED COMUNITÁRIO • EDITORIAL GALLERY',
                style: AppTypography.metaLabel().copyWith(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentTerracotta,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Partilhar Combinação',
            onPressed: _openShareSheet,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.textPrimary,
              size: 24,
>>>>>>> feat/social-feed-rf14-rf15
            ),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filterCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _filterCategories[index];
          final isSelected = category == _selectedFilterCategory;

          return GestureDetector(
            onTap: () => _onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.decelerate, // Transição sutil editorial
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.borderSubtle,
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: AppTypography.metaLabel(
                    color: isSelected
                        ? AppColors.surfaceCanvas
                        : AppColors.textPrimary,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
>>>>>>> feat/social-feed-rf14-rf15
}
