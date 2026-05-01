import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'patient.dart';
import 'booking.dart';

enum DataSourceStatus { noFileSelected, loading, connected, missing, invalid }

@immutable
class AppData {
  final List<Patient> patients;
  final List<Booking> bookings;
  final DataSourceStatus status;
  final String? fileName;
  final String? errorMessage;
  final bool isDirty;
  final String? fileType;
  final Uint8List? originalBytes;
  final String? driveFileId;

  const AppData({
    required this.patients,
    required this.bookings,
    required this.status,
    this.fileName,
    this.errorMessage,
    this.isDirty = false,
    this.fileType,
    this.originalBytes,
    this.driveFileId,
  });

  factory AppData.initial() => const AppData(
        patients: [],
        bookings: [],
        status: DataSourceStatus.noFileSelected,
      );

  AppData copyWith({
    List<Patient>? patients,
    List<Booking>? bookings,
    DataSourceStatus? status,
    String? fileName,
    String? errorMessage,
    bool? isDirty,
    String? fileType,
    Uint8List? originalBytes,
    String? driveFileId,
    bool clearFileName = false,
    bool clearError = false,
    bool clearOriginalBytes = false,
    bool clearDriveFileId = false,
  }) {
    return AppData(
      patients: patients ?? this.patients,
      bookings: bookings ?? this.bookings,
      status: status ?? this.status,
      fileName: clearFileName ? null : (fileName ?? this.fileName),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isDirty: isDirty ?? this.isDirty,
      fileType: fileType ?? this.fileType,
      originalBytes:
          clearOriginalBytes ? null : (originalBytes ?? this.originalBytes),
      driveFileId:
          clearDriveFileId ? null : (driveFileId ?? this.driveFileId),
    );
  }
}
