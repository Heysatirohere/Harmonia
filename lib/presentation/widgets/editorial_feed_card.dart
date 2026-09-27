import 'package:flutter/material.dart';
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

  const EditorialFeedCard({
    super.key,
    required this.post,
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
    );
  }
}
