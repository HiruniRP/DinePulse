import 'package:flutter/material.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';

class RestaurantSearchScreen extends StatefulWidget {
  const RestaurantSearchScreen({super.key});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  // Recent searches (mock)
  final List<String> _recentSearches = ['Italian', 'Sushi', 'The Spice Garden', 'Vegan'];
  final List<String> _popularSearches = ['Pizza', 'Seafood', 'Coffee', 'Desserts', 'Korean BBQ'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    Navigator.pushNamed(
      context,
      AppRoutes.m1SearchResults,
      arguments: {'query': query.trim()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onSubmitted: _search,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Search restaurants, cuisine...',
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchCtrl,
              builder: (_, value, __) => value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => setState(() => _searchCtrl.clear()),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _search(_searchCtrl.text),
            child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Browse by Cuisine
            const Text('Browse by Cuisine', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              itemCount: _cuisineTiles().length,
              itemBuilder: (context, i) {
                final tile = _cuisineTiles()[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.m1SearchResults,
                    arguments: {'query': '', 'cuisine': tile['label']},
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [tile['color'] as Color, (tile['color'] as Color).withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tile['emoji'] as String, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(
                          tile['label'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Recent searches
            if (_recentSearches.isNotEmpty) ...[
              Row(
                children: [
                  const Text('Recent Searches', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _recentSearches.clear()),
                    child: const Text('Clear', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _recentSearches.map((s) => GestureDetector(
                  onTap: () => _search(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 14, color: AppTheme.textHint),
                        const SizedBox(width: 6),
                        Text(s, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Popular now
            const Text('Popular Now 🔥', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _popularSearches.map((s) => GestureDetector(
                onTap: () => _search(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up, size: 14, color: AppTheme.accent),
                      const SizedBox(width: 6),
                      Text(s, style: const TextStyle(fontSize: 13, color: AppTheme.accent, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _cuisineTiles() => [
    {'label': 'Italian', 'emoji': '🍝', 'color': const Color(0xFFE64A19)},
    {'label': 'Japanese', 'emoji': '🍣', 'color': const Color(0xFFC62828)},
    {'label': 'Indian', 'emoji': '🍛', 'color': const Color(0xFFFF8F00)},
    {'label': 'Chinese', 'emoji': '🥡', 'color': const Color(0xFFAD1457)},
    {'label': 'Seafood', 'emoji': '🦞', 'color': const Color(0xFF006064)},
    {'label': 'Vegan', 'emoji': '🥗', 'color': AppTheme.success},
    {'label': 'Mexican', 'emoji': '🌮', 'color': const Color(0xFFF57F17)},
    {'label': 'Cafe', 'emoji': '☕', 'color': const Color(0xFF4E342E)},
    {'label': 'Thai', 'emoji': '🍜', 'color': const Color(0xFF1565C0)},
  ];
}
