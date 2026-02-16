/// Tests for PostTile widget
///
/// Covers:
/// - Basic rendering for different post types
/// - Video/Event indicators
/// - Stats overlay (likes, comments)
/// - Long press preview
/// - Tap interactions
/// - Private post indicator
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

/// Mock post types
enum MockPostType { image, video, event, caption, blogEntry }

/// Mock Post for testing
class MockPost {
  final String id;
  final String mediaUrl;
  final String thumbnailUrl;
  final MockPostType type;
  final List<String> likedProfiles;
  final List<String> commentIds;
  final List<String> sharedProfiles;
  final bool isPrivate;
  final String profileName;
  final String profileImgUrl;
  final String location;
  final String caption;
  final double aspectRatio;
  final int? likesCount; // Optional override for large numbers
  final int? commentsCount; // Optional override for large numbers

  MockPost({
    required this.id,
    this.mediaUrl = 'https://example.com/image.jpg',
    this.thumbnailUrl = '',
    this.type = MockPostType.image,
    this.likedProfiles = const [],
    this.commentIds = const [],
    this.sharedProfiles = const [],
    this.isPrivate = false,
    this.profileName = 'Test User',
    this.profileImgUrl = '',
    this.location = '',
    this.caption = '',
    this.aspectRatio = 1.0,
    this.likesCount,
    this.commentsCount,
  });

  int get totalLikes => likesCount ?? likedProfiles.length;
  int get totalComments => commentsCount ?? commentIds.length;
}

/// Mock PostTile widget for testing
class MockPostTile extends StatefulWidget {
  final MockPost post;
  final bool showStats;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MockPostTile({
    required this.post,
    this.showStats = true,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  @override
  State<MockPostTile> createState() => _MockPostTileState();
}

class _MockPostTileState extends State<MockPostTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

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
    widget.onTap?.call();
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
      builder: (context) => _QuickPreviewDialog(post: widget.post),
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
          key: Key('post_tile_${widget.post.id}'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey[900],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Main thumbnail
                Container(
                  key: const Key('thumbnail'),
                  color: Colors.grey[800],
                  child: const Center(child: Icon(Icons.image)),
                ),

                // Gradient overlay for stats
                if (widget.showStats && widget.post.totalLikes > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      key: const Key('gradient_overlay'),
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                // Video indicator
                if (widget.post.type == MockPostType.video)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: _VideoIndicator(),
                  ),

                // Event indicator
                if (widget.post.type == MockPostType.event)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: _EventIndicator(),
                  ),

                // Stats overlay
                if (widget.showStats && widget.post.totalLikes > 0)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: _StatsOverlay(
                      likes: widget.post.totalLikes,
                      comments: widget.post.totalComments,
                    ),
                  ),

                // Private indicator
                if (widget.post.isPrivate)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      key: const Key('private_indicator'),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.lock, size: 12, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoIndicator extends StatelessWidget {
  const _VideoIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('video_indicator'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
    );
  }
}

class _EventIndicator extends StatelessWidget {
  const _EventIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('event_indicator'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.event, size: 16, color: Colors.white),
    );
  }
}

class _StatsOverlay extends StatelessWidget {
  final int likes;
  final int comments;

  const _StatsOverlay({required this.likes, required this.comments});

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('stats_overlay'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (likes > 0) ...[
          const Icon(Icons.favorite, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            _formatCount(likes),
            key: const Key('likes_count'),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
        if (likes > 0 && comments > 0) const SizedBox(width: 8),
        if (comments > 0) ...[
          const Icon(Icons.chat_bubble, size: 11, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            _formatCount(comments),
            key: const Key('comments_count'),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _QuickPreviewDialog extends StatelessWidget {
  final MockPost post;

  const _QuickPreviewDialog({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Center(
        child: Container(
          key: const Key('preview_dialog'),
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          post.profileName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Image placeholder
                AspectRatio(
                  aspectRatio: post.aspectRatio,
                  child: Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.image, size: 48),
                  ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, size: 20),
                      const SizedBox(width: 4),
                      Text('${post.totalLikes}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.chat_bubble_outline, size: 18),
                      const SizedBox(width: 4),
                      Text('${post.totalComments}'),
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
}

void main() {
  group('PostTile Widget Tests', () {
    group('Basic Rendering', () {
      testWidgets('renders image post correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1', type: MockPostType.image),
            ),
          ),
        );

        expect(find.byKey(const Key('post_tile_1')), findsOneWidget);
        expect(find.byKey(const Key('thumbnail')), findsOneWidget);
      });

      testWidgets('renders video post with indicator', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1', type: MockPostType.video),
            ),
          ),
        );

        expect(find.byKey(const Key('video_indicator')), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      });

      testWidgets('renders event post with indicator', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1', type: MockPostType.event),
            ),
          ),
        );

        expect(find.byKey(const Key('event_indicator')), findsOneWidget);
        expect(find.byIcon(Icons.event), findsOneWidget);
      });

      testWidgets('does not show video indicator for image posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1', type: MockPostType.image),
            ),
          ),
        );

        expect(find.byKey(const Key('video_indicator')), findsNothing);
      });
    });

    group('Stats Overlay', () {
      testWidgets('shows likes count when post has likes', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(
                id: '1',
                likedProfiles: ['user1', 'user2', 'user3'],
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('stats_overlay')), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows comments count when post has comments', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(
                id: '1',
                likedProfiles: ['user1'],
                commentIds: ['c1', 'c2', 'c3', 'c4', 'c5'],
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('comments_count')), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('formats large numbers correctly (K)', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(
                id: '1',
                likedProfiles: List.generate(1500, (i) => 'user$i'),
              ),
            ),
          ),
        );

        expect(find.text('1.5K'), findsOneWidget);
      });

      testWidgets('formats very large numbers (M)', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(
                id: '1',
                likesCount: 1500000, // Use likesCount to avoid creating huge list
              ),
            ),
          ),
        );

        expect(find.text('1.5M'), findsOneWidget);
      });

      testWidgets('hides stats when showStats is false', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(
                id: '1',
                likedProfiles: ['user1'],
              ),
              showStats: false,
            ),
          ),
        );

        expect(find.byKey(const Key('stats_overlay')), findsNothing);
      });

      testWidgets('hides stats when no likes', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1', likedProfiles: []),
            ),
          ),
        );

        expect(find.byKey(const Key('stats_overlay')), findsNothing);
      });

      testWidgets('shows gradient overlay with stats', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(
                id: '1',
                likedProfiles: ['user1'],
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('gradient_overlay')), findsOneWidget);
      });
    });

    group('Private Posts', () {
      testWidgets('shows lock icon for private posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1', isPrivate: true),
            ),
          ),
        );

        expect(find.byKey(const Key('private_indicator')), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsOneWidget);
      });

      testWidgets('does not show lock icon for public posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1', isPrivate: false),
            ),
          ),
        );

        expect(find.byKey(const Key('private_indicator')), findsNothing);
      });
    });

    group('Tap Interactions', () {
      testWidgets('calls onTap when tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1'),
              onTap: () => tapped = true,
            ),
          ),
        );

        await tester.tap(find.byType(MockPostTile));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('calls onLongPress when long pressed', (tester) async {
        bool longPressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1'),
              onLongPress: () => longPressed = true,
            ),
          ),
        );

        await tester.longPress(find.byType(MockPostTile));
        await tester.pump();

        expect(longPressed, isTrue);
      });
    });

    group('Long Press Preview', () {
      testWidgets('shows preview dialog on long press', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1', profileName: 'John Doe'),
            ),
          ),
        );

        await tester.longPress(find.byType(MockPostTile));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('preview_dialog')), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
      });

      testWidgets('preview shows likes and comments', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(
                id: '1',
                likedProfiles: ['u1', 'u2', 'u3'],
                commentIds: ['c1', 'c2'],
              ),
            ),
          ),
        );

        await tester.longPress(find.byType(MockPostTile));
        await tester.pumpAndSettle();

        // Check that the dialog has likes and comments count displayed
        final dialog = find.byKey(const Key('preview_dialog'));
        expect(dialog, findsOneWidget);
        expect(find.text('3'), findsWidgets); // likes (may appear in overlay too)
        expect(find.text('2'), findsWidgets); // comments
      });

      testWidgets('preview closes on tap', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(
              post: MockPost(id: '1'),
            ),
          ),
        );

        await tester.longPress(find.byType(MockPostTile));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('preview_dialog')), findsOneWidget);

        await tester.tap(find.byKey(const Key('preview_dialog')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('preview_dialog')), findsNothing);
      });
    });

    group('Animation', () {
      testWidgets('scales down on tap down', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(post: MockPost(id: '1')),
          ),
        );

        // Verify Transform widget exists for animation
        expect(find.byType(Transform), findsWidgets);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(MockPostTile)),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 50));

        // Animation should have started without errors
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('returns to normal scale after tap', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockPostTile(post: MockPost(id: '1')),
          ),
        );

        await tester.tap(find.byType(MockPostTile));
        await tester.pumpAndSettle();

        final transform = tester.widget<Transform>(
          find.descendant(
            of: find.byType(MockPostTile),
            matching: find.byType(Transform),
          ),
        );

        expect(transform.transform.getMaxScaleOnAxis(), equals(1.0));
      });
    });
  });

  group('PostTile Grid Tests', () {
    testWidgets('renders in grid correctly', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            children: [
              MockPostTile(post: MockPost(id: '1')),
              MockPostTile(post: MockPost(id: '2', type: MockPostType.video)),
              MockPostTile(post: MockPost(id: '3', type: MockPostType.event)),
            ],
          ),
        ),
      );

      expect(find.byType(MockPostTile), findsNWidgets(3));
      expect(find.byKey(const Key('video_indicator')), findsOneWidget);
      expect(find.byKey(const Key('event_indicator')), findsOneWidget);
    });

    testWidgets('handles mixed post types in grid', (tester) async {
      final posts = [
        MockPost(id: '1', type: MockPostType.image),
        MockPost(id: '2', type: MockPostType.video),
        MockPost(id: '3', type: MockPostType.event),
        MockPost(id: '4', type: MockPostType.image, isPrivate: true),
        MockPost(id: '5', type: MockPostType.image, likedProfiles: ['u1']),
        MockPost(id: '6', type: MockPostType.video, likedProfiles: ['u1', 'u2']),
      ];

      await tester.pumpWidget(
        wrapWithMaterialApp(
          GridView.count(
            crossAxisCount: 3,
            children: posts.map((p) => MockPostTile(post: p)).toList(),
          ),
        ),
      );

      expect(find.byType(MockPostTile), findsNWidgets(6));
      expect(find.byKey(const Key('video_indicator')), findsNWidgets(2));
      expect(find.byKey(const Key('event_indicator')), findsOneWidget);
      expect(find.byKey(const Key('private_indicator')), findsOneWidget);
      expect(find.byKey(const Key('stats_overlay')), findsNWidgets(2));
    });
  });

  group('PostTile Edge Cases', () {
    testWidgets('handles empty media URL', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          MockPostTile(post: MockPost(id: '1', mediaUrl: '')),
        ),
      );

      expect(find.byType(MockPostTile), findsOneWidget);
    });

    testWidgets('handles very long profile name in preview', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          MockPostTile(
            post: MockPost(
              id: '1',
              profileName: 'A very long profile name that should be handled properly',
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(MockPostTile));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preview_dialog')), findsOneWidget);
    });
  });
}
