import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart';

/// Screen 12: Staff Reservation Dashboard
class M2StaffDashboardScreen extends StatefulWidget {
  const M2StaffDashboardScreen({super.key});

  @override
  State<M2StaffDashboardScreen> createState() => _M2StaffDashboardScreenState();
}

class _M2StaffDashboardScreenState extends State<M2StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String? _selectedStatus;
  int _activeViewIndex = 0; // 0 = Reservations List, 1 = Live Table Floor Map
  final _searchCtrl = TextEditingController();

  final List<String> _dateOptions = ['Today', 'Tomorrow', 'Custom'];
  int _selectedDateTab = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<M2ReservationService>();
    final allReservations = service.getStaffReservations(
      dateFilter: _selectedDate,
      statusFilter: _selectedStatus,
    );

    // Apply search query filter
    final filtered = allReservations.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.customerName.toLowerCase().contains(q) ||
          r.bookingId.toLowerCase().contains(q) ||
          r.customerPhone.contains(q);
    }).toList();

    // Stats
    final totalCount = service.reservations.where((r) => _isSameDay(r.date, _selectedDate)).length;
    final pendingCount = service.reservations.where((r) => _isSameDay(r.date, _selectedDate) && r.status == M2ReservationStatus.pending).length;
    final confirmedCount = service.reservations.where((r) => _isSameDay(r.date, _selectedDate) && r.status == M2ReservationStatus.confirmed).length;
    final completedCount = service.reservations.where((r) => _isSameDay(r.date, _selectedDate) && r.status == M2ReservationStatus.completed).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Staff Operations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Reservation & Floor Manager', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_activeViewIndex == 0 ? Icons.grid_view_rounded : Icons.view_list_rounded),
            tooltip: _activeViewIndex == 0 ? 'Floor Map View' : 'List View',
            onPressed: () {
              setState(() {
                _activeViewIndex = _activeViewIndex == 0 ? 1 : 0;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showStaffOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector Bar
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ...List.generate(_dateOptions.length, (index) {
                  final isSelected = _selectedDateTab == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_dateOptions[index]),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (selected) async {
                        if (!selected) return;
                        setState(() => _selectedDateTab = index);
                        if (index == 0) {
                          setState(() => _selectedDate = DateTime.now());
                        } else if (index == 1) {
                          setState(() => _selectedDate = DateTime.now().add(const Duration(days: 1)));
                        } else {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        }
                      },
                    ),
                  );
                }),
                const Spacer(),
                Text(
                  AppFormatters.formatDate(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // KPI Stats Header Cards
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: _kpiCard('Total', totalCount.toString(), Icons.event_note, AppTheme.accent)),
                const SizedBox(width: 8),
                Expanded(child: _kpiCard('Pending', pendingCount.toString(), Icons.hourglass_top, AppTheme.warning)),
                const SizedBox(width: 8),
                Expanded(child: _kpiCard('Confirmed', confirmedCount.toString(), Icons.check_circle_outline, AppTheme.success)),
                const SizedBox(width: 8),
                Expanded(child: _kpiCard('Completed', completedCount.toString(), Icons.done_all, AppTheme.primary)),
              ],
            ),
          ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search guest or booking ID...',
                        hintStyle: TextStyle(fontSize: 12.5, color: AppTheme.textHint),
                        prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.accent),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.done_all, size: 16, color: AppTheme.primary),
                    label: const Text('Confirm All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    onPressed: () => _confirmAllPending(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('All', _selectedStatus == null, () => setState(() => _selectedStatus = null)),
                _filterChip('Pending', _selectedStatus == M2ReservationStatus.pending, () => setState(() => _selectedStatus = M2ReservationStatus.pending)),
                _filterChip('Confirmed', _selectedStatus == M2ReservationStatus.confirmed, () => setState(() => _selectedStatus = M2ReservationStatus.confirmed)),
                _filterChip('Modified', _selectedStatus == M2ReservationStatus.modified, () => setState(() => _selectedStatus = M2ReservationStatus.modified)),
                _filterChip('Completed', _selectedStatus == M2ReservationStatus.completed, () => setState(() => _selectedStatus = M2ReservationStatus.completed)),
                _filterChip('Cancelled', _selectedStatus == M2ReservationStatus.cancelled, () => setState(() => _selectedStatus = M2ReservationStatus.cancelled)),
                _filterChip('No Show', _selectedStatus == M2ReservationStatus.noShow, () => setState(() => _selectedStatus = M2ReservationStatus.noShow)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Main Content: List or Floor Map
          Expanded(
            child: _activeViewIndex == 0
                ? _buildReservationList(filtered, service)
                : _buildFloorMap(service),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReservationList(List<M2ReservationModel> list, M2ReservationService service) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 50, color: AppTheme.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No reservations found',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text('Change date or search term', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final r = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pushNamed(
              context,
              '/m2/staff-details',
              arguments: r,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Time, ID, Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.time,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            r.bookingId,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textHint),
                          ),
                        ],
                      ),
                      M2StatusBadge(status: r.status),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Guest info & table
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : 'G',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${r.customerPhone} • ${r.partySize} Guests',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: r.assignedTableNumber != null
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              size: 14,
                              color: r.assignedTableNumber != null ? AppTheme.success : Colors.amber.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              r.assignedTableNumber != null ? 'Table ${r.assignedTableNumber}' : 'Unassigned',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: r.assignedTableNumber != null ? AppTheme.success : AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Badges: Occasion, dietary, pre-orders
                  if (r.specialOccasion != null || r.preOrderItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (r.specialOccasion != null)
                          _badge(Icons.celebration, r.specialOccasion!, AppTheme.accent),
                        if (r.preOrderItems.isNotEmpty)
                          _badge(Icons.restaurant_menu, '${r.preOrderItems.length} Pre-orders', AppTheme.warning),
                      ],
                    ),
                  ],

                  // Staff Action Bar for fast status changes
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (r.status == M2ReservationStatus.pending) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () => _rejectReservation(r),
                          child: const Text('Reject', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () => service.staffConfirmReservation(
                            reservationId: r.id,
                            staffId: 'staff1',
                            staffName: 'Staff On Duty',
                          ),
                          child: const Text('Confirm', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ] else if (r.status == M2ReservationStatus.confirmed || r.status == M2ReservationStatus.modified) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () => service.staffBulkUpdateStatus(
                            reservationIds: [r.id],
                            newStatus: M2ReservationStatus.noShow,
                            staffId: 'staff1',
                            staffName: 'Staff On Duty',
                          ),
                          child: const Text('No Show', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () => service.staffBulkUpdateStatus(
                            reservationIds: [r.id],
                            newStatus: M2ReservationStatus.completed,
                            staffId: 'staff1',
                            staffName: 'Staff On Duty',
                          ),
                          child: const Text('Complete', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ] else ...[
                        Text(
                          r.displayStatus,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textHint, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildFloorMap(M2ReservationService service) {
    final tables = service.tables;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Floor & Table Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Row(
                children: [
                  _legendDot(AppTheme.success, 'Available'),
                  const SizedBox(width: 10),
                  _legendDot(AppTheme.accent, 'Reserved'),
                  const SizedBox(width: 10),
                  _legendDot(AppTheme.primary, 'Occupied'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: tables.length,
              itemBuilder: (ctx, idx) {
                final t = tables[idx];
                Color statusColor;
                String statusLabel;
                switch (t.status) {
                  case M2TableStatus.available:
                    statusColor = AppTheme.success;
                    statusLabel = 'Free';
                    break;
                  case M2TableStatus.reserved:
                    statusColor = AppTheme.accent;
                    statusLabel = 'Reserved';
                    break;
                  case M2TableStatus.occupied:
                    statusColor = AppTheme.primary;
                    statusLabel = 'Occupied';
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusLabel = 'Inactive';
                    break;
                }

                return InkWell(
                  onTap: () => _showTableDetails(t),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('T-${t.number}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${t.capacity} seats • ${t.location}', style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
      ],
    );
  }

  void _showTableDetails(M2TableModel table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Table #${table.number}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(table.location, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Capacity: ${table.capacity} guests'),
            Text('Current Status: ${table.status.toUpperCase()}'),
            if (table.currentReservationId != null) ...[
              const SizedBox(height: 8),
              Text('Reservation ID: ${table.currentReservationId}'),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAllPending(BuildContext context) async {
    final service = context.read<M2ReservationService>();
    final pending = service.reservations
        .where((r) => _isSameDay(r.date, _selectedDate) && r.status == M2ReservationStatus.pending)
        .map((r) => r.id)
        .toList();

    if (pending.isEmpty) return;

    final success = await service.staffBulkUpdateStatus(
      reservationIds: pending,
      newStatus: M2ReservationStatus.confirmed,
      staffId: 'staff1',
      staffName: 'Staff On Duty',
    );

    if (context.mounted && success) {
      SnackBarHelper.showSuccess(context, 'Confirmed ${pending.length} pending reservations!');
    }
  }

  void _rejectReservation(M2ReservationModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Reservation'),
        content: Text('Are you sure you want to reject booking ${r.bookingId} for ${r.customerName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<M2ReservationService>().staffRejectReservation(
                reservationId: r.id,
                staffId: 'staff1',
                staffName: 'Staff On Duty',
                reason: 'Fully booked during this slot',
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showStaffOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: AppTheme.primary),
              title: const Text('Refresh Live Availability'),
              onTap: () {
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_bar, color: Colors.blue),
              title: const Text('Export Day Summary'),
              onTap: () {
                Navigator.pop(context);
                SnackBarHelper.showSuccess(context, 'Exported reservation schedule');
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
