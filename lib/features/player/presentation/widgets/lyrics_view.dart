import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/lyrics/lrclib_datasource.dart';
import '../providers/player_provider.dart';
import '../../../home/domain/entities/song_entity.dart';

class LyricsView extends ConsumerWidget {
  final Duration position;
  const LyricsView({super.key, required this.position});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    if (song == null) return const SizedBox.shrink();

    final lyricsAsync = ref.watch(lyricsProvider(song));

    return lyricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(
          color: AppColors.primary, strokeWidth: 2)),
      error: (_, __) => const Center(
          child: Text('Lyrics unavailable', style: TextStyle(color: AppColors.textMuted))),
      data: (lines) {
        if (lines.isEmpty) {
          return const Center(
              child: Text('No lyrics found', style: TextStyle(color: AppColors.textMuted)));
        }
        // Find active line index
        int activeIndex = 0;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].timestamp <= position) activeIndex = i;
        }
        return _SyncedLyrics(lines: lines, activeIndex: activeIndex);
      },
    );
  }
}

class _SyncedLyrics extends StatefulWidget {
  final List<LyricLine> lines;
  final int activeIndex;
  const _SyncedLyrics({required this.lines, required this.activeIndex});
  @override State<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends State<_SyncedLyrics> {
  final ScrollController _scroll = ScrollController();
  static const double _lineHeight = 52.0;

  @override
  void didUpdateWidget(_SyncedLyrics old) {
    super.didUpdateWidget(old);
    if (old.activeIndex != widget.activeIndex) _scrollToActive();
  }

  void _scrollToActive() {
    if (!_scroll.hasClients) return;
    final offset = (widget.activeIndex * _lineHeight) -
        (_scroll.position.viewportDimension / 2) + _lineHeight / 2;
    _scroll.animateTo(offset.clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    controller: _scroll,
    itemCount: widget.lines.length,
    itemExtent: _lineHeight,
    padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.3),
    itemBuilder: (_, i) {
      final isActive = i == widget.activeIndex;
      return AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: TextStyle(
          fontSize: isActive ? 18 : 14,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          color: isActive ? AppColors.textPrimary : AppColors.textMuted,
          height: 1.4,
        ),
        child: Text(widget.lines[i].text, textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis),
      );
    },
  );

  @override void dispose() { _scroll.dispose(); super.dispose(); }
}
