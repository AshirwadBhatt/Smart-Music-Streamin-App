import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/network_monitor.dart';
import 'segment_downloader.dart';

class BufferState {
  final List<AudioSegment> segments;
  final int  bufferedSeconds;
  final int  targetSeconds;
  final bool isBuffering;

  const BufferState({
    required this.segments,
    required this.bufferedSeconds,
    required this.targetSeconds,
    required this.isBuffering,
  });

  BufferState copyWith({List<AudioSegment>? segments, int? bufferedSeconds,
      int? targetSeconds, bool? isBuffering}) => BufferState(
    segments:        segments        ?? this.segments,
    bufferedSeconds: bufferedSeconds ?? this.bufferedSeconds,
    targetSeconds:   targetSeconds   ?? this.targetSeconds,
    isBuffering:     isBuffering     ?? this.isBuffering,
  );
}

class BufferManager extends StateNotifier<BufferState> {
  final NetworkMonitor     _networkMonitor;
  SegmentDownloader?       _downloader;
  Timer?                   _bufferTimer;
  int                      _playheadSecond = 0;

  BufferManager(this._networkMonitor)
      : super(const BufferState(
          segments: [], bufferedSeconds: 0,
          targetSeconds: ApiConstants.minBufferSeconds, isBuffering: false));

  void startBuffering(SegmentDownloader downloader) {
    _downloader = downloader;
    _bufferTimer?.cancel();
    // Poll every 2 seconds to maintain buffer
    _bufferTimer = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
    _tick();
  }

  void updatePlayhead(int second) {
    _playheadSecond = second;
  }

  Future<void> _tick() async {
    final d = _downloader;
    if (d == null) return;

    await d.ensureBuffer(_playheadSecond);

    state = state.copyWith(
      segments:        List.from(d.segments),
      bufferedSeconds: d.bufferedSeconds(_playheadSecond),
      targetSeconds:   _networkMonitor.targetBufferSeconds,
      isBuffering:     state.bufferedSeconds < ApiConstants.minBufferSeconds,
    );
  }

  void stop() {
    _bufferTimer?.cancel();
    _downloader?.clearCache();
    _downloader = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

final bufferManagerProvider =
    StateNotifierProvider<BufferManager, BufferState>((ref) {
  return BufferManager(ref.watch(networkMonitorProvider));
});
