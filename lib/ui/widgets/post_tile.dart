import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:sint/sint.dart';

/// Enhanced Instagram/TikTok-style post tile for grid view.
/// Features:
/// - Hover/press effect with slight scale
/// - Video indicator for video posts
/// - Multiple image indicator (carousel)
/// - Likes count overlay
/// - Long press preview
class PostTile extends StatefulWidget {
  final Post post;
  final Event? event;
  final bool showStats;
  final VoidCallback? onLongPress;

  const PostTile(
    this.post,
    this.event, {
    this.showStats = true,
    this.onLongPress,
    super.key,
  });

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    if (widget.post.type == PostType.releaseItem && widget.post.referenceId.isNotEmpty) {
      Sint.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [widget.post.referenceId]);
    } else {
      Sint.toNamed(AppRouteConstants.postDetailsFullScreen, arguments: [widget.post]);
    }
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    if (widget.onLongPress != null) {
      widget.onLongPress!();
    } else {
      _showQuickPreview();
    }
  }

  void _showQuickPreview() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _QuickPreviewDialog(post: widget.post, event: widget.event),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Main image/thumbnail
                _buildThumbnail(),

                // Gradient overlay for stats
                if (widget.showStats && widget.post.likedProfiles.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                // Post type indicator (video, carousel)
                if (widget.post.type == PostType.video)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: _VideoIndicator(),
                  ),

                // Event indicator
                if (widget.post.type == PostType.event && widget.event != null)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: _EventIndicator(),
                  ),

                // Release item indicator
                if (widget.post.type == PostType.releaseItem)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: _ReleaseIndicator(),
                  ),

                // Stats overlay (likes)
                if (widget.showStats && widget.post.likedProfiles.isNotEmpty)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: _StatsOverlay(
                      likes: widget.post.likedProfiles.length,
                      comments: widget.post.commentIds.length,
                    ),
                  ),

                // Private indicator
                if (widget.post.isPrivate)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    String imageUrl;

    switch (widget.post.type) {
      case PostType.image:
        imageUrl = widget.post.mediaUrl;
        break;
      case PostType.video:
        imageUrl = widget.post.thumbnailUrl.isNotEmpty
            ? widget.post.thumbnailUrl
            : widget.post.mediaUrl;
        break;
      case PostType.event:
        imageUrl = widget.event?.imgUrl ?? AppProperties.getNoImageUrl();
        break;
      default:
        imageUrl = widget.post.mediaUrl.isNotEmpty
            ? widget.post.mediaUrl
            : AppProperties.getNoImageUrl();
    }

    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30))),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[900],
          child: const Icon(Icons.broken_image_outlined, color: Colors.white30, size: 32),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white30,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Icon(
          Icons.broken_image_outlined,
          color: Colors.white30,
          size: 32,
        ),
      ),
    );
  }
}

/// Video type indicator icon
class _VideoIndicator extends StatelessWidget {
  const _VideoIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

/// Event type indicator icon
class _EventIndicator extends StatelessWidget {
  const _EventIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.event,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

/// Release item indicator icon with label
class _ReleaseIndicator extends StatelessWidget {
  const _ReleaseIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColor.bondiBlue.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_rounded, size: 12, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'Publicación',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats overlay showing likes and comments
class _StatsOverlay extends StatelessWidget {
  final int likes;
  final int comments;

  const _StatsOverlay({
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (likes > 0) ...[
          const Icon(Icons.favorite, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            _formatCount(likes),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (likes > 0 && comments > 0) const SizedBox(width: 8),
        if (comments > 0) ...[
          const Icon(Icons.chat_bubble, size: 11, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            _formatCount(comments),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Quick preview dialog on long press
class _QuickPreviewDialog extends StatelessWidget {
  final Post post;
  final Event? event;

  const _QuickPreviewDialog({
    required this.post,
    this.event,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final previewSize = screenSize.width * 0.85;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Center(
        child: Container(
          width: previewSize,
          constraints: BoxConstraints(
            maxHeight: screenSize.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with profile info
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: post.profileImgUrl.isNotEmpty
                            ? CachedNetworkImageProvider(post.profileImgUrl)
                            : null,
                        child: post.profileImgUrl.isEmpty
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.profileName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (post.location.isNotEmpty)
                              Text(
                                post.location,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Image preview
                Flexible(
                  child: AspectRatio(
                    aspectRatio: post.aspectRatio > 0 ? post.aspectRatio : 1,
                    child: kIsWeb
                      ? Image.network(
                          _getPreviewUrl(),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(color: Colors.grey[800], child: const Center(child: CircularProgressIndicator(color: Colors.white30)));
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.broken_image, color: Colors.white30, size: 48),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: _getPreviewUrl(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white30,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white30,
                              size: 48,
                            ),
                          ),
                        ),
                  ),
                ),

                // Footer with stats and caption
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      Row(
                        children: [
                          Icon(Icons.favorite,
                              size: 20, color: post.likedProfiles.isNotEmpty ? Colors.red : Colors.white60),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likedProfiles.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentIds.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.send_outlined, size: 18, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text(
                            '${post.sharedProfiles.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),

                      // Caption preview
                      if (post.caption.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          post.caption,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPreviewUrl() {
    switch (post.type) {
      case PostType.image:
        return post.mediaUrl;
      case PostType.video:
        return post.thumbnailUrl.isNotEmpty ? post.thumbnailUrl : post.mediaUrl;
      case PostType.event:
        return event?.imgUrl ?? AppProperties.getNoImageUrl();
      default:
        return post.mediaUrl.isNotEmpty ? post.mediaUrl : AppProperties.getNoImageUrl();
    }
  }
}
