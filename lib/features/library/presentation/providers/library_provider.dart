import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../home/domain/entities/song_entity.dart';

final likedSongsProvider = FutureProvider<List<SongEntity>>((ref) async {
  final client = Supabase.instance.client;
  final uid    = client.auth.currentUser?.id;
  if (uid == null) return [];
  try {
    final data = await client
        .from('liked_songs')
        .select('songs(*)')
        .eq('user_id', uid)
        .order('liked_at', ascending: false);
    return (data as List)
        .where((row) => row['songs'] != null)
        .map((row) => _mapSong(row['songs'] as Map<String, dynamic>))
        .toList();
  } catch (_) { return []; }
});

final recentlyPlayedProvider = FutureProvider<List<SongEntity>>((ref) async {
  final client = Supabase.instance.client;
  final uid    = client.auth.currentUser?.id;
  if (uid == null) return [];
  try {
    final data = await client
        .from('recently_played')
        .select('songs(*)')
        .eq('user_id', uid)
        .order('played_at', ascending: false)
        .limit(30);
    return (data as List)
        .where((row) => row['songs'] != null)
        .map((row) => _mapSong(row['songs'] as Map<String, dynamic>))
        .toList();
  } catch (_) { return []; }
});

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

// Upsert song then toggle like
Future<void> toggleLike(String songId, bool isLiked, SongEntity song) async {
  final client = Supabase.instance.client;
  final uid    = client.auth.currentUser?.id;
  if (uid == null) return;

  // Always upsert song first so FK constraint doesn't fail
  await client.from('songs').upsert({
    'id':               song.id,
    'title':            song.title,
    'artist':           song.artist,
    'album':            song.album,
    'artwork_url':      song.artworkUrl,
    'audio_url':        song.audioUrl,
    'duration_seconds': song.durationSeconds,
    'genre':            song.genre,
  }, onConflict: 'id');

  if (isLiked) {
    await client.from('liked_songs')
        .delete()
        .eq('user_id', uid)
        .eq('song_id', songId);
  } else {
    await client.from('liked_songs').upsert({
      'user_id':  uid,
      'song_id':  songId,
      'liked_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,song_id');
  }
}

Future<void> recordPlay(SongEntity song) async {
  final client = Supabase.instance.client;
  final uid    = client.auth.currentUser?.id;
  if (uid == null) return;
  try {
    await client.from('songs').upsert({
      'id': song.id, 'title': song.title, 'artist': song.artist,
      'album': song.album, 'artwork_url': song.artworkUrl,
      'audio_url': song.audioUrl, 'duration_seconds': song.durationSeconds,
    }, onConflict: 'id');
    await client.from('recently_played').insert({
      'user_id':   uid,
      'song_id':   song.id,
      'played_at': DateTime.now().toIso8601String(),
    });
  } catch (_) {}
}
