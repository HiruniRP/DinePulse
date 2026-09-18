import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';

import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_1/services/reservation_service.dart';
import 'package:dine_pulse/member_1/models/reservation_model.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.currentUser != null) {
        context.read<ReservationService>().loadReservations(auth.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Reservations'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: Consumer<ReservationService>(
        builder: (context, svc, _) {
          if (svc.isLoading) return const CenteredLoader();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _ReservationList(
                reservations: svc.upcomingReservations,
                emptyIcon: Icons.calendar_today_outlined,
                emptyTitle: 'No Upcoming Reservations',
                emptySubtitle: 'Discover and reserve a restaurant to get started',
                emptyAction: 'Find Restaurants',
                onEmptyAction: () => Navigator.pushNamed(context, AppRoutes.m1RestaurantSearch),
              ),
              _ReservationList(
                reservations: svc.pastReservations,
                emptyIcon: Icons.history,
                emptyTitle: 'No Past Reservations',
                emptySubtitle: 'Your dining history will appear here',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReservationList extends StatelessWidget {
  final List<ReservationModel> reservations;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final String? emptyAction;
  final VoidCallback? onEmptyAction;

  const _ReservationList({
    required this.reservations,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.emptyAction,
    this.onEmptyAction,
  });

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return EmptyStateWidget(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: emptyAction,
        onAction: onEmptyAction,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      itemBuilder: (context, i) => _ReservationCard(reservation: reservations[i]),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.m1ReservationDetails, arguments: r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            // Header with restaurant image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: r.restaurantImage.isNotEmpty
                    ? Image.network(r.restaurantImage, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder())
                    : _imagePlaceholder(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.restaurantName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(status: r.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(Icons.calendar_today, AppFormatters2.formatDate(r.date)),
                      const SizedBox(width: 8),
                      _InfoChip(Icons.access_time, r.time),
                      const SizedBox(width: 8),
                      _InfoChip(Icons.people, '${r.partySize} guests'),
                    ],
                  ),
                  if (r.tableNumber != null) ...[
                    const SizedBox(height: 6),
                    _InfoChip(Icons.table_restaurant, 'Table ${r.tableNumber}'),
                  ],
                  if (r.specialRequests != null && r.specialRequests!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes, size: 14, color: AppTheme.textHint),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r.specialRequests!,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.chevron_right, color: AppTheme.accent, size: 16),
                    Text('View Details', style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: AppTheme.primary.withOpacity(0.08),
    child: const Center(child: Icon(Icons.restaurant, size: 36, color: AppTheme.primary)),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class AppFormatters2 {
  static String formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month-1]} ${d.day}, ${d.year}';
  }
}
