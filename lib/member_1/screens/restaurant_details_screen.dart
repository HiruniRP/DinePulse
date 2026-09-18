import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';
import 'package:dine_pulse/member_1/services/restaurant_service.dart';
import 'package:dine_pulse/member_4/services/m4_queue_service.dart';


class RestaurantDetailsScreen extends StatefulWidget {
  final RestaurantModel? restaurant;
  const RestaurantDetailsScreen({super.key, this.restaurant});

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  RestaurantModel? get _restaurant => widget.restaurant;

  @override
  Widget build(BuildContext context) {
    final r = _restaurant;
    if (r == null) {
      return const Scaffold(body: Center(child: Text('Restaurant not found')));
    }
    return Consumer<RestaurantService>(
      builder: (context, svc, _) {
        final isFav = svc.restaurants.firstWhere((x) => x.id == r.id, orElse: () => r).isFavorite;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              // Image app bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppTheme.primary,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 20, color: isFav ? Colors.red : Colors.white),
                        onPressed: () => svc.toggleFavorite(r.id),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.share, size: 20, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: r.imageUrls.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              controller: _pageCtrl,
                              itemCount: r.imageUrls.length,
                              onPageChanged: (p) => setState(() => _currentPage = p),
                              itemBuilder: (_, i) => Image.network(
                                r.imageUrls[i], fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: AppTheme.primary.withOpacity(0.2)),
                              ),
                            ),
                            // Page indicator dots
                            if (r.imageUrls.length > 1)
                              Positioned(
                                bottom: 12, left: 0, right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(r.imageUrls.length, (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    height: 6,
                                    width: i == _currentPage ? 20 : 6,
                                    decoration: BoxDecoration(
                                      color: i == _currentPage ? Colors.white : Colors.white54,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  )),
                                ),
                              ),
                          ],
                        )
                      : Container(color: AppTheme.primary.withOpacity(0.3), child: const Icon(Icons.restaurant, size: 80, color: Colors.white54)),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & status
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(r.cuisine, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Text('·', style: TextStyle(color: AppTheme.textHint)),
                                    const SizedBox(width: 8),
                                    Text(r.priceRange, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: r.isOpen ? 'confirmed' : 'cancelled'),
                        ],
                      ),
                    ),

                    // Rating row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          StarRating(rating: r.rating, size: 18),
                          const SizedBox(width: 8),
                          Text(AppFormatters.formatRating(r.rating), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 4),
                          Text('(${r.reviewCount} reviews)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          const Spacer(),
                          Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                          Text('${r.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    // Tags
                    if (r.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Wrap(
                          spacing: 6, runSpacing: 6,
                          children: r.tags.map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )).toList(),
                        ),
                      ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Divider(),
                    ),

                    // ─── Cross-Module Live Queue & Table Status Hub ─────────────
                    Consumer<M4QueueService>(
                      builder: (context, qSvc, _) {
                        final queueLen = qSvc.getActiveQueue(r.id).length;
                        final dynamicWait = qSvc.calculateDynamicWaitTime(r.id, 2);
                        final availableTables = qSvc.getAvailableTablesCount(r.id);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryDark, AppTheme.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bolt, color: AppTheme.accent, size: 20),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Live Dining Status',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                                        const SizedBox(width: 4),
                                        const Text('Real-Time', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Virtual Queue', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$queueLen Waiting',
                                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                                          ),
                                          Text(
                                            '~$dynamicWait min wait',
                                            style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tables Available', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$availableTables Free',
                                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                                          ),
                                          Text(
                                            '${r.totalSeats} Total Seats',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // 4 Customer Journey Options
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.hourglass_top, size: 16),
                                      label: const Text('Join Queue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                      onPressed: () => Navigator.pushNamed(context, AppRoutes.m4JoinQueue, arguments: r),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppTheme.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.table_restaurant, size: 16),
                                      label: const Text('Reserve Table', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                      onPressed: () => Navigator.pushNamed(context, AppRoutes.m2MakeReservation, arguments: r),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white38),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.menu_book, size: 16),
                                      label: const Text('View Menu', style: TextStyle(fontSize: 12)),
                                      onPressed: () => Navigator.pushNamed(context, AppRoutes.m1RestaurantInfo, arguments: r),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white38),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                                      label: const Text('View Reviews', style: TextStyle(fontSize: 12)),
                                      onPressed: () => Navigator.pushNamed(context, AppRoutes.m1RestaurantInfo, arguments: r),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Divider(),
                    ),

                    // Info tiles
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _InfoTile(icon: Icons.location_on_outlined, label: '${r.address}, ${r.city}'),
                          if (r.phoneNumber.isNotEmpty)
                            _InfoTile(icon: Icons.phone_outlined, label: r.phoneNumber),
                          if (r.hours.isNotEmpty)
                            _InfoTile(
                              icon: Icons.access_time_outlined,
                              label: r.hours.entries.first.value.isClosed
                                  ? 'Closed today'
                                  : '${r.hours.entries.first.value.open} – ${r.hours.entries.first.value.close}',
                            ),
                          _InfoTile(icon: Icons.people_outlined, label: '${r.totalSeats} seats'),
                        ],
                      ),
                    ),

                    // Description
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('About', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(r.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
                        ],
                      ),
                    ),

                    // Reviews preview
                    if (r.reviews.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: SectionHeader(
                          title: 'Reviews',
                          actionLabel: 'See All',
                          onAction: () => Navigator.pushNamed(context, AppRoutes.m1RestaurantInfo, arguments: r),
                        ),
                      ),
                      ...r.reviews.take(2).map((rv) => _ReviewCard(review: rv)),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // Bottom action bar with Join Virtual Queue and Reserve Table
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Menu',
                    icon: const Icon(Icons.menu_book_outlined, color: AppTheme.primary),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.m1RestaurantInfo, arguments: r),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.hourglass_top, size: 16),
                      label: const Text('Join Queue'),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.m4JoinQueue, arguments: r),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Reserve Table'),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.m2MakeReservation, arguments: r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: Text(review.userName[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(AppFormatters.timeAgo(review.createdAt), style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                  ],
                ),
              ),
              StarRating(rating: review.rating, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

// Local helper
class AppFormatters {
  static String formatRating(double r) => r.toStringAsFixed(1);
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
