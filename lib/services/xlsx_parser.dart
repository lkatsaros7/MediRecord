import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:excel_community/excel_community.dart';
import '../models/patient.dart';
import '../models/booking.dart';

class XlsxParseResult {
  final List<Patient> patients;
  final List<Booking> bookings;
  final String? error;

  XlsxParseResult(
      {required this.patients, required this.bookings, this.error});
}

String _cellStr(Data? cell) {
  if (cell == null) return '';
  final v = cell.value;
  if (v == null) return '';
  if (v is TextCellValue) return v.value.toString().trim();
  if (v is IntCellValue) return v.value.toString();
  if (v is DoubleCellValue) return v.value.toString();
  if (v is DateCellValue) {
    return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
  }
  return v.toString().trim();
}

XlsxParseResult parseXlsx(Uint8List bytes) {
  try {
    dev.log('[xlsx] Decoding ${bytes.length} bytes…');
    final excel = Excel.decodeBytes(bytes);

    dev.log('[xlsx] Sheets found: ${excel.sheets.keys.toList()}');

    final patientsSheet = excel['Patients'];
    final bookingsSheet = excel['Bookings'];

    if (!excel.sheets.containsKey('Patients')) {
      dev.log('[xlsx] ERROR: Missing "Patients" sheet');
      return XlsxParseResult(
          patients: [], bookings: [], error: 'Missing "Patients" sheet');
    }
    if (!excel.sheets.containsKey('Bookings')) {
      dev.log('[xlsx] ERROR: Missing "Bookings" sheet');
      return XlsxParseResult(
          patients: [], bookings: [], error: 'Missing "Bookings" sheet');
    }

    final pRows = patientsSheet.rows;
    dev.log('[xlsx] Patients sheet: ${pRows.length} rows (including header)');
    if (pRows.isEmpty) {
      dev.log('[xlsx] ERROR: Patients sheet is empty');
      return XlsxParseResult(
          patients: [], bookings: [], error: 'Patients sheet is empty');
    }

    final pHeaders =
        pRows.first.map((c) => _cellStr(c).toLowerCase()).toList();
    dev.log('[xlsx] Patients headers: $pHeaders');
    // Resolve a column index, trying each alias in order.
    int pCol(List<String> aliases) {
      for (final a in aliases) {
        final idx = pHeaders.indexOf(a);
        if (idx >= 0) return idx;
      }
      return -1;
    }

    final patients = <Patient>[];
    for (int i = 1; i < pRows.length; i++) {
      final row = pRows[i];
      String get(List<String> aliases) {
        final idx = pCol(aliases);
        if (idx < 0 || idx >= row.length) return '';
        return _cellStr(row[idx]);
      }

      // Accept both "amka" (new format) and "patient_id" (spec format).
      final patientId = get(['amka', 'patient_id']);
      if (patientId.isEmpty) continue;
      patients.add(Patient(
        patientId: patientId,
        name: get(['first_name', 'name']),
        surname: get(['last_name', 'surname']),
        dateOfBirth:
            get(['date_of_birth']).isEmpty ? null : get(['date_of_birth']),
        mobile: get(['mobile']).isEmpty ? null : get(['mobile']),
        phone: get(['phone']).isEmpty ? null : get(['phone']),
        email: get(['email']).isEmpty ? null : get(['email']),
        address: get(['address']).isEmpty ? null : get(['address']),
        healthInformation: get(['cause', 'health_information']).isEmpty
            ? null
            : get(['cause', 'health_information']),
        allergies: get(['allergies']).isEmpty ? null : get(['allergies']),
        medication: get(['medication']).isEmpty ? null : get(['medication']),
        medicalHistory:
            get(['medical_history']).isEmpty ? null : get(['medical_history']),
        emergencyContact: get(['emergency_contact']).isEmpty
            ? null
            : get(['emergency_contact']),
      ));
    }

    // Prefer "Appointments" sheet (simple 3-column format); fall back to "Bookings".
    final useAppointments = excel.sheets.containsKey('Appointments');
    dev.log('[xlsx] Using ${useAppointments ? "Appointments" : "Bookings"} sheet for bookings');
    final bookingSource =
        useAppointments ? excel['Appointments'] : bookingsSheet;

    final bRows = bookingSource.rows;
    dev.log('[xlsx] Bookings sheet: ${bRows.length} rows (including header)');
    final bHeaders = bRows.isEmpty
        ? <String>[]
        : bRows.first.map((c) => _cellStr(c).toLowerCase()).toList();
    dev.log('[xlsx] Bookings headers: $bHeaders');
    int bCol(List<String> aliases) {
      for (final a in aliases) {
        final idx = bHeaders.indexOf(a);
        if (idx >= 0) return idx;
      }
      return -1;
    }

    final bookings = <Booking>[];
    for (int i = 1; i < bRows.length; i++) {
      final row = bRows[i];
      String get(List<String> aliases) {
        final idx = bCol(aliases);
        if (idx < 0 || idx >= row.length) return '';
        return _cellStr(row[idx]);
      }

      final patientId = get(['patient_id']);
      if (patientId.isEmpty) continue;

      final dateStr = get(['booking_date']);
      DateTime? date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        dev.log('[xlsx] Bookings row $i: skipped — unparseable date "$dateStr"');
        continue;
      }

      // Generate a stable booking ID from the row index when not present.
      final rawId = get(['booking_id']);
      final bookingId =
          rawId.isNotEmpty ? rawId : 'APT${i.toString().padLeft(4, '0')}';

      bookings.add(Booking(
        bookingId: bookingId,
        patientId: patientId,
        bookingDate: date,
        bookingTime:
            get(['booking_time']).isEmpty ? null : get(['booking_time']),
        bookingStatus:
            get(['booking_status']).isEmpty ? null : get(['booking_status']),
        bookingType:
            get(['booking_type']).isEmpty ? null : get(['booking_type']),
        notes: get(['booking_notes', 'notes']).isEmpty
            ? null
            : get(['booking_notes', 'notes']),
      ));
    }

    dev.log('[xlsx] Parsed ${patients.length} patients, ${bookings.length} bookings — success');
    return XlsxParseResult(patients: patients, bookings: bookings);
  } catch (e, st) {
    dev.log('[xlsx] EXCEPTION: $e', error: e, stackTrace: st);
    return XlsxParseResult(
        patients: [], bookings: [], error: 'Failed to parse XLSX: $e');
  }
}

Uint8List? generateFullXlsx(List<Patient> patients, List<Booking> bookings) {
  try {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // ── Patients sheet ──────────────────────────────────────────────────
    final pSheet = excel['Patients'];
    pSheet.appendRow([
      TextCellValue('id'),
      TextCellValue('first_name'),
      TextCellValue('last_name'),
      TextCellValue('mobile'),
      TextCellValue('phone'),
      TextCellValue('email'),
      TextCellValue('AMKA'),
      TextCellValue('cause'),
    ]);
    for (int i = 0; i < patients.length; i++) {
      final p = patients[i];
      pSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.name),
        TextCellValue(p.surname),
        TextCellValue(p.mobile ?? ''),
        TextCellValue(p.phone ?? ''),
        TextCellValue(p.email ?? ''),
        TextCellValue(p.patientId),
        TextCellValue(p.healthInformation ?? ''),
      ]);
    }

    // ── Appointments sheet ──────────────────────────────────────────────
    final aSheet = excel['Appointments'];
    aSheet.appendRow([
      TextCellValue('patient_id'),
      TextCellValue('booking_date'),
      TextCellValue('notes'),
    ]);
    final sorted = [...bookings]
      ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
    for (final b in sorted) {
      aSheet.appendRow([
        TextCellValue(b.patientId),
        TextCellValue(
            '${b.bookingDate.year}-${b.bookingDate.month.toString().padLeft(2, '0')}-${b.bookingDate.day.toString().padLeft(2, '0')}'),
        TextCellValue(b.notes ?? ''),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception(
          'The Excel encoder returned no data. '
          'The workbook could not be serialized.');
    }
    dev.log('[xlsx] generateFullXlsx: encoded ${encoded.length} bytes');
    return Uint8List.fromList(encoded);
  } catch (e, st) {
    dev.log('[xlsx] generateFullXlsx error: $e', error: e, stackTrace: st);
    rethrow;
  }
}

Uint8List? generateXlsx(
  List<Patient> patients,
  List<Booking> bookings,
  Uint8List originalBytes,
) {
  try {
    final excel = Excel.decodeBytes(originalBytes);

    // Write back to whichever sheet was used for reading.
    final sheetName =
        excel.sheets.containsKey('Appointments') ? 'Appointments' : 'Bookings';
    if (!excel.sheets.containsKey(sheetName)) return null;
    final bookingsSheet = excel[sheetName];

    final bRows = bookingsSheet.rows;
    if (bRows.isEmpty) return null;

    final bHeaders =
        bRows.first.map((c) => _cellStr(c).toLowerCase()).toList();
    int bCol(List<String> aliases) {
      for (final a in aliases) {
        final idx = bHeaders.indexOf(a);
        if (idx >= 0) return idx;
      }
      return -1;
    }

    // Notes column may be "notes" (Appointments) or "booking_notes" (Bookings).
    final notesColIdx = bCol(['notes', 'booking_notes']);
    // ID column — absent in Appointments; match by row position instead.
    final idColIdx = bCol(['booking_id']);
    if (notesColIdx < 0) return null;

    final notesMap = <String, String?>{};
    for (final b in bookings) {
      notesMap[b.bookingId] = b.notes;
    }

    for (int i = 1; i < bRows.length; i++) {
      final row = bRows[i];
      // For Appointments sheet there is no booking_id — use the generated key.
      final resolvedId = idColIdx >= 0 && idColIdx < row.length
          ? _cellStr(row[idColIdx])
          : 'APT${i.toString().padLeft(4, '0')}';

      if (resolvedId.isNotEmpty && notesMap.containsKey(resolvedId)) {
        bookingsSheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: notesColIdx, rowIndex: i))
            .value = TextCellValue(notesMap[resolvedId] ?? '');
      }
    }

    final encoded = excel.encode();
    if (encoded == null) return null;
    return Uint8List.fromList(encoded);
  } catch (_) {
    return null;
  }
}
