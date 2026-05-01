import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/patient.dart';
import '../providers/data_provider.dart';
import '../widgets/booking_tile.dart';
import '../widgets/add_booking_dialog.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  bool _editingProfile = false;
  bool _editingHealth = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _surnameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _causeCtrl;
  late TextEditingController _allergiesCtrl;
  late TextEditingController _medicationCtrl;
  late TextEditingController _historyCtrl;
  late TextEditingController _emergencyCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _surnameCtrl = TextEditingController();
    _mobileCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _causeCtrl = TextEditingController();
    _allergiesCtrl = TextEditingController();
    _medicationCtrl = TextEditingController();
    _historyCtrl = TextEditingController();
    _emergencyCtrl = TextEditingController();
  }

  void _initControllers(Patient p) {
    _nameCtrl.text = p.name;
    _surnameCtrl.text = p.surname;
    _mobileCtrl.text = p.mobile ?? '';
    _phoneCtrl.text = p.phone ?? '';
    _emailCtrl.text = p.email ?? '';
    _causeCtrl.text = p.healthInformation ?? '';
    _allergiesCtrl.text = p.allergies ?? '';
    _medicationCtrl.text = p.medication ?? '';
    _historyCtrl.text = p.medicalHistory ?? '';
    _emergencyCtrl.text = p.emergencyContact ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _mobileCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _causeCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationCtrl.dispose();
    _historyCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _addBookingForPatient(BuildContext context, Patient patient, DateTime? initialDate) async {
    final result = await showAddBookingDialog(
      context,
      patients: [],
      preselectedPatientId: patient.patientId,
      initialDate: initialDate,
    );
    if (result != null) {
      final (patientId, date, notes) = result;
      ref.read(dataProvider.notifier).addBooking(patientId, date, notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = ref.watch(dataProvider);
    final patient = appData.patients.where((p) => p.patientId == widget.patientId).firstOrNull;

    if (patient == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Patient not found.', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.go('/patients'), child: const Text('Back to Patients')),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayBookings = appData.bookings.where((b) {
      final d = DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
      return b.patientId == widget.patientId && d == today;
    }).toList()..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    final futureBookings = appData.bookings.where((b) {
      final d = DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
      return b.patientId == widget.patientId && d.isAfter(today);
    }).toList()..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    final pastBookings = appData.bookings.where((b) {
      final d = DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
      return b.patientId == widget.patientId && d.isBefore(today);
    }).toList()..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => context.go('/patients'), icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Text(
                patient.fullName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildProfileSection(context, patient),
          const SizedBox(height: 16),

          _buildHealthSection(context, patient),
          const SizedBox(height: 16),

          if (todayBookings.isNotEmpty) ...[
            _SectionCard(
              title: "Today's Appointments (${todayBookings.length})",
              icon: Icons.today,
              accentColor: Colors.orange,
              trailing: _AddButton(onPressed: () => _addBookingForPatient(context, patient, today)),
              children: todayBookings.map((b) => BookingTile(
                booking: b,
                onNotesChanged: (notes) => ref.read(dataProvider.notifier).updateBookingNotes(b.bookingId, notes),
                onDelete: () => ref.read(dataProvider.notifier).removeBooking(b.bookingId),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          _SectionCard(
            title: 'Upcoming Appointments (${futureBookings.length})',
            icon: Icons.upcoming,
            accentColor: const Color(0xFF1565C0),
            trailing: _AddButton(onPressed: () => _addBookingForPatient(context, patient, null)),
            children: futureBookings.isEmpty
                ? [const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No upcoming appointments.', style: TextStyle(color: Colors.grey)))]
                : futureBookings.map((b) => BookingTile(
                  booking: b,
                  onNotesChanged: (notes) => ref.read(dataProvider.notifier).updateBookingNotes(b.bookingId, notes),
                  onDelete: () => ref.read(dataProvider.notifier).removeBooking(b.bookingId),
                )).toList(),
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'Past Appointments (${pastBookings.length})',
            icon: Icons.history,
            accentColor: Colors.grey,
            children: pastBookings.isEmpty
                ? [const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No past appointments.', style: TextStyle(color: Colors.grey)))]
                : pastBookings.map((b) => BookingTile(
                  booking: b,
                  onNotesChanged: (notes) => ref.read(dataProvider.notifier).updateBookingNotes(b.bookingId, notes),
                  onDelete: () => ref.read(dataProvider.notifier).removeBooking(b.bookingId),
                )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, Patient patient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                const Text('Patient Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                const Spacer(),
                if (!_editingProfile)
                  OutlinedButton.icon(
                    onPressed: () {
                      _initControllers(patient);
                      setState(() => _editingProfile = true);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  )
                else ...[
                  TextButton(onPressed: () => setState(() => _editingProfile = false), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      final updated = patient.copyWith(
                        name: _nameCtrl.text.trim(),
                        surname: _surnameCtrl.text.trim(),
                        mobile: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                      );
                      ref.read(dataProvider.notifier).updatePatient(updated);
                      setState(() => _editingProfile = false);
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Save'),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            _InfoRow('AMKA', patient.patientId),
            if (!_editingProfile) ...[
              _InfoRow('First Name', patient.name),
              _InfoRow('Last Name', patient.surname),
              if (patient.mobile != null) _InfoRow('Mobile', patient.mobile!),
              if (patient.phone != null) _InfoRow('Phone', patient.phone!),
              if (patient.email != null) _InfoRow('Email', patient.email!),
            ] else ...[
              _EditRow('First Name', _nameCtrl),
              _EditRow('Last Name', _surnameCtrl),
              _EditRow('Mobile', _mobileCtrl),
              _EditRow('Phone', _phoneCtrl),
              _EditRow('Email', _emailCtrl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSection(BuildContext context, Patient patient) {
    final hasAny = patient.healthInformation != null || patient.allergies != null ||
        patient.medication != null || patient.medicalHistory != null || patient.emergencyContact != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                const Text('Health Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                const Spacer(),
                if (!_editingHealth)
                  OutlinedButton.icon(
                    onPressed: () {
                      _initControllers(patient);
                      setState(() => _editingHealth = true);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  )
                else ...[
                  TextButton(onPressed: () => setState(() => _editingHealth = false), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      final updated = patient.copyWith(
                        healthInformation: _causeCtrl.text.trim().isEmpty ? null : _causeCtrl.text.trim(),
                        allergies: _allergiesCtrl.text.trim().isEmpty ? null : _allergiesCtrl.text.trim(),
                        medication: _medicationCtrl.text.trim().isEmpty ? null : _medicationCtrl.text.trim(),
                        medicalHistory: _historyCtrl.text.trim().isEmpty ? null : _historyCtrl.text.trim(),
                        emergencyContact: _emergencyCtrl.text.trim().isEmpty ? null : _emergencyCtrl.text.trim(),
                      );
                      ref.read(dataProvider.notifier).updatePatient(updated);
                      setState(() => _editingHealth = false);
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Save'),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            if (!_editingHealth) ...[
              if (!hasAny)
                const Text('No health information available.', style: TextStyle(color: Colors.grey))
              else ...[
                if (patient.healthInformation != null) _InfoRow('Cause / Diagnosis', patient.healthInformation!),
                if (patient.allergies != null) _InfoRow('Allergies', patient.allergies!),
                if (patient.medication != null) _InfoRow('Medication', patient.medication!),
                if (patient.medicalHistory != null) _InfoRow('Medical History', patient.medicalHistory!),
                if (patient.emergencyContact != null) _InfoRow('Emergency Contact', patient.emergencyContact!),
              ],
            ] else ...[
              _EditRow('Cause / Diagnosis', _causeCtrl, maxLines: 2),
              _EditRow('Allergies', _allergiesCtrl),
              _EditRow('Medication', _medicationCtrl),
              _EditRow('Medical History', _historyCtrl, maxLines: 2),
              _EditRow('Emergency Contact', _emergencyCtrl),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? accentColor;
  final List<Widget> children;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.icon, this.accentColor, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? const Color(0xFF1565C0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              if (trailing != null) ...[const Spacer(), trailing!],
            ]),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  const _EditRow(this.label, this.controller, {this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.add, size: 15),
      label: const Text('Add', style: TextStyle(fontSize: 13)),
    );
  }
}
