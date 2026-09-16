import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/community_post.dart';
import 'garment_hotspots_layer.dart';
import 'ihe_chancery_badge.dart';
import 'palette_ribbon.dart';

/// Componente Oficial: Card do Feed Comunitário ("Editorial Frame")
/// Conforme diretrizes estritas do AGENTS.md:
/// - Tolerância zero a Material Design genérico / botões azuis / cards pré-moldados.
/// - Curadoria editorial de moda (lookbook, minimalismo quente, tipografia com peso e contraste).
/// - Hotspots circulares interativos sobre as peças com resposta tátil (HapticFeedback).
/// - Badge de IHE com chancela joalheira e selo '✦ Look Fortemente Recomendado' para pontuação >= 75%.
/// - Exibição da paleta cromática CIE L*a*b* e notas de consumo consciente (ESG).
class CommunityFeedCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback? onApplaud;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onTapAuthor;

  const CommunityFeedCard({
    super.key,
    required this.post,
    this.onApplaud,
    this.onSave,
    this.onShare,
    this.onTapAuthor,
  });

  @override
  State<CommunityFeedCard> createState() => _CommunityFeedCardState();
}

class _CommunityFeedCardState extends State<CommunityFeedCard> {
  bool _showHotspots = true;
  late bool _isApplauded;
  late int _appreciationCount;
  late bool _isSaved;
  late int _savesCount;

  @override
  void initState() {
    super.initState();
    _isApplauded = widget.post.isApplauded;
    _appreciationCount = widget.post.appreciationCount;
    _isSaved = widget.post.isSaved;
    _savesCount = widget.post.savesCount;
  }

  void _handleApplaud() {
    HapticFeedback.lightImpact();
    setState(() {
      _isApplauded = !_isApplauded;
      _appreciationCount += _isApplauded ? 1 : -1;
    });
    widget.onApplaud?.call();
  }

  void _handleSave() {
    HapticFeedback.selectionClick();
    setState(() {
      _isSaved = !_isSaved;
      _savesCount += _isSaved ? 1 : -1;
    });
    widget.onSave?.call();
  }

  void _toggleHotspots() {
    HapticFeedback.lightImpact();
    setState(() {
      _showHotspots = !_showHotspots;
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
        boxShadow: AppColors.editorialShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho Editorial do Autor
          _buildAuthorHeader(post.author, post.publishedAtAgo),

          // 2. Canvas Editorial do Look (Fotografia / Lookbook + Hotspots + IHE)
          _buildLookbookCanvas(post),

          // 3. Ribbon de Paleta Cromática e Contexto
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: PaletteRibbon(
              colors: post.ihe.paletteColors,
              occasionContext: post.ihe.occasionContext,
            ),
          ),

          // 4. Detalhes do Look (Título, Descrição e Selo IHE)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.ihe.isStronglyRecommended) ...[
                  Row(
                    children: [
                      const Text(
                        '✦',
                        style: TextStyle(
                          color: AppColors.iheGold,
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'LOOK FORTEMENTE RECOMENDADO',
                        style: AppTypography.sealLabel().copyWith(
                          fontSize: 10.5,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                Text(
                  post.title,
                  style: AppTypography.editorialTitleMedium(),
                ),

                const SizedBox(height: 6),

                Text(
                  post.editorialDescription,
                  style: AppTypography.bodySmall(color: AppColors.textPrimary).copyWith(
                    height: 1.5,
                    color: AppColors.textPrimary.withValues(alpha: 0.88),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 12),

                // 5. Barra de Interações & Curadoria Tátil
                _buildEditorialActionsBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cabeçalho do Card com autor e arquétipo de estilo
  Widget _buildAuthorHeader(PostAuthor author, String publishedAgo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onTapAuthor,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentSand, width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  author.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceCanvas,
                    child: Center(
                      child: Text(
                        author.name.substring(0, 1).toUpperCase(),
                        style: AppTypography.editorialTitleSmall(
                          color: AppColors.accentTerracotta,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: widget.onTapAuthor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          author.name,
                          style: AppTypography.authorName(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (author.isVerifiedCurator) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: AppColors.iheGold,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${author.styleArchetype} • $publishedAgo',
                    style: AppTypography.metaLabel(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            splashRadius: 20,
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onShare?.call();
            },
          ),
        ],
      ),
    );
  }

  /// Canvas principal do lookbook com proporção editorial 4:5
  Widget _buildLookbookCanvas(CommunityPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 4 / 5, // Proporção editorial clássica
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagem fotográfica do look
              Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.surfaceCanvas,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentSand),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceCanvas,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 36,
                          color: AppColors.accentSand,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Editorial Lookbook',
                          style: AppTypography.metaLabel(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Efeito de vinheta sutil no topo para contraste da chancela
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Hotspots circulares interativos sobrepostos
              GarmentHotspotsLayer(
                garments: post.garments,
                isVisible: _showHotspots,
              ),

              // Chancela Joalheria do IHE no topo direito
              Positioned(
                top: 14,
                right: 14,
                child: IheChanceryBadge(ihe: post.ihe),
              ),

              // Botão sutil para alternar visualização de peças da arara (canto inferior esquerdo)
              Positioned(
                bottom: 12,
                left: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleHotspots,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCanvas.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showHotspots
                                ? Icons.scatter_plot_rounded
                                : Icons.scatter_plot_outlined,
                            size: 14,
                            color: _showHotspots
                                ? AppColors.accentTerracotta
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _showHotspots
                                ? '${post.garments.length} Peças'
                                : 'Ver Peças',
                            style: AppTypography.metaLabel().copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _showHotspots
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra de Ações do Card (Apreciação, Salvar no Moodboard, Compartilhar)
  Widget _buildEditorialActionsBar() {
    return Row(
      children: [
        // Apreciação Editorial (Coração / Curadoria)
        InkWell(
          onTap: _handleApplaud,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isApplauded ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: _isApplauded
                      ? AppColors.accentTerracotta
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_appreciationCount',
                  style: AppTypography.metaLabel(
                    color: _isApplauded
                        ? AppColors.accentTerracotta
                        : AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Salvar no Acervo / Moodboard
        InkWell(
          onTap: _handleSave,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 20,
                  color: _isSaved ? AppColors.iheGold : AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_savesCount',
                  style: AppTypography.metaLabel(
                    color: _isSaved ? AppColors.iheGold : AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Compartilhar Editorial
        IconButton(
          icon: const Icon(
            Icons.ios_share_rounded,
            size: 19,
            color: AppColors.textSecondary,
          ),
          splashRadius: 20,
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onShare?.call();
          },
        ),
      ],
    );
  }
}
