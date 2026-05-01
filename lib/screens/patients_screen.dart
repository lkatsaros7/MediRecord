import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';
import '../models/data_state.dart';
import '../widgets/patient_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/add_patient_dialog.dart';

enum PatientFilter { all, hasUpcoming, hasPastOnly }

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _searchController = TextEditingController();
  PatientFilter _filter = PatientFilter.all;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            message,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveData() {
    final appData = ref.read(dataProvider);
    if (appData.driveFileId != null) {
      // Drive file — save back silently
      ref.read(dataProvider.notifier).saveToDrive().then((error) {
        if (!mounted) return;
        if (error != null) {
          _showErrorDialog('Drive Save Failed', error);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to Google Drive.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } else {
      final error = ref.read(dataProvider.notifier).saveAndDownload();
      if (!mounted) return;
      if (error != null) {
        _showErrorDialog('Save Failed', error);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _addPatient() async {
    final patient = await showAddPatientDialog(context);
    if (patient == null || !mounted) return;
    try {
      ref.read(dataProvider.notifier).addPatient(patient);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Patient "${patient.name} ${patient.surname}" added. Save the file to persist changes.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        'Could Not Add Patient',
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = ref.watch(dataProvider);
    final now = DateTime.now();

    if (appData.status == DataSourceStatus.noFileSelected) {
      return const EmptyState(
        message:
            'No data source selected. Please select a CSV or XLSX file.',
        icon: Icons.upload_file,
      );
    }

    final patients = appData.patients.where((p) {
      if (_search.isNotEmpty) {
        final name = '${p.name} ${p.surname}'.toLowerCase();
        if (!name.contains(_search)) return false;
      }
      if (_filter == PatientFilter.hasUpcoming) {
        return appData.bookings.any(
          (b) =>
              b.patientId == p.patientId && b.bookingDate.isAfter(now),
        );
      }
      if (_filter == PatientFilter.hasPastOnly) {
        final hasUpcoming = appData.bookings.any(
          (b) =>
              b.patientId == p.patientId && b.bookingDate.isAfter(now),
        );
        return !hasUpcoming &&
            appData.bookings.any(
              (b) =>
                  b.patientId == p.patientId &&
                  b.bookingDate.isBefore(now),
            );
      }
      return true;
    }).toList()
      ..sort((a, b) => a.surname.compareTo(b.surname));

    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Patients',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (appData.status == DataSourceStatus.connected) ...[
                  if (appData.isDirty) ...[
                    FilledButton.icon(
                      onPressed: _saveData,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _addPatient,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Patient'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or surname...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == PatientFilter.all,
                  onSelected: (_) =>
                      setState(() => _filter = PatientFilter.all),
                ),
                FilterChip(
                  label: const Text('Has Upcoming Bookings'),
                  selected: _filter == PatientFilter.hasUpcoming,
                  onSelected: (_) => setState(
                      () => _filter = PatientFilter.hasUpcoming),
                ),
                FilterChip(
                  label: const Text('Has Past Bookings Only'),
                  selected: _filter == PatientFilter.hasPastOnly,
                  onSelected: (_) => setState(
                      () => _filter = PatientFilter.hasPastOnly),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${patients.length} patient${patients.length == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: patients.isEmpty
                  ? EmptyState(
                      message: _search.isNotEmpty
                          ? 'No patients match your search.'
                          : appData.patients.isEmpty
                              ? 'No patients found in the selected file.'
                              : 'No patients match the selected filter.',
                      icon: Icons.people,
                    )
                  : ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        final bookings = appData.bookings
                            .where((b) =>
                                b.patientId == patient.patientId)
                            .toList();
                        return PatientCard(
                            patient: patient, bookings: bookings);
                      },
                    ),
            ),
          ],
        ),
    );
  }
}
