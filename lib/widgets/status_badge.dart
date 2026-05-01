import 'package:flutter/material.dart';
import '../models/data_state.dart';

class StatusBadge extends StatelessWidget {
  final DataSourceStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (status) {
      case DataSourceStatus.connected:
        color = Colors.green;
        label = 'Connected';
        icon = Icons.check_circle;
        break;
      case DataSourceStatus.missing:
        color = Colors.red;
        label = 'Missing';
        icon = Icons.error;
        break;
      case DataSourceStatus.invalid:
        color = Colors.amber;
        label = 'Invalid';
        icon = Icons.warning;
        break;
      case DataSourceStatus.loading:
        color = Colors.blue;
        label = 'Loading';
        icon = Icons.refresh;
        break;
      case DataSourceStatus.noFileSelected:
        color = Colors.grey;
        label = 'No File';
        icon = Icons.folder_off;
        break;
    }

    if (compact) {
      return Tooltip(
        message: label,
        child: Icon(icon, color: color, size: 16),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
