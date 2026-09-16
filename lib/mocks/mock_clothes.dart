import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';

/// Acervo Mockado de Peças Recortadas em PNG (Canal Alfa Transparente)
/// Curadoria Editorial do Guarda-Roupa HarmonIA
final List<ClothingItem> mockClothes = [
  const ClothingItem(
    id: 'item-1',
    name: 'Blazer Desestruturado em Linho',
    category: 'Partes de cima',
    dominantColor: AppColors.accentTerracotta,
    labColorSpace: 'L* 58.4, a* 28.2, b* 24.1',
    usageRate: 18,
    imageUrl:
        'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop&q=80',
    brandOrProvenance: 'Ateliê Sustentável • Linho Puro',
    isConsciousFashion: true,
    consciousNote: '100% Linho Orgânico',
    iheScore: 92,
  ),
  const ClothingItem(
    id: 'item-2',
    name: 'Camisa Regata Seda Areia',
    category: 'Partes de cima',
    dominantColor: AppColors.accentSand,
    labColorSpace: 'L* 82.1, a* 4.3, b* 11.8',
    usageRate: 24,
    imageUrl:
        'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800&auto=format&fit=crop&q=80',
    brandOrProvenance: 'Brechó Vintage Paulistano',
    isConsciousFashion: true,
    consciousNote: 'Segunda Mão Certificada',
    iheScore: 88,
  ),
  const ClothingItem(
    id: 'item-3',
    name: 'Pantalona Flutuante Off-White',
    category: 'Partes de baixo',
    dominantColor: AppColors.surfaceRaised,
    labColorSpace: 'L* 94.0, a* 1.2, b* 3.5',
    usageRate: 15,
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&auto=format&fit=crop&q=80',
    brandOrProvenance: 'Alfaiataria Botânica',
    isConsciousFashion: true,
    consciousNote: 'Algodão Agroecológico',
    iheScore: 95,
  ),
  const ClothingItem(
    id: 'item-4',
    name: 'Sobrecamisa Sarja Verde Oliva',
    category: 'Partes de cima',
    dominantColor: AppColors.accentOlive,
    labColorSpace: 'L* 38.6, a* -12.4, b* 14.8',
    usageRate: 31,
    imageUrl:
        'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800&auto=format&fit=crop&q=80',
    brandOrProvenance: 'Acervo Circular • 28 usos',
    isConsciousFashion: true,
    consciousNote: 'Cânhamo Sustentável',
    iheScore: 85,
  ),
  const ClothingItem(
    id: 'item-5',
    name: 'Calça Alfaiataria Carvão Lã Fria',
    category: 'Partes de baixo',
    dominantColor: AppColors.textPrimary,
    labColorSpace: 'L* 14.2, a* 0.5, b* -0.8',
    usageRate: 29,
    imageUrl:
        'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=800&auto=format&fit=crop&q=80',
    brandOrProvenance: 'Sob Medida • 5 anos de acervo',
    isConsciousFashion: false,
    iheScore: 78,
  ),
  const ClothingItem(
    id: 'item-6',
    name: 'Moccasin Couro Amaciado Carvão',
    category: 'Calçados',
    dominantColor: AppColors.textSecondary,
    labColorSpace: 'L* 45.3, a* 6.1, b* 12.0',
    usageRate: 42,
    imageUrl:
        'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800&auto=format&fit=crop&q=80',
    brandOrProvenance: 'Manufatura Artesanal Local',
    isConsciousFashion: true,
    consciousNote: 'Couro Vegetal Curtido',
    iheScore: 89,
  ),
  const ClothingItem(
    id: 'item-7',
    name: 'Trench Coat Terracota Editorial',
    category: 'Ocasião',
    dominantColor: AppColors.accentTerracotta,
    labColorSpace: 'L* 48.7, a* 32.1, b* 27.4',
    usageRate: 9,
    imageUrl:
        'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&auto=format&fit=crop&q=80',
    brandOrProvenance: 'Edição Limitada Ateliê',
    isConsciousFashion: true,
    consciousNote: 'Tingimento Botânico a Seco',
    iheScore: 94,
  ),
  const ClothingItem(
    id: 'item-8',
    name: 'Loafer Minimalista Marfim',
    category: 'Calçados',
    dominantColor: AppColors.surfaceSubtle,
    labColorSpace: 'L* 91.2, a* 2.1, b* 6.7',
    usageRate: 20,
    imageUrl:
        'https://images.unsplash.com/photo-1560343776-97e7d202ff0e?w=800&auto=format&fit=crop&q=80',
    brandOrProvenance: 'Design Autoral Nacional',
    isConsciousFashion: true,
    consciousNote: 'Solado Reciclado ESG',
    iheScore: 86,
  ),
];
