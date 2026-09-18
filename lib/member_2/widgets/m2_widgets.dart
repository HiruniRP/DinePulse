import 'package:flutter/material.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';

// ─── Status Badge ─────────────────────────────────────────────────────────────
class M2StatusBadge extends StatelessWidget {
  final String status;
  const M2StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; String label;
    switch (status) {
      case M2ReservationStatus.confirmed:
        bg = AppTheme.success; fg = Colors.white; label = 'Confirmed'; break;
      case M2ReservationStatus.pending:
        bg = AppTheme.warning; fg = Colors.white; label = 'Pending'; break;
      case M2ReservationStatus.rejected:
        bg = AppTheme.error; fg = Colors.white; label = 'Rejected'; break;
      case M2ReservationStatus.cancelled:
        bg = AppTheme.textSecondary; fg = Colors.white; label = 'Cancelled'; break;
      case M2ReservationStatus.completed:
        bg = AppTheme.primary; fg = Colors.white; label = 'Completed'; break;
      case M2ReservationStatus.modified:
        bg = AppTheme.accent; fg = Colors.white; label = 'Modified'; break;
      case M2ReservationStatus.noShow:
        bg = AppTheme.primaryDark; fg = Colors.white; label = 'No Show'; break;
      default:
        bg = AppTheme.divider; fg = AppTheme.textSecondary; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}

// ─── Table Status Badge ───────────────────────────────────────────────────────
class M2TableStatusBadge extends StatelessWidget {
  final String status;
  const M2TableStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case M2TableStatus.available: color = AppTheme.success; break;
      case M2TableStatus.reserved: color = AppTheme.warning; break;
      case M2TableStatus.occupied: color = AppTheme.error; break;
      case M2TableStatus.cleaning: color = AppTheme.info; break;
      default: color = AppTheme.textHint;
    }
    final label = status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Table Card ───────────────────────────────────────────────────────────────
class M2TableCard extends StatelessWidget {
  final M2TableModel table;
  final bool isSelected;
  final bool isSelectable;
  final VoidCallback? onTap;

  const M2TableCard({
    super.key,
    required this.table,
    this.isSelected = false,
    this.isSelectable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canSelect = isSelectable && table.isAvailable;
    return GestureDetector(
      onTap: canSelect ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : (canSelect ? AppTheme.divider : AppTheme.divider),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [BoxShadow(color: AppTheme.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(
              table.location == 'outdoor' ? Icons.deck : table.location == 'private' ? Icons.meeting_room : table.location == 'bar' ? Icons.local_bar : Icons.table_restaurant,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text('Table ${table.number}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.people, size: 13, color: AppTheme.textHint),
            const SizedBox(width: 3),
            Text('${table.capacity} seats', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(width: 8),
            if (table.hasWindowView) ...[
              const Icon(Icons.window, size: 12, color: AppTheme.accent),
              const SizedBox(width: 2),
              const Text('View', style: TextStyle(fontSize: 11, color: AppTheme.accent)),
              const SizedBox(width: 6),
            ],
            if (table.isAccessible) const Icon(Icons.accessible, size: 13, color: AppTheme.info),
          ]),
          const SizedBox(height: 6),
          M2TableStatusBadge(status: table.status),
        ]),
      ),
    );
  }
}

// ─── Reservation Card ─────────────────────────────────────────────────────────
class M2ReservationCard extends StatelessWidget {
  final M2ReservationModel reservation;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onModify;
  final VoidCallback? onCancel;

  const M2ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
    this.showActions = false,
    this.onModify,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.restaurant, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(reservation.restaurantName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis)),
              M2StatusBadge(status: reservation.status),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Booking ID
              Row(children: [
                const Icon(Icons.confirmation_number_outlined, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(reservation.bookingId, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const Spacer(),
                if (reservation.specialOccasion != null) ...[
                  Icon(Icons.celebration, size: 14, color: AppTheme.accent),
                  const SizedBox(width: 3),
                  Text(_capitalize(reservation.specialOccasion!), style: const TextStyle(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                ],
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _infoChip(Icons.calendar_today, _formatDate(reservation.date)),
                const SizedBox(width: 10),
                _infoChip(Icons.access_time, reservation.time),
                const SizedBox(width: 10),
                _infoChip(Icons.people, '${reservation.partySize} guests'),
              ]),
              if (reservation.assignedTableNumber != null) ...[
                const SizedBox(height: 6),
                _infoChip(Icons.table_restaurant, 'Table ${reservation.assignedTableNumber}'),
              ],
              if (showActions && reservation.canModify) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onModify,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Modify'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), textStyle: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: AppTheme.textHint),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
    ]);
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Step Header ──────────────────────────────────────────────────────────────
class M2StepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepLabel;

  const M2StepHeader({super.key, required this.currentStep, required this.totalSteps, required this.stepLabel});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Step $currentStep of $totalSteps', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(stepLabel, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: AppTheme.divider,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          minHeight: 4,
        ),
      ),
    ]);
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class M2InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const M2InfoRow({super.key, required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary)),
          ]),
        ),
      ]),
    );
  }
}

// ─── Audit Trail Tile ─────────────────────────────────────────────────────────
class M2AuditTile extends StatelessWidget {
  final M2AuditEntry entry;
  final bool isLast;

  const M2AuditTile({super.key, required this.entry, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (entry.action) {
      case 'created': icon = Icons.add_circle_outline; color = AppTheme.info; break;
      case 'confirmed': icon = Icons.check_circle_outline; color = AppTheme.success; break;
      case 'rejected': icon = Icons.cancel_outlined; color = AppTheme.error; break;
      case 'modified': icon = Icons.edit_outlined; color = AppTheme.primary; break;
      case 'cancelled': icon = Icons.block; color = AppTheme.error; break;
      case 'completed': icon = Icons.done_all; color = AppTheme.info; break;
      case 'table_assigned': icon = Icons.table_restaurant; color = AppTheme.accent; break;
      default: icon = Icons.info_outline; color = AppTheme.textSecondary;
    }

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle, border: Border.all(color: color.withAlpha(80))),
            child: Icon(icon, size: 16, color: color)),
          if (!isLast) Expanded(child: Container(width: 1, color: AppTheme.divider, margin: const EdgeInsets.symmetric(vertical: 4))),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(_actionLabel(entry.action), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                const Spacer(),
                Text(_formatTime(entry.timestamp), style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
              ]),
              const SizedBox(height: 2),
              Text('${entry.actorName} (${entry.actorRole})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(entry.notes!, style: const TextStyle(fontSize: 12, color: AppTheme.textHint, fontStyle: FontStyle.italic)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  String _actionLabel(String a) {
    const map = {
      'created': 'Reservation Created',
      'confirmed': 'Confirmed by Staff',
      'rejected': 'Rejected by Staff',
      'modified': 'Reservation Modified',
      'cancelled': 'Reservation Cancelled',
      'completed': 'Visit Completed',
      'table_assigned': 'Table Assigned',
      'checked_in': 'Customer Checked In',
    };
    if (map.containsKey(a)) return map[a]!;
    if (a.startsWith('bulk_update:')) return 'Bulk Updated to ${a.split(':').last}';
    return a;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── QR Code Placeholder ──────────────────────────────────────────────────────
class M2QrCode extends StatelessWidget {
  final String bookingId;
  const M2QrCode({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8)],
      ),
      child: Stack(alignment: Alignment.center, children: [
        // Grid background to simulate QR
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
          itemCount: 100,
          itemBuilder: (_, i) {
            final row = i ~/ 10; final col = i % 10;
            // Corner squares
            final isCorner = (row < 3 && col < 3) || (row < 3 && col > 6) || (row > 6 && col < 3);
            final isDark = isCorner || (i % 3 == 0 && i % 7 != 0);
            return Container(margin: const EdgeInsets.all(1), color: isDark ? AppTheme.textPrimary : Colors.transparent);
          },
        ),
        // Center logo overlay
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 18),
        ),
      ]),
    );
  }
}
