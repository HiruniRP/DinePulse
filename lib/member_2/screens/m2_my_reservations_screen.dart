import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart';

/// Screen 9: Customer – My Reservations
class M2MyReservationsScreen extends StatefulWidget {
  const M2MyReservationsScreen({super.key});

  @override
  State<M2MyReservationsScreen> createState() => _M2MyReservationsScreenState();
}

class _M2MyReservationsScreenState extends State<M2MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<M2ReservationService>();
    final auth = context.watch<AuthService>();
    // Use 'cust1' as demo customer so we see seeded data
    final customerId = auth.currentUser?.uid ?? 'cust1';
    final all = service.getCustomerReservations(customerId.isEmpty ? 'cust1' : customerId);
    final upcoming = all.where((r) => r.isUpcoming).toList();
    final past = all.where((r) => !r.isUpcoming && r.status != M2ReservationStatus.cancelled).toList();
    final cancelled = all.where((r) => r.status == M2ReservationStatus.cancelled).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Reservations'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Past (${past.length})'),
            Tab(text: 'Cancelled (${cancelled.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildList(upcoming, showActions: true),
          _buildList(past),
          _buildList(cancelled),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/m2/table-availability'),
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Reservation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildList(List<M2ReservationModel> list, {bool showActions = false}) {
    if (list.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_available_outlined,
        title: 'No Reservations',
        subtitle: showActions ? 'You have no upcoming reservations.\nMake one now!' : 'Nothing to show here.',
        actionLabel: showActions ? 'Make Reservation' : null,
        onAction: showActions ? () => Navigator.pushNamed(context, '/m2/table-availability') : null,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final r = list[i];
        return M2ReservationCard(
          reservation: r,
          showActions: showActions && r.canModify,
          onTap: () => Navigator.pushNamed(context, '/m2/reservation-detail', arguments: r),
          onModify: () => Navigator.pushNamed(context, '/m2/modify-reservation', arguments: r),
          onCancel: () => _showCancelDialog(r),
        );
      },
    );
  }

  void _showCancelDialog(M2ReservationModel r) {
    showDialog(
      context: context,
      builder: (ctx) => _CancelDialog(reservation: r),
    );
  }
}

class _CancelDialog extends StatefulWidget {
  final M2ReservationModel reservation;
  const _CancelDialog({required this.reservation});

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cancel Reservation', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Are you sure you want to cancel booking ${widget.reservation.bookingId}?', style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        TextField(
          controller: _reasonCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.error.withAlpha(15), borderRadius: BorderRadius.circular(8)),
          child: const Text('Free cancellation if done 2+ hours before the reservation.', style: TextStyle(fontSize: 12, color: AppTheme.error)),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Reservation')),
        _loading
            ? const SizedBox(width: 80, child: Center(child: CircularProgressIndicator(color: AppTheme.accent)))
            : ElevatedButton(
                onPressed: _cancel,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                child: const Text('Cancel Booking'),
              ),
      ],
    );
  }

  Future<void> _cancel() async {
    setState(() => _loading = true);
    final service = context.read<M2ReservationService>();
    final ok = await service.cancelReservation(
      reservationId: widget.reservation.id,
      actorId: 'cust1',
      actorName: widget.reservation.customerName,
      reason: _reasonCtrl.text.trim().isEmpty ? 'Customer cancelled' : _reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Reservation cancelled.' : 'Failed to cancel. Try again.'),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
  }
}
