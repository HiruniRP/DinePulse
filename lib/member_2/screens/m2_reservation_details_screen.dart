import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart';

/// Screen: Customer Reservation Details
class M2ReservationDetailsScreen extends StatelessWidget {
  final M2ReservationModel reservation;

  const M2ReservationDetailsScreen({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    // Watch service so real-time status changes update this screen
    final service = context.watch<M2ReservationService>();
    final currentReservation = service.reservations.firstWhere(
      (r) => r.id == reservation.id,
      orElse: () => reservation,
    );
    final r = currentReservation;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reservation Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (r.canModify)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modify',
              onPressed: () => Navigator.pushNamed(
                context,
                '/m2/modify-reservation',
                arguments: r,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status & QR Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
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
                          const Text(
                            'BOOKING REFERENCE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textHint,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.bookingId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      M2StatusBadge(status: r.status),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // QR code widget
                  M2QrCode(bookingId: r.bookingId),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan at restaurant entrance upon arrival',
                    style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Restaurant & Booking Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
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
                  Text(
                    r.restaurantName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 14),
                  _detailRow(Icons.calendar_today_outlined, 'Date', AppFormatters.formatDate(r.date)),
                  const Divider(height: 18),
                  _detailRow(Icons.access_time, 'Time Slot', r.time),
                  const Divider(height: 18),
                  _detailRow(Icons.people_outline, 'Party Size', '${r.partySize} Guests'),
                  if (r.assignedTableNumber != null) ...[
                    const Divider(height: 18),
                    _detailRow(
                      Icons.table_restaurant_outlined,
                      'Assigned Table',
                      'Table #${r.assignedTableNumber}',
                      highlight: true,
                    ),
                  ],
                  if (r.tableLocation != 'any') ...[
                    const Divider(height: 18),
                    _detailRow(Icons.place_outlined, 'Preferred Area', r.tableLocation),
                  ],
                  if (r.specialOccasion != null) ...[
                    const Divider(height: 18),
                    _detailRow(Icons.celebration_outlined, 'Special Occasion', r.specialOccasion!),
                  ],
                  if (r.specialRequests != null && r.specialRequests!.isNotEmpty) ...[
                    const Divider(height: 18),
                    _detailRow(Icons.notes_outlined, 'Special Requests', r.specialRequests!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pre-order & Payment Summary if present
            if (r.preOrderItems.isNotEmpty || (r.depositAmount != null && r.depositAmount! > 0))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
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
                    const Text(
                      'Pre-Orders & Payment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    if (r.preOrderItems.isNotEmpty) ...[
                      ...r.preOrderItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.quantity}x ${item.menuItemName}', style: const TextStyle(fontSize: 13)),
                            Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      )),
                      const Divider(height: 16),
                    ],
                    if (r.depositAmount != null && r.depositAmount! > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Deposit Paid', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            '\$${r.depositAmount!.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.success),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

            // Quick Actions: Calendar, Share, WhatsApp preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          context,
                          icon: Icons.calendar_today_outlined,
                          label: 'Calendar',
                          onTap: () => SnackBarHelper.showSuccess(context, 'Added to your calendar!'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          context,
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: () => SnackBarHelper.showSuccess(context, 'Sharing reservation link...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          context,
                          icon: Icons.chat_bubble_outline,
                          label: 'SMS / Msg',
                          color: const Color(0xFF128C7E),
                          onTap: () => _showSmsPreview(context, r),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Modification & Cancellation CTA
            if (r.canModify) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                      icon: const Icon(Icons.edit_calendar_outlined, color: AppTheme.primary, size: 18),
                      label: const Text('Modify', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/m2/modify-reservation',
                        arguments: r,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppTheme.error),
                      ),
                      icon: const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 18),
                      label: const Text('Cancel', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/m2/cancel-reservation',
                        arguments: r,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: highlight ? AppTheme.primary : AppTheme.textHint),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: highlight ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppTheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c),
            ),
          ],
        ),
      ),
    );
  }

  void _showSmsPreview(BuildContext context, M2ReservationModel r) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SMS / WhatsApp Preview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Text(
                '🍽 DinePulse: Your reservation at ${r.restaurantName} is confirmed for '
                '${AppFormatters.formatDate(r.date)} at ${r.time} for ${r.partySize} guests. '
                'Booking ID: ${r.bookingId}. Show your QR code on arrival!',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                  shadowColor: AppTheme.accent.withOpacity(0.35),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  SnackBarHelper.showSuccess(context, 'Confirmation message sent!');
                },
                child: const Text('Send Confirmation Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
