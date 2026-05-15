import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/song_entity.dart';

class JamendoDatasource {
  final Dio _dio;
  JamendoDatasource(this._dio);

  Map<String, dynamic> get _baseParams => {
    'client_id': ApiConstants.jamendoClientId,
    'format': 'json',
    'limit': 20,
  };

  SongEntity _mapTrack(Map<String, dynamic> t) => SongEntity(
    id:              t['id']?.toString() ?? '',
    title:           t['name'] ?? 'Unknown',
    artist:          t['artist_name'] ?? 'Unknown Artist',
    artistId:        t['artist_id']?.toString() ?? '',
    album:           t['album_name'],
    artworkUrl:      t['album_image'],
    audioUrl:        t['audio'] ?? '',
    durationSeconds: int.tryParse(t['duration']?.toString() ?? '0') ?? 0,
    genre:           (t['musicinfo']?['tags']?['genres'] as List?)?.firstOrNull?.toString(),
  );

  Future<List<SongEntity>> getFeaturedTracks() async {
    final res = await _dio.get('/tracks', queryParameters: {
      ..._baseParams,
      'featured': 1,
      'include': 'musicinfo',
      'imagesize': 500,
      'audioformat': 'mp32',
    });
    final results = res.data['results'] as List? ?? [];
    return results.map((t) => _mapTrack(t as Map<String, dynamic>)).toList();
  }

  Future<List<SongEntity>> searchTracks(String query) async {
    final res = await _dio.get('/tracks', queryParameters: {
      ..._baseParams,
      'search': query,
      'include': 'musicinfo',
      'imagesize': 500,
      'audioformat': 'mp32',
    });
    final results = res.data['results'] as List? ?? [];
    return results.map((t) => _mapTrack(t as Map<String, dynamic>)).toList();
  }

  Future<List<SongEntity>> getTracksByGenre(String tag) async {
    final res = await _dio.get('/tracks', queryParameters: {
      ..._baseParams,
      'tags': tag,
      'include': 'musicinfo',
      'imagesize': 500,
      'audioformat': 'mp32',
      'order': 'popularity_total',
    });
    final results = res.data['results'] as List? ?? [];
    return results.map((t) => _mapTrack(t as Map<String, dynamic>)).toList();
  }

  Future<List<SongEntity>> getRecommendations(List<String> artistIds) async {
    final res = await _dio.get('/tracks', queryParameters: {
      ..._baseParams,
      'artist_id': artistIds.take(3).join('+'),
      'include': 'musicinfo',
      'imagesize': 500,
      'audioformat': 'mp32',
    });
    final results = res.data['results'] as List? ?? [];
    return results.map((t) => _mapTrack(t as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> searchArtists(String query) async {
    final res = await _dio.get('/artists', queryParameters: {
      ..._baseParams,
      'namesearch': query,
      'imagesize': 200,
    });
    return List<Map<String, dynamic>>.from(res.data['results'] ?? []);
  }
}
