class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String createAccount = '/create-account';

  // Member 1 – Customer & Restaurant Discovery
  static const String m1Home = '/m1/home';
  static const String m1RestaurantSearch = '/m1/search';
  static const String m1SearchResults = '/m1/search-results';
  static const String m1RestaurantDetails = '/m1/restaurant-details';
  static const String m1RestaurantInfo = '/m1/restaurant-info';
  static const String m1Notifications = '/m1/notifications';
  static const String m1NotificationDetails = '/m1/notification-details';
  static const String m1MyReservations = '/m1/my-reservations';
  static const String m1ReservationDetails = '/m1/reservation-details';
  static const String m1Profile = '/m1/profile';
  static const String m1EditProfile = '/m1/edit-profile';
  static const String m1LogoutConfirm = '/m1/logout';

  // Member 2 – Reservation & Staff Management
  static const String m2TableAvailability = '/m2/table-availability';
  static const String m2ReservationForm = '/m2/reservation-form';
  static const String m2ReservationSummary = '/m2/reservation-summary';
  static const String m2ReservationSuccess = '/m2/reservation-success';
  static const String m2MyReservations = '/m2/my-reservations';
  static const String m2ReservationDetail = '/m2/reservation-detail';
  static const String m2ModifyReservation = '/m2/modify-reservation';
  static const String m2CancelReservation = '/m2/cancel-reservation';
  static const String m2StaffDashboard = '/m2/staff-dashboard';
  static const String m2StaffDetails = '/m2/staff-details';
  static const String m2ReservationManagement = '/m2/reservations';
  static const String m2MakeReservation = '/m2/make-reservation';

  // Member 4 – Virtual Queue & Table Management
  static const String m4QueueDashboard = '/m4/queue-dashboard';
  static const String m4JoinQueue = '/m4/join-queue';
  static const String m4LiveTicket = '/m4/live-ticket';
  static const String m4TableManagement = '/m4/tables';
  static const String m4StaffQueue = '/m4/staff-queue';
}
