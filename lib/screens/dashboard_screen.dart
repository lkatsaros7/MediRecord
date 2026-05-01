import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/data_state.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appData = ref.watch(dataProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    final todayBookings = appData.bookings.where((b) {
      final d = DateTime(
          b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
      return d == today;
    }).toList();

    final upcomingBookings = appData.bookings.where((b) {
      final d = DateTime(
          b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
      return d.isAfter(today) && !d.isAfter(nextWeek);
    }).toList()
      ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    final Color statusCardColor;
    switch (appData.status) {
      case DataSourceStatus.connected:
        statusCardColor = Colors.green.shade50;
        break;
      case DataSourceStatus.invalid:
        statusCardColor = Colors.amber.shade50;
        break;
      case DataSourceStatus.missing:
        statusCardColor = Colors.red.shade50;
        break;
      case DataSourceStatus.loading:
        statusCardColor = Colors.blue.shade50;
        break;
      case DataSourceStatus.noFileSelected:
        statusCardColor = Colors.grey.shade50;
        break;
    }

    final allUpcomingAndToday = [...todayBookings, ...upcomingBookings];

    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Status card
            Card(
              color: statusCardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    StatusBadge(status: appData.status),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appData.fileName ?? 'No file loaded',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          if (appData.errorMessage != null)
                            Text(
                              appData.errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Load File'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (appData.status == DataSourceStatus.noFileSelected)
              const Expanded(
                child: EmptyState(
                  message:
                      'No data source selected. Please select a CSV or XLSX file.',
                  icon: Icons.upload_file,
                ),
              )
            else ...[
              // Summary cards
              Row(
                children: [
                  _SummaryCard(
                    label: 'Total Patients',
                    value: '${appData.patients.length}',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    label: 'Total Bookings',
                    value: '${appData.bookings.length}',
                    icon: Icons.calendar_month,
                    color: Colors.purple,
                  ),
                  _SummaryCard(
                    label: 'Upcoming (7 days)',
                    value: '${upcomingBookings.length}',
                    icon: Icons.upcoming,
                    color: Colors.green,
                  ),
                  _SummaryCard(
                    label: "Today's Bookings",
                    value: '${todayBookings.length}',
                    icon: Icons.today,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "Today's & Upcoming Bookings",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: allUpcomingAndToday.isEmpty
                    ? const EmptyState(
                        message:
                            'No bookings for today or the next 7 days.',
                        icon: Icons.event_available,
                      )
                    : ListView.builder(
                        itemCount: allUpcomingAndToday.length,
                        itemBuilder: (context, index) {
                          final booking = allUpcomingAndToday[index];
                          final patient = appData.patients
                              .where((p) =>
                                  p.patientId == booking.patientId)
                              .firstOrNull;
                          final dateStr = DateFormat('MMM dd, yyyy')
                              .format(booking.bookingDate);
                          final isToday = DateTime(
                                booking.bookingDate.year,
                                booking.bookingDate.month,
                                booking.bookingDate.day,
                              ) ==
                              today;

                          return Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_today,
                                color: isToday
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                              title: Text(patient?.fullName ??
                                  'Unknown Patient'),
                              subtitle: Text(
                                '$dateStr${booking.bookingTime != null ? ' at ${booking.bookingTime}' : ''}'
                                '${booking.bookingType != null ? ' · ${booking.bookingType}' : ''}',
                              ),
                              trailing: isToday
                                  ? const Chip(
                                      label: Text('Today'),
                                      backgroundColor:
                                          Color(0xFFFFE0B2),
                                    )
                                  : null,
                              onTap: () => context.go(
                                  '/patients/${booking.patientId}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
