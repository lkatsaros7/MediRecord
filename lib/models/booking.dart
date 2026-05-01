class Booking {
  final String bookingId;
  final String patientId;
  final DateTime bookingDate;
  final String? bookingTime;
  final String? bookingStatus;
  final String? bookingType;
  String? notes;

  Booking({
    required this.bookingId,
    required this.patientId,
    required this.bookingDate,
    this.bookingTime,
    this.bookingStatus,
    this.bookingType,
    this.notes,
  });

  bool get isUpcoming => bookingDate.isAfter(DateTime.now());
  bool get isPast => !isUpcoming;
}
