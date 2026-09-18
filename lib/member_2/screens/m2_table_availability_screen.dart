import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/widgets/app_widgets.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart';

/// Screen 1: Live Table Availability
class M2TableAvailabilityScreen extends StatefulWidget {
  final RestaurantModel? restaurant;
  final DateTime? selectedDate;
  final String? selectedTime;
  final int? partySize;

  const M2TableAvailabilityScreen({
    super.key,
    this.restaurant,
    this.selectedDate,
    this.selectedTime,
    this.partySize,
  });

  @override
  State<M2TableAvailabilityScreen> createState() => _M2TableAvailabilityScreenState();
}

class _M2TableAvailabilityScreenState extends State<M2TableAvailabilityScreen> {
  String _selectedLocation = 'any';
  M2TableModel? _selectedTable;
  late DateTime _date;
  String _time = '7:00 PM';
  int _partySize = 2;

  final List<String> _locations = ['any', 'indoor', 'outdoor', 'private', 'bar'];
  final _locationIcons = <String, IconData>{
    'any': Icons.all_inclusive,
    'indoor': Icons.chair,
    'outdoor': Icons.deck,
    'private': Icons.meeting_room,
    'bar': Icons.local_bar,
  };

  @override
  void initState() {
    super.initState();
    _date = widget.selectedDate ?? DateTime.now().add(const Duration(days: 1));
    _time = widget.selectedTime ?? '7:00 PM';
    _partySize = widget.partySize ?? 2;
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<M2ReservationService>();
    final availableTables = service.getAvailableTables(
      partySize: _partySize,
      date: _date,
      time: _time,
      location: _selectedLocation == 'any' ? null : _selectedLocation,
    );
    final allTables = service.getTablesForRestaurant(widget.restaurant?.id ?? '');

    // Stats
    final totalAvail = allTables.where((t) => t.isAvailable).length;
    final totalReserved = allTables.where((t) => t.status == M2TableStatus.reserved).length;
    final totalOccupied = allTables.where((t) => t.status == M2TableStatus.occupied).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.restaurant != null ? widget.restaurant!.name : 'Table Availability'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(children: [
        // Live status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.primary,
          child: Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('Live Availability', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            _statChip('Available', totalAvail.toString(), AppTheme.success),
            const SizedBox(width: 8),
            _statChip('Reserved', totalReserved.toString(), AppTheme.warning),
            const SizedBox(width: 8),
            _statChip('Occupied', totalOccupied.toString(), AppTheme.error),
          ]),
        ),
        // Booking context
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: AppTheme.textHint),
            const SizedBox(width: 4),
            Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 14, color: AppTheme.textHint),
            const SizedBox(width: 4),
            Text(_time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            const Icon(Icons.people, size: 14, color: AppTheme.textHint),
            const SizedBox(width: 4),
            Text('$_partySize guests', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),
        // Location filter
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _locations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final loc = _locations[i];
              final selected = _selectedLocation == loc;
              return GestureDetector(
                onTap: () => setState(() => _selectedLocation = loc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_locationIcons[loc] ?? Icons.place, size: 14, color: selected ? Colors.white : AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Text(loc[0].toUpperCase() + loc.substring(1), style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                  ]),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Tables grid
        Expanded(
          child: availableTables.isEmpty
              ? const EmptyStateWidget(icon: Icons.table_restaurant, title: 'No Tables Available', subtitle: 'Try a different time, date, or location preference.')
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 1.3, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                  itemCount: availableTables.length,
                  itemBuilder: (_, i) {
                    final t = availableTables[i];
                    return M2TableCard(
                      table: t,
                      isSelected: _selectedTable?.id == t.id,
                      onTap: () => setState(() {
                        _selectedTable = _selectedTable?.id == t.id ? null : t;
                      }),
                    );
                  },
                ),
        ),
      ]),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_selectedTable != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.table_restaurant, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Table ${_selectedTable!.number} selected', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
              const Spacer(),
              Text('${_selectedTable!.capacity} seats • ${_selectedTable!.location}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/m2/reservation-form', arguments: {
              'restaurant': widget.restaurant,
              'date': _date,
              'time': _time,
              'partySize': _partySize,
              'selectedTable': _selectedTable,
            }),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue to Reservation Form'),
          ),
        ),
      ]),
    );
  }

  Widget _statChip(String label, String count, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 3),
      Text('$count $label', style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        date: _date,
        time: _time,
        partySize: _partySize,
        onApply: (date, time, partySize) {
          setState(() { _date = date; _time = time; _partySize = partySize; });
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final DateTime date;
  final String time;
  final int partySize;
  final Function(DateTime, String, int) onApply;

  const _FilterSheet({required this.date, required this.time, required this.partySize, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTime _date;
  late String _time;
  late int _partySize;

  @override
  void initState() {
    super.initState();
    _date = widget.date;
    _time = widget.time;
    _partySize = widget.partySize;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Filter Tables', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text('Party Size', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: List.generate(10, (i) {
          final size = i + 1;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _partySize = size),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _partySize == size ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _partySize == size ? AppTheme.primary : AppTheme.divider),
                ),
                alignment: Alignment.center,
                child: Text('$size', style: TextStyle(color: _partySize == size ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        })),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onApply(_date, _time, _partySize),
            child: const Text('Apply Filters'),
          ),
        ),
      ]),
    );
  }
}
