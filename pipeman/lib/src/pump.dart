import 'dart:async';
import 'dart:collection';

import 'package:pipeman/src/pipeline.dart';

class Pump<I, O> {
  Pump(
    this.pipeline, {
    this.maxConcurrent = 4,
  }) : assert(
          maxConcurrent > 0,
          'maxConcurrent must be >= 1',
        );

  final Pipeline<I, O> pipeline;
  final int maxConcurrent;

  int _inFlight = 0;
  final Queue<_Job<I, O>> _queue = Queue();
  bool _closed = false;

  /// Enqueue a job and get its result.
  Future<O> feed(I job) {
    if (_closed) {
      return Future.error(StateError('Pump closed'));
    }
    final c = Completer<O>();
    _queue.add(_Job(job, c));
    _pump();
    return c.future;
  }

  /// No more new jobs; await all queued + in-flight to finish.
  Future<void> close() async {
    _closed = true;
    // Wait until both queue is empty and nothing in flight
    while (_inFlight > 0 || _queue.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void _pump() {
    // Fill the runway
    while (_inFlight < maxConcurrent && _queue.isNotEmpty) {
      final job = _queue.removeFirst();
      _inFlight++;

      pipeline.run(job.input).then((value) {
        if (job.completer.isCompleted) return;
        job.completer.complete(value);
      }).catchError((Object error, [StackTrace? stackTrace]) {
        if (job.completer.isCompleted) return;
        job.completer.completeError(
          error,
          stackTrace,
        );
      }).whenComplete(() {
        _inFlight--;
        // Trigger next batch
        _pump();
      });
    }
  }
}

class _Job<I, O> {
  _Job(this.input, this.completer);
  final I input;
  final Completer<O> completer;
}
