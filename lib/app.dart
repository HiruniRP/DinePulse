import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/routes/app_router.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_1/services/restaurant_service.dart';
import 'package:dine_pulse/member_1/services/notification_service.dart';
import 'package:dine_pulse/member_1/services/reservation_service.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';
import 'package:dine_pulse/member_4/services/m4_queue_service.dart';
import 'package:dine_pulse/shared/providers/shared_firebase_provider.dart';

class DinePulseApp extends StatelessWidget {
  const DinePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Member 1 providers
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => RestaurantService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ReservationService()),
        // Member 2 providers
        ChangeNotifierProvider(create: (_) => M2ReservationService()),
        // Member 4 providers
        ChangeNotifierProvider(create: (_) => M4QueueService()),
        // Shared Firebase & Backend providers
        ChangeNotifierProvider(create: (_) => SharedFirebaseProvider.initialize()),
      ],
      child: MaterialApp(
        title: 'DinePulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
