import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isSynced = status == 'Synced';
    return Chip(
      avatar: Icon(
        isSynced ? Icons.cloud_done : Icons.cloud_off,
        size: 18,
        color: isSynced ? Colors.green.shade800 : Colors.orange.shade900,
      ),
      label: Text(isSynced ? 'Sinkroniza / Online' : 'Lokal / Offline'),
      backgroundColor: isSynced ? Colors.green.shade50 : Colors.orange.shade50,
    );
  }
}
