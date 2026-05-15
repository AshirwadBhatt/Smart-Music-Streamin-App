import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/song_tile.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  bool  _active = false;

  @override void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  void _onSearch(String v) {
    ref.read(searchQueryProvider.notifier).state = v;
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final query        = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // ── Search bar ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _active ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    onChanged: _onSearch,
                    onTap: () => setState(() => _active = true),
                    onTapOutside: (_) => setState(() => _active = false),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Songs, artists, albums…',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _ctrl.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              if (_active) ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    _ctrl.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    _focus.unfocus();
                    setState(() => _active = false);
                  },
                  child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ]),
          ),

          // ── Content ──────────────────────────────────────────
          Expanded(child: query.isEmpty ? _BrowseGrid() : _SearchResults(resultsAsync: resultsAsync)),
        ]),
      ),
    );
  }
}

// ── Browse by genre grid shown when no query ───────────────────
class _BrowseGrid extends ConsumerWidget {
  final _genres = const [
    ('Pop',         Icons.music_note_rounded,           Color(0xFFE91E63)),
    ('Rock',        Icons.electric_bolt_rounded,        Color(0xFF9C27B0)),
    ('Electronic',  Icons.headphones_rounded,           Color(0xFF3F51B5)),
    ('Jazz',        Icons.piano_rounded,                Color(0xFF009688)),
    ('Classical',   Icons.queue_music_rounded,          Color(0xFFFF9800)),
    ('Hip-Hop',     Icons.mic_rounded,                  Color(0xFFf44336)),
    ('Indie',       Icons.music_note_outlined,Color(0xFF4CAF50)),
    ('Ambient',     Icons.waves_rounded,                Color(0xFF00BCD4)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Browse by genre',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.4,
            ),
            itemCount: _genres.length,
            itemBuilder: (_, i) {
              final (label, icon, color) = _genres[i];
              return GestureDetector(
                onTap: () => ref.read(searchQueryProvider.notifier).state = label.toLowerCase(),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4), width: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 10),
                    Text(label, style: TextStyle(color: color,
                        fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              ).animate(delay: Duration(milliseconds: i * 50))
               .fade(duration: 300.ms).slideY(begin: 0.2, end: 0);
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Results list ───────────────────────────────────────────────
class _SearchResults extends ConsumerWidget {
  final AsyncValue<List<SongEntity>> resultsAsync;
  const _SearchResults({required this.resultsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return resultsAsync.when(
      loading: () => Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant, highlightColor: AppColors.card,
        child: ListView.builder(
          itemCount: 6, padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (_, __) => Container(
            height: 64, margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e',
          style: const TextStyle(color: AppColors.textMuted))),
      data: (songs) {
        if (songs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('No results found', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            ]).animate().fade(duration: 300.ms),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: songs.length,
          itemBuilder: (_, i) => SongTile(song: songs[i], queue: songs, queueIndex: i)
              .animate(delay: Duration(milliseconds: i * 40)).fade(duration: 250.ms).slideX(begin: 0.05, end: 0),
        );
      },
    );
  }
}
