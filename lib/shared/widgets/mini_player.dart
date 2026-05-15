import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/player/presentation/providers/player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song      = ref.watch(currentSongProvider);
    final pbAsync   = ref.watch(playbackStateProvider);
    final posAsync  = ref.watch(currentPositionProvider);
    final durAsync  = ref.watch(currentDurationProvider);

    if (song == null) return const SizedBox.shrink();

    final isPlaying = pbAsync.valueOrNull?.playing ?? false;
    final pos       = posAsync.valueOrNull ?? Duration.zero;
    final dur       = durAsync.valueOrNull ?? Duration.zero;
    final progress  = dur.inMilliseconds > 0
        ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Progress line at top
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.artworkUrl != null
                    ? CachedNetworkImage(imageUrl: song.artworkUrl!,
                        width: 44, height: 44, fit: BoxFit.cover)
                    : Container(width: 44, height: 44, color: AppColors.surfaceVariant,
                        child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted, size: 22)),
              ),
              const SizedBox(width: 12),
              // Song info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(song.artist, style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              // Controls
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 22),
                onPressed: () => ref.read(playerControllerProvider).skipPrev(),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isPlaying
                    ? () => ref.read(playerControllerProvider).pause()
                    : () => ref.read(playerControllerProvider).play(),
                child: Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                  child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.black, size: 20),
                ),
              ).animate(target: isPlaying ? 1 : 0).scale(end: const Offset(1.08, 1.08), duration: 150.ms),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 22),
                onPressed: () => ref.read(playerControllerProvider).skipNext(),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
            ]),
          ),
        ]),
      ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
           .fade(duration: 200.ms),
    );
  }
}
