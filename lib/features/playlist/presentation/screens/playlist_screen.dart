import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/song_tile.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../providers/playlist_provider.dart';

class PlaylistScreen extends ConsumerWidget {
  final String playlistId;
  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(singlePlaylistProvider(playlistId));

    if (playlist == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover art
                  playlist.coverUrl != null
                      ? CachedNetworkImage(imageUrl: playlist.coverUrl!, fit: BoxFit.cover)
                      : Container(color: AppColors.surfaceVariant,
                          child: const Icon(Icons.queue_music_rounded, size: 80, color: AppColors.textMuted)),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                      ),
                    ),
                  ),
                  // Playlist info
                  Positioned(
                    bottom: 16, left: 20, right: 20,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(playlist.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary)),
                      Text('${playlist.songs.length} songs',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ]),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showRenameDialog(context, ref, playlist.name),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),

          // ── Play controls ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: playlist.songs.isEmpty ? null : () {
                      ref.read(playerControllerProvider).playSong(
                          playlist.songs.first, queue: playlist.songs, index: 0);
                      context.push('/player');
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                    label: const Text('Play All'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: playlist.songs.isEmpty ? null : () {
                    ref.read(playerControllerProvider).toggleShuffle();
                    ref.read(playerControllerProvider).playSong(
                        playlist.songs.first, queue: playlist.songs, index: 0);
                    context.push('/player');
                  },
                  icon: const Icon(Icons.shuffle_rounded, color: AppColors.primary, size: 18),
                  label: const Text('Shuffle', style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ]),
            ),
          ),

          // ── Song list ─────────────────────────────────────────
          playlist.songs.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(children: [
                        const Icon(Icons.music_off_rounded, size: 52, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text('No songs yet', style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => context.go('/search'),
                          child: const Text('Search for songs to add'),
                        ),
                      ]).animate().fade(duration: 400.ms),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Dismissible(
                      key: ValueKey(playlist.songs[i].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppColors.error.withOpacity(0.15),
                        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      ),
                      onDismissed: (_) => ref.read(playlistProvider.notifier)
                          .removeSong(playlist.id, playlist.songs[i].id),
                      child: SongTile(
                        song: playlist.songs[i],
                        queue: playlist.songs,
                        queueIndex: i,
                      ).animate(delay: Duration(milliseconds: i * 40)).fade(duration: 250.ms),
                    ),
                    childCount: playlist.songs.length,
                  ),
                ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Rename playlist', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(playlistProvider.notifier).rename(playlistId, ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete playlist?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(playlistProvider.notifier).delete(playlistId);
              Navigator.pop(context);
              context.go('/library');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
