import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart';

/// Screen 13: Staff Reservation Details
class M2StaffDetailsScreen extends StatefulWidget {
  final M2ReservationModel reservation;

  const M2StaffDetailsScreen({super.key, required this.reservation});

  @override
  State<M2StaffDetailsScreen> createState() => _M2StaffDetailsScreenState();
}

class _M2StaffDetailsScreenState extends State<M2StaffDetailsScreen> {
  late TextEditingController _notesCtrl;
  bool _savingNotes = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.reservation.shiftNotes ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<M2ReservationService>();
    final currentReservation = service.reservations.firstWhere(
      (r) => r.id == widget.reservation.id,
      orElse: () => widget.reservation,
    );
    final r = currentReservation;
    final availableTables = service.getTablesForRestaurant(r.restaurantId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(r.bookingId),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            tooltip: 'Call Guest',
            onPressed: () => SnackBarHelper.showSuccess(context, 'Calling ${r.customerPhone}...'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            tooltip: 'Message Guest',
            onPressed: () => SnackBarHelper.showSuccess(context, 'Messaging ${r.customerPhone}...'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Quick Change Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CURRENT STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textHint)),
                          const SizedBox(height: 2),
                          Text(
                            r.displayStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(r.status),
                            ),
                          ),
                        ],
                      ),
                      M2StatusBadge(status: r.status),
                    ],
                  ),
                  const Divider(height: 20),

                  // Quick Action Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (r.status == M2ReservationStatus.pending)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                          icon: const Icon(Icons.check, size: 16, color: Colors.white),
                          label: const Text('Confirm Booking', style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: () => service.staffConfirmReservation(
                            reservationId: r.id,
                            staffId: 'staff1',
                            staffName: 'Staff On Duty',
                          ),
                        ),
                      if (r.status == M2ReservationStatus.confirmed || r.status == M2ReservationStatus.pending)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                          icon: const Icon(Icons.done_all, size: 16, color: Colors.white),
                          label: const Text('Mark Completed', style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: () => service.staffBulkUpdateStatus(
                            reservationIds: [r.id],
                            newStatus: M2ReservationStatus.completed,
                            staffId: 'staff1',
                            staffName: 'Staff On Duty',
                          ),
                        ),
                      if (r.status != M2ReservationStatus.cancelled && r.status != M2ReservationStatus.completed) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                          icon: const Icon(Icons.person_off_outlined, size: 16),
                          label: const Text('No-Show', style: TextStyle(fontSize: 12)),
                          onPressed: () => service.staffBulkUpdateStatus(
                            reservationIds: [r.id],
                            newStatus: M2ReservationStatus.noShow,
                            staffId: 'staff1',
                            staffName: 'Staff On Duty',
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Cancel / Reject', style: TextStyle(fontSize: 12)),
                          onPressed: () => _confirmReject(context, r),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Guest Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Guest Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.person_outline, 'Customer', r.customerName),
                  const SizedBox(height: 8),
                  _infoRow(Icons.phone_outlined, 'Phone', r.customerPhone),
                  const SizedBox(height: 8),
                  _infoRow(Icons.email_outlined, 'Email', r.customerEmail),
                  const SizedBox(height: 8),
                  _infoRow(Icons.group_outlined, 'Party Size', '${r.partySize} Guests'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.calendar_today_outlined, 'Date & Time', '${AppFormatters.formatDate(r.date)} at ${r.time}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Table Assignment Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Table Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (r.tableLocation != 'any')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Prefers: ${r.tableLocation}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: r.assignedTableNumber != null
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : Colors.amber.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.table_restaurant,
                          color: r.assignedTableNumber != null ? AppTheme.success : Colors.amber.shade800,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.assignedTableNumber != null ? 'Table #${r.assignedTableNumber}' : 'No Table Assigned',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              r.assignedTableNumber != null ? 'Assigned and confirmed' : 'Please select an available table',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                            ),
                          ],
                        ),
                      ),
                      // Dropdown / assign button
                      DropdownButton<String>(
                        hint: const Text('Change Table', style: TextStyle(fontSize: 12)),
                        underline: const SizedBox(),
                        items: availableTables.map((t) {
                          return DropdownMenuItem<String>(
                            value: t.id,
                            child: Text('T-${t.number} (${t.capacity}p, ${t.location})', style: const TextStyle(fontSize: 12.5)),
                          );
                        }).toList(),
                        onChanged: (newTableId) {
                          if (newTableId != null) {
                            final table = availableTables.firstWhere((t) => t.id == newTableId);
                            service.staffAssignTable(
                              reservationId: r.id,
                              tableId: table.id,
                              tableNumber: table.number,
                              staffId: 'staff1',
                              staffName: 'Staff On Duty',
                            );
                            SnackBarHelper.showSuccess(context, 'Assigned Table #${table.number}');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Special Occasion & Requests
            if (r.specialOccasion != null || (r.specialRequests != null && r.specialRequests!.isNotEmpty))
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text('Guest Notes & Special Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (r.specialOccasion != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• Occasion: ${r.specialOccasion}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    if (r.specialRequests != null && r.specialRequests!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• Request: ${r.specialRequests}', style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Pre-order Items Breakdown
            if (r.preOrderItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.cardShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kitchen Pre-Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...r.preOrderItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}x ${item.menuItemName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Staff Internal Shift Notes with Save
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Staff Shift Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add internal notes (e.g. VIP guest, window preferred)...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: AppTheme.textHint),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: _savingNotes
                          ? null
                          : () async {
                              final sm = ScaffoldMessenger.of(context);
                              setState(() => _savingNotes = true);
                              await service.staffConfirmReservation(
                                reservationId: r.id,
                                staffId: 'staff1',
                                staffName: 'Staff On Duty',
                                shiftNotes: _notesCtrl.text.trim(),
                              );
                              if (!mounted) return;
                              setState(() => _savingNotes = false);
                              sm.showSnackBar(
                                SnackBar(
                                  content: const Text('Internal notes saved'),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            },
                      child: _savingNotes
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Notes', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Audit / Modification History Log
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Modification History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  if (r.modificationHistory.isEmpty)
                    const Text('No modifications recorded. Original booking intact.', style: TextStyle(fontSize: 12, color: AppTheme.textHint))
                  else
                    ...r.modificationHistory.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.history, size: 16, color: AppTheme.textHint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.field}: ${item.oldValue} -> ${item.newValue} (by ${item.changedBy})',
                              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textHint),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case M2ReservationStatus.confirmed:
        return AppTheme.success;
      case M2ReservationStatus.completed:
        return AppTheme.primary;
      case M2ReservationStatus.pending:
        return AppTheme.warning;
      case M2ReservationStatus.cancelled:
      case M2ReservationStatus.rejected:
        return AppTheme.error;
      case M2ReservationStatus.noShow:
        return AppTheme.primaryDark;
      case M2ReservationStatus.modified:
        return AppTheme.accent;
      default:
        return AppTheme.textPrimary;
    }
  }

  void _confirmReject(BuildContext context, M2ReservationModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel / Reject Booking'),
        content: Text('Are you sure you want to cancel booking ${r.bookingId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<M2ReservationService>().staffRejectReservation(
                reservationId: r.id,
                staffId: 'staff1',
                staffName: 'Staff On Duty',
                reason: 'Cancelled by restaurant staff',
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }
}
