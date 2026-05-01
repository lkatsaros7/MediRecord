import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';

/// Shows a dialog to create a new booking.
///
/// [patients] is required only when [preselectedPatientId] is null (i.e. the
/// caller doesn't already know which patient to book).
/// [initialDate] pre-fills the date picker (defaults to today).
///
/// Returns `(patientId, date, notes)` on confirm, or null on cancel.
Future<(String, DateTime, String?)?> showAddBookingDialog(
  BuildContext context, {
  required List<Patient> patients,
  String? preselectedPatientId,
  DateTime? initialDate,
}) {
  return showDialog<(String, DateTime, String?)>(
    context: context,
    builder: (_) => _AddBookingDialog(
      patients: patients,
      preselectedPatientId: preselectedPatientId,
      initialDate: initialDate ?? DateTime.now(),
    ),
  );
}

class _AddBookingDialog extends StatefulWidget {
  final List<Patient> patients;
  final String? preselectedPatientId;
  final DateTime initialDate;

  const _AddBookingDialog({
    required this.patients,
    this.preselectedPatientId,
    required this.initialDate,
  });

  @override
  State<_AddBookingDialog> createState() => _AddBookingDialogState();
}

class _AddBookingDialogState extends State<_AddBookingDialog> {
  late DateTime _selectedDate;
  String? _selectedPatientId;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _selectedPatientId = widget.preselectedPatientId ??
        (widget.patients.isNotEmpty ? widget.patients.first.patientId : null);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool get _canConfirm => _selectedPatientId != null;

  @override
  Widget build(BuildContext context) {
    final showPatientPicker = widget.preselectedPatientId == null;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.event_available, color: Color(0xFF1565C0)),
          SizedBox(width: 10),
          Text('New Appointment'),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showPatientPicker) ...[
              const Text(
                'Patient',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedPatientId,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: widget.patients
                    .map((p) => DropdownMenuItem(
                          value: p.patientId,
                          child: Text(p.fullName, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPatientId = v),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Date',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notes (optional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add notes for this appointment…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _canConfirm
              ? () => Navigator.of(context).pop((
                    _selectedPatientId!,
                    _selectedDate,
                    _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                  ))
              : null,
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Add Appointment'),
        ),
      ],
    );
  }
}
