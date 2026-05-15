class SongEntity {
  final String  id;
  final String  title;
  final String  artist;
  final String  artistId;
  final String? album;
  final String? artworkUrl;
  final String  audioUrl;
  final int     durationSeconds;
  final String? genre;

  const SongEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    this.album,
    this.artworkUrl,
    required this.audioUrl,
    required this.durationSeconds,
    this.genre,
  });

  String get durationFormatted {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
