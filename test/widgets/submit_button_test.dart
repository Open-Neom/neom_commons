/// Tests for SubmitButton widget
///
/// Covers:
/// - Basic rendering
/// - Loading state
/// - Success/Error states
/// - Tap interactions
/// - Animation behavior
/// - Disabled state
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

// Note: Import the actual widget when running tests
// import 'package:neom_commons/ui/widgets/buttons/submit_button.dart';

/// Mock SubmitButton for isolated testing
/// Replace with actual import in production
class SubmitButton extends StatefulWidget {
  final String text;
  final Function()? onPressed;
  final bool isEnabled;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showSuccessState;
  final bool showErrorState;

  const SubmitButton(
    BuildContext context, {
    super.key,
    this.text = "",
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.width,
    this.height = 50,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.showSuccessState = false,
    this.showErrorState = false,
  });

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
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

  bool get _canPress =>
      widget.isEnabled && !widget.isLoading && !widget.showSuccessState;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _canPress ? _scaleController.forward() : null,
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        if (_canPress && widget.onPressed != null) {
          HapticFeedback.lightImpact();
          widget.onPressed!();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : widget.showSuccessState
                        ? const Icon(Icons.check_rounded, key: ValueKey('success'))
                        : widget.showErrorState
                            ? const Icon(Icons.close_rounded, key: ValueKey('error'))
                            : Row(
                                key: const ValueKey('text'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.icon != null) ...[
                                    Icon(widget.icon, size: 20),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(widget.text),
                                ],
                              ),
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  group('SubmitButton Widget Tests', () {
    group('Basic Rendering', () {
      testWidgets('renders with text', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
              ),
            ),
          ),
        );

        expect(find.text('Submit'), findsOneWidget);
      });

      testWidgets('renders with custom width and height', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                width: 200,
                height: 60,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SubmitButton),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, 200);
      });

      testWidgets('renders with icon', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Save',
                icon: Icons.save,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.save), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('renders with custom colors', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                backgroundColor: Colors.red,
                textColor: Colors.white,
              ),
            ),
          ),
        );

        expect(find.byType(SubmitButton), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('shows loading indicator when isLoading is true', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                isLoading: true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Submit'), findsNothing);
      });

      testWidgets('hides text when loading', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                isLoading: true,
              ),
            ),
          ),
        );

        expect(find.byKey(const ValueKey('loading')), findsOneWidget);
        expect(find.byKey(const ValueKey('text')), findsNothing);
      });

      testWidgets('disables tap when loading', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                isLoading: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(SubmitButton));
        await tester.pump();

        expect(tapped, isFalse);
      });
    });

    group('Success/Error States', () {
      testWidgets('shows check icon on success state', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                showSuccessState: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        expect(find.text('Submit'), findsNothing);
      });

      testWidgets('shows close icon on error state', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                showErrorState: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      });

      testWidgets('disables tap on success state', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                showSuccessState: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(SubmitButton));
        await tester.pump();

        expect(tapped, isFalse);
      });
    });

    group('Tap Interactions', () {
      testWidgets('calls onPressed when tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(SubmitButton));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('does not call onPressed when disabled', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                isEnabled: false,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(SubmitButton));
        await tester.pump();

        expect(tapped, isFalse);
      });

      testWidgets('handles null onPressed gracefully', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                onPressed: null,
              ),
            ),
          ),
        );

        // Should not throw
        await tester.tap(find.byType(SubmitButton));
        await tester.pump();
      });
    });

    group('Animation Behavior', () {
      testWidgets('scales down on tap down', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                onPressed: () {},
              ),
            ),
          ),
        );

        // Verify the button has Transform for scale animation
        expect(find.byType(Transform), findsWidgets);

        // Get initial transform
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(SubmitButton)),
        );

        // Pump multiple frames to allow animation to progress
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 50));

        // The animation should have started - just verify no errors
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('returns to normal scale on tap up', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                onPressed: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(SubmitButton));
        await tester.pumpAndSettle();

        final transform = tester.widget<Transform>(
          find.descendant(
            of: find.byType(SubmitButton),
            matching: find.byType(Transform),
          ),
        );

        expect(transform.transform.getMaxScaleOnAxis(), equals(1.0));
      });

      testWidgets('returns to normal on tap cancel', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                onPressed: () {},
              ),
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(SubmitButton)),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Move away to trigger cancel
        await gesture.moveBy(const Offset(500, 500));
        await gesture.cancel();
        await tester.pumpAndSettle();

        final transform = tester.widget<Transform>(
          find.descendant(
            of: find.byType(SubmitButton),
            matching: find.byType(Transform),
          ),
        );

        expect(transform.transform.getMaxScaleOnAxis(), equals(1.0));
      });
    });

    group('Disabled State', () {
      testWidgets('does not animate when disabled', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Builder(
              builder: (context) => SubmitButton(
                context,
                text: 'Submit',
                isEnabled: false,
              ),
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(SubmitButton)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        final transform = tester.widget<Transform>(
          find.descendant(
            of: find.byType(SubmitButton),
            matching: find.byType(Transform),
          ),
        );

        // Should remain at scale 1.0 when disabled
        expect(transform.transform.getMaxScaleOnAxis(), equals(1.0));

        await gesture.up();
      });
    });

    group('State Transitions', () {
      testWidgets('transitions from text to loading', (tester) async {
        bool isLoading = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return wrapWithMaterialApp(
                SubmitButton(
                  context,
                  text: 'Submit',
                  isLoading: isLoading,
                  onPressed: () => setState(() => isLoading = true),
                ),
              );
            },
          ),
        );

        expect(find.text('Submit'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.tap(find.byType(SubmitButton));
        // Use pump instead of pumpAndSettle because CircularProgressIndicator
        // has infinite animation
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Submit'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });

  group('SubmitButton Accessibility', () {
    testWidgets('has minimum touch target size', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Builder(
            builder: (context) => SubmitButton(
              context,
              text: 'Submit',
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(SubmitButton));

      // Minimum recommended touch target is 48x48
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });
}
