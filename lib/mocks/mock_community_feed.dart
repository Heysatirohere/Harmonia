<<<<<<< HEAD
import '../models/community_post.dart';

class MockCommunityFeed {
  static final List<CommunityPost> posts = [
    CommunityPost(
      id: 'post_01',
      authorName: 'Elena Rostova',
      authorAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
      authorBiotype: 'Ampulheta',
      authorColorPalette: 'Outono Quente',
      outfitTitle: 'Alfaiataria Minimalista & Linho Cru',
      outfitImageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800',
      iheScore: 92.4,
      likeCount: 148,
      tags: ['Trabalho', 'Alfaiataria', 'Outono'],
      isPublic: true,
      garmentHotspots: const [
        GarmentHotspot(
          name: 'Blazer Linho Oversized',
          brand: 'Zara Studio',
          fabric: '100% Linho Puro',
          colorHex: '#D9CDBF',
          xRatio: 0.45,
          yRatio: 0.35,
        ),
        GarmentHotspot(
          name: 'Calça Cenoura Alfaiataria',
          brand: 'Massimo Dutti',
          fabric: 'Lã Fria & Algodão',
          colorHex: '#1A1817',
          xRatio: 0.55,
          yRatio: 0.70,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CommunityPost(
      id: 'post_02',
      authorName: 'Camilla Valente',
      authorAvatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300',
      authorBiotype: 'Retângulo',
      authorColorPalette: 'Inverno Frio',
      outfitTitle: 'Camadas de Sobretudo Terroso',
      outfitImageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800',
      iheScore: 88.0,
      likeCount: 92,
      tags: ['Casual Chic', 'Inverno', 'Camadas'],
      isPublic: true,
      garmentHotspots: const [
        GarmentHotspot(
          name: 'Sobretudo Lã Terracota',
          brand: 'Lojas Renner',
          fabric: 'Lã Batida',
          colorHex: '#A34836',
          xRatio: 0.50,
          yRatio: 0.40,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    CommunityPost(
      id: 'post_03',
      authorName: 'Beatriz Fonseca',
      authorAvatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=300',
      authorBiotype: 'Ampulheta',
      authorColorPalette: 'Primavera Brilhante',
      outfitTitle: 'Vestido Fluido de Seda Verde Oliva',
      outfitImageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
      iheScore: 94.8,
      likeCount: 215,
      tags: ['Gala', 'Seda', 'Primavera'],
      isPublic: true,
      garmentHotspots: const [
        GarmentHotspot(
          name: 'Vestido Midi Seda',
          brand: 'C&A Premium',
          fabric: 'Seda Orgânica',
          colorHex: '#4B5842',
          xRatio: 0.48,
          yRatio: 0.50,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
=======
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/community_post.dart';

/// Coleção de Posts Mockados do Feed Comunitário Editorial (RF14 / RF15)
class MockCommunityFeed {
  MockCommunityFeed._();

  static List<CommunityPost> get posts => [
        // Post 1: Ampulheta / Outono Suave / Trabalho & Ateliê
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
          bodyType: 'Ampulheta',
          colorPalette: 'Outono Suave',
          occasionTag: 'Trabalho & Ateliê',
          isPublic: true,
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

        // Post 2: Retângulo / Outono Quente / Gala & Eventos
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
          bodyType: 'Retângulo',
          colorPalette: 'Outono Quente',
          occasionTag: 'Gala & Eventos',
          isPublic: true,
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

        // Post 3: Triângulo Invertido / Inverno Frio / Lazer Casual
        CommunityPost(
          id: 'post-3',
          author: const PostAuthor(
            id: 'author-3',
            name: 'Camila Siqueira',
            handle: '@camilasiqueira',
            avatarUrl:
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&auto=format&fit=crop&q=80',
            styleArchetype: 'Elegância Minimalista & Vintage',
            isVerifiedCurator: true,
          ),
          title: 'Monocromia Areia & Fluidos Urbanos',
          editorialDescription:
              'Composição monocromática em tons areia e linho para dias amenos de primavera urbana.',
          imageUrl:
              'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=900&auto=format&fit=crop&q=80',
          publishedAtAgo: 'há 1d',
          appreciationCount: 184,
          savesCount: 72,
          isApplauded: true,
          bodyType: 'Triângulo Invertido',
          colorPalette: 'Inverno Frio',
          occasionTag: 'Lazer Casual',
          isPublic: true,
          ihe: const IheBreakdown(
            overallScore: 91,
            sColor: 0.94,
            sBio: 0.90,
            sOcasion: 0.88,
            sCos: 0.92,
            dominantColor: AppColors.accentSand,
            paletteColors: [
              Color(0xFFD9CDBF), // Sand
              Color(0xFFF3EFEA), // Creme
              Color(0xFFA34836), // Terracota
            ],
            occasionContext: 'Passeio Cultural • 21°C',
          ),
          garments: const [
            GarmentHotspot(
              id: 'g-6',
              name: 'Trench Coat Linho Leve',
              brandOrProvenance: 'Brechó Selecionado',
              category: 'Sobreposição',
              position: Offset(0.5, 0.4),
              dominantColor: Color(0xFFD9CDBF),
              isConsciousFashion: true,
            ),
          ],
        ),
      ];
>>>>>>> feat/social-feed-rf14-rf15
}
