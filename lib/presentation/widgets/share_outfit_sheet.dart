import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
<<<<<<< HEAD

class ShareOutfitSheet extends StatefulWidget {
  final VoidCallback? onPublish;
=======
import '../../models/community_post.dart';

/// Bottom Sheet Elegante de Compartilhamento de Look (RF14 & RN05)
///
/// Permite simular a publicação de uma combinação de look com nota editorial
/// e chave de alternância de privacidade ("Público" vs "Privado").
class ShareOutfitSheet extends StatefulWidget {
  final ValueChanged<CommunityPost>? onPublish;
>>>>>>> feat/social-feed-rf14-rf15

  const ShareOutfitSheet({
    super.key,
    this.onPublish,
  });

<<<<<<< HEAD
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
=======
  static Future<CommunityPost?> show(
    BuildContext context, {
    ValueChanged<CommunityPost>? onPublish,
  }) {
    return showModalBottomSheet<CommunityPost>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
>>>>>>> feat/social-feed-rf14-rf15
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
<<<<<<< HEAD
        child: const ShareOutfitSheet(),
=======
        child: ShareOutfitSheet(
          onPublish: (post) {
            onPublish?.call(post);
            Navigator.of(ctx).pop(post);
          },
        ),
>>>>>>> feat/social-feed-rf14-rf15
      ),
    );
  }

  @override
  State<ShareOutfitSheet> createState() => _ShareOutfitSheetState();
}

class _ShareOutfitSheetState extends State<ShareOutfitSheet> {
<<<<<<< HEAD
  final TextEditingController _captionController = TextEditingController();
  bool _isPublic = true;

  @override
  void dispose() {
    _captionController.dispose();
=======
  final TextEditingController _legendController = TextEditingController();
  final TextEditingController _titleController = TextEditingController(
    text: 'Sobreposição Linho Cru & Terracota',
  );

  bool _isPublic = true; // RN05: Padrão Público
  String _selectedBodyType = 'Ampulheta';
  String _selectedPalette = 'Outono Suave';
  String _selectedOccasion = 'Trabalho & Ateliê';

  @override
  void dispose() {
    _legendController.dispose();
    _titleController.dispose();
>>>>>>> feat/social-feed-rf14-rf15
    super.dispose();
  }

  void _handlePublish() {
<<<<<<< HEAD
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
=======
    if (_titleController.text.trim().isEmpty) return;

    HapticFeedback.mediumImpact();

    final newPost = CommunityPost(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      author: const PostAuthor(
        id: 'user-me',
        name: 'Helena Vasconcelos',
        handle: '@helenav',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        styleArchetype: 'Curadoria Pessoal',
        isVerifiedCurator: true,
      ),
      title: _titleController.text.trim(),
      editorialDescription: _legendController.text.trim().isNotEmpty
          ? _legendController.text.trim()
          : 'Composição editorial publicada via Provador HarmonIA.',
      imageUrl:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=900&auto=format&fit=crop&q=80',
      publishedAtAgo: 'Agora',
      appreciationCount: 1,
      savesCount: 0,
      isApplauded: true,
      bodyType: _selectedBodyType,
      colorPalette: _selectedPalette,
      occasionTag: _selectedOccasion,
      isPublic: _isPublic, // RN05
      ihe: const IheBreakdown(
        overallScore: 88,
        sColor: 0.90,
        sBio: 0.86,
        sOcasion: 0.85,
        sCos: 0.89,
        dominantColor: AppColors.accentTerracotta,
        paletteColors: [
          Color(0xFFA34836),
          Color(0xFFD9CDBF),
          Color(0xFF4B5842),
        ],
        occasionContext: 'Curadoria de Estilo • 23°C',
      ),
      garments: const [],
    );

    widget.onPublish?.call(newPost);
>>>>>>> feat/social-feed-rf14-rf15
  }

  @override
  Widget build(BuildContext context) {
    return Container(
<<<<<<< HEAD
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
=======
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderGold, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Puxador Indicador Minimalista
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

            const SizedBox(height: 16),

            // Título da BottomSheet
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPARTILHAR INSPIRAÇÃO',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.accentTerracotta,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Publicar Look no Feed',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 1. CHAVE DE PRIVACIDADE (RN05)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPublic
                        ? Icons.public_rounded
                        : Icons.lock_outline_rounded,
                    color: _isPublic
                        ? AppColors.accentOlive
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPublic
                              ? 'Visibilidade Pública'
                              : 'Visibilidade Privada',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _isPublic
                              ? 'Visível para toda a comunidade de estilo.'
                              : 'Armazenado no seu acervo pessoal (RN05).',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isPublic,
                    activeTrackColor: AppColors.accentOlive,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _isPublic = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. CAMPO: TÍTULO DO LOOK
            Text(
              'TÍTULO DO LOOK',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceRaised,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.borderSubtle, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.borderSubtle, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.iheGold, width: 1.2),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. CAMPO: NOTA EDITORIAL / LEGENDA
            Text(
              'NOTA EDITORIAL / LEGENDA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _legendController,
              maxLines: 3,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:
                    'Descreva a intenção estilística, ocasião ou sensações do look...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: AppColors.surfaceRaised,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.borderSubtle, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.borderSubtle, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.iheGold, width: 1.2),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 4. METADADOS: BIÓTIPO & CARTELA
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BIÓTIPO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBodyType,
                        dropdownColor: AppColors.surfaceRaised,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: AppColors.surfaceRaised,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.borderSubtle, width: 0.8),
                          ),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5, color: AppColors.textPrimary),
                        items: ['Ampulheta', 'Retângulo', 'Triângulo Invertido']
                            .map((bt) =>
                                DropdownMenuItem(value: bt, child: Text(bt)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBodyType = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARTELA SAZONAL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPalette,
                        dropdownColor: AppColors.surfaceRaised,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: AppColors.surfaceRaised,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.borderSubtle, width: 0.8),
                          ),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5, color: AppColors.textPrimary),
                        items: ['Outono Suave', 'Outono Quente', 'Inverno Frio']
                            .map((cp) =>
                                DropdownMenuItem(value: cp, child: Text(cp)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPalette = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 5. BOTÃO DE ENVIO PRIMÁRIO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handlePublish,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isPublic
                      ? 'Publicar no Feed Comunitário'
                      : 'Salvar no Acervo Privado',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTerracotta,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
>>>>>>> feat/social-feed-rf14-rf15
      ),
    );
  }
}
