import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_4/models/m4_queue_model.dart';
import 'package:dine_pulse/member_4/services/m4_queue_service.dart';
import 'package:dine_pulse/member_4/widgets/m4_widgets.dart';
import 'package:dine_pulse/core/constants/app_constants.dart';
import 'package:dine_pulse/member_1/models/notification_model.dart';
import 'package:dine_pulse/member_1/services/notification_service.dart';

/// Screen 1: Join Virtual Queue (Customer)
class M4JoinQueueScreen extends StatefulWidget {
  final RestaurantModel? restaurant;

  const M4JoinQueueScreen({super.key, this.restaurant});

  @override
  State<M4JoinQueueScreen> createState() => _M4JoinQueueScreenState();
}

class _M4JoinQueueScreenState extends State<M4JoinQueueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int _partySize = 2;
  String _seatingPreference = 'Any';
  bool _needsHighChair = false;
  bool _needsWheelchair = false;
  bool _prefersQuietCorner = false;
  String _notificationChannel = M4NotificationChannel.push;

  final List<String> _seatingOptions = ['Any', 'Indoor', 'Outdoor', 'Booth'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.currentUser != null) {
        _nameCtrl.text = auth.currentUser!.fullName;
        _phoneCtrl.text = auth.currentUser!.phoneNumber ?? '';
      } else {
        _nameCtrl.text = 'Guest Customer';
        _phoneCtrl.text = '+94 77 123 4567';
      }
      _checkDuplicateTicket();
    });
  }

  void _checkDuplicateTicket() {
    final service = context.read<M4QueueService>();
    final auth = context.read<AuthService>();
    final customerId = auth.currentUser?.uid ?? 'demo_guest';
    final restaurantId = widget.restaurant?.id ?? 'rest1';

    final activeTicket = service.getActiveCustomerTicket(customerId, restaurantId);
    if (activeTicket != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Active Ticket Found'),
            ],
          ),
          content: Text(
            'You are already in this virtual queue!\n\n'
            'Ticket: ${activeTicket.ticketNumber}\n'
            'Position: #${activeTicket.position}\n'
            'Est. Wait: ~${activeTicket.estimatedWaitMinutes} mins',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shadowColor: AppTheme.accent.withOpacity(0.35),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(
                  context,
                  '/m4/live-ticket',
                  arguments: activeTicket,
                );
              },
              child: const Text('View Active Ticket', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<M4QueueService>();
    final lang = service.currentLanguage;
    final restaurantId = widget.restaurant?.id ?? 'rest1';
    final restaurantName = widget.restaurant?.name ?? 'The Grand Heritage';
    final activeQueue = service.getActiveQueue(restaurantId);
    final config = service.getConfig(restaurantId);
    final estWait = service.calculateDynamicWaitTime(restaurantId, _partySize);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(M4Localizations.tr('join_queue', lang)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: M4LanguageSelector(
                currentLanguage: lang,
                onLanguageChanged: (l) => service.setLanguage(l),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Queue Snapshot Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          restaurantName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.amber, size: 14),
                              SizedBox(width: 4),
                              Text('LIVE QUEUE', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _liveStatCol('Parties Waiting', '${activeQueue.length} ahead'),
                        Container(width: 1, height: 30, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 16)),
                        _liveStatCol('Est. Wait Time', '~$estWait mins'),
                      ],
                    ),
                  ],
                ),
              ),

              // Peak hour wait prediction notice
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppTheme.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        config.peakPredictionMessage,
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryDark, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Party Size Stepper
              const Text(
                'Party Size',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, color: AppTheme.primary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          '$_partySize ${_partySize == 1 ? "Guest" : "Guests"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: _partySize > 1 ? AppTheme.primary : AppTheme.textHint,
                          onPressed: _partySize > 1 ? () => setState(() => _partySize--) : null,
                        ),
                        Text('$_partySize', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: _partySize < 20 ? AppTheme.primary : AppTheme.textHint,
                          onPressed: _partySize < 20 ? () => setState(() => _partySize++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Seating Preference
              const Text(
                'Seating Preference',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _seatingOptions.map((opt) {
                  final isSelected = _seatingPreference == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    onSelected: (sel) {
                      if (sel) setState(() => _seatingPreference = opt);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Special Requirements
              const Text(
                'Special Requirements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('High Chair Needed (Baby / Toddler)', style: TextStyle(fontSize: 13.5)),
                      value: _needsHighChair,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _needsHighChair = v ?? false),
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Wheelchair Accessible Table', style: TextStyle(fontSize: 13.5)),
                      value: _needsWheelchair,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _needsWheelchair = v ?? false),
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Prefers Quiet / Corner Table', style: TextStyle(fontSize: 13.5)),
                      value: _prefersQuietCorner,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _prefersQuietCorner = v ?? false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact & Notification Channel
              const Text(
                'Contact & Notification Channel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDec('Your Name', Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDec('Mobile Phone (for queue alerts)', Icons.phone_outlined),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 12),
              // Channel selection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alert Me Via:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _channelRadio(M4NotificationChannel.push, Icons.notifications_active),
                        const SizedBox(width: 8),
                        _channelRadio(M4NotificationChannel.sms, Icons.sms_outlined),
                        const SizedBox(width: 8),
                        _channelRadio(M4NotificationChannel.whatsapp, Icons.chat_bubble_outline),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: _inputDec('Dietary or special requests (optional)', Icons.notes_outlined),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    shadowColor: AppTheme.accent.withOpacity(0.35),
                  ),
                  onPressed: service.isLoading ? null : _handleJoinQueue,
                  child: service.isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Confirm & Get Queue Ticket',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveStatCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _channelRadio(String channel, IconData icon) {
    final isSelected = _notificationChannel == channel;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _notificationChannel = channel),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.divider),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? AppTheme.primary : AppTheme.textHint),
              const SizedBox(height: 4),
              Text(
                channel.split(' ').first,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textHint),
      prefixIcon: Icon(icon, size: 18, color: AppTheme.textHint),
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.divider),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Future<void> _handleJoinQueue() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<M4QueueService>();
    final auth = context.read<AuthService>();
    final customerId = auth.currentUser?.uid ?? 'demo_guest_${DateTime.now().millisecondsSinceEpoch}';

    final ticket = await service.joinQueue(
      restaurantId: widget.restaurant?.id ?? 'rest1',
      restaurantName: widget.restaurant?.name ?? 'The Grand Heritage',
      customerId: customerId,
      customerName: _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      partySize: _partySize,
      seatingPreference: _seatingPreference,
      needsHighChair: _needsHighChair,
      needsWheelchair: _needsWheelchair,
      prefersQuietCorner: _prefersQuietCorner,
      specialNotes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      notificationChannel: _notificationChannel,
    );

    if (!mounted) return;

    if (ticket != null) {
      // Cross-module sync: Add queue notification to Member 1
      context.read<NotificationService>().addNotification(
        NotificationModel(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          userId: customerId,
          title: 'Joined Queue: #${ticket.ticketNumber}',
          body: 'You are #${ticket.position} in line at ${ticket.restaurantName}. Est. wait: ~${ticket.estimatedWaitMinutes} mins.',
          type: AppConstants.notifReminder,
          isRead: false,
          createdAt: DateTime.now(),
          data: {'ticketId': ticket.id, 'restaurantId': ticket.restaurantId},
        ),
      );

      SnackBarHelper.showSuccess(context, 'You joined the queue! Ticket: #${ticket.ticketNumber}');
      Navigator.pushReplacementNamed(
        context,
        '/m4/live-ticket',
        arguments: ticket,
      );
    } else {
      SnackBarHelper.showError(context, service.lastError ?? 'Failed to join queue.');
    }
  }
}
