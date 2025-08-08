// ignore_for_file: avoid_print

import 'dart:async';

import 'package:pipeman/pipeman.dart';

class Pipeline<I, O> extends Pipe<I, O> {
  Pipeline(super.id) : _stages = [];

  Pipeline._fromStages(super.id, List<Pipe<dynamic, dynamic>> stages) : _stages = stages {
    // Listen to all stages to emit progress events

    if (stages.isEmpty) {
      throw ArgumentError('Pipeline must have at least one stage');
    }
    if (stages.first is! Pipe<I, dynamic>) {
      throw ArgumentError('First stage must accept input type $I');
    }
    if (stages.last is! Pipe<dynamic, O>) {
      throw ArgumentError('Last stage must produce output type $O');
    }
  }

  void seal() {
    for (var i = 0; i < _stages.length; i++) {
      final stage = _stages[i];
      final isFirst = i == 0;

      stage.stream.listen(
        (event) {
          final isFirstQueued = isFirst && event.type == PipeEventType.queued;
          final isSuccess = event.type == PipeEventType.success;

          if (isFirstQueued || isSuccess) return;

          setProgress((i + event.progress) / _stages.length);
        },
      );
    }
  }

  final List<Pipe<dynamic, dynamic>> _stages;

  /// Attach a single pipe
  Pipeline<I, NewO> pipe<NewO>(Pipe<O, NewO> pipe) {
    return Pipeline<I, NewO>._fromStages(id, [..._stages, pipe]);
  }

  /// Gauged pipe attachment (conditional branching)
  Pipeline<I, NewO> gauge<NewO>(Pipe<O, NewO> Function(O current) selector) {
    final gaugedPipe = FunctionPipe<O, NewO>(
      id: 'gauged-${_stages.length}',
      fn: (O current) => selector(current).run(current),
    );
    return pipe(gaugedPipe);
  }

  /// Parallel pipes (concurrent processing of two branches)
  Pipeline<I, NewO> parallel<A, B, NewO>({
    required Pipe<O, A> aPipe,
    required Pipe<O, B> bPipe,
    required NewO Function(A a, B b) combinator,
  }) {
    final paralelPipe = FunctionPipe<O, NewO>(
      id: 'paralel-${_stages.length}',
      fn: (O input) async {
        final aFuture = aPipe.run(input);
        final bFuture = bPipe.run(input);
        return combinator(await aFuture, await bFuture);
      },
    );
    return pipe(paralelPipe);
  }

  /// Run pipeline for one item
  @override
  Future<O> execute(I input) async {
    dynamic current = input;
    for (final stage in _stages) {
      current = await stage.run(current);
    }
    return current as O;
  }
}

void main() async {
  final pipeline = Pipeline<String, String>('test')
      .pipe(
        FunctionPipe<String, double>(
          id: 'length',
          fn: (input) => input.length.toDouble(),
        ),
      )
      .pipe(
        FunctionPipe<double, double>(
          id: 'square',
          fn: (input) => input * 2,
        ),
      )
      .gauge(
        (current) => current < 10
            ? FunctionPipe<double, String>(
                id: 'short',
                fn: (n) => 'short $n',
              )
            : FunctionPipe<double, String>(
                id: 'long',
                fn: (n) => 'long $n',
              ),
      )
      .pipe(
        FunctionPipe<String, String>(
          id: 'final',
          fn: (input) => 'final result: $input',
        ),
      )..seal();

  // Listen to all stage events
  pipeline.stream.listen((event) {
    print('${event.pipeId}: ${event.type.name} ${event.progress}');
  });

  // Or run with concurrency control
  final pump = Pump(
    pipeline,
    maxConcurrent: 2,
  );

  print('Feeding jobs to pump...');

  final food = [
    'apple',
    'banana',
    'cherry',
    'date',
    'elderberry',
    'fig',
    'grape',
  ];

  for (final item in food) {
    print('$item >>');
    unawaited(
      pump.feed(item).then((result) {
        print('$item => $result');
      }),
    );
  }

  print('Feeding done, waiting for all to finish...');

  await pump.close();
}
