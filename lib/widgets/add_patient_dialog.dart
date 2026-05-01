import 'package:flutter/material.dart';
import '../models/patient.dart';

Future<Patient?> showAddPatientDialog(BuildContext context) {
  return showDialog<Patient>(
    context: context,
    builder: (context) => const _AddPatientDialog(),
  );
}

class _AddPatientDialog extends StatefulWidget {
  const _AddPatientDialog();

  @override
  State<_AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<_AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amkaCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _causeCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationCtrl = TextEditingController();
  final _historyCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();

  @override
  void dispose() {
    _amkaCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _mobileCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _causeCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationCtrl.dispose();
    _historyCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final patient = Patient(
      patientId: _amkaCtrl.text.trim(),
      name: _firstNameCtrl.text.trim(),
      surname: _lastNameCtrl.text.trim(),
      dateOfBirth:
          _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
      mobile:
          _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      healthInformation:
          _causeCtrl.text.trim().isEmpty ? null : _causeCtrl.text.trim(),
      allergies: _allergiesCtrl.text.trim().isEmpty
          ? null
          : _allergiesCtrl.text.trim(),
      medication: _medicationCtrl.text.trim().isEmpty
          ? null
          : _medicationCtrl.text.trim(),
      medicalHistory:
          _historyCtrl.text.trim().isEmpty ? null : _historyCtrl.text.trim(),
      emergencyContact: _emergencyCtrl.text.trim().isEmpty
          ? null
          : _emergencyCtrl.text.trim(),
    );
    Navigator.of(context).pop(patient);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Text('Add New Patient'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Required fields'),
                _field('AMKA (Patient ID)', _amkaCtrl, required: true),
                _field('First Name', _firstNameCtrl, required: true),
                _field('Last Name', _lastNameCtrl, required: true),
                const SizedBox(height: 12),
                _sectionHeader('Contact'),
                _field('Date of Birth', _dobCtrl, hint: 'YYYY-MM-DD'),
                _field('Mobile', _mobileCtrl),
                _field('Phone', _phoneCtrl),
                _field('Email', _emailCtrl),
                _field('Address', _addressCtrl),
                const SizedBox(height: 12),
                _sectionHeader('Medical'),
                _field('Health Information / Cause', _causeCtrl,
                    maxLines: 2),
                _field('Allergies', _allergiesCtrl, maxLines: 2),
                _field('Medication', _medicationCtrl, maxLines: 2),
                _field('Medical History', _historyCtrl, maxLines: 2),
                _field('Emergency Contact', _emergencyCtrl),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Add Patient'),
        ),
      ],
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF1565C0),
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    String? hint,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'This field is required' : null
              : null,
        ),
      );
}
