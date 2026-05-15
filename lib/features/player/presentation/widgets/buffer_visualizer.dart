import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/network_monitor.dart';
import '../../data/streaming/buffer_manager.dart';
import '../../data/streaming/segment_downloader.dart';

class BufferVisualizer extends ConsumerWidget {
  const BufferVisualizer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bufferState  = ref.watch(bufferManagerProvider);
    final netMonitor   = ref.watch(networkMonitorProvider);

    if (bufferState.segments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Network status row
        Row(children: [
          _StatusDot(color: netMonitor.status == NetworkStatus.online
              ? AppColors.success : AppColors.error),
          const SizedBox(width: 6),
          Text('Network: ${netMonitor.statusLabel}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const Spacer(),
          Text('Buffer: ${bufferState.bufferedSeconds}s / ${bufferState.targetSeconds}s',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 10),

        // Segment strip
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: bufferState.segments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 3),
            itemBuilder: (_, i) {
              final seg = bufferState.segments[i];
              return _SegmentChip(segment: seg);
            },
          ),
        ),

        const SizedBox(height: 6),
        // Legend
        Row(children: const [
          _LegendDot(color: AppColors.primary, label: 'Downloaded'),
          SizedBox(width: 12),
          _LegendDot(color: AppColors.warning, label: 'Downloading'),
          SizedBox(width: 12),
          _LegendDot(color: Color(0xFF3A3A3A), label: 'Waiting'),
        ]),
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final AudioSegment segment;
  const _SegmentChip({required this.segment});

  Color get _color {
    switch (segment.status) {
      case SegmentStatus.downloaded:  return AppColors.primary;
      case SegmentStatus.downloading: return AppColors.warning;
      case SegmentStatus.failed:      return AppColors.error;
      case SegmentStatus.waiting:     return const Color(0xFF3A3A3A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = segment.status == SegmentStatus.downloading;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 36, height: 28,
      decoration: BoxDecoration(
        color: _color.withOpacity(isActive ? 0.9 : 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? AppColors.warning : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '${segment.startSecond}',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});
  @override Widget build(BuildContext context) => Container(
    width: 7, height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override Widget build(BuildContext context) => Row(
    children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ],
  );
}
