import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';
import 'package:dine_pulse/core/widgets/auth_gate.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_1/screens/login_screen.dart';
import 'package:dine_pulse/member_1/screens/create_account_screen.dart';
import 'package:dine_pulse/member_1/screens/home_screen.dart';
import 'package:dine_pulse/member_1/screens/restaurant_search_screen.dart';
import 'package:dine_pulse/member_1/screens/search_results_screen.dart';
import 'package:dine_pulse/member_1/screens/restaurant_details_screen.dart';
import 'package:dine_pulse/member_1/screens/restaurant_info_screen.dart';
import 'package:dine_pulse/member_1/screens/notifications_screen.dart';
import 'package:dine_pulse/member_1/screens/notification_details_screen.dart';
import 'package:dine_pulse/member_1/screens/my_reservations_screen.dart';
import 'package:dine_pulse/member_1/screens/reservation_details_screen.dart';
import 'package:dine_pulse/member_1/screens/profile_screen.dart';
import 'package:dine_pulse/member_1/screens/edit_profile_screen.dart';
import 'package:dine_pulse/member_1/screens/logout_confirm_screen.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';
import 'package:dine_pulse/member_1/models/notification_model.dart';
import 'package:dine_pulse/member_1/models/reservation_model.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/screens/m2_table_availability_screen.dart';
import 'package:dine_pulse/member_2/screens/m2_reservation_form_screen.dart';
import 'package:dine_pulse/member_2/screens/m2_reservation_summary_screen.dart';
import 'package:dine_pulse/member_2/screens/m2_reservation_success_screen.dart';
import 'package:dine_pulse/member_2/screens/m2_my_reservations_screen.dart';
import 'package:dine_pulse/member_2/screens/m2_reservation_details_screen.dart';
import 'package:dine_pulse/member_2/screens/m2_modify_reservation_screen.dart';
import 'package:dine_pulse/member_2/screens/m2_cancel_reservation_screen.dart';
import 'package:dine_pulse/member_2/screens/m2_staff_dashboard_screen.dart';
import 'package:dine_pulse/member_2/screens/m2_staff_details_screen.dart';
import 'package:dine_pulse/member_4/models/m4_queue_model.dart';
import 'package:dine_pulse/member_4/screens/m4_join_queue_screen.dart';
import 'package:dine_pulse/member_4/screens/m4_live_ticket_screen.dart';
import 'package:dine_pulse/member_4/screens/m4_staff_queue_dashboard_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fadeRoute(const AuthGate(), settings);

      case AppRoutes.login:
        return _fadeRoute(const LoginScreen(), settings);

      case AppRoutes.createAccount:
        return _slideRoute(const CreateAccountScreen(), settings);

      case AppRoutes.m1Home:
        return _fadeRoute(const HomeScreen(), settings);

      case AppRoutes.m1RestaurantSearch:
        return _slideRoute(const RestaurantSearchScreen(), settings);

      case AppRoutes.m1SearchResults:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          SearchResultsScreen(
            query: args?['query'] as String? ?? '',
            cuisine: args?['cuisine'] as String?,
          ),
          settings,
        );

      case AppRoutes.m1RestaurantDetails:
        final restaurant = settings.arguments as RestaurantModel?;
        return _slideRoute(
          RestaurantDetailsScreen(restaurant: restaurant),
          settings,
        );

      case AppRoutes.m1RestaurantInfo:
        final restaurant = settings.arguments as RestaurantModel?;
        return _slideRoute(
          RestaurantInfoScreen(restaurant: restaurant),
          settings,
        );

      case AppRoutes.m1Notifications:
        return _slideRoute(const NotificationsScreen(), settings);

      case AppRoutes.m1NotificationDetails:
        final notification = settings.arguments as NotificationModel?;
        return _slideRoute(
          NotificationDetailsScreen(notification: notification),
          settings,
        );

      case AppRoutes.m1MyReservations:
        return _slideRoute(const MyReservationsScreen(), settings);

      case AppRoutes.m1ReservationDetails:
        final reservation = settings.arguments as ReservationModel?;
        return _slideRoute(
          ReservationDetailsScreen(reservation: reservation),
          settings,
        );

      case AppRoutes.m1Profile:
        return _slideRoute(const ProfileScreen(), settings);

      case AppRoutes.m1EditProfile:
        return _slideRoute(const EditProfileScreen(), settings);

      case AppRoutes.m1LogoutConfirm:
        return _dialogRoute(const LogoutConfirmScreen(), settings);

      // Member 2 routes – Customer & Staff Reservation Flow
      case AppRoutes.m2TableAvailability:
      case AppRoutes.m2MakeReservation:
        final restaurant = settings.arguments as RestaurantModel?;
        return _slideRoute(M2TableAvailabilityScreen(restaurant: restaurant), settings);

      case AppRoutes.m2ReservationForm:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          M2ReservationFormScreen(
            restaurant: args?['restaurant'] as RestaurantModel?,
            initialDate: args?['date'] as DateTime?,
            initialTime: args?['time'] as String?,
            initialPartySize: args?['partySize'] as int?,
            selectedTable: (args?['selectedTable'] ?? args?['table']) as M2TableModel?,
          ),
          settings,
        );

      case AppRoutes.m2ReservationSummary:
        final args = settings.arguments as Map<String, dynamic>;
        return _slideRoute(M2ReservationSummaryScreen(bookingData: args), settings);

      case AppRoutes.m2ReservationSuccess:
        final reservation = settings.arguments as M2ReservationModel;
        return _slideRoute(M2ReservationSuccessScreen(reservation: reservation), settings);

      case AppRoutes.m2MyReservations:
      case AppRoutes.m2ReservationManagement:
        return _slideRoute(const M2MyReservationsScreen(), settings);

      case AppRoutes.m2ReservationDetail:
        final reservation = settings.arguments as M2ReservationModel;
        return _slideRoute(M2ReservationDetailsScreen(reservation: reservation), settings);

      case AppRoutes.m2ModifyReservation:
        final reservation = settings.arguments as M2ReservationModel;
        return _slideRoute(M2ModifyReservationScreen(reservation: reservation), settings);

      case AppRoutes.m2CancelReservation:
        final reservation = settings.arguments as M2ReservationModel;
        return _slideRoute(M2CancelReservationScreen(reservation: reservation), settings);

      case AppRoutes.m2StaffDashboard:
        return _slideRoute(
          const _StaffGuardWidget(child: M2StaffDashboardScreen()),
          settings,
        );

      case AppRoutes.m2StaffDetails:
        final reservation = settings.arguments as M2ReservationModel;
        return _slideRoute(
          _StaffGuardWidget(child: M2StaffDetailsScreen(reservation: reservation)),
          settings,
        );

      // Member 4 – Virtual Queue & Table Management
      case AppRoutes.m4JoinQueue:
        final restaurant = settings.arguments as RestaurantModel?;
        return _slideRoute(M4JoinQueueScreen(restaurant: restaurant), settings);

      case AppRoutes.m4LiveTicket:
        final ticket = settings.arguments as M4QueueTicket;
        return _slideRoute(M4LiveTicketScreen(ticket: ticket), settings);

      case AppRoutes.m4QueueDashboard:
      case AppRoutes.m4StaffQueue:
      case AppRoutes.m4TableManagement:
        return _slideRoute(
          const _StaffGuardWidget(child: M4StaffQueueDashboardScreen()),
          settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }

  static PageRoute _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  static PageRoute _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRoute _dialogRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

/// Role-based access guard for staff screens
class _StaffGuardWidget extends StatelessWidget {
  final Widget child;
  const _StaffGuardWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final isStaff = auth.currentUser?.isStaff ?? false;

    if (!isStaff) {
      return Scaffold(
        appBar: AppBar(title: const Text('Staff Access')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppTheme.accent),
                const SizedBox(height: 16),
                const Text(
                  'Staff Permissions Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This operational screen is restricted to restaurant staff, managers, and administrators.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Switch to Staff Role (Demo)'),
                  onPressed: () {
                    auth.switchRole('staff');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => child),
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to App'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return child;
  }
}
