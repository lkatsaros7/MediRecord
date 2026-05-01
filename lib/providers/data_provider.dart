import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data_state.dart';
import '../models/booking.dart';
import '../models/patient.dart';
import '../services/csv_parser.dart';
import '../services/xlsx_parser.dart';
import '../services/file_service.dart';
import '../services/drive_service.dart';

class DataNotifier extends StateNotifier<AppData> {
  DataNotifier() : super(AppData.initial());

  Future<void> loadFile(Uint8List bytes, String fileName) async {
    state = state.copyWith(status: DataSourceStatus.loading);

    final isXlsx = fileName.toLowerCase().endsWith('.xlsx');
    final isCsv = fileName.toLowerCase().endsWith('.csv');

    if (!isXlsx && !isCsv) {
      state = state.copyWith(
        status: DataSourceStatus.invalid,
        errorMessage: 'Unsupported file type. Please use CSV or XLSX.',
      );
      return;
    }

    if (isCsv) {
      final result = parseCsv(bytes);
      if (result.error != null) {
        state = state.copyWith(
          status: DataSourceStatus.invalid,
          errorMessage: result.error,
          fileName: fileName,
        );
      } else {
        state = AppData(
          patients: result.patients,
          bookings: result.bookings,
          status: DataSourceStatus.connected,
          fileName: fileName,
          fileType: 'csv',
          originalBytes: bytes,
          isDirty: false,
        );
      }
    } else {
      final result = parseXlsx(bytes);
      if (result.error != null) {
        state = state.copyWith(
          status: DataSourceStatus.invalid,
          errorMessage: result.error,
          fileName: fileName,
        );
      } else {
        state = AppData(
          patients: result.patients,
          bookings: result.bookings,
          status: DataSourceStatus.connected,
          fileName: fileName,
          fileType: 'xlsx',
          originalBytes: bytes,
          isDirty: false,
        );
      }
    }
  }

  void updatePatient(Patient updatedPatient) {
    final updatedPatients = state.patients.map((p) {
      return p.patientId == updatedPatient.patientId ? updatedPatient : p;
    }).toList();
    state = state.copyWith(patients: updatedPatients, isDirty: true);
  }

  String _nextBookingId() {
    int max = 0;
    for (final b in state.bookings) {
      final match = RegExp(r'APT(\d+)').firstMatch(b.bookingId);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > max) max = n;
      }
    }
    return 'APT${(max + 1).toString().padLeft(4, '0')}';
  }

  void addBooking(String patientId, DateTime date, String? notes) {
    final newBooking = Booking(
      bookingId: _nextBookingId(),
      patientId: patientId,
      bookingDate: date,
      notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
    );
    state = state.copyWith(
      bookings: [...state.bookings, newBooking],
      isDirty: true,
    );
  }

  void removeBooking(String bookingId) {
    state = state.copyWith(
      bookings: state.bookings.where((b) => b.bookingId != bookingId).toList(),
      isDirty: true,
    );
  }

  void updateBookingNotes(String bookingId, String notes) {
    final updatedBookings = state.bookings.map((b) {
      if (b.bookingId == bookingId) {
        return Booking(
          bookingId: b.bookingId,
          patientId: b.patientId,
          bookingDate: b.bookingDate,
          bookingTime: b.bookingTime,
          bookingStatus: b.bookingStatus,
          bookingType: b.bookingType,
          notes: notes.isEmpty ? null : notes,
        );
      }
      return b;
    }).toList();
    state = state.copyWith(bookings: updatedBookings, isDirty: true);
  }

  void addPatient(Patient patient) {
    if (state.patients.any((p) => p.patientId == patient.patientId)) {
      throw Exception(
          'A patient with AMKA "${patient.patientId}" already exists.\n\n'
          'Each patient must have a unique AMKA. '
          'Please check the ID and try again.');
    }
    state = state.copyWith(
      patients: [...state.patients, patient],
      isDirty: true,
    );
  }

  void removePatient(String patientId) {
    state = state.copyWith(
      patients: state.patients.where((p) => p.patientId != patientId).toList(),
      bookings: state.bookings.where((b) => b.patientId != patientId).toList(),
      isDirty: true,
    );
  }

  /// Opens the Google Picker, downloads the chosen file, and parses it.
  /// Returns an error string on failure, or null on success (including cancel).
  Future<String?> openFromDrive() async {
    try {
      final driveService = DriveService.instance;
      await driveService.signIn();
      final picked = await driveService.pickFile();
      if (picked == null) return null; // user cancelled

      state = state.copyWith(status: DataSourceStatus.loading);
      final bytes = await driveService.downloadFile(picked.fileId);
      await loadFile(bytes, picked.fileName);
      // Store the Drive file ID so we can save back later.
      state = state.copyWith(driveFileId: picked.fileId);
      return null;
    } catch (e, st) {
      dev.log('[drive] openFromDrive error: $e', error: e, stackTrace: st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Saves the current data back to the same Drive file and returns an error
  /// string on failure, or null on success.
  Future<String?> saveToDrive() async {
    try {
      final fileId = state.driveFileId;
      if (fileId == null) {
        return 'No Drive file is linked. Open a file from Google Drive first.';
      }
      final bytes = generateUpdatedFile();
      if (bytes == null) {
        return 'File generation failed — see console for details.';
      }
      await DriveService.instance.saveFile(fileId, bytes);
      state = state.copyWith(isDirty: false);
      return null;
    } catch (e, st) {
      dev.log('[drive] saveToDrive error: $e', error: e, stackTrace: st);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  void clearData() {
    state = AppData.initial();
  }

  Uint8List? generateUpdatedFile() {
    if (state.fileType == 'csv') {
      return generateCsv(state.patients, state.bookings);
    } else if (state.fileType == 'xlsx') {
      return generateFullXlsx(state.patients, state.bookings);
    }
    return null;
  }

  Future<void> pickAndLoadFile() async {
    final result = await pickFile();
    if (result != null) {
      final (bytes, name) = result;
      await loadFile(bytes, name);
    }
  }

  /// Saves the current data and triggers a browser download with the original
  /// filename. Returns `null` on success, or a descriptive error message on
  /// failure.
  String? saveAndDownload() {
    try {
      if (state.fileType == null) {
        return 'Cannot save: no file is currently loaded.';
      }
      final bytes = generateUpdatedFile();
      if (bytes == null) {
        return 'File generation returned no data.\n\n'
            'The file could not be encoded. This may be caused by an '
            'unsupported file structure or a library error.\n\n'
            'Try re-selecting the file and re-applying your changes.';
      }
      final ext = state.fileType!;
      final baseName = state.fileName ?? 'updated_data';
      final downloadName =
          baseName.contains('.') ? baseName : '$baseName.$ext';
      downloadFile(bytes, downloadName);
      state = state.copyWith(isDirty: false);
      return null;
    } catch (e, st) {
      dev.log('[save] Error saving file: $e', error: e, stackTrace: st);
      return 'Failed to save file.\n\nDetails: $e\n\n'
          'If this problem persists, try the Settings screen to reload your file.';
    }
  }
}

final dataProvider = StateNotifierProvider<DataNotifier, AppData>(
  (ref) => DataNotifier(),
);
