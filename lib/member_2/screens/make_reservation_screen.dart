// Member 2 placeholder – screens will be implemented by Member 2
// Reservation & Staff Reservation Management
import 'package:flutter/material.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';

/// Placeholder screen that Member 1 routes to for making a reservation.
/// Member 2 will replace this with full implementation.
class MakeReservationScreen extends StatelessWidget {
  final RestaurantModel? restaurant;
  const MakeReservationScreen({super.key, this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(restaurant != null ? 'Reserve – ${restaurant!.name}' : 'Make Reservation')),
      body: EmptyStateWidget(
        icon: Icons.construction_outlined,
        title: 'Coming Soon',
        subtitle: 'Member 2 is implementing the Reservation flow.\nThis screen will be available shortly.',
        actionLabel: 'Go Back',
        onAction: () => Navigator.pop(context),
      ),
    );
  }
}
