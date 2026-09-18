import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';

import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_1/services/reservation_service.dart';
import 'package:dine_pulse/member_1/services/notification_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.m1EditProfile),
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not signed in'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                            child: user.avatarUrl == null
                                ? Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800))
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.m1EditProfile),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: user.isStaff ? AppTheme.accent : Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      if (user.phoneNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(user.phoneNumber!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                      const SizedBox(height: 16),
                      // Quick stats row
                      Consumer2<ReservationService, NotificationService>(
                        builder: (_, resSvc, notifSvc, __) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatBadge(label: 'Reservations', value: '${resSvc.reservations.length}'),
                            Container(height: 32, width: 1, color: Colors.white24),
                            _StatBadge(label: 'Upcoming', value: '${resSvc.upcomingReservations.length}'),
                            Container(height: 32, width: 1, color: Colors.white24),
                            _StatBadge(label: 'Notifications', value: '${notifSvc.unreadCount}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Staff Management Section (Visible to staff or easily switchable for testing)
                _MenuSection(
                  title: 'Staff Portals & Operations',
                  items: [
                    _MenuItem(
                      icon: Icons.table_restaurant,
                      label: 'Staff Reservation Dashboard',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textHint),
                      onTap: () {
                        if (!user.isStaff) {
                          auth.switchRole('staff');
                        }
                        Navigator.pushNamed(context, AppRoutes.m2StaffDashboard);
                      },
                    ),
                    _MenuItem(
                      icon: Icons.people_alt_outlined,
                      label: 'Staff Queue & Table Operations',
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textHint),
                      onTap: () {
                        if (!user.isStaff) {
                          auth.switchRole('staff');
                        }
                        Navigator.pushNamed(context, AppRoutes.m4StaffQueue);
                      },
                    ),
                    _MenuItem(
                      icon: Icons.swap_horiz,
                      label: 'Current Role Mode',
                      trailing: Text(
                        user.isStaff ? 'Staff (Tap to Customer)' : 'Customer (Tap to Staff)',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onTap: () {
                        auth.switchRole(user.isStaff ? 'customer' : 'staff');
                      },
                    ),
                  ],
                ),

                // Menu sections
                _MenuSection(
                  title: 'Account',
                  items: [
                    _MenuItem(icon: Icons.person_outlined, label: 'Edit Profile', onTap: () => Navigator.pushNamed(context, AppRoutes.m1EditProfile)),
                    _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => Navigator.pushNamed(context, AppRoutes.m1Notifications)),
                    _MenuItem(icon: Icons.calendar_today_outlined, label: 'My Reservations', onTap: () => Navigator.pushNamed(context, AppRoutes.m1MyReservations)),
                    _MenuItem(icon: Icons.favorite_outline, label: 'Favourite Restaurants', onTap: () {}),
                  ],
                ),

                _MenuSection(
                  title: 'Preferences',
                  items: [
                    _MenuItem(icon: Icons.restaurant_outlined, label: 'Dietary Preferences', trailing: Text(user.dietaryPreferences.isEmpty ? 'Set' : '${user.dietaryPreferences.length} set', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)), onTap: () => Navigator.pushNamed(context, AppRoutes.m1EditProfile)),
                    _MenuItem(icon: Icons.language, label: 'Language', trailing: const Text('English', style: TextStyle(color: AppTheme.textHint, fontSize: 12)), onTap: () {}),
                  ],
                ),

                _MenuSection(
                  title: 'Support',
                  items: [
                    _MenuItem(icon: Icons.help_outline, label: 'Help & FAQs', onTap: () {}),
                    _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
                    _MenuItem(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
                    _MenuItem(icon: Icons.info_outline, label: 'App Version', trailing: const Text('1.0.0', style: TextStyle(color: AppTheme.textHint, fontSize: 12)), onTap: () {}),
                  ],
                ),

                // Logout
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: AppTheme.error),
                      label: const Text('Sign Out', style: TextStyle(color: AppTheme.error)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.m1LogoutConfirm),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textHint, letterSpacing: 1.2)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: Column(
              children: List.generate(items.length, (i) => Column(
                children: [
                  items[i],
                  if (i < items.length - 1) const Divider(height: 1, indent: 54),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: AppTheme.textHint),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
