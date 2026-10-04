import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/consultation.dart';
import '../models/text_analysis.dart';

/// Layout breakpoints shared by every screen.
class Breakpoints {
  const Breakpoints._();

  /// Sidebar layout, multi-column dashboards.
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  /// Maximum width of page content on large monitors.
  static const double contentMaxWidth = 1200;
}

/// White card with a title row, used for every dashboard section.
class Panel extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  const Panel({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        border: Border.all(color: borderColor ?? MindCareTheme.border),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title!, style: text.titleLarge?.copyWith(fontSize: 17)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: text.bodyMedium?.copyWith(fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

/// Big-number KPI card.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color color;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.color = MindCareTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        border: Border.all(color: MindCareTheme.border),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: text.displayMedium?.copyWith(fontSize: 28, height: 1.1)),
                const SizedBox(height: 2),
                Text(label,
                    style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: MindCareTheme.textPrimary)),
                if (caption != null)
                  Text(caption!, style: text.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays children out in a responsive grid with equal-width columns.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int wideColumns;
  final int narrowColumns;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.wideColumns = 4,
    this.narrowColumns = 1,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 720 ? wideColumns : narrowColumns;
      final width =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final c in children) SizedBox(width: width, child: c),
        ],
      );
    });
  }
}

/// Small coloured pill.
class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const Pill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final ConsultationStatus status;
  const StatusPill(this.status, {super.key});

  static Color colorFor(ConsultationStatus s) {
    switch (s) {
      case ConsultationStatus.pending:
        return const Color(0xFFB08A2E);
      case ConsultationStatus.accepted:
        return MindCareTheme.primaryDark;
      case ConsultationStatus.declined:
        return MindCareTheme.error;
      case ConsultationStatus.completed:
        return MindCareTheme.success;
      case ConsultationStatus.rescheduleRequested:
        return MindCareTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) =>
      Pill(label: status.label, color: colorFor(status));
}

class RiskPill extends StatelessWidget {
  final RiskLevel level;
  const RiskPill(this.level, {super.key});

  static Color colorFor(RiskLevel l) {
    switch (l) {
      case RiskLevel.critical:
      case RiskLevel.high:
        return MindCareTheme.error;
      case RiskLevel.moderate:
        return const Color(0xFFB08A2E);
      case RiskLevel.low:
        return MindCareTheme.primaryDark;
      case RiskLevel.none:
        return MindCareTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Pill(
        label: level == RiskLevel.none ? 'No flags' : '${level.label} risk',
        color: colorFor(level),
        icon: level.needsSafetyResponse ? Icons.warning_amber_rounded : null,
      );
}

/// Round avatar showing the first letter of [name].
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const Avatar(this.name, {super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? MindCareTheme.primaryDark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: MindCareTheme.textLight),
            const SizedBox(height: 12),
            Text(title, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center, style: text.bodyMedium),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Page title with optional subtitle and action buttons.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.displayMedium?.copyWith(fontSize: 28)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: text.bodyLarge),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
