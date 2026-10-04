import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'motion.dart';
import 'ui.dart';

const Color _base = Color(0xFFEEE7DC);
const Color _highlight = Color(0xFFF7F1E6);

class _SlideTransform extends GradientTransform {
  final double slide;
  const _SlideTransform(this.slide);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

/// Soft light sweeping slowly across placeholder blocks, left to right.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          colors: const [_base, _highlight, _base],
          stops: const [0.25, 0.5, 0.75],
          transform: _SlideTransform(-1 + 2 * _c.value),
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

/// One rounded placeholder block.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _SkeletonPanel extends StatelessWidget {
  final Widget child;
  const _SkeletonPanel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MindCareTheme.surface,
          borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
          border: Border.all(color: MindCareTheme.border),
        ),
        child: child,
      );
}

/// Placeholder shaped like the daily check-in card.
class CheckInSkeleton extends StatelessWidget {
  const CheckInSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _SkeletonPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 220, height: 20),
            const SizedBox(height: 8),
            const SkeletonBox(width: 160, height: 12),
            const SizedBox(height: 20),
            Row(
              children: [
                for (int i = 0; i < 5; i++)
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: SkeletonBox(height: 84, radius: 20),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

/// Placeholder shaped like a stat tile.
class StatSkeleton extends StatelessWidget {
  const StatSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const _SkeletonPanel(
        child: Row(
          children: [
            SkeletonBox(width: 48, height: 48, radius: 14),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 60, height: 24),
                  SizedBox(height: 8),
                  SkeletonBox(width: 110, height: 12),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Placeholder shaped like a chart card (title, plot area, axis labels).
class ChartSkeleton extends StatelessWidget {
  final double height;
  const ChartSkeleton({super.key, this.height = 170});

  @override
  Widget build(BuildContext context) => _SkeletonPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 150, height: 18),
            const SizedBox(height: 16),
            SkeletonBox(height: height, radius: 16),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < 7; i++) const SkeletonBox(width: 14, height: 10),
              ],
            ),
          ],
        ),
      );
}

/// Placeholder shaped like a request / entry row.
class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const _SkeletonPanel(
        child: Row(
          children: [
            SkeletonBox(width: 44, height: 44, radius: 22),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 240, height: 11),
                ],
              ),
            ),
            SizedBox(width: 12),
            SkeletonBox(width: 70, height: 26, radius: 13),
          ],
        ),
      );
}

/// What the patient Home looks like while it loads.
class PatientHomeSkeleton extends StatelessWidget {
  const PatientHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 280, height: 30),
            const SizedBox(height: 10),
            const SkeletonBox(width: 200, height: 14),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, c) {
              final left = Column(
                children: const [
                  CheckInSkeleton(),
                  SizedBox(height: 24),
                  ListRowSkeleton(),
                ],
              );
              final right = Column(
                children: const [
                  ChartSkeleton(),
                  SizedBox(height: 24),
                  ListRowSkeleton(),
                ],
              );
              return c.maxWidth >= 860
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: left),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: right),
                      ],
                    )
                  : Column(children: [left, const SizedBox(height: 24), right]);
            }),
          ],
        ),
      );
}

/// What the psychologist workspace looks like while it loads.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 320, height: 30),
            const SizedBox(height: 10),
            const SkeletonBox(width: 180, height: 14),
            const SizedBox(height: 24),
            const ResponsiveGrid(
              wideColumns: 4,
              narrowColumns: 2,
              children: [
                StatSkeleton(),
                StatSkeleton(),
                StatSkeleton(),
                StatSkeleton(),
              ],
            ),
            const SizedBox(height: 24),
            const ChartSkeleton(height: 200),
            const SizedBox(height: 24),
            const ListRowSkeleton(),
            const SizedBox(height: 12),
            const ListRowSkeleton(),
          ],
        ),
      );
}
