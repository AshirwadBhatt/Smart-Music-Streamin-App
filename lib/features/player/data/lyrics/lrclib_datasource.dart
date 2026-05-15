import 'package:dio/dio.dart';

class LyricLine {
  final Duration timestamp;
  final String   text;
  const LyricLine({required this.timestamp, required this.text});
}

class LrclibDatasource {
  final Dio _dio;
  LrclibDatasource(this._dio);

  Future<List<LyricLine>> getLyrics(String title, String artist) async {
    try {
      final res = await _dio.get('/get', queryParameters: {
        'track_name': title,
        'artist_name': artist,
      });
      final syncedLyrics = res.data['syncedLyrics'] as String?;
      if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
        return _parseLrc(syncedLyrics);
      }
      // Fallback to plain lyrics
      final plain = res.data['plainLyrics'] as String?;
      if (plain != null) {
        return plain.split('\n').where((l) => l.trim().isNotEmpty).map((line) =>
            LyricLine(timestamp: Duration.zero, text: line)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  List<LyricLine> _parseLrc(String lrc) {
    final lines  = <LyricLine>[];
    final regex  = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    for (final line in lrc.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match == null) continue;
      final min  = int.parse(match.group(1)!);
      final sec  = int.parse(match.group(2)!);
      final ms   = int.parse(match.group(3)!.padRight(3, '0').substring(0, 3));
      final text = match.group(4)!.trim();
      if (text.isEmpty) continue;
      lines.add(LyricLine(
        timestamp: Duration(minutes: min, seconds: sec, milliseconds: ms),
        text: text,
      ));
    }
    return lines;
  }
}
