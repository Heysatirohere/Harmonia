import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class ShareOutfitSheet extends StatefulWidget {
  final VoidCallback? onPublish;

  const ShareOutfitSheet({
    super.key,
    this.onPublish,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const ShareOutfitSheet(),
      ),
    );
  }

  @override
  State<ShareOutfitSheet> createState() => _ShareOutfitSheetState();
}

class _ShareOutfitSheetState extends State<ShareOutfitSheet> {
  final TextEditingController _captionController = TextEditingController();
  bool _isPublic = true;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _handlePublish() {
    HapticFeedback.mediumImpact();
    widget.onPublish?.call();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        content: Text(
          _isPublic
              ? 'Inspiração publicada na comunidade HarmonIA!'
              : 'Look salvo privadamente em seus rascunhos.',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Compartilhar Inspiração',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Insira uma nota editorial sobre a combinação para a comunidade.',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 20),

          // Caption Input
          TextField(
            controller: _captionController,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Ex: "Combinação leve de alfaiataria em linho para tardes quentes..."',
              hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12.5),
              filled: true,
              fillColor: AppColors.surfaceRaised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.iheGold),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Privacy Selector (RN05)
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacidade da Publicação (RN05)',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _isPublic
                        ? 'Visível para toda a comunidade'
                        : 'Privado (apenas no seu acervo)',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Switch.adaptive(
                value: _isPublic,
                activeColor: AppColors.accentTerracotta,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isPublic = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Publish Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handlePublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTerracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Publicar Inspiração',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
