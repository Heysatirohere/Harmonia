import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/community_post.dart';
import 'widgets/community_feed_card.dart';

/// Tela do Feed Comunitário Editorial ("Editorial Gallery")
/// Conforme AGENTS.md:
/// - Fundo creme quente (#FBF9F5)
/// - Tipografia com contraste deliberado e curadoria editorial
/// - Zero Material Design cru ou genérico
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Editorial',
    '✦ Alto IHE',
    'Moda Consciente (ESG)',
    'Alfaiataria',
    'Casual Orgânico',
  ];

  late List<CommunityPost> _posts;

  @override
  void initState() {
    super.initState();
    _posts = _generateMockPosts();
  }

  List<CommunityPost> _generateMockPosts() {
    return [
      // Post 1: Alta alfaiataria com linho e peças vintage
      CommunityPost(
        id: 'post-1',
        author: const PostAuthor(
          id: 'author-1',
          name: 'Helena Vasconcelos',
          handle: '@helenav',
          avatarUrl:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
          styleArchetype: 'Minimalismo Quente & Alfaiataria',
          isVerifiedCurator: true,
        ),
        title: 'Sobreposições Terracota em Linho Cru',
        editorialDescription:
            'Harmonização de contrastes orgânicos para tardes amenas de ateliê. O blazer de corte desestruturado compensa a fluidez da calça pantalona.',
        imageUrl:
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=900&auto=format&fit=crop&q=80',
        publishedAtAgo: 'há 2h',
        appreciationCount: 142,
        savesCount: 58,
        isApplauded: true,
        ihe: const IheBreakdown(
          overallScore: 89,
          sColor: 0.92,
          sBio: 0.88,
          sOcasion: 0.85,
          sCos: 0.91,
          dominantColor: AppColors.accentTerracotta,
          paletteColors: [
            Color(0xFFA34836), // Terracota
            Color(0xFFD9CDBF), // Sand
            Color(0xFF4B5842), // Olive
            Color(0xFF2B2625), // Carvão
          ],
          occasionContext: 'Encontro Criativo • 23°C Ensolarado',
        ),
        garments: const [
          GarmentHotspot(
            id: 'g-1',
            name: 'Blazer Desestruturado em Linho',
            brandOrProvenance: 'Acervo Pessoal • 4 anos de uso',
            category: 'Alfaiataria',
            position: Offset(0.48, 0.38),
            dominantColor: Color(0xFFA34836),
            isConsciousFashion: true,
            consciousNote: '100% Linho puro • Consumo Consciente',
          ),
          GarmentHotspot(
            id: 'g-2',
            name: 'Regata Seda Areia',
            brandOrProvenance: 'Brechó Vintage Paulistano',
            category: 'Superior',
            position: Offset(0.50, 0.28),
            dominantColor: Color(0xFFD9CDBF),
            isConsciousFashion: true,
            consciousNote: 'Segunda mão certificada',
          ),
          GarmentHotspot(
            id: 'g-3',
            name: 'Pantalona Ampla Off-White',
            brandOrProvenance: 'Ateliê Sustentável Local',
            category: 'Inferior',
            position: Offset(0.50, 0.72),
            dominantColor: Color(0xFFF3EFEA),
            isConsciousFashion: true,
            consciousNote: 'Algodão agroecológico tingido a seco',
          ),
        ],
      ),

      // Post 2: Curadoria Casual com tons oliva e terra
      CommunityPost(
        id: 'post-2',
        author: const PostAuthor(
          id: 'author-2',
          name: 'Lucas Moretti',
          handle: '@moretti.style',
          avatarUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
          styleArchetype: 'Alfaiataria Utilitária & ESG',
          isVerifiedCurator: true,
        ),
        title: 'Geometrias Naturais & Textura Botânica',
        editorialDescription:
            'A camisa em sarja oliva estabelece um ponto focal sóbrio. A transição de proporções equilibra a silhueta para eventos culturais noturnos.',
        imageUrl:
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=900&auto=format&fit=crop&q=80',
        publishedAtAgo: 'há 5h',
        appreciationCount: 96,
        savesCount: 34,
        isApplauded: false,
        ihe: const IheBreakdown(
          overallScore: 82,
          sColor: 0.85,
          sBio: 0.81,
          sOcasion: 0.80,
          sCos: 0.84,
          dominantColor: AppColors.accentOlive,
          paletteColors: [
            Color(0xFF4B5842), // Oliva
            Color(0xFF1A1817), // Preto Carvão
            Color(0xFFB88E3E), // IHE Ouro
            Color(0xFFE5DDD0), // Creme
          ],
          occasionContext: 'Vernissage & Galeria • 19°C Noturno',
        ),
        garments: const [
          GarmentHotspot(
            id: 'g-4',
            name: 'Sobrecamisa de Sarja Verde Oliva',
            brandOrProvenance: 'Acervo Circular • 28 usos',
            category: 'Camisaria',
            position: Offset(0.48, 0.35),
            dominantColor: Color(0xFF4B5842),
            isConsciousFashion: true,
            consciousNote: 'Fibra de cânhamo sustentável',
          ),
          GarmentHotspot(
            id: 'g-5',
            name: 'Calça de Corte Reto em Lã Fria',
            brandOrProvenance: 'Alfaiataria Sob Medida',
            category: 'Inferior',
            position: Offset(0.48, 0.68),
            dominantColor: Color(0xFF1A1817),
            isConsciousFashion: false,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // AppBar Editorial Customizada
            SliverToBoxAdapter(
              child: _buildEditorialHeader(),
            ),

            // Filtros de Curadoria
            SliverToBoxAdapter(
              child: _buildFilterChips(),
            ),

            // Lista de Cards do Feed
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];
                  return CommunityFeedCard(
                    post: post,
                    onTapAuthor: () {
                      HapticFeedback.lightImpact();
                    },
                    onApplaud: () {},
                    onSave: () {},
                    onShare: () {},
                  );
                },
                childCount: _posts.length,
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 48),
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
            onPressed: () {
              HapticFeedback.lightImpact();
            },
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilterIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPrimary : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.textPrimary : AppColors.borderSubtle,
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  _filters[index],
                  style: AppTypography.metaLabel(
                    color: isSelected ? AppColors.surfaceCanvas : AppColors.textPrimary,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
