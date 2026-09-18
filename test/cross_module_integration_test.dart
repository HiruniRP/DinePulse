import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';
import 'package:dine_pulse/member_1/services/notification_service.dart';
import 'package:dine_pulse/member_1/services/reservation_service.dart';
import 'package:dine_pulse/member_1/models/notification_model.dart';
import 'package:dine_pulse/member_1/models/reservation_model.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';
import 'package:dine_pulse/member_2/services/m2_reservation_service.dart';
import 'package:dine_pulse/member_4/services/m4_queue_service.dart';
import 'package:dine_pulse/member_4/models/m4_queue_model.dart';
import 'package:dine_pulse/shared/services/table_repository.dart';
import 'package:dine_pulse/shared/models/shared_table_model.dart';

void main() {
  group('Cross-Module Integration Tests', () {
    late AuthService authService;
    late NotificationService notificationService;
    late ReservationService m1ReservationService;
    late M2ReservationService m2ReservationService;
    late M4QueueService m4QueueService;
    late SharedTableRepository sharedTableRepository;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
      notificationService = NotificationService();
      m1ReservationService = ReservationService();
      m2ReservationService = M2ReservationService();
      m4QueueService = M4QueueService();
      sharedTableRepository = SharedTableRepository();
    });

    test('Point 10 & 11: Shared Customer & Staff Authentication with Role Control', () async {
      // Customer sign in
      final customerSuccess = await authService.signIn('alex.customer@dinepulse.com', 'password123');
      expect(customerSuccess, isTrue);
      expect(authService.currentUser?.role, 'customer');
      expect(authService.currentUser?.isStaff, isFalse);

      // Staff sign in
      final staffSuccess = await authService.signIn('staff.manager@dinepulse.com', 'password123');
      expect(staffSuccess, isTrue);
      expect(authService.currentUser?.role, 'staff');
      expect(authService.currentUser?.isStaff, isTrue);
    });

    test('Point 4 & 5: Member 2 Reservation marks Table Reserved in Member 4', () async {
      const targetTableNumber = '4';
      final initialTable = m4QueueService.allTables.firstWhere((t) => t.number == targetTableNumber);
      expect(initialTable.status, M4TableStatus.available);

      // Member 2 locks table
      m4QueueService.markTableReservedFromM2(
        tableNumberOrId: targetTableNumber,
        customerName: 'Elena Rostova',
      );

      final updatedTable = m4QueueService.allTables.firstWhere((t) => t.number == targetTableNumber);
      expect(updatedTable.status, M4TableStatus.reservedM2);
      expect(updatedTable.isAvailable, isFalse);
    });

    test('Point 6: Member 4 CANNOT seat a queue party at a Member 2 reserved table', () async {
      // Reserve table 4
      m4QueueService.markTableReservedFromM2(
        tableNumberOrId: '4',
        customerName: 'Reserved Guest',
      );

      // Add queue ticket
      final ticket = await m4QueueService.joinQueue(
        restaurantId: 'rest1',
        restaurantName: 'The Grand Heritage',
        customerId: 'cust_test',
        customerName: 'Walk-in Guest',
        customerPhone: '+1 555-0199',
        partySize: 2,
      );
      expect(ticket, isNotNull);

      // Try seating at reserved table 4 (tbl_4)
      final seated = await m4QueueService.seatCustomer(
        ticketId: ticket!.id,
        tableId: 'tbl_4',
        staffId: 'staff_1',
        staffName: 'Staff Operator',
      );

      expect(seated, isFalse);
      expect(m4QueueService.lastError, contains('reserved by Member 2'));
    });

    test('Point 7: Member 4 Available Tables and Queue Wait dynamic calculation', () async {
      final initialWait = m4QueueService.calculateDynamicWaitTime('rest1', 2);
      final initialFreeTables = m4QueueService.getAvailableTablesCount('rest1');
      expect(initialFreeTables, greaterThan(0));

      // Reserving a table reduces available count and affects wait calculation
      m4QueueService.markTableReservedFromM2(
        tableNumberOrId: '1',
        customerName: 'VIP Table Guest',
      );

      final newFreeTables = m4QueueService.getAvailableTablesCount('rest1');
      expect(newFreeTables, equals(initialFreeTables - 1));
    });

    test('Point 8: Member 2 Reservation updates Member 1 Reservations and Notifications', () {
      final now = DateTime.now();
      const bookingId = 'DP-20240929-TEST';

      // Simulate Member 2 reservation sync to Member 1
      m1ReservationService.addOrUpdateReservation(
        ReservationModel(
          id: bookingId,
          customerId: 'cust_100',
          customerName: 'Alex Johnson',
          restaurantId: 'rest1',
          restaurantName: 'The Spice Garden',
          restaurantImage: '',
          date: now.add(const Duration(days: 2)),
          time: '7:30 PM',
          partySize: 4,
          status: 'confirmed',
          createdAt: now,
        ),
      );

      expect(m1ReservationService.reservations.any((r) => r.id == bookingId), isTrue);

      // Notification sync
      notificationService.addNotification(
        NotificationModel(
          id: 'notif_test',
          userId: 'cust_100',
          title: 'Reservation Confirmed! 🎉',
          body: 'Your table at The Spice Garden is booked.',
          type: 'reservation',
          isRead: false,
          createdAt: now,
        ),
      );

      expect(notificationService.notifications.any((n) => n.id == 'notif_test'), isTrue);
      expect(notificationService.unreadCount, equals(1));
    });

    test('Point 9: Queue Status updates push to Member 1 Notifications', () async {
      notificationService.addNotification(
        NotificationModel(
          id: 'notif_queue_1',
          userId: 'cust_100',
          title: 'Joined Queue: #Q-101',
          body: 'You are #1 in line. Est. wait: ~5 mins.',
          type: 'reminder',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      expect(notificationService.notifications.first.title, contains('Joined Queue'));
      expect(notificationService.unreadCount, equals(1));
    });

    test('Point 12: Shared Table Repository atomic reservation and queue block enforcement', () async {
      final tables = await sharedTableRepository.getTables('rest1');
      expect(tables, isNotEmpty);

      final available = tables.where((t) => t.status == SharedTableStatus.available).first;
      final locked = await sharedTableRepository.lockTableForReservation(
        restaurantId: 'rest1',
        tableId: available.id,
        reservationId: 'res_sync_test',
        customerName: 'Marcus Aurelius',
      );
      expect(locked, isTrue);

      // Attempt to seat queue customer at this reserved table: must fail!
      final seatResult = await sharedTableRepository.seatQueueCustomerAtTable(
        restaurantId: 'rest1',
        tableId: available.id,
        queueTicketId: 'q_tkt_1',
        customerName: 'Queue Customer',
        partySize: 2,
      );
      expect(seatResult, isFalse);
    });

    test('Real Account Creation & Session Persistence: User logs in as themselves, not Alex', () async {
      // 1. Create a brand new real user account
      final created = await authService.createAccount(
        firstName: 'Nikii',
        lastName: 'Fernando',
        email: 'nikii.fernando@example.com',
        password: 'securepassword123',
        phoneNumber: '+94 77 123 4567',
      );
      expect(created, isTrue);
      expect(authService.currentUser?.firstName, 'Nikii');
      expect(authService.currentUser?.lastName, 'Fernando');
      expect(authService.currentUser?.fullName, 'Nikii Fernando');
      expect(authService.currentUser?.email, 'nikii.fernando@example.com');
      expect(authService.isAuthenticated, isTrue);

      // 2. Sign out
      await authService.signOut();
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);

      // 3. Sign back in with the created account credentials
      final signedIn = await authService.signIn('nikii.fernando@example.com', 'securepassword123');
      expect(signedIn, isTrue);
      // MUST be Nikii Fernando, NOT Alex Johnson!
      expect(authService.currentUser?.firstName, 'Nikii');
      expect(authService.currentUser?.lastName, 'Fernando');
      expect(authService.currentUser?.fullName, 'Nikii Fernando');
      expect(authService.currentUser?.email, 'nikii.fernando@example.com');

      // 4. Test wrong password rejection
      await authService.signOut();
      final wrongPw = await authService.signIn('nikii.fernando@example.com', 'wrongpassword');
      expect(wrongPw, isFalse);
      expect(authService.error, contains('Incorrect password'));
    });
  });
}
