import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/song_tile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/song_entity.dart';
import '../providers/home_provider.dart';
import '../../../player/presentation/providers/player_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user          = ref.watch(currentUserProvider);
    final featuredAsync = ref.watch(featuredTracksProvider);
    final popAsync      = ref.watch(genreTracksProvider('pop'));
    final rockAsync     = ref.watch(genreTracksProvider('rock'));
    final elecAsync     = ref.watch(genreTracksProvider('electronic'));

    final hour    = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ───────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              title: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(greeting, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400)),
                  Text(user?.username ?? 'Listener', style: const TextStyle(
                      fontSize: 20, color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                ]),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ]),
            ),
            expandedHeight: 70,
          ),

          SliverToBoxAdapter(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Featured / Hero strip ──────────────────────────
              featuredAsync.when(
                loading: () => _ShimmerBanner(),
                error: (e, _) => const SizedBox.shrink(),
                data: (songs) => _FeaturedBanner(songs: songs.take(5).toList()),
              ).animate().fade(duration: 400.ms),

              const SizedBox(height: 28),

              // ── Genre rows ────────────────────────────────────
              _SectionHeader(title: 'Pop Hits', onSeeAll: () {}),
              _HorizontalSongRow(tracksAsync: popAsync),
              const SizedBox(height: 24),

              _SectionHeader(title: 'Rock Classics', onSeeAll: () {}),
              _HorizontalSongRow(tracksAsync: rockAsync),
              const SizedBox(height: 24),

              _SectionHeader(title: 'Electronic', onSeeAll: () {}),
              _HorizontalSongRow(tracksAsync: elecAsync),
              const SizedBox(height: 24),

              // ── Featured list ─────────────────────────────────
              _SectionHeader(title: 'Featured Tracks', onSeeAll: () {}),
              featuredAsync.when(
                loading: () => const _ShimmerList(),
                error: (_, __) => const SizedBox.shrink(),
                data: (songs) => _SongList(songs: songs),
              ),

              const SizedBox(height: 100), // bottom nav padding
            ],
          )),
        ],
      ),
    );
  }
}

// ── Featured banner ────────────────────────────────────────────
class _FeaturedBanner extends ConsumerStatefulWidget {
  final List<SongEntity> songs;
  const _FeaturedBanner({required this.songs});
  @override ConsumerState<_FeaturedBanner> createState() => _FeaturedBannerState();
}
class _FeaturedBannerState extends ConsumerState<_FeaturedBanner> {
  int _page = 0;
  final PageController _pc = PageController(viewportFraction: 0.88);
  @override void dispose() { _pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 200,
        child: PageView.builder(
          controller: _pc,
          itemCount: widget.songs.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final s = widget.songs[i];
            return GestureDetector(
              onTap: () {
                ref.read(playerControllerProvider).playSong(s, queue: widget.songs, index: i);
                context.push('/player');
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: s.artworkUrl != null
                      ? DecorationImage(image: CachedNetworkImageProvider(s.artworkUrl!), fit: BoxFit.cover)
                      : null,
                  color: AppColors.card,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(s.artist, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      // Page indicators
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.songs.length, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _page == i ? 18 : 6, height: 6,
          decoration: BoxDecoration(
            color: _page == i ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(3),
          ),
        )),
      ),
    ]);
  }
}

class _HorizontalSongRow extends ConsumerWidget {
  final AsyncValue<List<SongEntity>> tracksAsync;
  const _HorizontalSongRow({required this.tracksAsync});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return tracksAsync.when(
      loading: () => SizedBox(height: 160, child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant, highlightColor: AppColors.card,
        child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5, itemBuilder: (_, __) => Container(
            width: 120, height: 140, margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          )),
      )),
      error: (_, __) => const SizedBox.shrink(),
      data: (songs) => SizedBox(
        height: 165,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: songs.length,
          itemBuilder: (_, i) {
            final s = songs[i];
            return GestureDetector(
              onTap: () {
                ref.read(playerControllerProvider).playSong(s, queue: songs, index: i);
                context.push('/player');
              },
              child: Container(
                width: 120, margin: const EdgeInsets.only(right: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: s.artworkUrl != null
                        ? CachedNetworkImage(imageUrl: s.artworkUrl!, width: 120, height: 120, fit: BoxFit.cover)
                        : Container(width: 120, height: 120, color: AppColors.card,
                            child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted)),
                  ),
                  const SizedBox(height: 6),
                  Text(s.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(s.artist, style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SongList extends ConsumerWidget {
  final List<SongEntity> songs;
  const _SongList({required this.songs});
  @override Widget build(BuildContext context, WidgetRef ref) => Column(
    children: songs.asMap().entries.map((e) =>
        SongTile(song: e.value, queue: songs, queueIndex: e.key)).toList(),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        TextButton(onPressed: onSeeAll, child: const Text('See all', style: TextStyle(fontSize: 12, color: AppColors.primary))),
      ],
    ),
  );
}

class _ShimmerBanner extends StatelessWidget {
  @override Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.surfaceVariant, highlightColor: AppColors.card,
    child: Container(height: 200, margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18))),
  );
}
class _ShimmerList extends StatelessWidget {
  const _ShimmerList();
  @override Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.surfaceVariant, highlightColor: AppColors.card,
    child: Column(children: List.generate(4, (_) => Container(
      height: 56, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
    ))),
  );
}
