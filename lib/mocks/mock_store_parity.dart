import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/store_parity_result.dart';
import 'mock_clothes.dart';

/// Mocks de Análise de Paridade do Provador conforme RF08 / RF09
class MockStoreParity {
  MockStoreParity._();

  /// Cenário Principal: Blazer Linho Terracota (Lojas Renner)
  static StoreParityResult get blazerTerracotaRenner {
    final closet = MockClothes.items;

    return StoreParityResult(
      storeGarment: const StoreGarment(
        id: 'store_01',
        title: 'Blazer Linho Terracota',
        storeName: 'Lojas Renner',
        price: 299.90,
        category: 'ALFAIATARIA (SUPERIOR)',
        dominantColor: AppColors.accentTerracotta,
        tag: 'Coleção Outono Sustentável',
      ),
      overallParityScore: 0.86, // 86% de compatibilidade global
      editorialSummary:
          'Esta peça em terracota se conecta harmoniosamente à sua cartela Outono Suave, destravando até 4 novas coordenações completas com peças do seu acervo.',
      compatibleMatches: [
        ParityMatchItem(
          closetItem: closet[0], // Pantalona Ampla Off-White
          parityScore: 0.94,
          chromaticScore: 0.96,
          morphologicalScore: 0.92,
          matchReason:
              'Contraste aquecido perfeito entre o terracota e a base off-white.',
        ),
        ParityMatchItem(
          closetItem: closet[1], // Regata Seda Areia
          parityScore: 0.91,
          chromaticScore: 0.93,
          morphologicalScore: 0.89,
          matchReason:
              'Texturas nobres complementares de seda e linho natural.',
        ),
        ParityMatchItem(
          closetItem: closet[4], // Mocassim Couro Caramelo
          parityScore: 0.88,
          chromaticScore: 0.90,
          morphologicalScore: 0.86,
          matchReason:
              'Ressonância tonal refinada na mesma família de terrosos.',
        ),
        ParityMatchItem(
          closetItem: closet[2], // Saia Mídia Plissada Oliva
          parityScore: 0.82,
          chromaticScore: 0.85,
          morphologicalScore: 0.79,
          matchReason:
              'Harmonia complementar orgânica entre terracota e verde oliva.',
        ),
      ],
    );
  }

  /// Cenário Secundário: Calça Alfaiataria Areia (C&A)
  static StoreParityResult get calcaAreiaCA {
    final closet = MockClothes.items;

    return StoreParityResult(
      storeGarment: const StoreGarment(
        id: 'store_02',
        title: 'Calça Alfaiataria Areia',
        storeName: 'C&A Modas',
        price: 199.90,
        category: 'ALFAIATARIA (INFERIOR)',
        dominantColor: AppColors.accentSand,
        tag: 'Algodão & Viscose',
      ),
      overallParityScore: 0.89,
      editorialSummary:
          'Excelente peça curinga de base neutra que dialoga nativamente com todas as suas opções superiores.',
      compatibleMatches: [
        ParityMatchItem(
          closetItem: closet[3], // Camisa Alfaiataria Creme
          parityScore: 0.95,
          chromaticScore: 0.97,
          morphologicalScore: 0.93,
          matchReason: 'Monocromia minimalista de altíssima elegância.',
        ),
        ParityMatchItem(
          closetItem: closet[1], // Regata Seda Areia
          parityScore: 0.90,
          chromaticScore: 0.92,
          morphologicalScore: 0.88,
          matchReason: 'Continuidade de silhueta e fluidez visual.',
        ),
      ],
    );
  }
}
