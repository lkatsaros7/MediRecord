import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/patient.dart';
import '../models/booking.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final List<Booking> bookings;

  const PatientCard({
    super.key,
    required this.patient,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcomingCount =
        bookings.where((b) => b.bookingDate.isAfter(now)).length;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          child: Text(patient.name[0].toUpperCase()),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (patient.mobile != null) Text(patient.mobile!),
            if (patient.phone != null && patient.mobile == null) Text(patient.phone!),
            if (patient.email != null)
              Text(patient.email!,
                  style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: upcomingCount > 0
            ? Chip(
                label: Text('$upcomingCount upcoming'),
                backgroundColor: Colors.green.shade100,
                labelStyle: TextStyle(
                    color: Colors.green.shade800, fontSize: 11),
              )
            : null,
        onTap: () => context.go('/patients/${patient.patientId}'),
        isThreeLine:
            (patient.mobile != null || patient.phone != null) && patient.email != null,
      ),
    );
  }
}
