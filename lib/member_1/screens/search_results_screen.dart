import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';
import 'package:dine_pulse/core/constants/app_constants.dart';
import 'package:dine_pulse/member_1/services/restaurant_service.dart';
import 'package:dine_pulse/member_1/widgets/restaurant_widgets.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? cuisine;

  const SearchResultsScreen({super.key, required this.query, this.cuisine});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late String _selectedCuisine;
  String _selectedPriceRange = 'All';
  double? _minRating;
  String _sortBy = 'Relevance';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _selectedCuisine = widget.cuisine ?? 'All';
    WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch());
  }

  void _doSearch() {
    context.read<RestaurantService>().searchRestaurants(
      query: widget.query,
      cuisine: _selectedCuisine == 'All' ? null : _selectedCuisine,
      priceRange: _selectedPriceRange == 'All' ? null : _selectedPriceRange,
      minRating: _minRating,
      sortBy: _sortBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.query.isEmpty ? _selectedCuisine : '"${widget.query}"'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list, color: Colors.white),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters panel
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _showFilters ? _buildFilterPanel() : const SizedBox.shrink(),
          ),

          // Sort chips row
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.sortOptions.map((opt) {
                  final isSelected = opt == _sortBy;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(opt),
                      selected: isSelected,
                      onSelected: (_) => setState(() {
                        _sortBy = opt;
                        _doSearch();
                      }),
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12),
                      backgroundColor: AppTheme.background,
                      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.divider),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Results
          Expanded(
            child: Consumer<RestaurantService>(
              builder: (context, svc, _) {
                if (svc.isLoading) return const CenteredLoader();
                final results = svc.searchResults;
                if (results.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No restaurants found',
                    subtitle: 'Try adjusting your search or filters',
                    actionLabel: 'Clear Filters',
                    onAction: () {
                      setState(() {
                        _selectedCuisine = 'All';
                        _selectedPriceRange = 'All';
                        _minRating = null;
                        _sortBy = 'Relevance';
                      });
                      _doSearch();
                    },
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${results.length} restaurant${results.length == 1 ? '' : 's'} found',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, i) => RestaurantListCard(
                          restaurant: results[i],
                          onFavorite: () => svc.toggleFavorite(results[i].id),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Results', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // Cuisine filter
          const Text('Cuisine', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.cuisineTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final c = AppConstants.cuisineTypes[i];
                final sel = c == _selectedCuisine;
                return ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  onSelected: (_) => setState(() {
                    _selectedCuisine = c;
                    _doSearch();
                  }),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(color: sel ? Colors.white : AppTheme.textSecondary, fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Price range
          const Text('Price Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: AppConstants.priceRanges.map((p) {
              final sel = p == _selectedPriceRange;
              return ChoiceChip(
                label: Text(p),
                selected: sel,
                onSelected: (_) => setState(() {
                  _selectedPriceRange = p;
                  _doSearch();
                }),
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(color: sel ? Colors.white : AppTheme.textSecondary, fontSize: 12),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Min rating
          const Text('Minimum Rating', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(label: const Text('Any'), selected: _minRating == null,
                  onSelected: (_) => setState(() { _minRating = null; _doSearch(); }),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(color: _minRating == null ? Colors.white : AppTheme.textSecondary, fontSize: 12)),
              ...AppConstants.ratingFilters.where((r) => r > 0).map((r) {
                final sel = _minRating == r;
                return ChoiceChip(
                  label: Text('${r.toStringAsFixed(1)}+ ⭐'),
                  selected: sel,
                  onSelected: (_) => setState(() { _minRating = r; _doSearch(); }),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(color: sel ? Colors.white : AppTheme.textSecondary, fontSize: 12),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
