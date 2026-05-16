import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'cache_service.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  static bool get _connectivityAvailable => !(isLinuxDesktop);

  static bool get isLinuxDesktop => !kIsWeb && Platform.isLinux;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  int _pendingSyncCount = 0;
  int get pendingSyncCount => _pendingSyncCount;

  Future<void> initialize() async {
    if (!_connectivityAvailable) {
      await _updatePendingCount();
      return;
    }

    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    await _updatePendingCount();

    _subscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        await _syncOnReconnect();
      }
    });
  }

  Future<void> _syncOnReconnect() async {
    _syncStatusController.add(SyncStatus.syncing);
    try {
      await CacheService.processSyncQueue();
      await _updatePendingCount();
      _syncStatusController.add(SyncStatus.completed);
    } catch (e) {
      _syncStatusController.add(SyncStatus.failed);
    }
  }

  Future<void> _updatePendingCount() async {
    _pendingSyncCount = await CacheService.getPendingSyncCount();
  }

  Future<void> triggerManualSync() async {
    if (_isOnline) {
      await _syncOnReconnect();
    }
  }

  void dispose() {
    _subscription?.cancel();
    _syncStatusController.close();
  }
}

enum SyncStatus { idle, syncing, completed, failed }
