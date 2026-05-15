import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/song_tile.dart';
import '../../../playlist/presentation/providers/playlist_provider.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync  = ref.watch(playlistProvider);
    final likedAsync      = ref.watch(likedSongsProvider);
    final recentAsync     = ref.watch(recentlyPlayedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Library'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New playlist',
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Playlists ──────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Playlists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
          playlistsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
            data: (playlists) => playlists.isEmpty
                ? _EmptyState(
                    icon: Icons.queue_music_rounded,
                    message: 'No playlists yet',
                    actionLabel: 'Create one',
                    onAction: () => _showCreateDialog(context, ref),
                  )
                : Column(
                    children: playlists.asMap().entries.map((e) {
                      final pl = e.value;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: pl.coverUrl != null
                              ? CachedNetworkImage(imageUrl: pl.coverUrl!,
                                  width: 52, height: 52, fit: BoxFit.cover)
                              : Container(
                                  width: 52, height: 52,
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(Icons.queue_music_rounded,
                                      color: AppColors.textMuted, size: 24),
                                ),
                        ),
                        title: Text(pl.name,
                            style: const TextStyle(fontWeight: FontWeight.w600,
                                fontSize: 14, color: AppColors.textPrimary)),
                        subtitle: Text('${pl.songs.length} songs',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () => context.push('/playlist/${pl.id}'),
                      ).animate(delay: Duration(milliseconds: e.key * 50)).fade(duration: 250.ms);
                    }).toList(),
                  ),
          ),

          const Divider(color: AppColors.divider, height: 32),

          // ── Liked Songs ────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text('Liked Songs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
          likedAsync.when(
            loading: () => const SizedBox(height: 60,
                child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
            error: (_, __) => const SizedBox.shrink(),
            data: (songs) => songs.isEmpty
                ? const _EmptyState(icon: Icons.favorite_border_rounded, message: 'No liked songs yet')
                : Column(children: songs.asMap().entries.map((e) =>
                    SongTile(song: e.value, queue: songs, queueIndex: e.key)
                        .animate(delay: Duration(milliseconds: e.key * 40)).fade(duration: 250.ms)
                  ).toList()),
          ),

          const Divider(color: AppColors.divider, height: 32),

          // ── Recently Played ────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text('Recently Played',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
          recentAsync.when(
            loading: () => const SizedBox(height: 60,
                child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
            error: (_, __) => const SizedBox.shrink(),
            data: (songs) => songs.isEmpty
                ? const _EmptyState(icon: Icons.history_rounded, message: 'Nothing played yet')
                : Column(children: songs.take(15).toList().asMap().entries.map((e) =>
                    SongTile(song: e.value, queue: songs.toList(), queueIndex: e.key)
                        .animate(delay: Duration(milliseconds: e.key * 40)).fade(duration: 250.ms)
                  ).toList()),
          ),

          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('New Playlist', style: TextStyle(color: AppColors.textPrimary)),
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
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(playlistProvider.notifier).create(ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData  icon;
  final String    message;
  final String?   actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 44, color: AppColors.textMuted),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        if (actionLabel != null) ...[
          const SizedBox(height: 10),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    ),
  );
}
