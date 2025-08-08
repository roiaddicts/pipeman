/// The type of events that can occur in the pipeline
enum PipeEventType { queued, skipped, processing, success, failed }

/// A unified event object that every pipe emits
class PipeEvent<T> {
  PipeEvent({
    required this.pipeId,
    required this.type,
    required this.progress,
    this.data,
    this.error,
  });
  final String pipeId;
  final PipeEventType type;
  final double progress; // 0.0 → 1.0
  final T? data;
  final Object? error;
}
