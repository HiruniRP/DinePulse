import 'package:flutter/material.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/member_4/models/m4_queue_model.dart';

/// Status badge for queue tickets
class M4QueueBadge extends StatelessWidget {
  final String status;

  const M4QueueBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case M4QueueStatus.waiting:
        bg = AppTheme.accent.withValues(alpha: 0.12);
        fg = const Color(0xFF007A9E);
        label = 'Waiting';
        icon = Icons.hourglass_top_rounded;
        break;
      case M4QueueStatus.almostTurn:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Almost Turn!';
        icon = Icons.notifications_active_outlined;
        break;
      case M4QueueStatus.called:
        bg = AppTheme.success.withValues(alpha: 0.15);
        fg = AppTheme.success;
        label = 'Table Ready!';
        icon = Icons.table_restaurant_rounded;
        break;
      case M4QueueStatus.seated:
        bg = AppTheme.primary.withValues(alpha: 0.12);
        fg = AppTheme.primary;
        label = 'Seated';
        icon = Icons.check_circle_outline;
        break;
      case M4QueueStatus.cancelled:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      case M4QueueStatus.noShow:
        bg = AppTheme.error.withValues(alpha: 0.1);
        fg = AppTheme.error;
        label = 'No Show';
        icon = Icons.person_off_outlined;
        break;
      case M4QueueStatus.expired:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Expired';
        icon = Icons.timer_off_outlined;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Table Card for staff table management overview
class M4TableStatusCard extends StatelessWidget {
  final M4TableItem table;
  final VoidCallback? onTap;
  final VoidCallback? onStatusToggle;

  const M4TableStatusCard({
    super.key,
    required this.table,
    this.onTap,
    this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color statusBg;
    Color statusFg;
    String statusLabel;

    switch (table.status) {
      case M4TableStatus.available:
        borderColor = AppTheme.success;
        statusBg = AppTheme.success.withValues(alpha: 0.12);
        statusFg = AppTheme.success;
        statusLabel = 'Available';
        break;
      case M4TableStatus.occupied:
        borderColor = AppTheme.primary;
        statusBg = AppTheme.primary.withValues(alpha: 0.1);
        statusFg = AppTheme.primary;
        statusLabel = 'Occupied';
        break;
      case M4TableStatus.reservedM2:
        borderColor = AppTheme.accent;
        statusBg = AppTheme.accent.withValues(alpha: 0.15);
        statusFg = const Color(0xFF007A9E);
        statusLabel = 'Reserved (M2)';
        break;
      case M4TableStatus.cleaning:
        borderColor = Colors.orange.shade600;
        statusBg = Colors.orange.shade50;
        statusFg = Colors.orange.shade800;
        statusLabel = 'Cleaning...';
        break;
      default:
        borderColor = AppTheme.divider;
        statusBg = Colors.grey.shade100;
        statusFg = Colors.grey.shade700;
        statusLabel = table.status;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [
            BoxShadow(color: AppTheme.cardShadow, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'T-${table.number}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 2),
                    Text(
                      '${table.capacity}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              table.location,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusFg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (table.currentCustomerName != null) ...[
              const SizedBox(height: 4),
              Text(
                table.currentCustomerName!,
                style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Visual Position Tracker for customer ticket
class M4PositionTracker extends StatelessWidget {
  final int position;
  final int estimatedWaitMinutes;
  final int delayAlert;

  const M4PositionTracker({
    super.key,
    required this.position,
    required this.estimatedWaitMinutes,
    this.delayAlert = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Position
              Column(
                children: [
                  const Text(
                    'POSITION IN LINE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textHint),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '#',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      Text(
                        '$position',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(width: 1, height: 45, color: AppTheme.divider),
              // Estimated Wait
              Column(
                children: [
                  const Text(
                    'ESTIMATED WAIT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textHint),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '~$estimatedWaitMinutes',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                      ),
                      const Text(
                        ' mins',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (delayAlert > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kitchen busy: +$delayAlert mins adjustment applied',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Language Selector pill widget for EN / SI / TA
class M4LanguageSelector extends StatelessWidget {
  final M4Language currentLanguage;
  final ValueChanged<M4Language> onLanguageChanged;

  const M4LanguageSelector({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langChip('EN', M4Language.english),
          _langChip('සිං', M4Language.sinhala),
          _langChip('தமிழ்', M4Language.tamil),
        ],
      ),
    );
  }

  Widget _langChip(String label, M4Language lang) {
    final isSelected = currentLanguage == lang;
    return GestureDetector(
      onTap: () => onLanguageChanged(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
