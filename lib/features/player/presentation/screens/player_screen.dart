import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/player_provider.dart';
import '../widgets/buffer_visualizer.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/seek_bar.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});
  @override ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Color _dominantColor = AppColors.primary;

  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override void dispose()   { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final song     = ref.watch(currentSongProvider);
    final pbAsync  = ref.watch(playbackStateProvider);
    final posAsync = ref.watch(currentPositionProvider);
    final durAsync = ref.watch(currentDurationProvider);
    final isShuffle = ref.watch(isShuffleProvider);
    final repeatMode = ref.watch(repeatModeProvider);
    final controller = ref.read(playerControllerProvider);

    final pb  = pbAsync.valueOrNull;
    final pos = posAsync.valueOrNull ?? Duration.zero;
    final dur = durAsync.valueOrNull ?? Duration.zero;
    final isPlaying = pb?.playing ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_dominantColor.withOpacity(0.6), AppColors.background, AppColors.background],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // ── Top bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
                Column(children: [
                  const Text('PLAYING FROM', style: TextStyle(fontSize: 10,
                      color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                  Text(song?.album ?? 'ASHU Music', style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ]),
                const Spacer(),
                IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
              ]),
            ),

            // ── Tab bar: Player / Lyrics ───────────────────────
            TabBar(
              controller: _tab,
              tabs: const [Tab(text: 'Player'), Tab(text: 'Lyrics')],
              indicatorColor: AppColors.primary,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
            ),

            Expanded(
              child: TabBarView(controller: _tab, children: [
                // ── Player tab ─────────────────────────────────
                _PlayerTab(
                  song: song,
                  pos: pos, dur: dur,
                  isPlaying: isPlaying,
                  isShuffle: isShuffle,
                  repeatMode: repeatMode,
                  controller: controller,
                  onColorExtracted: (c) => setState(() => _dominantColor = c),
                ),
                // ── Lyrics tab ─────────────────────────────────
                LyricsView(position: pos),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PlayerTab extends StatelessWidget {
  final song;
  final Duration pos, dur;
  final bool isPlaying, isShuffle;
  final AudioServiceRepeatMode repeatMode;
  final PlayerController controller;
  final ValueChanged<Color> onColorExtracted;

  const _PlayerTab({
    required this.song, required this.pos, required this.dur,
    required this.isPlaying, required this.isShuffle,
    required this.repeatMode, required this.controller,
    required this.onColorExtracted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const SizedBox(height: 24),

        // ── Artwork ───────────────────────────────────────────
        Hero(
          tag: 'artwork_${song?.id}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isPlaying ? 280 : 240,
            height: isPlaying ? 280 : 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40, offset: const Offset(0, 16),
              )],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: song?.artworkUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song!.artworkUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceVariant,
                          child: const Icon(Icons.music_note_rounded, size: 60, color: AppColors.textMuted)),
                    )
                  : Container(color: AppColors.surfaceVariant,
                      child: const Icon(Icons.music_note_rounded, size: 60, color: AppColors.textMuted)),
            ),
          ),
        ).animate(target: isPlaying ? 1 : 0).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

        const SizedBox(height: 28),

        // ── Song info ─────────────────────────────────────────
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song?.title ?? 'No song playing',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(song?.artist ?? '',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ]),

        const SizedBox(height: 16),

        // ── Seek bar ──────────────────────────────────────────
        SeekBar(
          position: pos, duration: dur,
          onSeek: (d) => controller.seek(d),
        ),

        const SizedBox(height: 8),

        // ── Controls ──────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          // Shuffle
          IconButton(
            icon: Icon(Icons.shuffle_rounded,
                color: isShuffle ? AppColors.primary : AppColors.textSecondary, size: 22),
            onPressed: controller.toggleShuffle,
          ),
          // Seek -10
          IconButton(
            icon: const Icon(Icons.replay_10_rounded, size: 28, color: AppColors.textSecondary),
            onPressed: controller.seekBackward10,
          ),
          // Previous
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, size: 36),
            onPressed: controller.skipPrev,
          ),
          // Play / Pause
          GestureDetector(
            onTap: isPlaying ? controller.pause : controller.play,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68, height: 68,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20)],
              ),
              child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black, size: 38),
            ),
          ).animate(target: isPlaying ? 1 : 0).scale(end: const Offset(1.05, 1.05), duration: 150.ms),
          // Next
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, size: 36),
            onPressed: controller.skipNext,
          ),
          // Seek +10
          IconButton(
            icon: const Icon(Icons.forward_10_rounded, size: 28, color: AppColors.textSecondary),
            onPressed: controller.seekForward10,
          ),
          // Repeat
          IconButton(
            icon: Icon(
              repeatMode == AudioServiceRepeatMode.one
                  ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: repeatMode == AudioServiceRepeatMode.none
                  ? AppColors.textSecondary : AppColors.primary,
              size: 22,
            ),
            onPressed: controller.cycleRepeat,
          ),
        ]),

        const SizedBox(height: 24),

        // ── Buffer visualizer ─────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const BufferVisualizer(),
        ),

        const SizedBox(height: 24),
      ]),
    );
  }
}
