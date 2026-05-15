import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/network_monitor.dart';

enum SegmentStatus { waiting, downloading, downloaded, failed }

class AudioSegment {
  final int index;
  final int startSecond;
  final int endSecond;
  SegmentStatus status;
  Uint8List? bytes;
  String? filePath;
  int byteSize;

  AudioSegment({
    required this.index,
    required this.startSecond,
    required this.endSecond,
    this.status = SegmentStatus.waiting,
    this.bytes,
    this.filePath,
    this.byteSize = 0,
  });
}

class SegmentDownloader {
  final Dio _dio;
  final NetworkMonitor _networkMonitor;
  final String _audioUrl;
  final int _totalSeconds;

  final List<AudioSegment> segments = [];
  int _currentlyDownloading = 0;

  SegmentDownloader({
    required Dio dio,
    required NetworkMonitor networkMonitor,
    required String audioUrl,
    required int totalSeconds,
  })  : _dio = dio,
        _networkMonitor = networkMonitor,
        _audioUrl = audioUrl,
        _totalSeconds = totalSeconds {
    _buildSegmentList();
  }

  void _buildSegmentList() {
    segments.clear();
    int i = 0;
    for (int start = 0; start < _totalSeconds;
        start += ApiConstants.segmentDurationSeconds) {
      final end =
          (start + ApiConstants.segmentDurationSeconds).clamp(0, _totalSeconds);
      segments.add(AudioSegment(index: i++, startSecond: start, endSecond: end));
    }
  }

  int bufferedSeconds(int playheadSecond) {
    int buffered = 0;
    for (final seg in segments) {
      if (seg.startSecond >= playheadSecond &&
          seg.status == SegmentStatus.downloaded) {
        buffered += (seg.endSecond - seg.startSecond);
      }
    }
    return buffered;
  }

  Future<void> ensureBuffer(int playheadSecond) async {
    final target = _networkMonitor.targetBufferSeconds;
    for (final seg in segments) {
      if (seg.startSecond < playheadSecond) continue;
      if (seg.startSecond >= playheadSecond + target) break;
      if (seg.status == SegmentStatus.downloaded) continue;
      if (seg.status == SegmentStatus.downloading) continue;
      if (_currentlyDownloading >= 2) break;
      unawaited(_downloadSegment(seg));
    }
  }

  Future<void> _downloadSegment(AudioSegment seg) async {
    seg.status = SegmentStatus.downloading;
    _currentlyDownloading++;
    try {
      final start = DateTime.now();
      final startByte = seg.startSecond * 16000;
      final endByte = seg.endSecond * 16000 - 1;

      final response = await _dio.get<Uint8List>(
        _audioUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Range': 'bytes=$startByte-$endByte'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      final bytes = response.data!;
      final elapsed = DateTime.now().difference(start);
      _networkMonitor.recordTransfer(bytes.length, elapsed);

      seg.bytes = bytes;
      seg.byteSize = bytes.length;
      seg.status = SegmentStatus.downloaded;
    } catch (_) {
      seg.status = SegmentStatus.failed;
    } finally {
      _currentlyDownloading--;
    }
  }

  List<String> get downloadedPaths => [];

  void clearCache() {
    for (final seg in segments) {
      seg.bytes = null;
    }
    segments.clear();
  }
}

void unawaited(Future<void> future) {}
