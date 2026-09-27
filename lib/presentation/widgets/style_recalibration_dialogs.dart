import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class StyleRecalibrationDialogs {
  static void showColorimetryRecalibration(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCanvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderGold, width: 0.8),
        ),
        title: Text(
          'Recalibrar Colorimetria',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Deseja reabrir o teste de iluminação assistida via câmera selfie para reavaliar sua cartela cromática pessoal no espaço CIE Lab*?',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.textPrimary,
                  content: Text(
                    'Teste de colorimetria via selfie iniciado...',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTerracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Iniciar Selfie Test', style: GoogleFonts.plusJakartaSans()),
          ),
        ],
      ),
    );
  }

  static void showBodyTypeAdjustment(BuildContext context, {required ValueChanged<String> onSelected}) {
    HapticFeedback.lightImpact();
    final silhouettes = [
      'Ampulheta',
      'Triângulo Invertido',
      'Retângulo',
      'Pera / Triângulo',
      'Oval',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceCanvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.borderGold, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ajustar Biótipo Corporal',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecione a silhueta que melhor representa suas proporções atuais.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 16),
            ...silhouettes.map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.accessibility_new, color: AppColors.iheGold),
                  title: Text(
                    s,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(s);
                    Navigator.of(ctx).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }
}
