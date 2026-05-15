import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_formatter.dart';

class SeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final ValueChanged<Duration>? onSeek;

  const SeekBar({super.key, required this.position, required this.duration,
      this.buffered = Duration.zero, this.onSeek});

  @override State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  bool   _dragging  = false;
  double _dragValue = 0;

  double get _progress {
    if (_dragging) return _dragValue;
    if (widget.duration.inMilliseconds == 0) return 0;
    return widget.position.inMilliseconds / widget.duration.inMilliseconds;
  }

  double get _bufferedProgress {
    if (widget.duration.inMilliseconds == 0) return 0;
    return (widget.buffered.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Seek slider with buffered track overlay
      Stack(children: [
        // Buffered layer
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 3,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
            activeTrackColor: Color(0xFF3A3A3A),
            inactiveTrackColor: Color(0xFF2A2A2A),
          ),
          child: Slider(value: _bufferedProgress, onChanged: null),
        ),
        // Position layer
        Slider(
          value: _progress.clamp(0.0, 1.0),
          onChangeStart: (_) => setState(() => _dragging = true),
          onChanged: (v) => setState(() => _dragValue = v),
          onChangeEnd: (v) {
            setState(() => _dragging = false);
            final target = Duration(milliseconds: (v * widget.duration.inMilliseconds).round());
            widget.onSeek?.call(target);
          },
        ),
      ]),

      // Time labels
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DurationFormatter.format(_dragging
                  ? Duration(milliseconds: (_dragValue * widget.duration.inMilliseconds).round())
                  : widget.position),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              DurationFormatter.format(widget.duration),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ]);
  }
}
