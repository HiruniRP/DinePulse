import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart';

/// Screen 10: Modify Reservation
class M2ModifyReservationScreen extends StatefulWidget {
  final M2ReservationModel reservation;
  const M2ModifyReservationScreen({super.key, required this.reservation});

  @override
  State<M2ModifyReservationScreen> createState() => _M2ModifyReservationScreenState();
}

class _M2ModifyReservationScreenState extends State<M2ModifyReservationScreen> {
  late DateTime _date;
  late String _time;
  late int _partySize;
  late String _specialRequests;
  late String? _specialOccasion;
  late String _tableLocation;
  bool _saving = false;

  static const _times = [
    '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM', '1:00 PM', '1:30 PM',
    '6:00 PM', '6:30 PM', '7:00 PM', '7:30 PM', '8:00 PM', '8:30 PM', '9:00 PM',
  ];

  final _occasions = ['birthday', 'anniversary', 'business', 'date_night', 'family', 'other'];
  final _locations = ['any', 'indoor', 'outdoor', 'private', 'bar'];

  @override
  void initState() {
    super.initState();
    final r = widget.reservation;
    _date = r.date;
    _time = r.time;
    _partySize = r.partySize;
    _specialRequests = r.specialRequests ?? '';
    _specialOccasion = r.specialOccasion;
    _tableLocation = r.tableLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Modify Reservation'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Booking reference
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withAlpha(15), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.confirmation_number, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(widget.reservation.bookingId, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 15, letterSpacing: 0.5)),
              const Spacer(),
              M2StatusBadge(status: widget.reservation.status),
            ]),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.warning.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 14, color: AppTheme.warning),
              SizedBox(width: 6),
              Expanded(child: Text('Changes require staff re-confirmation. Your reservation status will reset to "Modified".', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
            ]),
          ),
          const SizedBox(height: 20),

          // Date
          _section('Date', Icons.calendar_today, [
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
                child: Row(children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.edit, color: AppTheme.textHint, size: 16),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Time
          _section('Time', Icons.access_time, [
            Wrap(spacing: 8, runSpacing: 8, children: _times.map((t) {
              final sel = _time == t;
              return GestureDetector(
                onTap: () => setState(() => _time = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider),
                  ),
                  child: Text(t, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList()),
          ]),
          const SizedBox(height: 16),

          // Party size
          _section('Party Size', Icons.people_outline, [
            Row(children: [
              _circleBtn(Icons.remove, () { if (_partySize > 1) setState(() => _partySize--); }),
              Expanded(child: Center(child: Text('$_partySize guests', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary)))),
              _circleBtn(Icons.add, () { if (_partySize < 20) setState(() => _partySize++); }),
            ]),
          ]),
          const SizedBox(height: 16),

          // Table location
          _section('Seating Area', Icons.chair_alt, [
            Wrap(spacing: 8, runSpacing: 8, children: _locations.map((loc) {
              final sel = _tableLocation == loc;
              return GestureDetector(
                onTap: () => setState(() => _tableLocation = loc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider),
                  ),
                  child: Text(loc[0].toUpperCase() + loc.substring(1), style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList()),
          ]),
          const SizedBox(height: 16),

          // Occasion
          _section('Special Occasion', Icons.celebration_outlined, [
            Wrap(spacing: 8, runSpacing: 8, children: [
              GestureDetector(onTap: () => setState(() => _specialOccasion = null),
                child: _chip('None', _specialOccasion == null)),
              ..._occasions.map((o) => GestureDetector(onTap: () => setState(() => _specialOccasion = o),
                child: _chip(o[0].toUpperCase() + o.substring(1).replaceAll('_', ' '), _specialOccasion == o))),
            ]),
          ]),
          const SizedBox(height: 16),

          // Special requests
          _section('Special Requests', Icons.notes_outlined, [
            TextField(
              maxLines: 3,
              controller: TextEditingController(text: _specialRequests),
              onChanged: (v) => _specialRequests = v,
              decoration: InputDecoration(
                hintText: 'Any changes to your requirements...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent, width: 2)),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Modification history
          if (widget.reservation.modificationHistory.isNotEmpty) ...[
            _section('Modification History', Icons.history, widget.reservation.modificationHistory.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.edit_note, size: 16, color: AppTheme.textHint),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${m.field}: ${m.oldValue} → ${m.newValue}', style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                  Text(_formatTime(m.changedAt), style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                ])),
              ]),
            )).toList()),
            const SizedBox(height: 16),
          ],

          _saving
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Changes'),
                  ),
                ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Discard Changes')),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: const [AppTheme.cardBoxShadow]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _chip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w500)),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppTheme.primary.withAlpha(20), shape: BoxShape.circle, border: Border.all(color: AppTheme.primary.withAlpha(60))),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
    );
  }

  String _formatTime(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: ThemeData(colorScheme: const ColorScheme.light(primary: AppTheme.primary, onPrimary: Colors.white)), child: child!),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final service = context.read<M2ReservationService>();
    final ok = await service.modifyReservation(
      reservationId: widget.reservation.id,
      actorId: widget.reservation.customerId,
      actorName: widget.reservation.customerName,
      newDate: _date != widget.reservation.date ? _date : null,
      newTime: _time != widget.reservation.time ? _time : null,
      newPartySize: _partySize != widget.reservation.partySize ? _partySize : null,
      newSpecialRequests: _specialRequests,
      newSpecialOccasion: _specialOccasion,
      newTableLocation: _tableLocation,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Reservation updated! Pending staff confirmation.' : 'Failed to update. Try again.'),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
    if (ok) Navigator.pop(context);
  }
}
