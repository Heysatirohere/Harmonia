import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/community_post.dart';

class EditorialFeedCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onSaveToggle;
=======
import '../../models/community_post.dart';
import '../feed/widgets/community_feed_card.dart';

export '../feed/widgets/community_feed_card.dart';

/// Facade / Widget EditorialFeedCard conforme especificação do escopo
class EditorialFeedCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onApplaud;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onTapAuthor;
>>>>>>> feat/social-feed-rf14-rf15

  const EditorialFeedCard({
    super.key,
    required this.post,
<<<<<<< HEAD
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

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceRaised,
                  child: Text(
                    post.authorName[0],
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _buildBadge(post.authorBiotype),
                          const SizedBox(width: 6),
                          _buildBadge(post.authorColorPalette),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGold, width: 0.6),
                  ),
                  child: Text(
                    '✦ ${post.iheScore.toStringAsFixed(1)}%',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.iheGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Editorial Photo Container with Hotspots
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      post.outfitImageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceRaised,
                          child: const Center(
                            child: Icon(Icons.style_outlined, color: AppColors.iheGold, size: 48),
                          ),
                        );
                      },
                    ),
                  ),

                  // Hotspots overlay
                  ...post.garmentHotspots.map((hotspot) {
                    final isSelected = _selectedHotspot == hotspot;
                    return Positioned(
                      left: hotspot.xRatio * 300,
                      top: hotspot.yRatio * 400,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedHotspot = isSelected ? null : hotspot;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentTerracotta
                                : Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.iheGold,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: isSelected ? Colors.white : AppColors.accentTerracotta,
                          ),
                        ),
                      ),
                    );
                  }),

                  // Expanded Hotspot Info Chip
                  if (_selectedHotspot != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCanvas.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGold, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Color(int.parse(_selectedHotspot!.colorHex.replaceAll('#', '0xFF'))),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedHotspot!.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedHotspot!.brand} • ${_selectedHotspot!.fabric}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                              onPressed: () => setState(() => _selectedHotspot = null),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Actions & Caption
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onLikeToggle?.call();
                      },
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: post.isLiked ? AppColors.accentTerracotta : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likeCount}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSaveToggle?.call();
                      },
                      child: Icon(
                        post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                        color: post.isSaved ? AppColors.accentTerracotta : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      post.isPublic ? 'PÚBLICO' : 'PRIVADO',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post.outfitTitle,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: post.tags.map((t) => Text(
                    '#$t',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
=======
    this.onApplaud,
    this.onSave,
    this.onShare,
    this.onTapAuthor,
  });

  @override
  Widget build(BuildContext context) {
    return CommunityFeedCard(
      post: post,
      onApplaud: onApplaud,
      onSave: onSave,
      onShare: onShare,
      onTapAuthor: onTapAuthor,
>>>>>>> feat/social-feed-rf14-rf15
    );
  }
}
