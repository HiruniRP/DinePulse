import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_2/widgets/m2_widgets.dart'; // Reuse high-res M2QrCode
import 'package:dine_pulse/member_4/models/m4_queue_model.dart';
import 'package:dine_pulse/member_4/services/m4_queue_service.dart';
import 'package:dine_pulse/member_4/widgets/m4_widgets.dart';

/// Screen: Customer Live Digital Ticket & Queue Tracker
class M4LiveTicketScreen extends StatefulWidget {
  final M4QueueTicket ticket;

  const M4LiveTicketScreen({super.key, required this.ticket});

  @override
  State<M4LiveTicketScreen> createState() => _M4LiveTicketScreenState();
}

class _M4LiveTicketScreenState extends State<M4LiveTicketScreen> {
  bool _leaving = false;
  bool _feedbackShown = false;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<M4QueueService>();
    final lang = service.currentLanguage;

    // Find latest ticket state from real-time stream in service
    final currentTicket = service.allTickets.firstWhere(
      (t) => t.id == widget.ticket.id,
      orElse: () => widget.ticket,
    );
    final t = currentTicket;

    // Check if seated and show post-dining feedback
    if (t.status == M4QueueStatus.seated && !_feedbackShown && t.rating == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _feedbackShown = true;
        _showPostVisitFeedback(context, t);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(M4Localizations.tr('live_ticket', lang)),
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
        child: Column(
          children: [
            // ─── Table Ready / Almost-Turn Hero Banners ────────────────────────
            if (t.isCalled)
              _buildTableReadyBanner(context, t)
            else if (t.isAlmostTurn)
              _buildAlmostTurnBanner(lang),

            const SizedBox(height: 14),

            // ─── Live Position Tracker ─────────────────────────────────────────
            M4PositionTracker(
              position: t.position,
              estimatedWaitMinutes: t.estimatedWaitMinutes,
              delayAlert: t.delayMinutesAlert,
            ),
            const SizedBox(height: 16),

            // ─── Digital Queue Ticket Card ─────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: AppTheme.cardShadow, blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  // Top ticket stub
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      border: Border(bottom: BorderSide(color: AppTheme.divider, style: BorderStyle.solid)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.restaurantName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Joined ${AppFormatters.timeAgo(t.joinedAt)}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                            ),
                          ],
                        ),
                        M4QueueBadge(status: t.status),
                      ],
                    ),
                  ),

                  // Ticket body with QR and ticket number
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          t.ticketNumber,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Visual QR Code
                        M2QrCode(bookingId: t.ticketNumber),
                        const SizedBox(height: 8),
                        const Text(
                          'Show this QR code to host upon arrival',
                          style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Ticket details grid
                        _detailRow('Customer', t.customerName),
                        const SizedBox(height: 8),
                        _detailRow('Party Size', '${t.partySize} Guests'),
                        const SizedBox(height: 8),
                        _detailRow('Seating Preference', t.seatingPreference),
                        if (t.needsHighChair || t.needsWheelchair || t.prefersQuietCorner) ...[
                          const SizedBox(height: 8),
                          _detailRow(
                            'Special Notes',
                            [
                              if (t.needsHighChair) 'High Chair',
                              if (t.needsWheelchair) 'Wheelchair',
                              if (t.prefersQuietCorner) 'Quiet Corner',
                            ].join(', '),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _detailRow('Notification Via', t.notificationChannel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Wait-Elsewhere Remote Mode ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: t.waitElsewhereActive ? AppTheme.primary : AppTheme.divider,
                  width: t.waitElsewhereActive ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            color: t.waitElsewhereActive ? AppTheme.primary : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Wait-Elsewhere Mode',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Switch(
                        value: t.waitElsewhereActive,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) {
                          service.setWaitElsewhere(t.id, val, radiusMeters: t.waitElsewhereRadiusMeters);
                          if (val) {
                            SnackBarHelper.showSuccess(
                              context,
                              'Wait-Elsewhere active! We will alert you 10 mins before your turn.',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Feel free to walk around nearby shops. We will send you a prompt when it is time to return.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  if (t.waitElsewhereActive) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.radar, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Safe distance radius: ${t.waitElsewhereRadiusMeters.toInt()}m',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Leave Queue Button ────────────────────────────────────────────
            if (t.isActive)
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.exit_to_app, size: 18),
                  label: Text(
                    M4Localizations.tr('leave_queue', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  onPressed: _leaving ? null : () => _confirmLeaveQueue(context, t),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTableReadyBanner(BuildContext context, M4QueueTicket t) {
    final mins = (t.callCountdownSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (t.callCountdownSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success, width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant, color: AppTheme.success, size: 24),
              SizedBox(width: 8),
              Text(
                'YOUR TABLE IS READY!',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppTheme.success,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Please report to the host stand immediately to claim your table.',
            style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimary, height: 1.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Claim within $mins:$secs',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlmostTurnBanner(M4Language lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppTheme.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              M4Localizations.tr('almost_turn', lang),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: AppTheme.warning,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _confirmLeaveQueue(BuildContext context, M4QueueTicket t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Virtual Queue?'),
        content: const Text(
          'Are you sure you want to cancel your ticket? Your spot in line will be forfeited and given to the next guest.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay in Queue'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final nav = Navigator.of(context);
              final sm = ScaffoldMessenger.of(context);
              setState(() => _leaving = true);
              final success = await context.read<M4QueueService>().leaveQueue(
                t.id,
                reason: 'Customer cancelled from app',
              );
              if (!mounted) return;
              setState(() => _leaving = false);
              if (success) {
                sm.showSnackBar(
                  SnackBar(
                    content: const Text('You left the queue.'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
                nav.pop();
              }
            },
            child: const Text('Leave Queue'),
          ),
        ],
      ),
    );
  }

  void _showPostVisitFeedback(BuildContext context, M4QueueTicket t) {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('How was your wait?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate your queue and dining experience:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    icon: Icon(
                      star <= rating ? Icons.star : Icons.star_border,
                      color: AppTheme.star,
                      size: 30,
                    ),
                    onPressed: () => setDialogState(() => rating = star),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(
                  hintText: 'Share quick feedback...',
                  hintStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shadowColor: AppTheme.accent.withOpacity(0.35),
              ),
              onPressed: () {
                context.read<M4QueueService>().submitFeedback(t.id, rating, commentCtrl.text.trim());
                Navigator.pop(ctx);
                SnackBarHelper.showSuccess(context, 'Thank you for your feedback!');
              },
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
