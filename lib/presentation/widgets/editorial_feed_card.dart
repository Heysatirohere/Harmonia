import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/community_post.dart';
import '../../theme/app_theme.dart';

/// Post do "Editorial Gallery" direto sobre a tapeçaria noir (AGENTS.md 7.4):
/// foto de página inteira, legenda em Bodoni e, quando o post vem de um look aprovado,
/// as peças do acervo numa folha de papel.
class EditorialFeedCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onSaveToggle;
  final VoidCallback? onDelete;

  const EditorialFeedCard({
    super.key,
    required this.post,
    this.onLikeToggle,
    this.onSaveToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ihe = post.ihePercentage;

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
                  post.authorName.characters.first.toUpperCase(),
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
                      [post.authorTraits, _timeAgo(post.createdAt)].where((t) => t.isNotEmpty).join(' • ').toUpperCase(),
                      style: AppTypography.atelierMeta().copyWith(fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (ihe != null)
                Text(
                  post.isStronglyRecommended ? '✦ ${ihe.toStringAsFixed(0)}%' : '${ihe.toStringAsFixed(0)}%',
                  style: AppTypography.displayEditorial(
                    color: post.isStronglyRecommended ? AppColors.gildedLeaf : AppColors.ivoryText,
                  ).copyWith(fontSize: 18),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Foto editorial do look vestido
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              child: LayoutBuilder(
                builder: (context, constraints) => Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
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
            ),
          ),

          if (post.pieces.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PiecesStrip(pieces: post.pieces),
          ],

          const SizedBox(height: 14),

          // Legenda, ocasião, tags e ações
          Text(
            post.caption,
            style: AppTypography.displayEditorial(color: AppColors.ivoryText).copyWith(fontSize: 22, height: 1.15),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              Text(post.occasionLabel, style: AppTypography.bodySmall(color: AppColors.ivoryText)),
              for (final tag in post.styleTags) Text('#$tag', style: AppTypography.bodySmall(color: AppColors.ivoryMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FeedAction(
                icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                active: post.likedByMe,
                label: '${post.likeCount}',
                semanticLabel: post.likedByMe ? 'Descurtir' : 'Curtir',
                onTap: onLikeToggle,
              ),
              const SizedBox(width: 22),
              _FeedAction(
                icon: post.savedByMe ? Icons.bookmark : Icons.bookmark_border,
                active: post.savedByMe,
                semanticLabel: post.savedByMe ? 'Remover do moodboard' : 'Salvar no moodboard',
                onTap: onSaveToggle,
              ),
              const Spacer(),
              if (post.isMine) ...[
                Text(post.isPublic ? 'PÚBLICO' : 'PRIVADO', style: AppTypography.atelierMeta().copyWith(fontSize: 9.5)),
                if (onDelete != null) ...[
                  const SizedBox(width: 14),
                  _FeedAction(
                    icon: Icons.delete_outline,
                    active: false,
                    semanticLabel: 'Apagar publicação',
                    onTap: onDelete,
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime createdAt) {
    final elapsed = DateTime.now().difference(createdAt);
    if (elapsed.inMinutes < 1) return 'agora';
    if (elapsed.inHours < 1) return 'há ${elapsed.inMinutes} min';
    if (elapsed.inDays < 1) return 'há ${elapsed.inHours} h';
    if (elapsed.inDays < 30) return 'há ${elapsed.inDays} d';
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
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

/// Peças do look aprovado: amostras de cor em anel dourado; o toque abre a ficha em papel
class _PiecesStrip extends StatelessWidget {
  final List<PostPiece> pieces;

  const _PiecesStrip({required this.pieces});

  @override
  Widget build(BuildContext context) {
    final label = '${pieces.length} ${pieces.length == 1 ? 'peça do acervo' : 'peças do acervo'}';
    return Semantics(
      button: true,
      label: 'Ver $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => _PiecesSheet(pieces: pieces),
          );
        },
        child: Row(
          children: [
            for (final piece in pieces)
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: piece.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gildedLeaf, width: 1.0),
                ),
              ),
            const SizedBox(width: 6),
            Text(label.toUpperCase(), style: AppTypography.atelierMeta().copyWith(fontSize: 9.5)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.ivoryMuted),
          ],
        ),
      ),
    );
  }
}

/// Folha de papel com as peças recortadas do look: categoria, nome e cor L*a*b* (AGENTS.md 7.4, 7.5)
class _PiecesSheet extends StatelessWidget {
  final List<PostPiece> pieces;

  const _PiecesSheet({required this.pieces});

  @override
  Widget build(BuildContext context) {
    final cacheWidth = (64 * MediaQuery.devicePixelRatioOf(context)).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageMargin, 16, AppSpacing.pageMargin, 28),
      decoration: const BoxDecoration(
        color: AppColors.paperBone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.hairlineInk, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text('COMPOSIÇÃO DO LOOK', style: AppTypography.metadataBadge(color: AppColors.inkSecondary)),
            const SizedBox(height: 12),
            for (final piece in pieces)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Image.network(
                        piece.imageUrl,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        cacheWidth: cacheWidth,
                        errorBuilder: (_, _, _) => const Icon(Icons.checkroom, color: AppColors.inkSecondary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(piece.name, style: AppTypography.uiHeadline(color: AppColors.inkText)),
                          const SizedBox(height: 2),
                          Text(piece.category, style: AppTypography.bodySmall(color: AppColors.inkSecondary)),
                          const SizedBox(height: 2),
                          Text(piece.labLabel, style: AppTypography.bodySmall(color: AppColors.inkSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: piece.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.hairlineInk, width: 1.0),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
