import 'package:flutter/material.dart';
import '../models/outfit_combination.dart';
import 'mock_clothes.dart';

/// Mocks de Combinações de Looks do HarmonIA com Análise do IHE
final List<OutfitCombination> mockOutfits = [
  // Outfit 1: Terracota & Linho Cru
  OutfitCombination(
    id: 'outfit-1',
    title: 'Sobreposições Terracota em Linho Cru',
    editorialNote:
        'Harmonização de contrastes orgânicos para tardes amenas de ateliê. O blazer desestruturado compensa a fluidez da pantalona off-white com silhueta alongada.',
    topItem: mockClothes[0], // Blazer Terracota
    bottomItem: mockClothes[2], // Pantalona Off-White
    footwearItem: mockClothes[7], // Loafer Marfim
    accessoryItem: mockClothes[1], // Regata Seda
    occasion: 'Encontro Criativo & Ateliê',
    ihe: const IheSubScores(
      overallScore: 89,
      sColor: 0.92,
      sBio: 0.88,
      sOcasion: 0.85,
      sCos: 0.91,
      occasionContext: 'Casual Chic • 24°C Ensolarado',
      dominantColor: Color(0xFFA34836),
      paletteColors: [
        Color(0xFFA34836),
        Color(0xFFF3EFEA),
        Color(0xFFEBE5DC),
        Color(0xFF1A1817),
      ],
    ),
  ),

  // Outfit 2: Alfaiataria Utilitária Oliva & Carvão
  OutfitCombination(
    id: 'outfit-2',
    title: 'Geometrias Botânicas & Lã Fria',
    editorialNote:
        'A sobrecamisa em sarja verde oliva estabelece um ponto focal sóbrio. A transição de proporções equilibra a silhueta para vernissages e eventos culturais noturnos.',
    topItem: mockClothes[3], // Sobrecamisa Oliva
    bottomItem: mockClothes[4], // Calça Carvão
    footwearItem: mockClothes[5], // Moccasin Carvão
    occasion: 'Vernissage & Galeria Noturna',
    ihe: const IheSubScores(
      overallScore: 82,
      sColor: 0.85,
      sBio: 0.81,
      sOcasion: 0.80,
      sCos: 0.84,
      occasionContext: 'Vernissage & Galeria • 19°C Mild',
      dominantColor: Color(0xFF4B5842),
      paletteColors: [
        Color(0xFF4B5842),
        Color(0xFF1A1817),
        Color(0xFF706B65),
        Color(0xFFB88E3E),
      ],
    ),
  ),

  // Outfit 3: Trench Coat Editorial & Off-White
  OutfitCombination(
    id: 'outfit-3',
    title: 'Monocromia Quente & Trench Ateliê',
    editorialNote:
        'Composição de altíssima ressonância morfocromática. O corte estruturado do trench coat cria linhas verticais limpas com o caimento da pantalona agroecológica.',
    topItem: mockClothes[6], // Trench Coat Terracota
    bottomItem: mockClothes[2], // Pantalona Off-White
    footwearItem: mockClothes[7], // Loafer Marfim
    occasion: 'Almoço de Negócios & Reunião',
    ihe: const IheSubScores(
      overallScore: 94,
      sColor: 0.96,
      sBio: 0.92,
      sOcasion: 0.90,
      sCos: 0.95,
      occasionContext: 'Almoço de Negócios • 22°C Agradável',
      dominantColor: Color(0xFFA34836),
      paletteColors: [
        Color(0xFFA34836),
        Color(0xFFF3EFEA),
        Color(0xFFB88E3E),
        Color(0xFFD9CDBF),
      ],
    ),
  ),
];
