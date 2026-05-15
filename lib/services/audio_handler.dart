import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioHandlerProvider = Provider<AudioHandler>((ref) => throw UnimplementedError());

class AshuAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AshuAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent e) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle:       AudioProcessingState.idle,
        ProcessingState.loading:    AudioProcessingState.loading,
        ProcessingState.buffering:  AudioProcessingState.buffering,
        ProcessingState.ready:      AudioProcessingState.ready,
        ProcessingState.completed:  AudioProcessingState.completed,
      }[_player.processingState]!,
      playing:  _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed:    _player.speed,
      queueIndex: _player.currentIndex,
    );
  }

  // ── Public controls ────────────────────────────────────────────
  @override Future<void> play()           => _player.play();
  @override Future<void> pause()          => _player.pause();
  @override Future<void> stop()           => _player.stop();
  @override Future<void> seek(Duration p) => _player.seek(p);
  @override Future<void> skipToNext()     => _player.seekToNext();
  @override Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    await _player.setShuffleModeEnabled(mode != AudioServiceShuffleMode.none);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    await _player.setLoopMode(const {
      AudioServiceRepeatMode.none:  LoopMode.off,
      AudioServiceRepeatMode.one:   LoopMode.one,
      AudioServiceRepeatMode.all:   LoopMode.all,
      AudioServiceRepeatMode.group: LoopMode.all,
    }[mode]!);
  }

  Future<void> playFromUrl(String url, MediaItem item) async {
    mediaItem.add(item);
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> playQueue(List<MediaItem> items, int index) async {
    queue.add(items);
    mediaItem.add(items[index]);
    final sources = items.map((i) => AudioSource.uri(Uri.parse(i.extras!['url'] as String))).toList();
    await _player.setAudioSource(ConcatenatingAudioSource(children: sources), initialIndex: index);
    await _player.play();
  }

  AudioPlayer get player => _player;

  @override
  Future<void> onTaskRemoved() => stop();
}
