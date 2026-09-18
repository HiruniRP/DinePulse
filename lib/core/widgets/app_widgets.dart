import 'package:flutter/material.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';

/// Generic loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black38,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          ),
      ],
    );
  }
}

/// Full-screen centered loading spinner
class CenteredLoader extends StatelessWidget {
  const CenteredLoader({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppTheme.accent),
  );
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: AppTheme.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Star rating row
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final int count;
  final Color? color;

  const StarRating({super.key, required this.rating, this.size = 16, this.count = 5, this.color});

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? AppTheme.star;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star, color: starColor, size: size);
        } else if (i < rating) {
          return Icon(Icons.star_half, color: starColor, size: size);
        } else {
          return Icon(Icons.star_border, color: starColor, size: size);
        }
      }),
    );
  }
}

/// Status badge chip
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status[0].toUpperCase() + status.substring(1);
    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = AppTheme.success.withOpacity(0.12); fg = AppTheme.success;
        break;
      case 'pending':
        bg = AppTheme.warning.withOpacity(0.12); fg = AppTheme.warning;
        break;
      case 'cancelled':
        bg = AppTheme.error.withOpacity(0.12); fg = AppTheme.error;
        break;
      case 'completed':
        bg = AppTheme.primary.withOpacity(0.12); fg = AppTheme.primary;
        break;
      default:
        bg = AppTheme.textHint.withOpacity(0.15); fg = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// Section header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
          )),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(actionLabel!, style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

/// Custom app bar with gradient
class DinePulseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;

  const DinePulseAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: showBack
          ? leading ?? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          : leading,
      automaticallyImplyLeading: false,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
