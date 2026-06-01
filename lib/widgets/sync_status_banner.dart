import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class SyncStatusBanner extends StatefulWidget {
  final Widget child;

  const SyncStatusBanner({super.key, required this.child});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  bool _showSynced = false;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onSyncCompleted() {
    if (!mounted) return;
    setState(() => _showSynced = true);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSynced = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: ConnectivityService.instance.syncStatusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        final isOnline = ConnectivityService.instance.isOnline;
        final pendingCount = ConnectivityService.instance.pendingSyncCount;

        if (status == SyncStatus.completed && pendingCount == 0 && !_showSynced) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _onSyncCompleted());
        }
        if (status != SyncStatus.completed) {
          _showSynced = false;
        }

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
                      'Offline \u2014 perubahan akan disinkron saat terhubung',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                    if (pendingCount > 0) ...[
                      const Spacer(),
                      Text(
                        '$pendingCount tertunda',
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
                      'Menyinkronkan...',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ],
                ),
              )
            else if (_showSynced)
              Container(
                width: double.infinity,
                color: Colors.green.shade50,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Semua perubahan tersinkron',
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
