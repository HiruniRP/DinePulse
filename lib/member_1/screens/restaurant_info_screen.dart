import 'package:flutter/material.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';


class RestaurantInfoScreen extends StatefulWidget {
  final RestaurantModel? restaurant;
  const RestaurantInfoScreen({super.key, this.restaurant});

  @override
  State<RestaurantInfoScreen> createState() => _RestaurantInfoScreenState();
}

class _RestaurantInfoScreenState extends State<RestaurantInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _showVegetarianOnly = false;
  bool _showAvailableOnly = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    if (r == null) return const Scaffold(body: Center(child: Text('Not found')));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(r.name),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Menu'),
            Tab(text: 'Reviews'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MenuTab(restaurant: r, showVegOnly: _showVegetarianOnly, showAvailableOnly: _showAvailableOnly,
              onVegToggle: () => setState(() => _showVegetarianOnly = !_showVegetarianOnly),
              onAvailableToggle: () => setState(() => _showAvailableOnly = !_showAvailableOnly)),
          _ReviewsTab(reviews: r.reviews),
          _InfoTab(restaurant: r),
        ],
      ),
    );
  }
}

// ─── Menu Tab ────────────────────────────────────────────────────────────────
class _MenuTab extends StatelessWidget {
  final RestaurantModel restaurant;
  final bool showVegOnly;
  final bool showAvailableOnly;
  final VoidCallback onVegToggle;
  final VoidCallback onAvailableToggle;

  const _MenuTab({
    required this.restaurant,
    required this.showVegOnly,
    required this.showAvailableOnly,
    required this.onVegToggle,
    required this.onAvailableToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter row
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.divider)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(label: '🥦 Vegetarian', isSelected: showVegOnly, onTap: onVegToggle),
              const SizedBox(width: 8),
              _FilterChip(label: '✅ Available', isSelected: showAvailableOnly, onTap: onAvailableToggle),
            ],
          ),
        ),

        Expanded(
          child: restaurant.menuCategories.isEmpty
              ? const EmptyStateWidget(icon: Icons.menu_book, title: 'Menu Coming Soon', subtitle: 'We\'re working on adding the menu')
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: restaurant.menuCategories.length,
                  itemBuilder: (context, ci) {
                    final cat = restaurant.menuCategories[ci];
                    var items = cat.items;
                    if (showVegOnly) items = items.where((i) => i.isVegetarian || i.isVegan).toList();
                    if (showAvailableOnly) items = items.where((i) => i.isAvailable).toList();
                    if (items.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          color: AppTheme.primary.withOpacity(0.06),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(cat.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ),
                        ...items.map((item) => _MenuItemTile(item: item)),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final MenuItem item;
  const _MenuItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [AppTheme.cardBoxShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.isPopular)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Popular', style: TextStyle(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.w700)),
                      ),
                    if (item.isVegan)
                      _DietTag('Vegan', AppTheme.success)
                    else if (item.isVegetarian)
                      _DietTag('Veg', AppTheme.success),
                    Expanded(
                      child: Text(item.name,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: item.isAvailable ? AppTheme.textPrimary : AppTheme.textHint),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (item.allergens.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('⚠ ${item.allergens.join(', ')}', style: const TextStyle(fontSize: 11, color: AppTheme.warning)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs. ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.isAvailable ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(fontSize: 10, color: item.isAvailable ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DietTag extends StatelessWidget {
  final String label;
  final Color color;
  const _DietTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.divider),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Reviews Tab ─────────────────────────────────────────────────────────────
class _ReviewsTab extends StatelessWidget {
  final List<ReviewModel> reviews;
  const _ReviewsTab({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const EmptyStateWidget(icon: Icons.rate_review_outlined, title: 'No Reviews Yet', subtitle: 'Be the first to review this restaurant!');
    }
    // Rating summary
    final avgRating = reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
    final ratingsCount = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) ratingsCount[r.rating.floor()] = (ratingsCount[r.rating.floor()] ?? 0) + 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [AppTheme.cardBoxShadow],
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppTheme.primary, height: 1.0)),
                  StarRating(rating: avgRating, size: 18),
                  const SizedBox(height: 4),
                  Text('${reviews.length} reviews', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = ratingsCount[star] ?? 0;
                    final pct = reviews.isEmpty ? 0.0 : count / reviews.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: pct, color: AppTheme.accent, backgroundColor: AppTheme.divider, minHeight: 6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('$count', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...reviews.map((rv) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [AppTheme.cardBoxShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18, backgroundColor: AppTheme.primary.withOpacity(0.15),
                    child: Text(rv.userName[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(rv.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Row(children: [
                        StarRating(rating: rv.rating, size: 12),
                        const SizedBox(width: 6),
                        Text(_timeAgo(rv.createdAt), style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                      ]),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(rv.comment, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.thumb_up_outlined, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text('${rv.helpfulCount} found helpful', style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
              ]),
            ],
          ),
        )),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0) return '${d.inDays}d ago';
    return '${d.inHours}h ago';
  }
}

// ─── Info Tab ─────────────────────────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final RestaurantModel restaurant;
  const _InfoTab({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Location',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.address}, ${r.city}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('View on Map'),
              onPressed: () {},
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (r.hours.isNotEmpty)
          _InfoCard(
            title: 'Opening Hours',
            child: Column(
              children: r.hours.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    Text(
                      e.value.isClosed ? 'Closed' : '${e.value.open} – ${e.value.close}',
                      style: TextStyle(color: e.value.isClosed ? AppTheme.error : AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Contact',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (r.phoneNumber.isNotEmpty)
              _ContactRow(icon: Icons.phone_outlined, label: r.phoneNumber),
            if (r.email.isNotEmpty)
              _ContactRow(icon: Icons.email_outlined, label: r.email),
            if (r.website.isNotEmpty)
              _ContactRow(icon: Icons.language, label: r.website),
          ]),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Features',
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              if (r.acceptsReservations) _FeatureBadge('🗓 Reservations'),
              if (r.hasQueue) _FeatureBadge('⏱ Virtual Queue'),
              _FeatureBadge('🪑 ${r.totalSeats} Seats'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface, borderRadius: BorderRadius.circular(14),
        boxShadow: const [AppTheme.cardBoxShadow],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final String label;
  const _FeatureBadge(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
  );
}
