import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:sint/sint.dart';

import '../../app_flavour.dart';
import '../../utils/constants/translations/app_translation_constants.dart';
import '../theme/app_color.dart';
import 'profile_stat_item.dart';

/// A reusable card widget that displays profile statistics with animations.
///
/// Shows an avatar, name, verification badge, and a configurable
/// grid of stats (followers, following, posts, bands, events, etc.)
/// derived from [AppProfile] fields.
///
/// Features:
/// - Animated count-up on load
/// - Haptic feedback on tap
/// - Optional followers/following visibility (hide for mate profiles)
/// - Compact mode for smaller displays
///
/// Usage:
/// ```dart
/// ProfileStatsCard(
///   profile: userProfile,
///   showFollowStats: true, // false for mate profiles
///   onFollowersTap: () => navigateToFollowers(),
///   onFollowingTap: () => navigateToFollowing(),
/// )
/// ```
class ProfileStatsCard extends StatefulWidget {

  final AppProfile profile;
  final bool showAvatar;
  final bool showName;
  final bool compact;
  /// If false, hides followers/following stats (use for mate profiles)
  final bool showFollowStats;
  final List<ProfileStatConfig>? customStats;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onPostsTap;
  final VoidCallback? onBandsTap;
  final VoidCallback? onEventsTap;
  final VoidCallback? onItemsTap;

  const ProfileStatsCard({
    super.key,
    required this.profile,
    this.showAvatar = true,
    this.showName = true,
    this.compact = false,
    this.showFollowStats = true,
    this.customStats,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onPostsTap,
    this.onBandsTap,
    this.onEventsTap,
    this.onItemsTap,
  });

  @override
  State<ProfileStatsCard> createState() => _ProfileStatsCardState();
}

class _ProfileStatsCardState extends State<ProfileStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _countAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.customStats ?? _buildDefaultStats();

    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColor.main25,
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showAvatar || widget.showName) _buildHeader(context),
              if (widget.showAvatar || widget.showName) const SizedBox(height: 16),
              _buildStatsGrid(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (widget.showAvatar) ...[
          CachedNetworkImage(
            imageUrl: widget.profile.photoUrl.isNotEmpty
                ? widget.profile.photoUrl
                : AppProperties.getAppLogoUrl(),
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: widget.compact ? 20 : 28,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => CircleAvatar(
              radius: widget.compact ? 20 : 28,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => CircleAvatar(
              radius: widget.compact ? 20 : 28,
              backgroundImage: CachedNetworkImageProvider(
                AppProperties.getAppLogoUrl(),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (widget.showName)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.profile.name,
                        style: TextStyle(
                          fontSize: widget.compact ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.profile.verificationLevel != VerificationLevel.none) ...[
                      const SizedBox(width: 6),
                      AppFlavour.getVerificationIcon(
                        widget.profile.verificationLevel,
                        size: widget.compact ? 16 : 18,
                      ),
                    ],
                  ],
                ),
                if (widget.profile.aboutMe.isNotEmpty && !widget.compact)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.profile.aboutMe,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsGrid(List<ProfileStatConfig> stats) {
    final visibleStats = stats.where((s) => s.visible).toList();
    if (visibleStats.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: visibleStats.map((stat) {
        // Apply animation to numeric values
        final animatedValue = stat.numericValue != null
            ? (_countAnimation.value * stat.numericValue!).round()
            : null;
        final displayValue = animatedValue != null
            ? _formatCount(animatedValue)
            : stat.value;

        return Expanded(
          child: _AnimatedStatItem(
            label: stat.label,
            value: displayValue,
            icon: stat.icon,
            onTap: stat.onTap,
          ),
        );
      }).toList(),
    );
  }

  List<ProfileStatConfig> _buildDefaultStats() {
    final stats = <ProfileStatConfig>[];

    // Only show followers/following for own profile (not mate profiles)
    if (widget.showFollowStats) {
      stats.add(ProfileStatConfig(
        label: AppTranslationConstants.followers.tr,
        value: _formatCount(widget.profile.followers?.length ?? 0),
        numericValue: widget.profile.followers?.length ?? 0,
        icon: Icons.people_outline,
        onTap: widget.onFollowersTap,
      ));
      stats.add(ProfileStatConfig(
        label: AppTranslationConstants.following.tr,
        value: _formatCount(widget.profile.following?.length ?? 0),
        numericValue: widget.profile.following?.length ?? 0,
        icon: Icons.person_add_outlined,
        onTap: widget.onFollowingTap,
      ));
    }

    // Always show posts
    stats.add(ProfileStatConfig(
      label: AppTranslationConstants.post.tr,
      value: _formatCount(widget.profile.posts?.length ?? 0),
      numericValue: widget.profile.posts?.length ?? 0,
      icon: Icons.grid_on_rounded,
      onTap: widget.onPostsTap,
    ));

    // Show bands if available
    if (widget.profile.bands?.isNotEmpty ?? false) {
      stats.add(ProfileStatConfig(
        label: AppTranslationConstants.bands.tr,
        value: _formatCount(widget.profile.bands?.length ?? 0),
        numericValue: widget.profile.bands?.length ?? 0,
        icon: Icons.groups_outlined,
        onTap: widget.onBandsTap,
      ));
    }

    // Show events if available
    if (widget.profile.events?.isNotEmpty ?? false) {
      stats.add(ProfileStatConfig(
        label: AppTranslationConstants.events.tr,
        value: _formatCount(widget.profile.events?.length ?? 0),
        numericValue: widget.profile.events?.length ?? 0,
        icon: Icons.event_outlined,
        onTap: widget.onEventsTap,
      ));
    }

    return stats;
  }

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Animated stat item with haptic feedback
class _AnimatedStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  const _AnimatedStatItem({
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: ProfileStatItem(
        label: label,
        value: value,
        icon: icon,
        onTap: null, // Handle tap in parent
      ),
    );
  }
}

/// Configuration for a single stat item in [ProfileStatsCard].
///
/// Use this to define custom stats beyond the defaults:
/// ```dart
/// ProfileStatsCard(
///   profile: profile,
///   customStats: [
///     ProfileStatConfig(label: 'Casete', value: '1.2K', icon: Icons.headphones),
///     ProfileStatConfig(label: 'Rating', value: '9.5', icon: Icons.star),
///   ],
/// )
/// ```
class ProfileStatConfig {
  final String label;
  final String value;
  /// Numeric value for animated count-up effect
  final int? numericValue;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool visible;

  const ProfileStatConfig({
    required this.label,
    required this.value,
    this.numericValue,
    this.icon,
    this.onTap,
    this.visible = true,
  });
}
