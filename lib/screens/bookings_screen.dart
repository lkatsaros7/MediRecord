import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/data_provider.dart';
import '../models/booking.dart';
import '../models/data_state.dart';
import '../widgets/booking_tile.dart';
import '../widgets/add_booking_dialog.dart';
import '../widgets/empty_state.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Booking>> _buildEventMap(List<Booking> bookings) {
    final map = <DateTime, List<Booking>>{};
    for (final b in bookings) {
      final key = DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
      map.putIfAbsent(key, () => []).add(b);
    }
    return map;
  }

  List<Booking> _getEventsForDay(DateTime day, Map<DateTime, List<Booking>> eventMap) {
    final key = DateTime(day.year, day.month, day.day);
    return eventMap[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final appData = ref.watch(dataProvider);

    if (appData.status == DataSourceStatus.noFileSelected) {
      return const EmptyState(
        message: 'No data source selected. Please select a CSV or XLSX file.',
        icon: Icons.upload_file,
      );
    }

    final eventMap = _buildEventMap(appData.bookings);

    if (_selectedDay == null) {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (eventMap.containsKey(today)) {
        _selectedDay = today;
      } else {
        final upcoming = eventMap.keys
            .where((d) => d.isAfter(today) || d == today)
            .toList()..sort();
        if (upcoming.isNotEmpty) {
          _selectedDay = upcoming.first;
          _focusedDay = upcoming.first;
        } else {
          _selectedDay = today;
        }
      }
    }

    final selectedEvents = _selectedDay != null
        ? _getEventsForDay(_selectedDay!, eventMap)
        : <Booking>[];

    final totalBookings = appData.bookings.length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingCount = appData.bookings
        .where((b) => !DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day).isBefore(today))
        .length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Appointments',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _StatChip(label: 'Total', value: totalBookings, color: Colors.blue),
              const SizedBox(width: 8),
              _StatChip(label: 'Upcoming', value: upcomingCount, color: Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 420,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TableCalendar<Booking>(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2035),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) => _getEventsForDay(day, eventMap),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.orange.shade300,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF1565C0),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFF1565C0),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      markerSize: 6,
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                      leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF1565C0)),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF1565C0)),
                      headerPadding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      weekendStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDay != null
                                  ? DateFormat('EEEE, d MMMM yyyy').format(_selectedDay!)
                                  : 'Select a day',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            if (selectedEvents.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${selectedEvents.length} appointment${selectedEvents.length == 1 ? '' : 's'}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1565C0),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                final result = await showAddBookingDialog(
                                  context,
                                  patients: appData.patients,
                                  initialDate: _selectedDay,
                                );
                                if (result != null) {
                                  final (patientId, date, notes) = result;
                                  ref.read(dataProvider.notifier).addBooking(patientId, date, notes);
                                  setState(() {
                                    _selectedDay = DateTime(date.year, date.month, date.day);
                                    _focusedDay = _selectedDay!;
                                  });
                                }
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: selectedEvents.isEmpty
                            ? const EmptyState(
                                message: 'No appointments on this day.',
                                icon: Icons.event_available,
                              )
                            : ListView.builder(
                                itemCount: selectedEvents.length,
                                itemBuilder: (context, index) {
                                  final booking = selectedEvents[index];
                                  final patient = appData.patients
                                      .where((p) => p.patientId == booking.patientId)
                                      .firstOrNull;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () => context.go('/patients/${booking.patientId}'),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: const Color(0xFF1565C0),
                                                foregroundColor: Colors.white,
                                                child: Text(
                                                  (patient?.name ?? '?')[0].toUpperCase(),
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                patient?.fullName ?? 'Unknown Patient (${booking.patientId})',
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                                            ],
                                          ),
                                        ),
                                      ),
                                      BookingTile(
                                        booking: booking,
                                        onNotesChanged: (notes) =>
                                            ref.read(dataProvider.notifier).updateBookingNotes(booking.bookingId, notes),
                                        onDelete: () =>
                                            ref.read(dataProvider.notifier).removeBooking(booking.bookingId),
                                      ),
                                      if (index < selectedEvents.length - 1)
                                        const SizedBox(height: 8),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
