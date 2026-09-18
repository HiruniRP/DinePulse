import 'package:flutter/material.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart';

/// Screen 8: Reservation Success
class M2ReservationSuccessScreen extends StatefulWidget {
  final M2ReservationModel reservation;

  const M2ReservationSuccessScreen({super.key, required this.reservation});

  @override
  State<M2ReservationSuccessScreen> createState() => _M2ReservationSuccessScreenState();
}

class _M2ReservationSuccessScreenState extends State<M2ReservationSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _checkAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 200), () {
      _checkCtrl.forward();
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose(); _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const SizedBox(height: 20),
              // Animated check
              ScaleTransition(
                scale: _checkAnim,
                child: Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 56),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Reservation Confirmed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Your table at ${r.restaurantName} has been successfully booked.', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // Booking ID
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  const Text('Booking ID', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(r.bookingId, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _pill(Icons.calendar_today, '${r.date.day}/${r.date.month}/${r.date.year}'),
                    const SizedBox(width: 10),
                    _pill(Icons.access_time, r.time),
                    const SizedBox(width: 10),
                    _pill(Icons.people, '${r.partySize}'),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),

              // QR Code
              const Text('Your QR Code', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 10),
              M2QrCode(bookingId: r.bookingId),
              const SizedBox(height: 4),
              const Text('Show at the restaurant', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
              const SizedBox(height: 24),

              // Actions
              Row(children: [
                Expanded(child: _actionBtn(Icons.calendar_today_outlined, 'Add to Calendar', _addToCalendar)),
                const SizedBox(width: 10),
                Expanded(child: _actionBtn(Icons.share_outlined, 'Share', _share)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _actionBtn(Icons.chat_bubble_outline, 'WhatsApp', _whatsApp, color: const Color(0xFF128C7E))),
                const SizedBox(width: 10),
                Expanded(child: _actionBtn(Icons.download_outlined, 'Save QR', _saveQr)),
              ]),
              const SizedBox(height: 24),

              // Estimated wait / table info
              if (r.assignedTableNumber != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.success.withAlpha(20), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.success.withAlpha(60))),
                  child: Row(children: [
                    const Icon(Icons.table_restaurant, color: AppTheme.success),
                    const SizedBox(width: 10),
                    Text('Table ${r.assignedTableNumber} assigned to you!', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.success)),
                  ]),
                ),
              const SizedBox(height: 24),

              // Navigation
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/m2/my-reservations', (r) => r.settings.name == AppRoutes.m1Home),
                child: const Text('View My Reservations'),
              )),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.m1Home, (r) => false),
                child: const Text('Back to Home'),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 13),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primary).withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (color ?? AppTheme.primary).withAlpha(60)),
        ),
        child: Column(children: [
          Icon(icon, color: color ?? AppTheme.primary, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color ?? AppTheme.primary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _addToCalendar() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adding to calendar... (TODO: calendar_events package)')));
  void _share() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sharing: ${widget.reservation.bookingId}')));
  void _whatsApp() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening WhatsApp... (TODO: url_launcher)')));
  void _saveQr() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving QR code...')));
}
