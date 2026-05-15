import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../services/audio_handler.dart';
import '../../data/lyrics/lrclib_datasource.dart';
import '../../data/streaming/buffer_manager.dart';
import '../../data/streaming/segment_downloader.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../data/lyrics/lrclib_datasource.dart' show LyricLine;

// ── Currently playing song ─────────────────────────────────────
final currentSongProvider = StateProvider<SongEntity?>((ref) => null);

// ── Player state from just_audio ──────────────────────────────
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});

final currentPositionProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  if (handler is AshuAudioHandler) return handler.player.positionStream;
  return const Stream.empty();
});

final currentDurationProvider = StreamProvider<Duration?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  if (handler is AshuAudioHandler) return handler.player.durationStream;
  return const Stream.empty();
});

// ── Lyrics ─────────────────────────────────────────────────────
final lrclibDatasourceProvider = Provider<LrclibDatasource>((ref) {
  return LrclibDatasource(ref.watch(dioClientProvider).lrclibDio);
});

final lyricsProvider = FutureProvider.family<List<LyricLine>, SongEntity>((ref, song) async {
  return ref.watch(lrclibDatasourceProvider).getLyrics(song.title, song.artist);
});

// ── Queue ──────────────────────────────────────────────────────
final queueProvider = StateProvider<List<SongEntity>>((ref) => []);
final queueIndexProvider = StateProvider<int>((ref) => 0);
final isShuffleProvider = StateProvider<bool>((ref) => false);
final repeatModeProvider = StateProvider<AudioServiceRepeatMode>((ref) => AudioServiceRepeatMode.none);

// ── Player actions ─────────────────────────────────────────────
class PlayerController {
  final Ref _ref;
  PlayerController(this._ref);

  AshuAudioHandler get _handler => _ref.read(audioHandlerProvider) as AshuAudioHandler;

  Future<void> playSong(SongEntity song, {List<SongEntity>? queue, int index = 0}) async {
    _ref.read(currentSongProvider.notifier).state = song;

    // Start buffer manager
    final networkMonitor = _ref.read(networkMonitorProvider);
    final dio            = _ref.read(dioClientProvider).jamendoDio;
    final downloader     = SegmentDownloader(
      dio: dio,
      networkMonitor: networkMonitor,
      audioUrl: song.audioUrl,
      totalSeconds: song.durationSeconds,
    );
    _ref.read(bufferManagerProvider.notifier).startBuffering(downloader);

    final item = MediaItem(
      id:       song.id,
      title:    song.title,
      artist:   song.artist,
      album:    song.album,
      artUri:   song.artworkUrl != null ? Uri.parse(song.artworkUrl!) : null,
      duration: Duration(seconds: song.durationSeconds),
      extras:   {'url': song.audioUrl},
    );

    await _handler.playFromUrl(song.audioUrl, item);

    // Track listening history in Supabase (fire-and-forget)
    if (queue != null) {
      _ref.read(queueProvider.notifier).state = queue;
      _ref.read(queueIndexProvider.notifier).state = index;
    }
  }

  Future<void> play()           => _handler.play();
  Future<void> pause()          => _handler.pause();
  Future<void> seekForward10()  => _seekRelative(const Duration(seconds: 10));
  Future<void> seekBackward10() => _seekRelative(const Duration(seconds: -10));
  Future<void> skipNext()       => _handler.skipToNext();
  Future<void> skipPrev()       => _handler.skipToPrevious();

  Future<void> seek(Duration pos) {
    _ref.read(bufferManagerProvider.notifier).updatePlayhead(pos.inSeconds);
    return _handler.seek(pos);
  }

  Future<void> _seekRelative(Duration delta) async {
    final pos = _handler.player.position;
    final dur = _handler.player.duration ?? Duration.zero;
    final raw = pos + delta;
    final target = raw < Duration.zero ? Duration.zero : (raw > dur ? dur : raw);
    await seek(target);
  }

  void toggleShuffle() {
    final current = _ref.read(isShuffleProvider);
    _ref.read(isShuffleProvider.notifier).state = !current;
    _handler.setShuffleMode(
      current ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all);
  }

  void cycleRepeat() {
    final modes = [
      AudioServiceRepeatMode.none,
      AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.one,
    ];
    final current = _ref.read(repeatModeProvider);
    final next    = modes[(modes.indexOf(current) + 1) % modes.length];
    _ref.read(repeatModeProvider.notifier).state = next;
    _handler.setRepeatMode(next);
  }
}

final playerControllerProvider = Provider<PlayerController>((ref) => PlayerController(ref));
