import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/community_post.dart';
import '../../theme/app_theme.dart';

/// Post do "Editorial Gallery" direto sobre a tapeçaria noir (AGENTS.md 7.4):
/// foto de página inteira, hotspots em anel dourado e ficha da peça em papel.
class EditorialFeedCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onSaveToggle;

  const EditorialFeedCard({
    super.key,
    required this.post,
    this.onLikeToggle,
    this.onSaveToggle,
  });

  @override
  State<EditorialFeedCard> createState() => _EditorialFeedCardState();
}

class _EditorialFeedCardState extends State<EditorialFeedCard> {
  GarmentHotspot? _selectedHotspot;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Padding(
      padding: const EdgeInsets.only(bottom: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Autor
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.hairlineGold, width: 1.0),
                ),
                child: Text(
                  post.authorName[0],
                  style: AppTypography.displayEditorial(color: AppColors.ivoryText).copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: AppTypography.uiHeadline(color: AppColors.ivoryText)),
                    const SizedBox(height: 2),
                    Text(
                      '${post.authorBiotype} • ${post.authorColorPalette}'.toUpperCase(),
                      style: AppTypography.atelierMeta().copyWith(fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '✦ ${post.iheScore.toStringAsFixed(1)}%',
                style: AppTypography.displayEditorial(color: AppColors.gildedLeaf).copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Foto editorial com hotspots (posições relativas ao tamanho real da foto)
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        post.outfitImageUrl,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        cacheWidth: (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).round(),
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0x14F4EEE1),
                          child: const Center(
                            child: Icon(Icons.style_outlined, color: AppColors.gildedLeaf, size: 44),
                          ),
                        ),
                      ),
                    ),
                    for (final hotspot in post.garmentHotspots)
                      Positioned(
                        left: hotspot.xRatio * constraints.maxWidth - 14,
                        top: hotspot.yRatio * constraints.maxHeight - 14,
                        child: _HotspotRing(
                          selected: _selectedHotspot == hotspot,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedHotspot = _selectedHotspot == hotspot ? null : hotspot;
                            });
                          },
                        ),
                      ),
                    if (_selectedHotspot != null)
                      Positioned(
                        bottom: 14,
                        left: 14,
                        right: 14,
                        child: _HotspotSheet(
                          hotspot: _selectedHotspot!,
                          onClose: () => setState(() => _selectedHotspot = null),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Título, ações e tags
          Text(
            post.outfitTitle,
            style: AppTypography.displayEditorial(color: AppColors.ivoryText).copyWith(fontSize: 22, height: 1.15),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final tag in post.tags) Text('#$tag', style: AppTypography.bodySmall(color: AppColors.ivoryMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FeedAction(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                active: post.isLiked,
                label: '${post.likeCount}',
                semanticLabel: post.isLiked ? 'Descurtir' : 'Curtir',
                onTap: widget.onLikeToggle,
              ),
              const SizedBox(width: 22),
              _FeedAction(
                icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                active: post.isSaved,
                semanticLabel: post.isSaved ? 'Remover do moodboard' : 'Salvar no moodboard',
                onTap: widget.onSaveToggle,
              ),
              const Spacer(),
              Text(post.isPublic ? 'PÚBLICO' : 'PRIVADO', style: AppTypography.atelierMeta().copyWith(fontSize: 9.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedAction extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String? label;
  final String semanticLabel;
  final VoidCallback? onTap;

  const _FeedAction({
    required this.icon,
    required this.active,
    required this.semanticLabel,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Cinábrio sobre a tapeçaria noir: 3,3:1, suficiente para ícone
    final color = active ? AppColors.accentCinnabar : AppColors.ivoryText;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: AppMotion.theatricalGesture),
                child: child,
              ),
              child: Icon(icon, key: ValueKey(active), size: 22, color: color),
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!, style: AppTypography.uiHeadline(color: AppColors.ivoryText).copyWith(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Anel capilar dourado sobre a peça da foto (AGENTS.md 7.4)
class _HotspotRing extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _HotspotRing({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Detalhes da peça',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.editorialDecel,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.gildedLeaf : AppColors.tapestryNoir.withValues(alpha: 0.35),
            border: Border.all(color: AppColors.gildedLeaf, width: 1.2),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.tapestryNoir : AppColors.gildedLeaf,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ficha da peça em papel sobre a foto: marca, tecido e cor
class _HotspotSheet extends StatelessWidget {
  final GarmentHotspot hotspot;
  final VoidCallback onClose;

  const _HotspotSheet({required this.hotspot, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: AppColors.paperShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Color(int.parse(hotspot.colorHex.replaceAll('#', '0xFF'))),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairlineInk, width: 1.0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hotspot.name, style: AppTypography.uiHeadline(color: AppColors.inkText).copyWith(fontSize: 13.5)),
                Text(
                  '${hotspot.brand} • ${hotspot.fabric}',
                  style: AppTypography.bodySmall(color: AppColors.inkSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            icon: const Icon(Icons.close, size: 16, color: AppColors.inkSecondary),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
