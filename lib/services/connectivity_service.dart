import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/env.dart';
import 'cache_service.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  // Short, isolated client for the reachability probe. A live network interface
  // (wifi/mobile) does NOT mean the internet works — captive portals, weak
  // signal, and metered/throttled links all report "connected" while requests
  // time out. We probe /health to confirm the backend is actually reachable.
  final Dio _probeDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Recovery probe: the connectivity listener only fires on interface change,
  // so a link that silently degrades mid-session (interface stays "wifi" the
  // whole time) never flips us offline on its own. When a live request times
  // out we get told via reportUnreachable(), then poll /health until the
  // backend answers again and recover online state.
  Timer? _recoveryTimer;
  Timer? _connectivityPollTimer;

  Future<bool> _isReachable() async {
    try {
      // Probe under the API prefix, not the server root: the backend serves
      // /health at both / and /api/v1/, but a reverse proxy that only forwards
      // /api/* would 404 the root path — and a non-200 probe flips the app
      // into permanent offline mode (stale cache served, never recovers).
      final res = await _probeDio.get('${Env.apiBaseUrl}/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static bool get _connectivityAvailable => !(isLinuxDesktop);

  static bool get isLinuxDesktop => !kIsWeb && Platform.isLinux;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  int _pendingSyncCount = 0;
  int get pendingSyncCount => _pendingSyncCount;

  Future<void> initialize() async {
    await _updatePendingCount();

    if (!_connectivityAvailable) {
      _isOnline = await _isReachable();
      _startConnectivityPoll();
      return;
    }

    final result = await _connectivity.checkConnectivity();
    _isOnline =
        result != ConnectivityResult.none && await _isReachable();

    _subscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      _isOnline =
          result != ConnectivityResult.none && await _isReachable();

      if (!wasOnline && _isOnline) {
        await _syncOnReconnect();
      }
    });
  }

  // Called by the API client when a request fails with a timeout/connection
  // error. Flips us offline immediately so the cache layer serves stale data
  // instead of every subsequent request burning the full timeout, then starts
  // polling for recovery.
  void reportUnreachable() {
    if (!_isOnline) return;
    _isOnline = false;
    _startRecoveryProbe();
  }

  void _startRecoveryProbe() {
    if (_recoveryTimer != null) return;
    _recoveryTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (await _isReachable()) {
        _recoveryTimer?.cancel();
        _recoveryTimer = null;
        final wasOnline = _isOnline;
        _isOnline = true;
        if (!wasOnline) await _syncOnReconnect();
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

  void _startConnectivityPoll() {
    _connectivityPollTimer?.cancel();
    _connectivityPollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final wasOnline = _isOnline;
      _isOnline = await _isReachable();
      if (!wasOnline && _isOnline) {
        await _syncOnReconnect();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _recoveryTimer?.cancel();
    _connectivityPollTimer?.cancel();
    _syncStatusController.close();
  }
}

enum SyncStatus { idle, syncing, completed, failed }
