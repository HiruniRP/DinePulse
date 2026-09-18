import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_1/models/reservation_model.dart';
import 'package:dine_pulse/member_1/services/reservation_service.dart';
import 'package:dine_pulse/member_1/screens/my_reservations_screen.dart' show AppFormatters2;

class ReservationDetailsScreen extends StatelessWidget {
  final ReservationModel? reservation;
  const ReservationDetailsScreen({super.key, this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    if (r == null) return const Scaffold(body: Center(child: Text('Reservation not found')));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Reservation Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Restaurant header card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: r.restaurantImage.isNotEmpty
                          ? Image.network(r.restaurantImage, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.restaurantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text('Booked on ${AppFormatters2.formatDate(r.createdAt)}', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                            ],
                          ),
                        ),
                        StatusBadge(status: r.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Booking details card
            _DetailCard(
              title: 'Booking Details',
              children: [
                _DetailRow(icon: Icons.confirmation_number, label: 'Booking ID', value: '#${r.id.substring(0, 8).toUpperCase()}'),
                _DetailRow(icon: Icons.calendar_today, label: 'Date', value: AppFormatters2.formatDate(r.date)),
                _DetailRow(icon: Icons.access_time, label: 'Time', value: r.time),
                _DetailRow(icon: Icons.people, label: 'Party Size', value: '${r.partySize} guest${r.partySize > 1 ? 's' : ''}'),
                if (r.tableNumber != null)
                  _DetailRow(icon: Icons.table_restaurant, label: 'Table', value: r.tableNumber!),
              ],
            ),
            const SizedBox(height: 12),

            // Special requests
            if (r.specialRequests != null && r.specialRequests!.isNotEmpty) ...[
              _DetailCard(
                title: 'Special Requests',
                children: [
                  Text(r.specialRequests!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Guest info
            _DetailCard(
              title: 'Guest Information',
              children: [
                _DetailRow(icon: Icons.person, label: 'Name', value: r.customerName),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (r.canCancel)
              Consumer<ReservationService>(
                builder: (context, svc, _) => SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                    label: const Text('Cancel Reservation', style: TextStyle(color: AppTheme.error)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                    onPressed: () => _showCancelDialog(context, svc, r.id),
                  ),
                ),
              ),

            if (r.status == 'completed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Leave a Review'),
                  onPressed: () {},
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.primary.withOpacity(0.08),
    child: const Center(child: Icon(Icons.restaurant, size: 40, color: AppTheme.primary)),
  );

  void _showCancelDialog(BuildContext context, ReservationService svc, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Reservation', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this reservation? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await svc.cancelReservation(id);
              if (context.mounted) {
                if (ok) {
                  SnackBarHelper.showSuccess(context, 'Reservation cancelled successfully');
                  Navigator.pop(context);
                } else {
                  SnackBarHelper.showError(context, 'Failed to cancel reservation');
                }
              }
            },
            child: const Text('Cancel Reservation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
