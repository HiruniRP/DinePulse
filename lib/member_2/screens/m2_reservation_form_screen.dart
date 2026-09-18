import 'package:flutter/material.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart';

/// Screen 5: Reservation Form (combines Date/Time/Guest/Options)
class M2ReservationFormScreen extends StatefulWidget {
  final RestaurantModel? restaurant;
  final DateTime? initialDate;
  final String? initialTime;
  final int? initialPartySize;
  final M2TableModel? selectedTable;

  const M2ReservationFormScreen({
    super.key,
    this.restaurant,
    this.initialDate,
    this.initialTime,
    this.initialPartySize,
    this.selectedTable,
  });

  @override
  State<M2ReservationFormScreen> createState() => _M2ReservationFormScreenState();
}

class _M2ReservationFormScreenState extends State<M2ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _requestsCtrl = TextEditingController();

  late DateTime _date;
  late String _time;
  late int _partySize;
  String _tableLocation = 'any';
  String? _specialOccasion;
  bool _isRecurring = false;
  String? _recurringPattern;
  int? _recurringCount;
  bool _smsReminder = true;
  bool _emailReminder = true;
  int _reminderMinutes = 60;
  bool _depositPay = false;
  bool _policyAccepted = false;

  final _occasions = ['birthday', 'anniversary', 'business', 'date_night', 'family', 'other'];
  final _locations = ['any', 'indoor', 'outdoor', 'private', 'bar'];
  final _reminderOptions = {30: '30 min', 60: '1 hour', 120: '2 hours', 1440: '1 day'};
  final _recurringPatterns = {'weekly': 'Weekly', 'biweekly': 'Bi-weekly', 'monthly': 'Monthly'};

  static const _times = [
    '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM', '1:00 PM', '1:30 PM',
    '6:00 PM', '6:30 PM', '7:00 PM', '7:30 PM', '8:00 PM', '8:30 PM', '9:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    _time = widget.initialTime ?? '7:00 PM';
    _partySize = widget.initialPartySize ?? 2;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _requestsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reservation Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            M2StepHeader(currentStep: 2, totalSteps: 4, stepLabel: 'Reservation Details'),
            const SizedBox(height: 20),

            // --- Contact Info ---
            _sectionCard('Contact Information', Icons.person_outline, [
              _buildField('Full Name', _nameCtrl, validator: AppValidators.validateName, prefixIcon: Icons.person),
              const SizedBox(height: 12),
              _buildField('Phone Number', _phoneCtrl, validator: AppValidators.validatePhone, prefixIcon: Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildField('Email', _emailCtrl, validator: AppValidators.validateEmail, prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress),
            ]),
            const SizedBox(height: 16),

            // --- Date & Time ---
            _sectionCard('Date & Time', Icons.event, [
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(Icons.edit_calendar, color: AppTheme.textHint, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Select Time', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _times.map((t) {
                final sel = _time == t;
                return GestureDetector(
                  onTap: () => setState(() => _time = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList()),
            ]),
            const SizedBox(height: 16),

            // --- Party & Table ---
            _sectionCard('Party & Seating', Icons.people_outline, [
              const Text('Number of Guests', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(children: [
                _circleBtn(Icons.remove, () { if (_partySize > 1) setState(() => _partySize--); }),
                Expanded(child: Center(child: Text('$_partySize', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.primary)))),
                _circleBtn(Icons.add, () { if (_partySize < 20) setState(() => _partySize++); }),
              ]),
              const SizedBox(height: 14),
              const Text('Preferred Seating Area', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _locations.map((loc) {
                final sel = _tableLocation == loc;
                return GestureDetector(
                  onTap: () => setState(() => _tableLocation = loc),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider),
                    ),
                    child: Text(loc[0].toUpperCase() + loc.substring(1), style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList()),
              if (widget.selectedTable != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.success.withAlpha(20), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.success.withAlpha(80))),
                  child: Row(children: [
                    const Icon(Icons.table_restaurant, color: AppTheme.success, size: 18),
                    const SizedBox(width: 8),
                    Text('Preferred: Table ${widget.selectedTable!.number} (${widget.selectedTable!.capacity} seats)', style: const TextStyle(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // --- Special Occasion ---
            _sectionCard('Special Occasion', Icons.celebration_outlined, [
              Wrap(spacing: 8, runSpacing: 8, children: [
                GestureDetector(
                  onTap: () => setState(() => _specialOccasion = null),
                  child: _occChip('None', null, _specialOccasion == null),
                ),
                ..._occasions.map((o) => GestureDetector(
                  onTap: () => setState(() => _specialOccasion = o),
                  child: _occChip(o[0].toUpperCase() + o.substring(1).replaceAll('_', ' '), o, _specialOccasion == o),
                )),
              ]),
            ]),
            const SizedBox(height: 16),

            // --- Recurring ---
            _sectionCard('Recurring Reservation', Icons.repeat, [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Make this a recurring reservation', style: TextStyle(fontSize: 14)),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                activeThumbColor: AppTheme.primary,
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _recurringPattern,
                  decoration: _inputDec('Repeat Pattern'),
                  items: _recurringPatterns.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setState(() => _recurringPattern = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: _recurringCount,
                  decoration: _inputDec('Number of Occurrences'),
                  items: [2,3,4,6,8,12].map((n) => DropdownMenuItem(value: n, child: Text('$n times'))).toList(),
                  onChanged: (v) => setState(() => _recurringCount = v),
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // --- Special Requests ---
            _sectionCard('Special Requests', Icons.notes_outlined, [
              TextFormField(
                controller: _requestsCtrl,
                maxLines: 3,
                decoration: _inputDec('Any dietary restrictions, allergies, or special arrangements...'),
              ),
            ]),
            const SizedBox(height: 16),

            // --- Notifications ---
            _sectionCard('Reminder Preferences', Icons.notifications_outlined, [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('SMS Reminder', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Receive reminder via SMS/WhatsApp', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                value: _smsReminder,
                onChanged: (v) => setState(() => _smsReminder = v),
                activeThumbColor: AppTheme.primary,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Email Reminder', style: TextStyle(fontSize: 14)),
                value: _emailReminder,
                onChanged: (v) => setState(() => _emailReminder = v),
                activeThumbColor: AppTheme.primary,
              ),
              if (_smsReminder || _emailReminder) ...[
                const SizedBox(height: 8),
                const Text('Remind me before', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Row(children: _reminderOptions.entries.map((e) {
                  final sel = _reminderMinutes == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _reminderMinutes = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider),
                        ),
                        child: Text(e.value, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  );
                }).toList()),
              ],
            ]),
            const SizedBox(height: 16),

            // --- Deposit ---
            _sectionCard('Deposit', Icons.payments_outlined, [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pay deposit now (optional)', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Secure your table with a deposit', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                value: _depositPay,
                onChanged: (v) => setState(() => _depositPay = v),
                activeThumbColor: AppTheme.primary,
              ),
              if (_depositPay)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.accent.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: AppTheme.accent, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('A deposit of LKR 1,000 will be collected. Refundable up to 24h before.', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
                  ]),
                ),
            ]),
            const SizedBox(height: 16),

            // --- Cancellation Policy ---
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withAlpha(40)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.policy_outlined, color: AppTheme.error, size: 18),
                  SizedBox(width: 8),
                  Text('Cancellation Policy', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.error, fontSize: 14)),
                ]),
                const SizedBox(height: 8),
                const Text('• Free cancellation up to 2 hours before the reservation.\n• Late cancellations may incur a fee.\n• No-shows will be charged a cancellation fee.', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.5)),
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Checkbox(
                    value: _policyAccepted,
                    onChanged: (v) => setState(() => _policyAccepted = v ?? false),
                    activeColor: AppTheme.primary,
                  ),
                  const Expanded(child: Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('I have read and agree to the cancellation policy', style: TextStyle(fontSize: 13)),
                  )),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _proceed,
                icon: const Icon(Icons.summarize_outlined),
                label: const Text('Review Reservation'),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppTheme.primary, size: 18)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {String? Function(String?)? validator, IconData? prefixIcon, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textHint, size: 18) : null,
      ),
    );
  }

  Widget _occChip(String label, String? value, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : Colors.white,
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

  InputDecoration _inputDec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData(colorScheme: const ColorScheme.light(primary: AppTheme.primary, onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;
    if (!_policyAccepted) {
      SnackBarHelper.showError(context, 'Please accept the cancellation policy to continue.');
      return;
    }
    Navigator.pushNamed(context, '/m2/reservation-summary', arguments: {
      'restaurant': widget.restaurant,
      'customerName': _nameCtrl.text.trim(),
      'customerPhone': _phoneCtrl.text.trim(),
      'customerEmail': _emailCtrl.text.trim(),
      'date': _date,
      'time': _time,
      'partySize': _partySize,
      'tableLocation': _tableLocation,
      'preferredTable': widget.selectedTable,
      'specialOccasion': _specialOccasion,
      'specialRequests': _requestsCtrl.text.trim().isEmpty ? null : _requestsCtrl.text.trim(),
      'isRecurring': _isRecurring,
      'recurringPattern': _recurringPattern,
      'recurringCount': _recurringCount,
      'smsReminder': _smsReminder,
      'emailReminder': _emailReminder,
      'reminderMinutes': _reminderMinutes,
      'depositRequired': _depositPay,
      'depositAmount': _depositPay ? 1000.0 : null,
      'policyAccepted': _policyAccepted,
    });
  }
}
