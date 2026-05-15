import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/jamendo_datasource.dart';
import '../../domain/entities/song_entity.dart';

final jamendoDatasourceProvider = Provider<JamendoDatasource>((ref) {
  return JamendoDatasource(ref.watch(dioClientProvider).jamendoDio);
});

final featuredTracksProvider = FutureProvider<List<SongEntity>>((ref) async {
  return ref.watch(jamendoDatasourceProvider).getFeaturedTracks();
});

final genreTracksProvider = FutureProvider.family<List<SongEntity>, String>((ref, genre) async {
  return ref.watch(jamendoDatasourceProvider).getTracksByGenre(genre);
});

// Genres available on Jamendo
const kGenres = ['pop', 'rock', 'electronic', 'jazz', 'classical', 'hiphop', 'indie', 'ambient'];
