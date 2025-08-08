import 'dart:async';

import 'package:pipeman/src/pipe_event.dart';

typedef PipeFunction<I, O> = FutureOr<O> Function(I input);

abstract class Pipe<I, O> {
  Pipe(this.id);
  final String id;
  final StreamController<PipeEvent<O>> _events = StreamController();

  Stream<PipeEvent<O>> get stream => _events.stream;

  /// Must be implemented by child classes or passed as a function
  FutureOr<O> execute(I input);

  /// Called internally by the pipeline
  Future<O> run(I input) async {
    _emit(
      PipeEvent(
        pipeId: id,
        type: PipeEventType.queued,
        progress: 0,
      ),
    );

    try {
      final result = await execute(input);
      _emit(
        PipeEvent(
          pipeId: id,
          type: PipeEventType.success,
          data: result,
          progress: 1,
        ),
      );
      return result;
    } catch (e) {
      _emit(
        PipeEvent(
          pipeId: id,
          type: PipeEventType.failed,
          error: e,
          progress: 1,
        ),
      );
      rethrow;
    }
  }

  /// To be called by implementors to update progress
  void setProgress(double progress) {
    if (progress < 0 || progress > 1) {
      throw ArgumentError('Progress must be between 0.0 and 1.0');
    }

    _emit(
      PipeEvent(
        pipeId: id,
        type: PipeEventType.processing,
        progress: progress,
      ),
    );
  }

  void _emit(PipeEvent<O> event) => _events.add(event);
}

class FunctionPipe<I, O> extends Pipe<I, O> {
  FunctionPipe({
    required String id,
    required this.fn,
  }) : super(id);
  final PipeFunction<I, O> fn;

  @override
  FutureOr<O> execute(I input) => fn(input);
}
