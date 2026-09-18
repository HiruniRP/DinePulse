import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_4/models/m4_queue_model.dart';
import 'package:dine_pulse/member_4/services/m4_queue_service.dart';
import 'package:dine_pulse/member_4/widgets/m4_widgets.dart';

/// Screen 16: Staff Queue & Table Operations Dashboard
class M4StaffQueueDashboardScreen extends StatefulWidget {
  const M4StaffQueueDashboardScreen({super.key});

  @override
  State<M4StaffQueueDashboardScreen> createState() => _M4StaffQueueDashboardScreenState();
}

class _M4StaffQueueDashboardScreenState extends State<M4StaffQueueDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final String _restaurantId = 'rest1';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<M4QueueService>();
    final activeQueue = service.getActiveQueue(_restaurantId);
    final allTables = service.allTables;
    final config = service.getConfig(_restaurantId);

    // Filtered by search
    final filteredQueue = activeQueue.where((t) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.customerName.toLowerCase().contains(q) ||
          t.ticketNumber.toLowerCase().contains(q) ||
          t.customerPhone.contains(q);
    }).toList();

    // Staff KPIs
    final waitingCount = activeQueue.length;
    final avgWait = waitingCount > 0 ? (waitingCount * 7) : 0;
    final availableTablesCount = allTables.where((t) => t.isAvailable).length;
    final occupiedTablesCount = allTables.where((t) => t.isOccupied).length;
    final reservedM2Count = allTables.where((t) => t.isReservedM2).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Queue & Floor Host Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Member 4 Virtual Queue & Tables', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          // QR Check-in instant search
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Quick QR Check-in',
            onPressed: () => _showQuickQrCheckIn(context, service),
          ),
          // Pause / Close Queue Switch
          IconButton(
            icon: Icon(config.isQueueOpen ? Icons.pause_circle_outline : Icons.play_circle_outline),
            tooltip: config.isQueueOpen ? 'Pause Queue' : 'Resume Queue',
            onPressed: () => _toggleQueuePause(context, service, config),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            Tab(text: 'Queue ($waitingCount)'),
            Tab(text: 'Tables (${allTables.length})'),
            const Tab(text: '+ Walk-in'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Staff Dashboard KPIs Header ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppTheme.surface,
            child: Row(
              children: [
                Expanded(child: _kpiPill('In Queue', '$waitingCount', Icons.groups, AppTheme.accent)),
                const SizedBox(width: 4),
                Expanded(child: _kpiPill('Avg Wait', '~${avgWait}m', Icons.timer_outlined, AppTheme.warning)),
                const SizedBox(width: 4),
                Expanded(child: _kpiPill('Free', '$availableTablesCount', Icons.table_bar, AppTheme.success)),
                const SizedBox(width: 4),
                Expanded(child: _kpiPill('Occ', '$occupiedTablesCount', Icons.chair, AppTheme.primary)),
                const SizedBox(width: 4),
                Expanded(child: _kpiPill('M2 Lock', '$reservedM2Count', Icons.lock_outline, AppTheme.accent)),
              ],
            ),
          ),

          // If Queue is paused, show warning strip
          if (!config.isQueueOpen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_filled, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Queue is currently PAUSED: ${config.pauseReason ?? "Not accepting entries"}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Tab Content ─────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab 1: Active Queue List
                _buildQueueTab(filteredQueue, service),
                // Tab 2: Live Table Management & Capacity Fit
                _buildTableManagementTab(service),
                // Tab 3: Quick Add Walk-in
                _buildAddWalkInTab(service),
                // Tab 4: Seated & Completed History
                _buildHistoryTab(service),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiPill(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textHint), maxLines: 1),
        ],
      ),
    );
  }

  // ─── Tab 1: Active Queue ───────────────────────────────────────────────────
  Widget _buildQueueTab(List<M4QueueTicket> list, M4QueueService service) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.divider),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search ticket #, guest name, or phone...',
                hintStyle: TextStyle(fontSize: 12, color: AppTheme.textHint),
                prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.accent),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('No guests currently in queue.', style: TextStyle(color: AppTheme.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  itemCount: list.length,
                  itemBuilder: (ctx, index) {
                    final t = list[index];
                    return _buildStaffQueueCard(t, service);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStaffQueueCard(M4QueueTicket t, M4QueueService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: t.isCalled ? AppTheme.success : (t.isPriority ? AppTheme.warning : AppTheme.divider),
          width: t.isCalled || t.isPriority ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: AppTheme.cardShadow, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ticket #, Position, Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.ticketNumber,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Pos #${t.position}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (t.isPriority) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text('PRIORITY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.warning)),
                    ),
                  ],
                ],
              ),
              M4QueueBadge(status: t.status),
            ],
          ),
          const SizedBox(height: 8),

          // Guest info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    '${t.customerPhone} • Party of ${t.partySize} (${t.seatingPreference})',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Text('~${t.estimatedWaitMinutes}m wait', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),

          // Special alerts
          if (t.needsHighChair || t.needsWheelchair || (t.specialNotes != null && t.specialNotes!.isNotEmpty)) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                if (t.needsHighChair) _chipBadge(Icons.child_care, 'High Chair'),
                if (t.needsWheelchair) _chipBadge(Icons.accessible, 'Wheelchair'),
                if (t.specialNotes != null) _chipBadge(Icons.notes, t.specialNotes!),
              ],
            ),
          ],

          if (t.staffNotes != null && t.staffNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Note: ${t.staffNotes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.primary)),
          ],

          // Staff Action Row
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Notes button
              IconButton(
                icon: const Icon(Icons.edit_note, size: 20, color: AppTheme.textSecondary),
                tooltip: 'Add Note',
                onPressed: () => _showAddStaffNoteDialog(t, service),
              ),
              // Priority button
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18, color: AppTheme.warning),
                tooltip: 'Promote Priority',
                onPressed: () => service.reorderPriority(t.id, 1, staffName: 'Host Staff'),
              ),
              // Skip / No-show
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                ),
                onPressed: () => service.markNoShowOrSkip(t.id, isNoShow: true, staffName: 'Host Staff'),
                child: const Text('No-Show', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),

              // Call Next or Seat button
              if (t.status != M4QueueStatus.called)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.campaign, color: Colors.white, size: 15),
                  label: const Text('Call Next', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  onPressed: () => service.callNextCustomer(t.id, staffId: 'staff1', staffName: 'Host Staff'),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.chair, color: Colors.white, size: 15),
                  label: const Text('Assign Table & Seat', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  onPressed: () => _showSeatDialog(context, t, service),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ─── Tab 2: Live Table Management & Capacity-Fit ───────────────────────────
  Widget _buildTableManagementTab(M4QueueService service) {
    final tables = service.allTables;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Floor & Capacity Fit',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                'Tap table for auto-match',
                style: TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemCount: tables.length,
              itemBuilder: (ctx, idx) {
                final tbl = tables[idx];
                return M4TableStatusCard(
                  table: tbl,
                  onTap: () => _handleTableAction(tbl, service),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleTableAction(M4TableItem table, M4QueueService service) {
    if (table.isReservedM2) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Member 2 Reserved Table'),
          content: Text(
            'Table #${table.number} is locked for a pre-booked reservation from Member 2. '
            'Virtual queue customers cannot be seated here.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    if (table.isAvailable) {
      // Auto-suggest next best-fit waiting party!
      final suggested = service.suggestNextPartyForTable(table.id, _restaurantId);
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
                  Text('Table #${table.number} (${table.capacity}p)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('AVAILABLE', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (suggested != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Best Fit Match: ${suggested.ticketNumber} (${suggested.customerName}, Party of ${suggested.partySize})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    onPressed: () {
                      Navigator.pop(ctx);
                      service.seatCustomer(
                        ticketId: suggested.id,
                        tableId: table.id,
                        staffId: 'staff1',
                        staffName: 'Host Staff',
                      );
                      SnackBarHelper.showSuccess(context, 'Seated ${suggested.customerName} at Table #${table.number}!');
                    },
                    child: Text('Seat ${suggested.ticketNumber} Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                const Text('No waiting guests in queue currently match this table capacity.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 42)),
                onPressed: () {
                  Navigator.pop(ctx);
                  service.startCleaningTable(table.id);
                  SnackBarHelper.showSuccess(context, 'Table #${table.number} set to cleaning timer');
                },
                child: const Text('Mark as Cleaning / Reset'),
              ),
            ],
          ),
        ),
      );
    } else if (table.isOccupied) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Clear Table #${table.number}?'),
          content: Text('Guests have finished dining. Clear table and start 3-minute cleaning timer?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                Navigator.pop(ctx);
                service.startCleaningTable(table.id);
                SnackBarHelper.showSuccess(context, 'Table #${table.number} marked for cleaning');
              },
              child: const Text('Clear & Clean', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  // ─── Tab 3: Walk-in Entry Form ─────────────────────────────────────────────
  Widget _buildAddWalkInTab(M4QueueService service) {
    final walkInNameCtrl = TextEditingController();
    final walkInPhoneCtrl = TextEditingController();
    int walkInPartySize = 2;
    String walkInPreference = 'Any';

    return StatefulBuilder(
      builder: (ctx, setWalkInState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Walk-in Customer to Queue',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter guest details who are waiting in person at host stand.',
                style: TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: walkInNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: walkInPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Phone (for SMS)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Party Size:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: walkInPartySize > 1 ? () => setWalkInState(() => walkInPartySize--) : null,
                      ),
                      Text('$walkInPartySize', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setWalkInState(() => walkInPartySize++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () async {
                    if (walkInNameCtrl.text.trim().isEmpty) {
                      SnackBarHelper.showError(context, 'Please enter customer name');
                      return;
                    }
                    await service.addWalkIn(
                      restaurantId: _restaurantId,
                      restaurantName: 'The Grand Heritage',
                      customerName: walkInNameCtrl.text.trim(),
                      customerPhone: walkInPhoneCtrl.text.trim().isNotEmpty ? walkInPhoneCtrl.text.trim() : 'Walk-in',
                      partySize: walkInPartySize,
                      seatingPreference: walkInPreference,
                      staffName: 'Host Staff',
                    );
                    if (!mounted) return;
                    SnackBarHelper.showSuccess(context, 'Walk-in added to queue!');
                    _tabCtrl.animateTo(0);
                  },
                  child: const Text('Add to Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Tab 4: Seated & Completed History ─────────────────────────────────────
  Widget _buildHistoryTab(M4QueueService service) {
    final completed = service.allTickets
        .where((t) => t.status == M4QueueStatus.seated || t.status == M4QueueStatus.noShow || t.status == M4QueueStatus.cancelled)
        .toList();

    if (completed.isEmpty) {
      return const Center(child: Text('No completed tickets yet today.', style: TextStyle(color: AppTheme.textHint)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: completed.length,
      itemBuilder: (ctx, i) {
        final t = completed[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.ticketNumber} • ${t.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    'Party of ${t.partySize} ${t.assignedTableNumber != null ? "• Table ${t.assignedTableNumber}" : ""}',
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              M4QueueBadge(status: t.status),
            ],
          ),
        );
      },
    );
  }

  // ─── Modal Dialogs ──────────────────────────────────────────────────────────
  void _showSeatDialog(BuildContext context, M4QueueTicket t, M4QueueService service) {
    final available = service.allTables.where((tbl) => tbl.isAvailable && tbl.canFitParty(t.partySize)).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seat ${t.customerName} (${t.partySize} Guests)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (available.isEmpty) ...[
              const Text('No available tables fit this party size right now. Please wait for a table to clear.', style: TextStyle(color: AppTheme.error)),
            ] else ...[
              const Text('Select an available table:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              ...available.map((tbl) => ListTile(
                    leading: const Icon(Icons.table_bar, color: AppTheme.success),
                    title: Text('Table #${tbl.number} (${tbl.capacity} seats, ${tbl.location})'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      service.seatCustomer(
                        ticketId: t.id,
                        tableId: tbl.id,
                        staffId: 'staff1',
                        staffName: 'Host Staff',
                      );
                      SnackBarHelper.showSuccess(context, 'Seated at Table #${tbl.number}');
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddStaffNoteDialog(M4QueueTicket t, M4QueueService service) {
    final ctrl = TextEditingController(text: t.staffNotes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Staff Note for ${t.ticketNumber}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. VIP regular, guest waiting at bar...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              service.updateStaffNotes(t.id, ctrl.text.trim());
              Navigator.pop(ctx);
              SnackBarHelper.showSuccess(context, 'Note saved');
            },
            child: const Text('Save Note', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQuickQrCheckIn(BuildContext context, M4QueueService service) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Quick QR Check-in'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter ticket code shown on customer device (or scan QR):', style: TextStyle(fontSize: 12.5)),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Q-101',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              final found = service.findTicketByNumber(codeCtrl.text.trim());
              Navigator.pop(ctx);
              if (found != null) {
                _showSeatDialog(context, found, service);
              } else {
                SnackBarHelper.showError(context, 'Ticket not found in active queue.');
              }
            },
            child: const Text('Find & Seat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleQueuePause(BuildContext context, M4QueueService service, M4QueueConfig config) {
    if (config.isQueueOpen) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pause Virtual Queue?'),
          content: const Text('New customers will not be able to join the queue. Active guests remain in line.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () {
                service.toggleQueueOpen(_restaurantId, false, reason: 'Temporarily paused by host manager');
                Navigator.pop(ctx);
                SnackBarHelper.showSuccess(context, 'Queue is now paused');
              },
              child: const Text('Pause Queue', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      service.toggleQueueOpen(_restaurantId, true);
      SnackBarHelper.showSuccess(context, 'Queue resumed and open for new guests');
    }
  }
}
