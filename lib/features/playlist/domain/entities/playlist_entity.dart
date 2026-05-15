import '../../../home/domain/entities/song_entity.dart';

class PlaylistEntity {
  final String         id;
  final String         userId;
  final String         name;
  final String?        coverUrl;
  final bool           isPublic;
  final List<SongEntity> songs;
  final DateTime       createdAt;

  const PlaylistEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.coverUrl,
    this.isPublic = false,
    this.songs    = const [],
    required this.createdAt,
  });

  PlaylistEntity copyWith({String? name, String? coverUrl, bool? isPublic, List<SongEntity>? songs}) =>
      PlaylistEntity(
        id: id, userId: userId,
        name:      name      ?? this.name,
        coverUrl:  coverUrl  ?? this.coverUrl,
        isPublic:  isPublic  ?? this.isPublic,
        songs:     songs     ?? this.songs,
        createdAt: createdAt,
      );
}
