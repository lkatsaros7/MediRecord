import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';

class BookingTile extends StatefulWidget {
  final Booking booking;
  final Function(String notes) onNotesChanged;
  final VoidCallback? onDelete;

  const BookingTile({
    super.key,
    required this.booking,
    required this.onNotesChanged,
    this.onDelete,
  });

  @override
  State<BookingTile> createState() => _BookingTileState();
}

class _BookingTileState extends State<BookingTile> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.booking.notes ?? '');
  }

  @override
  void didUpdateWidget(BookingTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing &&
        oldWidget.booking.notes != widget.booking.notes) {
      _controller.text = widget.booking.notes ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete!();
  }

  /// Returns (label, color) for the relative date badge.
  (String, Color) _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;

    if (diff == 0) return ('Today', Colors.orange);
    if (diff == 1) return ('Tomorrow', Colors.blue.shade700);
    if (diff == -1) return ('Yesterday', Colors.grey.shade600);
    if (diff > 0) return ('in $diff days', Colors.blue.shade700);
    return ('${(-diff)} days ago', Colors.grey.shade600);
  }

  Color _accentColor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return Colors.orange;
    if (diff > 0) return const Color(0xFF1565C0);
    return Colors.grey.shade400;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Scheduled':  return Colors.blue;
      case 'Completed':  return Colors.green;
      case 'Cancelled':  return Colors.red;
      case 'No-show':    return Colors.orange;
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.booking.bookingDate;
    final accentColor = _accentColor(date);
    final (relLabel, relColor) = _relativeDate(date);
    final hasNotes = widget.booking.notes?.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Date row ──────────────────────────────────────────
                    Row(
                      children: [
                        Icon(Icons.calendar_month,
                            size: 17, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        if (widget.booking.bookingTime != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            widget.booking.bookingTime!,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                        const Spacer(),
                        // Relative date badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: relColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            relLabel,
                            style: TextStyle(
                              color: relColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Optional status chip
                        if (widget.booking.bookingStatus != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(widget.booking.bookingStatus)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _statusColor(
                                      widget.booking.bookingStatus)),
                            ),
                            child: Text(
                              widget.booking.bookingStatus!,
                              style: TextStyle(
                                color: _statusColor(
                                    widget.booking.bookingStatus),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        // Optional type chip
                        if (widget.booking.bookingType != null) ...[
                          const SizedBox(width: 6),
                          Chip(
                            label: Text(
                              widget.booking.bookingType!,
                              style: const TextStyle(fontSize: 11),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 10),
                    // ── Notes row ─────────────────────────────────────────
                    if (!_editing) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            hasNotes ? Icons.notes : Icons.notes_outlined,
                            size: 16,
                            color: hasNotes
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hasNotes
                                  ? widget.booking.notes!
                                  : 'No notes — tap Edit to add.',
                              style: TextStyle(
                                fontSize: 13,
                                color: hasNotes
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade400,
                                fontStyle: hasNotes
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() {
                              _controller.text =
                                  widget.booking.notes ?? '';
                              _editing = true;
                            }),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 14, color: accentColor),
                                  const SizedBox(width: 4),
                                  Text('Edit',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: accentColor,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          if (widget.onDelete != null) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _confirmDelete(context),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 14, color: Colors.red.shade400),
                                    const SizedBox(width: 4),
                                    Text('Delete',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade400,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      TextField(
                        controller: _controller,
                        maxLines: 3,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Enter notes for this appointment…',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _editing = false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              widget.onNotesChanged(_controller.text);
                              setState(() => _editing = false);
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
