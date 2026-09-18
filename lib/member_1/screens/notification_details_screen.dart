import 'package:flutter/material.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/constants/app_constants.dart';
import 'package:dine_pulse/member_1/models/notification_model.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final NotificationModel? notification;
  const NotificationDetailsScreen({super.key, this.notification});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    if (n == null) return const Scaffold(body: Center(child: Text('Notification not found')));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Notification Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and type banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_iconColor(n.type).withOpacity(0.08), _iconColor(n.type).withOpacity(0.02)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _iconColor(n.type).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _iconColor(n.type).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconData(n.type), color: _iconColor(n.type), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _typeName(n.type),
                          style: TextStyle(color: _iconColor(n.type), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 4),
                        Text(n.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [AppTheme.cardBoxShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHint, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Text(n.body, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Timestamp
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [AppTheme.cardBoxShadow],
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(n.createdAt),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Action button if it's a reservation notification
            if (n.type == AppConstants.notifReservation || n.type == AppConstants.notifReminder) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('View Reservation'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],

            if (n.type == AppConstants.notifPromotion) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant, size: 18),
                  label: const Text('View Restaurant'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconData(String type) {
    switch (type) {
      case AppConstants.notifReservation: return Icons.calendar_today;
      case AppConstants.notifPromotion: return Icons.local_offer;
      case AppConstants.notifReminder: return Icons.alarm;
      default: return Icons.notifications;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case AppConstants.notifReservation: return AppTheme.primary;
      case AppConstants.notifPromotion: return AppTheme.accent;
      case AppConstants.notifReminder: return AppTheme.warning;
      default: return AppTheme.info;
    }
  }

  String _typeName(String type) {
    switch (type) {
      case AppConstants.notifReservation: return 'RESERVATION';
      case AppConstants.notifPromotion: return 'PROMOTION';
      case AppConstants.notifReminder: return 'REMINDER';
      default: return 'NOTIFICATION';
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$min $period';
  }
}
