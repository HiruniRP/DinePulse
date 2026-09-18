import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';
import 'package:dine_pulse/core/constants/app_constants.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_1/services/restaurant_service.dart';
import 'package:dine_pulse/member_1/services/notification_service.dart';
import 'package:dine_pulse/member_1/widgets/restaurant_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantService>().loadRestaurants();
      final auth = context.read<AuthService>();
      if (auth.currentUser != null) {
        context.read<NotificationService>().loadNotifications(auth.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: const _HomeTab(),
      bottomNavigationBar: Consumer<NotificationService>(
        builder: (context, notif, _) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 1) {
                Navigator.pushNamed(context, AppRoutes.m1RestaurantSearch);
              } else if (index == 2) {
                Navigator.pushNamed(context, AppRoutes.m1MyReservations);
              } else if (index == 3) {
                Navigator.pushNamed(context, AppRoutes.m1Profile);
              } else {
                setState(() => _currentIndex = 0);
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Reservations'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person), label: 'Profile'),
            ],
          );
        },
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, RestaurantService>(
      builder: (context, auth, restaurantSvc, _) {
        final user = auth.currentUser;
        final isLoading = restaurantSvc.isLoading;

        return CustomScrollView(
          slivers: [
            // App bar with greeting
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _greeting(),
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    user?.firstName ?? 'Guest',
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Notifications bell
                              Consumer<NotificationService>(
                                builder: (context, notif, _) => Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                                      onPressed: () => Navigator.pushNamed(context, AppRoutes.m1Notifications),
                                    ),
                                    if (notif.unreadCount > 0)
                                      Positioned(
                                        right: 8, top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                                          child: Text('${notif.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Avatar
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRoutes.m1Profile),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white.withOpacity(0.25),
                                  child: Text(
                                    user?.initials ?? 'G',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Search bar tap target
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRoutes.m1RestaurantSearch),
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.search, color: Colors.white70, size: 20),
                                  SizedBox(width: 10),
                                  Text('Search restaurants, cuisine...', style: TextStyle(color: Colors.white60, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (isLoading)
              const SliverFillRemaining(child: CenteredLoader())
            else ...[
              // Staff Portal Banner (Role-based access)
              if (user?.isStaff == true)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: AppTheme.accent, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Staff Operations Mode',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user!.role.toUpperCase(),
                                style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.table_restaurant, size: 16),
                                label: const Text('M2 Reservations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.m2StaffDashboard),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.people_alt, size: 16),
                                label: const Text('M4 Queue & Tables', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.m4StaffQueue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Cuisine filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SectionHeader(title: 'Cuisines'),
                      ),
                      const SizedBox(height: 12),
                      CuisineFilterChips(
                        selectedCuisine: 'All',
                        cuisines: ['All', ...AppConstants.cuisineTypes.skip(1)],
                        onSelected: (cuisine) {
                          Navigator.pushNamed(
                            context, AppRoutes.m1SearchResults,
                            arguments: {'query': '', 'cuisine': cuisine == 'All' ? null : cuisine},
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Featured restaurants header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: SectionHeader(title: '⭐ Top Rated'),
                ),
              ),

              // Featured horizontal scroll
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: restaurantSvc.featuredRestaurants.length,
                    itemBuilder: (context, i) {
                      final r = restaurantSvc.featuredRestaurants[i];
                      return FeaturedRestaurantCard(
                        restaurant: r,
                        onFavorite: () => restaurantSvc.toggleFavorite(r.id),
                      );
                    },
                  ),
                ),
              ),

              // Nearby header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: SectionHeader(
                    title: '📍 Nearby You',
                    actionLabel: 'View All',
                    onAction: () => Navigator.pushNamed(context, AppRoutes.m1SearchResults, arguments: {'query': ''}),
                  ),
                ),
              ),

              // Nearby list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final r = restaurantSvc.nearbyRestaurants[i];
                    return RestaurantListCard(
                      restaurant: r,
                      onFavorite: () => restaurantSvc.toggleFavorite(r.id),
                    );
                  },
                  childCount: restaurantSvc.nearbyRestaurants.take(4).length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

