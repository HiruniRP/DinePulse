import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart';
import 'package:dine_pulse/core/constants/app_constants.dart';
import 'package:dine_pulse/member_1/models/reservation_model.dart';
import 'package:dine_pulse/member_1/models/notification_model.dart';
import 'package:dine_pulse/member_1/services/reservation_service.dart';
import 'package:dine_pulse/member_1/services/notification_service.dart';
import 'package:dine_pulse/member_4/services/m4_queue_service.dart';
import 'package:dine_pulse/shared/providers/shared_firebase_provider.dart';

/// Screens 6 & 7: Reservation Summary + Confirm
class M2ReservationSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const M2ReservationSummaryScreen({super.key, required this.bookingData});

  @override
  State<M2ReservationSummaryScreen> createState() => _M2ReservationSummaryScreenState();
}

class _M2ReservationSummaryScreenState extends State<M2ReservationSummaryScreen> {
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.bookingData;
    final RestaurantModel? restaurant = d['restaurant'];
    final DateTime date = d['date'] ?? DateTime.now();
    final String time = d['time'] ?? '';
    final int partySize = d['partySize'] ?? 1;
    final String tableLocation = d['tableLocation'] ?? 'any';
    final M2TableModel? preferredTable = d['preferredTable'];
    final String? occasion = d['specialOccasion'];
    final String? requests = d['specialRequests'];
    final bool isRecurring = d['isRecurring'] ?? false;
    final String? recurringPattern = d['recurringPattern'];
    final int? recurringCount = d['recurringCount'];
    final bool smsReminder = d['smsReminder'] ?? true;
    final bool emailReminder = d['emailReminder'] ?? true;
    final int reminderMinutes = d['reminderMinutes'] ?? 60;
    final bool depositRequired = d['depositRequired'] ?? false;
    final double? depositAmount = d['depositAmount'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reservation Summary'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            M2StepHeader(currentStep: 3, totalSteps: 4, stepLabel: 'Review Details'),
            const SizedBox(height: 20),

            // Restaurant banner
            if (restaurant != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.restaurant, color: Colors.white, size: 28)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(restaurant.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(restaurant.address, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ])),
                  if (occasion != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.celebration, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(occasion[0].toUpperCase() + occasion.substring(1).replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ]),
              ),
            const SizedBox(height: 16),

            // Booking details card
            _summaryCard('Booking Details', [
              M2InfoRow(icon: Icons.calendar_today, label: 'Date', value: '${date.day}/${date.month}/${date.year} (${_dayName(date)})'),
              M2InfoRow(icon: Icons.access_time, label: 'Time', value: time),
              M2InfoRow(icon: Icons.people, label: 'Party Size', value: '$partySize guests'),
              M2InfoRow(icon: Icons.chair_alt, label: 'Seating Preference', value: tableLocation[0].toUpperCase() + tableLocation.substring(1)),
              if (preferredTable != null) M2InfoRow(icon: Icons.table_restaurant, label: 'Preferred Table', value: 'Table ${preferredTable.number} (${preferredTable.capacity} seats)'),
            ]),
            const SizedBox(height: 12),

            // Guest info
            _summaryCard('Guest Information', [
              M2InfoRow(icon: Icons.person, label: 'Name', value: d['customerName'] ?? ''),
              M2InfoRow(icon: Icons.phone, label: 'Phone', value: d['customerPhone'] ?? ''),
              M2InfoRow(icon: Icons.email, label: 'Email', value: d['customerEmail'] ?? ''),
              if (requests != null) M2InfoRow(icon: Icons.notes, label: 'Special Requests', value: requests),
            ]),
            const SizedBox(height: 12),

            // Options
            if (isRecurring || depositRequired) ...[
              _summaryCard('Options', [
                if (isRecurring) M2InfoRow(icon: Icons.repeat, label: 'Recurring', value: '${recurringPattern ?? ""} × ${recurringCount ?? ""}'),
                if (depositRequired) M2InfoRow(icon: Icons.payments, label: 'Deposit', value: 'LKR ${depositAmount?.toStringAsFixed(0) ?? "1,000"}', valueColor: AppTheme.success),
              ]),
              const SizedBox(height: 12),
            ],

            // Reminders
            _summaryCard('Reminders', [
              if (smsReminder) M2InfoRow(icon: Icons.sms_outlined, label: 'SMS/WhatsApp', value: '${_reminderLabel(reminderMinutes)} before'),
              if (emailReminder) M2InfoRow(icon: Icons.email_outlined, label: 'Email', value: '${_reminderLabel(reminderMinutes)} before'),
              if (!smsReminder && !emailReminder) const M2InfoRow(icon: Icons.notifications_off, label: 'Reminders', value: 'No reminders'),
            ]),
            const SizedBox(height: 12),

            // SMS / WhatsApp preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF128C7E).withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF128C7E).withAlpha(60)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.chat_bubble_outline, color: Color(0xFF128C7E), size: 18),
                  SizedBox(width: 8),
                  Text('SMS / WhatsApp Preview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF128C7E))),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'DinePulse: Your reservation at ${restaurant?.name ?? "Restaurant"} is confirmed for ${date.day}/${date.month}/${date.year} at $time for $partySize guests. Booking ID: [DP-XXXXXXXX]. View details in the DinePulse app.',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.5),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Confirm CTA
            _confirming
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Reservation'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppTheme.accent.withOpacity(0.35),
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Edit Details')),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ]),
    );
  }

  Widget _summaryCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),
        ...rows,
      ]),
    );
  }

  String _dayName(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  String _reminderLabel(int mins) {
    if (mins < 60) return '$mins minutes';
    if (mins == 60) return '1 hour';
    if (mins < 1440) return '${mins ~/ 60} hours';
    return '1 day';
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    final service = context.read<M2ReservationService>();
    final auth = context.read<AuthService>();
    final d = widget.bookingData;
    final RestaurantModel? restaurant = d['restaurant'];

    final result = await service.createReservation(
      customerId: auth.currentUser?.uid ?? 'guest',
      customerName: d['customerName'] ?? '',
      customerPhone: d['customerPhone'] ?? '',
      customerEmail: d['customerEmail'] ?? '',
      restaurant: restaurant ?? RestaurantModel(
        id: 'unknown', name: 'Restaurant', description: '', cuisine: '',
        address: '', city: '', rating: 0, reviewCount: 0, priceRange: r'$', imageUrls: [],
      ),
      date: d['date'],
      time: d['time'],
      partySize: d['partySize'] ?? 1,
      preferredTableId: (d['preferredTable'] as M2TableModel?)?.id,
      preferredTableNumber: (d['preferredTable'] as M2TableModel?)?.number,
      tableLocation: d['tableLocation'] ?? 'any',
      specialRequests: d['specialRequests'],
      specialOccasion: d['specialOccasion'],
      isRecurring: d['isRecurring'] ?? false,
      recurringPattern: d['recurringPattern'],
      recurringCount: d['recurringCount'],
      smsReminder: d['smsReminder'] ?? true,
      emailReminder: d['emailReminder'] ?? true,
      reminderMinutes: d['reminderMinutes'] ?? 60,
      depositRequired: d['depositRequired'] ?? false,
      depositAmount: d['depositAmount'],
      cancellationPolicyAccepted: d['policyAccepted'] ?? true,
    );

    if (!mounted) return;
    setState(() => _confirming = false);

    if (result != null) {
      // 1. Cross-module sync: Lock table in Member 4 queue service
      final tableRef = result.preferredTableNumber ?? result.assignedTableNumber ?? (d['preferredTable'] as M2TableModel?)?.number ?? 'T1';
      context.read<M4QueueService>().markTableReservedFromM2(
        tableNumberOrId: tableRef,
        customerName: result.customerName,
      );

      // 2. Cross-module sync: Synchronize with Member 1's My Reservations
      context.read<ReservationService>().addOrUpdateReservation(
        ReservationModel(
          id: result.bookingId,
          customerId: result.customerId,
          customerName: result.customerName,
          restaurantId: result.restaurantId,
          restaurantName: result.restaurantName,
          restaurantImage: result.restaurantImage,
          date: result.date,
          time: result.time,
          partySize: result.partySize,
          status: AppConstants.statusConfirmed,
          specialRequests: result.specialRequests,
          tableNumber: tableRef,
          createdAt: result.createdAt,
        ),
      );

      // 3. Cross-module sync: Push real-time notification to Member 1
      context.read<NotificationService>().addNotification(
        NotificationModel(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          userId: result.customerId,
          title: 'Reservation Confirmed! 🎉',
          body: 'Your table at ${result.restaurantName} for ${result.partySize} guests on ${result.date.day}/${result.date.month} at ${result.time} is reserved (Table $tableRef).',
          type: AppConstants.notifReservation,
          isRead: false,
          createdAt: DateTime.now(),
          data: {'reservationId': result.bookingId, 'restaurantId': result.restaurantId},
        ),
      );

      // 4. Update SharedTableRepository if accessible
      try {
        final shared = context.read<SharedFirebaseProvider>();
        shared.tableRepository.lockTableForReservation(
          restaurantId: result.restaurantId,
          tableId: tableRef,
          reservationId: result.bookingId,
          customerName: result.customerName,
        );
      } catch (_) {}

      Navigator.pushNamedAndRemoveUntil(context, '/m2/reservation-success', (r) => r.settings.name == '/m1/home', arguments: result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create reservation. Please try again.')));
    }
  }
}
