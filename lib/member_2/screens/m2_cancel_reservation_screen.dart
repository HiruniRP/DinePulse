import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';

/// Screen 11: Cancel Reservation Screen
class M2CancelReservationScreen extends StatefulWidget {
  final M2ReservationModel reservation;

  const M2CancelReservationScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<M2CancelReservationScreen> createState() => _M2CancelReservationScreenState();
}

class _M2CancelReservationScreenState extends State<M2CancelReservationScreen> {
  final _reasonCtrl = TextEditingController();
  String _selectedReason = 'Change of plans';
  bool _understandPolicy = false;
  bool _isLoading = false;

  final List<String> _reasons = [
    'Change of plans',
    'Emergency / Illness',
    'Found another restaurant',
    'Booked by mistake / duplicate',
    'Weather or travel issues',
    'Scheduling conflict',
    'Other reason',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Cancel Reservation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you sure you want to cancel?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.error,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This will release your reserved table and notify the restaurant immediately.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reservation Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r.restaurantName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.bookingId,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _infoRow(Icons.calendar_today_outlined, 'Date', AppFormatters.formatDate(r.date)),
                  const SizedBox(height: 8),
                  _infoRow(Icons.access_time_outlined, 'Time', r.time),
                  const SizedBox(height: 8),
                  _infoRow(Icons.people_outline, 'Party Size', '${r.partySize} Guests'),
                  if (r.assignedTableNumber != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(Icons.table_restaurant_outlined, 'Table', 'Table #${r.assignedTableNumber}'),
                  ],
                  if (r.depositAmount != null && r.depositAmount! > 0) ...[
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.payment_outlined,
                      'Deposit Paid',
                      '\$${r.depositAmount!.toStringAsFixed(2)} (Eligible for refund)',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cancellation Reason Selection
            const Text(
              'Select Cancellation Reason',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _reasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional details note
            const Text(
              'Additional Comments (Optional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Let the restaurant know if you want to reschedule...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 24),

            // Policy & refund info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'Cancellation Policy Notice',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Free cancellation up to 2 hours before reservation time.\n'
                    '• If deposit was paid, refund will be processed within 3-5 business days.\n'
                    '• Late cancellations (under 2 hours) may incur a small fee.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _understandPolicy,
                          activeColor: AppTheme.error,
                          onChanged: (val) => setState(() => _understandPolicy = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'I understand and accept the cancellation terms',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_understandPolicy && !_isLoading) ? _handleCancellation : null,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Cancellation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Keep My Reservation',
                  style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
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
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _handleCancellation() async {
    setState(() => _isLoading = true);
    final service = context.read<M2ReservationService>();
    final auth = context.read<AuthService>();
    final actorId = auth.currentUser?.uid ?? widget.reservation.customerId;
    final actorName = auth.currentUser?.fullName ?? widget.reservation.customerName;

    final fullReason = _reasonCtrl.text.trim().isNotEmpty
        ? '$_selectedReason - ${_reasonCtrl.text.trim()}'
        : _selectedReason;

    final success = await service.cancelReservation(
      reservationId: widget.reservation.id,
      actorId: actorId,
      actorName: actorName,
      reason: fullReason,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      SnackBarHelper.showSuccess(context, 'Reservation cancelled successfully');
      Navigator.pop(context, true);
    } else {
      SnackBarHelper.showError(context, 'Failed to cancel reservation. Please try again.');
    }
  }
}
