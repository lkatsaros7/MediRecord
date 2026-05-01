import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';
import '../models/data_state.dart';
import '../widgets/status_badge.dart';

void _showErrorDialog(BuildContext context, String title, String message) {
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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appData = ref.watch(dataProvider);
    final dataNotifier = ref.read(dataProvider.notifier);

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Data Source Section
            _SettingsCard(
              title: 'Data Source',
              icon: Icons.storage,
              children: [
                Row(
                  children: [
                    const Text('Status: '),
                    const SizedBox(width: 8),
                    StatusBadge(status: appData.status),
                  ],
                ),
                const SizedBox(height: 8),
                if (appData.fileName != null) ...[
                  Text(
                    'File: ${appData.fileName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${appData.patients.length} patients, ${appData.bookings.length} bookings loaded',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ] else
                  const Text('No file loaded.',
                      style: TextStyle(color: Colors.grey)),
                if (appData.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    appData.errorMessage!,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                // ── Local file actions ───────────────────────────────────────
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await dataNotifier.pickAndLoadFile();
                        if (context.mounted) {
                          final newData = ref.read(dataProvider);
                          if (newData.status ==
                              DataSourceStatus.connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'File loaded: ${newData.fileName}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (newData.status ==
                              DataSourceStatus.invalid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error: ${newData.errorMessage}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Open Local File'),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          appData.status == DataSourceStatus.connected
                              ? () async {
                                  await dataNotifier.pickAndLoadFile();
                                }
                              : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload File'),
                    ),
                    ElevatedButton.icon(
                      onPressed: appData.status ==
                                      DataSourceStatus.connected &&
                                  appData.isDirty &&
                                  appData.driveFileId == null
                          ? () {
                              final error =
                                  dataNotifier.saveAndDownload();
                              if (!context.mounted) return;
                              if (error != null) {
                                _showErrorDialog(
                                    context, 'Save Failed', error);
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'File saved and downloaded.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.download),
                      label: const Text('Save & Download'),
                    ),
                    OutlinedButton.icon(
                      onPressed: appData.status !=
                              DataSourceStatus.noFileSelected
                          ? () {
                              dataNotifier.clearData();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                    content: Text('Data cleared.')),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.clear,
                          color: Colors.red),
                      label: const Text('Clear Data',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Google Drive Section ──────────────────────────────────────────────────
            _SettingsCard(
              title: 'Google Drive',
              icon: Icons.cloud,
              children: [
                if (appData.driveFileId != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.link, size: 16,
                          color: Colors.green),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Linked: ${appData.fileName ?? appData.driveFileId}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Changes are saved directly back to Drive.',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ] else
                  Text(
                    'No Drive file linked. Open a file from Google Drive to enable direct saving.',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        final error =
                            await dataNotifier.openFromDrive();
                        if (!context.mounted) return;
                        if (error != null) {
                          _showErrorDialog(context,
                              'Could Not Open from Drive', error);
                        } else if (ref
                                .read(dataProvider)
                                .status ==
                            DataSourceStatus.connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Loaded from Drive: ${ref.read(dataProvider).fileName}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('Open from Google Drive'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                      ),
                    ),
                    if (appData.driveFileId != null)
                      FilledButton.icon(
                        onPressed: appData.isDirty
                            ? () async {
                                final error =
                                    await dataNotifier.saveToDrive();
                                if (!context.mounted) return;
                                if (error != null) {
                                  _showErrorDialog(context,
                                      'Drive Save Failed', error);
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Saved to Google Drive.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.cloud_upload, size: 18),
                        label: const Text('Save to Drive'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Credentials section
            const _SettingsCard(
              title: 'Credentials',
              icon: Icons.lock,
              children: [
                Text('Current login credentials:'),
                SizedBox(height: 8),
                Text('Username: admin',
                    style: TextStyle(fontFamily: 'monospace')),
                Text('Password: admin123',
                    style: TextStyle(fontFamily: 'monospace')),
              ],
            ),
            const SizedBox(height: 24),

            // Status legend
            const _SettingsCard(
              title: 'Status Legend',
              icon: Icons.info_outline,
              children: [
                _LegendRow(Icons.check_circle, Colors.green,
                    'Connected',
                    'File loaded successfully with valid data.'),
                _LegendRow(Icons.error, Colors.red, 'Missing',
                    'Required data or columns are missing.'),
                _LegendRow(Icons.warning, Colors.amber, 'Invalid',
                    'File format is invalid or cannot be parsed.'),
                _LegendRow(Icons.refresh, Colors.blue, 'Loading',
                    'File is being loaded and parsed.'),
                _LegendRow(Icons.folder_off, Colors.grey,
                    'No File Selected',
                    'No data source has been selected.'),
              ],
            ),
          ],
        ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String status;
  final String description;

  const _LegendRow(this.icon, this.color, this.status, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(status,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(description,
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
