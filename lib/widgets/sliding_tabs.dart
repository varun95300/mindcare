import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'motion.dart';

/// A segmented tab bar whose sage indicator glides to the selected tab.
class SlidingTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const SlidingTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final count = labels.length;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MindCareTheme.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final tabWidth = c.maxWidth / count;
        return Stack(
          children: [
            // Moves with a transform, not a layout change.
            AnimatedSlide(
              offset: Offset(index.toDouble(), 0),
              duration: Motion.of(context, const Duration(milliseconds: 240)),
              curve: Motion.standard,
              child: Container(
                width: tabWidth,
                decoration: BoxDecoration(
                  color: MindCareTheme.primary.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
                ),
              ),
            ),
            Row(
              children: [
                for (int i = 0; i < count; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == index,
                      label: labels[i],
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(MindCareTheme.radiusFull),
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration:
                                Motion.of(context, Motion.normal),
                            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                  fontSize: 14,
                                  fontWeight: i == index
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: i == index
                                      ? MindCareTheme.textPrimary
                                      : MindCareTheme.textSecondary,
                                ),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
