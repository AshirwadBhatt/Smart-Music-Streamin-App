import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/playlist_datasource.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';

final playlistDatasourceProvider = Provider<PlaylistDatasource>((ref) => PlaylistDatasource());

class PlaylistNotifier extends StateNotifier<AsyncValue<List<PlaylistEntity>>> {
  final PlaylistDatasource _ds;
  PlaylistNotifier(this._ds) : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _ds.getUserPlaylists());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> create(String name) async {
    await _ds.createPlaylist(name);
    await load();
  }

  Future<void> rename(String id, String name) async {
    await _ds.renamePlaylist(id, name);
    await load();
  }

  Future<void> delete(String id) async {
    await _ds.deletePlaylist(id);
    await load();
  }

  Future<void> addSong(String playlistId, SongEntity song) async {
    await _ds.addSongToPlaylist(playlistId, song);
    await load();
  }

  Future<void> removeSong(String playlistId, String songId) async {
    await _ds.removeSongFromPlaylist(playlistId, songId);
    await load();
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, AsyncValue<List<PlaylistEntity>>>((ref) {
  return PlaylistNotifier(ref.watch(playlistDatasourceProvider));
});

final singlePlaylistProvider = Provider.family<PlaylistEntity?, String>((ref, id) {
  return ref.watch(playlistProvider).valueOrNull
      ?.firstWhere((p) => p.id == id, orElse: () => throw StateError('Not found'));
});
