import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/domain/entities/song_entity.dart';
import '../../features/library/presentation/providers/library_provider.dart';
import '../../features/player/presentation/providers/player_provider.dart';
import '../../features/playlist/presentation/providers/playlist_provider.dart';

// Tracks liked song ids for instant UI refresh
final likedSongIdsProvider = FutureProvider<Set<String>>((ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return {};
  try {
    final data = await client
        .from('liked_songs')
        .select('song_id')
        .eq('user_id', uid);
    return (data as List).map((e) => e['song_id'] as String).toSet();
  } catch (_) { return {}; }
});

class SongTile extends ConsumerWidget {
  final SongEntity song;
  final List<SongEntity>? queue;
  final int? queueIndex;

  const SongTile({super.key, required this.song, this.queue, this.queueIndex});

  void _showMoreMenu(BuildContext context, WidgetRef ref, bool isLiked) {
    final playlists = ref.read(playlistProvider).valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          // Song header
          ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: song.artworkUrl != null
                  ? Image.network(song.artworkUrl!, width: 46, height: 46,
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                          Container(width: 46, height: 46, color: AppColors.surfaceVariant,
                              child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted)))
                  : Container(width: 46, height: 46, color: AppColors.surfaceVariant,
                      child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted)),
            ),
            title: Text(song.title, style: const TextStyle(color: AppColors.textPrimary,
                fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(song.artist, style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
          ),
          const Divider(color: AppColors.divider, height: 1),

          // Like
          ListTile(
            leading: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? AppColors.primary : AppColors.textSecondary),
            title: Text(isLiked ? 'Remove from liked' : 'Like song',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            onTap: () async {
              Navigator.of(sheetCtx).pop();
              await toggleLike(song.id, isLiked, song);
              ref.invalidate(likedSongIdsProvider);
              ref.invalidate(likedSongsProvider);
            },
          ),

          // Add to playlist
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded, color: AppColors.textSecondary),
            title: const Text('Add to playlist',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            onTap: () {
              Navigator.of(sheetCtx).pop();
              if (playlists.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Create a playlist first from the Library tab'),
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.card,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (plCtx) => Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2))),
                  const Text('Add to playlist', style: TextStyle(color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...playlists.map((pl) => ListTile(
                    leading: Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.queue_music_rounded,
                          color: AppColors.textMuted, size: 20),
                    ),
                    title: Text(pl.name, style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                    subtitle: Text('${pl.songs.length} songs',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    onTap: () async {
                      Navigator.of(plCtx).pop();
                      try {
                        await ref.read(playlistProvider.notifier).addSong(pl.id, song);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Added to ${pl.name}!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                          ));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.error,
                          ));
                        }
                      }
                    },
                  )),
                  const SizedBox(height: 16),
                ]),
              );
            },
          ),

          // Share
          ListTile(
            leading: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
            title: const Text('Share', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            onTap: () {
              Navigator.of(sheetCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Sharing coming soon!'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current  = ref.watch(currentSongProvider);
    final isActive = current?.id == song.id;
    final likedIds = ref.watch(likedSongIdsProvider);
    final isLiked  = likedIds.whenOrNull(data: (ids) => ids.contains(song.id)) ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song.artworkUrl != null
            ? Image.network(song.artworkUrl!, width: 50, height: 50, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 50, height: 50,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted)))
            : Container(width: 50, height: 50, color: AppColors.surfaceVariant,
                child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted)),
      ),
      title: Text(song.title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
              color: isActive ? AppColors.primary : AppColors.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${song.artist} • ${song.durationFormatted}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isActive)
          const Icon(Icons.equalizer_rounded, color: AppColors.primary, size: 18),
        // Like button
        GestureDetector(
          onTap: () async {
            await toggleLike(song.id, isLiked, song);
            ref.invalidate(likedSongIdsProvider);
            ref.invalidate(likedSongsProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
          ),
        ),
        // More menu
        GestureDetector(
          onTap: () => _showMoreMenu(context, ref, isLiked),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
          ),
        ),
      ]),
      onTap: () => ref.read(playerControllerProvider).playSong(
          song, queue: queue ?? [song], index: queueIndex ?? 0),
    );
  }
}
