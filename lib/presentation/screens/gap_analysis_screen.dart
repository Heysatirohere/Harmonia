import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../mocks/mock_gap_analysis.dart';
import '../widgets/gap_analysis_sheet.dart';

class GapAnalysisScreen extends StatelessWidget {
  const GapAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gaps = MockGapAnalysis.gaps;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCanvas,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Otimização de Acervo',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'ANÁLISE DE LACUNAS & AFILIAÇÃO (RF11/RF12)',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: gaps.length,
        itemBuilder: (context, index) {
          final gap = gaps[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle, width: 0.8),
            ),
            child: GapAnalysisSheet(gap: gap),
          );
        },
      ),
    );
  }
}
