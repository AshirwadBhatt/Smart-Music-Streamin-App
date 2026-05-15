import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/data/datasources/jamendo_datasource.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../../home/presentation/providers/home_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<SongEntity>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.watch(jamendoDatasourceProvider).searchTracks(query);
});
