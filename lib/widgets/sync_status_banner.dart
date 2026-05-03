import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class SyncStatusBanner extends StatefulWidget {
  final Widget child;

  const SyncStatusBanner({super.key, required this.child});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: ConnectivityService.instance.syncStatusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        final isOnline = ConnectivityService.instance.isOnline;
        final pendingCount = ConnectivityService.instance.pendingSyncCount;

        return Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                color: Colors.red.shade100,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Offline \u2014 changes will sync when reconnected',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                    if (pendingCount > 0) ...[
                      const Spacer(),
                      Text(
                        '$pendingCount pending',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              )
            else if (status == SyncStatus.syncing)
              Container(
                width: double.infinity,
                color: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Syncing changes...',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ],
                ),
              )
            else if (status == SyncStatus.completed && pendingCount == 0)
              Container(
                width: double.infinity,
                color: Colors.green.shade50,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'All changes synced',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }
}
