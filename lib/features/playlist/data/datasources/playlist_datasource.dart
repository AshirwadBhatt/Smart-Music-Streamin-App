import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../domain/entities/playlist_entity.dart';

class PlaylistDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  String get _uid => _client.auth.currentUser!.id;

  Future<List<PlaylistEntity>> getUserPlaylists() async {
    final data = await _client
        .from('playlists')
        .select('*, playlist_songs(position, songs(*))')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);

    return (data as List).map((e) => _mapPlaylist(e as Map<String, dynamic>)).toList();
  }

  Future<PlaylistEntity> createPlaylist(String name) async {
    final data = await _client.from('playlists').insert({
      'user_id':    _uid,
      'name':       name,
      'is_public':  false,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();
    return _mapPlaylist(data);
  }

  Future<void> renamePlaylist(String id, String name) async {
    await _client.from('playlists').update({'name': name}).eq('id', id);
  }

  Future<void> deletePlaylist(String id) async {
    await _client.from('playlists').delete().eq('id', id);
  }

  Future<void> addSongToPlaylist(String playlistId, SongEntity song) async {
    // Upsert song into songs table first
    await _client.from('songs').upsert({
      'id':               song.id,
      'title':            song.title,
      'artist':           song.artist,
      'album':            song.album,
      'artwork_url':      song.artworkUrl,
      'audio_url':        song.audioUrl,
      'duration_seconds': song.durationSeconds,
      'genre':            song.genre,
      'jamendo_id':       song.id,
    });
    // Get max position
    final positions = await _client
        .from('playlist_songs')
        .select('position')
        .eq('playlist_id', playlistId)
        .order('position', ascending: false)
        .limit(1);
    final nextPos = positions.isEmpty ? 0 : (positions.first['position'] as int) + 1;

    await _client.from('playlist_songs').insert({
      'playlist_id': playlistId,
      'song_id':     song.id,
      'position':    nextPos,
      'added_at':    DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _client.from('playlist_songs')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('song_id', songId);
  }

  PlaylistEntity _mapPlaylist(Map<String, dynamic> d) {
    final rawSongs = (d['playlist_songs'] as List? ?? []);
    final songs = rawSongs
        .where((ps) => ps['songs'] != null)
        .map((ps) => _mapSong(ps['songs'] as Map<String, dynamic>))
        .toList();
    return PlaylistEntity(
      id:        d['id'],
      userId:    d['user_id'],
      name:      d['name'],
      coverUrl:  d['cover_url'],
      isPublic:  d['is_public'] ?? false,
      songs:     songs,
      createdAt: DateTime.parse(d['created_at']),
    );
  }

  SongEntity _mapSong(Map<String, dynamic> d) => SongEntity(
    id:              d['id'],
    title:           d['title'] ?? 'Unknown',
    artist:          d['artist'] ?? 'Unknown',
    artistId:        '',
    album:           d['album'],
    artworkUrl:      d['artwork_url'],
    audioUrl:        d['audio_url'] ?? '',
    durationSeconds: d['duration_seconds'] ?? 0,
    genre:           d['genre'],
  );
}
