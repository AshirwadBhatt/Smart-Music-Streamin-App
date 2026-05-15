import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

enum NetworkSpeed { fast, slow, unknown }

class NetworkMonitor {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.online;
  NetworkSpeed _currentSpeed   = NetworkSpeed.unknown;
  double _estimatedKbps        = 0;

  NetworkStatus get status => _currentStatus;
  NetworkSpeed  get speed  => _currentSpeed;
  double        get kbps   => _estimatedKbps;
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  void init() {
    _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      _currentStatus = isOnline ? NetworkStatus.online : NetworkStatus.offline;
      _statusController.add(_currentStatus);
    });
  }

  /// Call this with bytes downloaded and duration to update speed estimate.
  void recordTransfer(int bytes, Duration duration) {
    if (duration.inMilliseconds == 0) return;
    _estimatedKbps = (bytes * 8) / duration.inMilliseconds; // kbps
    _currentSpeed  = _estimatedKbps >= 500
        ? NetworkSpeed.fast
        : NetworkSpeed.slow;
  }

  /// Returns target buffer in seconds based on current speed.
  int get targetBufferSeconds {
    switch (_currentSpeed) {
      case NetworkSpeed.fast:    return 40;
      case NetworkSpeed.slow:    return 20;
      case NetworkSpeed.unknown: return 30;
    }
  }

  String get statusLabel {
    if (_currentStatus == NetworkStatus.offline) return 'Offline';
    switch (_currentSpeed) {
      case NetworkSpeed.fast:    return 'Good';
      case NetworkSpeed.slow:    return 'Slow';
      case NetworkSpeed.unknown: return 'Checking…';
    }
  }

  void dispose() => _statusController.close();
}

final networkMonitorProvider = Provider<NetworkMonitor>((ref) {
  final monitor = NetworkMonitor()..init();
  ref.onDispose(monitor.dispose);
  return monitor;
});
