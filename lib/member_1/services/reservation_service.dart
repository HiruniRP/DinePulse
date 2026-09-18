import 'package:flutter/foundation.dart';
import 'package:dine_pulse/member_1/models/reservation_model.dart';
import 'package:dine_pulse/core/constants/app_constants.dart';

/// Firebase-ready reservation service for Member 1 (read-only view of customer reservations).
class ReservationService extends ChangeNotifier {
  List<ReservationModel> _reservations = [];
  bool _isLoading = false;
  String? _error;

  List<ReservationModel> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ReservationModel> get upcomingReservations =>
      _reservations.where((r) => r.isUpcoming).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<ReservationModel> get pastReservations =>
      _reservations.where((r) => !r.isUpcoming).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  Future<void> loadReservations(String customerId) async {
    _setLoading(true);
    _error = null;
    try {
      // TODO: Firestore().collection('reservations').where('customerId', isEqualTo: customerId).snapshots()
      await Future.delayed(const Duration(milliseconds: 700));
      _reservations = _mockReservations(customerId);
    } catch (e) {
      _error = 'Failed to load reservations';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    _setLoading(true);
    try {
      // TODO: Firestore().collection('reservations').doc(reservationId).update({'status': 'cancelled'})
      await Future.delayed(const Duration(milliseconds: 500));
      _reservations = _reservations.map((r) {
        if (r.id == reservationId) return r.copyWith(status: AppConstants.statusCancelled);
        return r;
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to cancel reservation';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Synchronize reservation created or updated by Member 2
  void addOrUpdateReservation(ReservationModel reservation) {
    final idx = _reservations.indexWhere((r) => r.id == reservation.id);
    if (idx != -1) {
      _reservations[idx] = reservation;
    } else {
      _reservations.insert(0, reservation);
    }
    notifyListeners();
  }

  List<ReservationModel> _mockReservations(String customerId) => [
    ReservationModel(
      id: 'res1',
      customerId: customerId,
      customerName: 'Alex Johnson',
      restaurantId: 'r1',
      restaurantName: 'The Spice Garden',
      restaurantImage: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400',
      date: DateTime.now().add(const Duration(days: 3)),
      time: '7:00 PM',
      partySize: 4,
      status: AppConstants.statusConfirmed,
      specialRequests: 'Window table preferred. One guest has a nut allergy.',
      tableNumber: 'T-12',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ReservationModel(
      id: 'res2',
      customerId: customerId,
      customerName: 'Alex Johnson',
      restaurantId: 'r2',
      restaurantName: 'Sakura Japanese',
      restaurantImage: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400',
      date: DateTime.now().add(const Duration(days: 8)),
      time: '6:30 PM',
      partySize: 2,
      status: AppConstants.statusPending,
      specialRequests: 'Anniversary dinner – please arrange a surprise.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ReservationModel(
      id: 'res3',
      customerId: customerId,
      customerName: 'Alex Johnson',
      restaurantId: 'r4',
      restaurantName: 'Dragon Palace',
      restaurantImage: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400',
      date: DateTime.now().subtract(const Duration(days: 2)),
      time: '1:00 PM',
      partySize: 6,
      status: AppConstants.statusCancelled,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ReservationModel(
      id: 'res4',
      customerId: customerId,
      customerName: 'Alex Johnson',
      restaurantId: 'r3',
      restaurantName: 'La Bella Italia',
      restaurantImage: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400',
      date: DateTime.now().subtract(const Duration(days: 10)),
      time: '8:00 PM',
      partySize: 2,
      status: AppConstants.statusCompleted,
      tableNumber: 'T-05',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    ReservationModel(
      id: 'res5',
      customerId: customerId,
      customerName: 'Alex Johnson',
      restaurantId: 'r5',
      restaurantName: 'Ocean Breeze Seafood',
      restaurantImage: 'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400',
      date: DateTime.now().subtract(const Duration(days: 20)),
      time: '7:30 PM',
      partySize: 3,
      status: AppConstants.statusCompleted,
      tableNumber: 'T-02',
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
    ),
  ];
}
