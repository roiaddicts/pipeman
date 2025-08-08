import 'dart:async';

import 'package:pipeman/src/pipe.dart';

class Pipeline<I, O> extends Pipe<I, O> {
  Pipeline(super.id);

  Pipeline._fromStages(
    List<Pipe<dynamic, dynamic>> stages,
    String id,
  ) : super(id) {
    (stages.last as Pipe<dynamic, O>).stream.listen(emit);

    for (var i = 0; i < stages.length; i++) {
      final stage = stages[i];
      stage.stream.listen(
        (event) => setProgress((i + event.progress) / stages.length),
      );
    }
  }

  final List<Pipe<dynamic, dynamic>> _stages = [];

  /// Attach a single pipe
  Pipeline<I, NewO> attach<NewO>(Pipe<O, NewO> pipe) {
    return Pipeline<I, NewO>._fromStages([..._stages, pipe], id);
  }

  /// Gauged pipe attachment (conditional branching)
  Pipeline<I, NewO> gauged<NewO>(Pipe<O, NewO> Function(O current) selector) {
    final gaugedPipe = FunctionPipe<O, NewO>(
      id: 'gauged-${_stages.length}',
      fn: (O current) => selector(current).execute(current),
    );
    return attach(gaugedPipe);
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

  /// Run pipeline for many items
  Future<List<O>> runAll(List<I> inputs) async {
    final futures = inputs.map(execute).toList();
    return Future.wait(futures);
  }
}
