import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';
import 'package:dine_pulse/member_4/services/m4_queue_service.dart';

/// Large featured restaurant card for horizontal scroll
class FeaturedRestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback? onFavorite;

  const FeaturedRestaurantCard({
    super.key,
    required this.restaurant,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.m1RestaurantDetails,
        arguments: restaurant,
      ),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: AppTheme.cardShadow, blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Image
              _RestaurantImage(imageUrl: restaurant.imageUrls.isNotEmpty ? restaurant.imageUrls.first : null, height: 200),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    ),
                  ),
                ),
              ),
              // Open/Closed badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: restaurant.isOpen ? AppTheme.success : AppTheme.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    restaurant.isOpen ? 'Open' : 'Closed',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Favorite button
              Positioned(
                top: 8,
                right: 8,
                child: _FavoriteButton(
                  isFavorite: restaurant.isFavorite,
                  onTap: onFavorite,
                ),
              ),
              // Info overlay
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 17,
                          fontWeight: FontWeight.w700, letterSpacing: 0.3,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.restaurant, color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text(restaurant.cuisine, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, color: Colors.white70, size: 12),
                          const SizedBox(width: 2),
                          Text('${restaurant.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          StarRating(rating: restaurant.rating, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${AppFormatters.formatRating(restaurant.rating)} (${restaurant.reviewCount})',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
                            ),
                            child: Text(restaurant.priceRange, style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Consumer<M4QueueService>(
                        builder: (_, qSvc, __) {
                          final qLen = qSvc.getActiveQueue(restaurant.id).length;
                          final wait = qSvc.calculateDynamicWaitTime(restaurant.id, 2);
                          final freeTables = qSvc.getAvailableTablesCount(restaurant.id);
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.hourglass_top, size: 11, color: AppTheme.accent),
                                    const SizedBox(width: 3),
                                    Text('~$wait mins ($qLen in queue)', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.table_restaurant, size: 11, color: AppTheme.success),
                                    const SizedBox(width: 3),
                                    Text('$freeTables free', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact list-style restaurant card
class RestaurantListCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback? onFavorite;

  const RestaurantListCard({
    super.key,
    required this.restaurant,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.m1RestaurantDetails,
        arguments: restaurant,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: _RestaurantImage(
                imageUrl: restaurant.imageUrls.isNotEmpty ? restaurant.imageUrls.first : null,
                height: 110, width: 110,
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _FavoriteButton(isFavorite: restaurant.isFavorite, onTap: onFavorite, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.restaurant, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(restaurant.cuisine, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text('·', style: TextStyle(color: AppTheme.textHint)),
                        const SizedBox(width: 8),
                        Text(restaurant.priceRange, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StarRating(rating: restaurant.rating, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          AppFormatters.formatRating(restaurant.rating),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(width: 4),
                        Text('(${restaurant.reviewCount})', style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: AppTheme.primary),
                        const SizedBox(width: 2),
                        Text(
                          '${restaurant.distanceKm.toStringAsFixed(1)} km away',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: restaurant.isOpen
                                ? AppTheme.success.withOpacity(0.1)
                                : AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            restaurant.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              color: restaurant.isOpen ? AppTheme.success : AppTheme.error,
                              fontSize: 11, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Consumer<M4QueueService>(
                      builder: (_, qSvc, __) {
                        final qLen = qSvc.getActiveQueue(restaurant.id).length;
                        final wait = qSvc.calculateDynamicWaitTime(restaurant.id, 2);
                        final freeTables = qSvc.getAvailableTablesCount(restaurant.id);
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.hourglass_top, size: 10, color: AppTheme.accent),
                                  const SizedBox(width: 3),
                                  Text('~$wait mins ($qLen in queue)', style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.table_restaurant, size: 10, color: AppTheme.success),
                                  const SizedBox(width: 3),
                                  Text('$freeTables free', style: const TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuisine filter chip row
class CuisineFilterChips extends StatelessWidget {
  final String selectedCuisine;
  final List<String> cuisines;
  final ValueChanged<String> onSelected;

  const CuisineFilterChips({
    super.key,
    required this.selectedCuisine,
    required this.cuisines,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cuisines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cuisine = cuisines[index];
          final isSelected = cuisine == selectedCuisine;
          return GestureDetector(
            onTap: () => onSelected(cuisine),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.divider),
                boxShadow: isSelected ? [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2)),
                ] : [
                  const BoxShadow(color: AppTheme.cardShadow, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Text(
                cuisine,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Reusable search bar widget
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.hint = 'Search restaurants...',
    this.onTap,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: const [
          BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppTheme.accent, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─── Private helpers ────────────────────────────────────────────────────────

class _RestaurantImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double? width;

  const _RestaurantImage({this.imageUrl, required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: AppTheme.primary.withOpacity(0.08),
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Center(child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                  color: AppTheme.primary, strokeWidth: 2,
                ));
              },
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Center(
    child: Icon(Icons.restaurant, size: 40, color: AppTheme.primary.withOpacity(0.3)),
  );
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onTap;
  final double size;

  const _FavoriteButton({required this.isFavorite, this.onTap, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: size,
          color: isFavorite ? Colors.red : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// Re-export AppFormatters for convenience
class AppFormatters {
  static String formatRating(double rating) => rating.toStringAsFixed(1);
}
