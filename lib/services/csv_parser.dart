import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../models/patient.dart';
import '../models/booking.dart';

class CsvParseResult {
  final List<Patient> patients;
  final List<Booking> bookings;
  final String? error;

  CsvParseResult({required this.patients, required this.bookings, this.error});
}

CsvParseResult parseCsv(Uint8List bytes) {
  try {
    final csvString = utf8.decode(bytes, allowMalformed: true);
    final rows =
        const CsvToListConverter().convert(csvString, eol: '\n');
    if (rows.isEmpty) {
      return CsvParseResult(
          patients: [], bookings: [], error: 'CSV file is empty');
    }

    final headers =
        rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

    // Resolve a column index, trying each alias in order.
    int col(List<String> aliases) {
      for (final a in aliases) {
        final idx = headers.indexOf(a);
        if (idx >= 0) return idx;
      }
      return -1;
    }

    // Require at least one of the known patient-id and name columns.
    final hasId = col(['amka', 'patient_id']) >= 0;
    final hasName = col(['first_name', 'name']) >= 0;
    final hasSurname = col(['last_name', 'surname']) >= 0;
    if (!hasId || !hasName || !hasSurname) {
      final missing = [
        if (!hasId) 'patient_id / amka',
        if (!hasName) 'name / first_name',
        if (!hasSurname) 'surname / last_name',
      ];
      return CsvParseResult(
        patients: [],
        bookings: [],
        error: 'Missing required column(s): ${missing.join(', ')}',
      );
    }

    final patientsMap = <String, Patient>{};
    final bookings = <Booking>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      String get(List<String> aliases) {
        final idx = col(aliases);
        if (idx < 0 || idx >= row.length) return '';
        return row[idx]?.toString().trim() ?? '';
      }

      final patientId = get(['amka', 'patient_id']);
      if (patientId.isEmpty) continue;

      if (!patientsMap.containsKey(patientId)) {
        patientsMap[patientId] = Patient(
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
        );
      }

      final bookingId = get(['booking_id']);
      if (bookingId.isNotEmpty) {
        final dateStr = get(['booking_date']);
        DateTime? date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          continue;
        }
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
          notes:
              get(['booking_notes']).isEmpty ? null : get(['booking_notes']),
        ));
      }
    }

    return CsvParseResult(
      patients: patientsMap.values.toList(),
      bookings: bookings,
    );
  } catch (e) {
    return CsvParseResult(
        patients: [], bookings: [], error: 'Failed to parse CSV: $e');
  }
}

Uint8List generateCsv(List<Patient> patients, List<Booking> bookings) {
  final headers = [
    'AMKA',
    'first_name',
    'last_name',
    'date_of_birth',
    'mobile',
    'phone',
    'email',
    'address',
    'cause',
    'allergies',
    'medication',
    'medical_history',
    'emergency_contact',
    'booking_id',
    'booking_date',
    'booking_time',
    'booking_status',
    'booking_type',
    'booking_notes',
  ];

  final rows = <List<dynamic>>[headers];

  final patientBookings = <String, List<Booking>>{};
  for (final b in bookings) {
    patientBookings.putIfAbsent(b.patientId, () => []).add(b);
  }

  for (final p in patients) {
    final pBookings = patientBookings[p.patientId] ?? [];
    if (pBookings.isEmpty) {
      rows.add([
        p.patientId, p.name, p.surname,
        p.dateOfBirth ?? '', p.mobile ?? '', p.phone ?? '',
        p.email ?? '', p.address ?? '', p.healthInformation ?? '',
        p.allergies ?? '', p.medication ?? '', p.medicalHistory ?? '',
        p.emergencyContact ?? '', '', '', '', '', '', '',
      ]);
    } else {
      for (final b in pBookings) {
        rows.add([
          p.patientId, p.name, p.surname,
          p.dateOfBirth ?? '', p.mobile ?? '', p.phone ?? '',
          p.email ?? '', p.address ?? '', p.healthInformation ?? '',
          p.allergies ?? '', p.medication ?? '', p.medicalHistory ?? '',
          p.emergencyContact ?? '',
          b.bookingId,
          b.bookingDate.toIso8601String().split('T').first,
          b.bookingTime ?? '', b.bookingStatus ?? '',
          b.bookingType ?? '', b.notes ?? '',
        ]);
      }
    }
  }

  final csv = const ListToCsvConverter().convert(rows);
  return Uint8List.fromList(utf8.encode(csv));
}
