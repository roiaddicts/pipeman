# Pipeman

**Pipeman** is a type-safe, event-driven pipeline framework for Dart that makes it easy to compose and run complex data-processing flows — from simple transformations to fully concurrent, multi-stage jobs.

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

---

## ✨ Features

- **Strongly-typed chaining** – each `Pipe<I, O>` enforces matching input/output types at compile-time.
- **Composable stages** – attach single pipes, multiple pipes, or even other pipelines.
- **Event visibility** – unified stream of `queued`, `skipped`, `processing`, `success`, and `failed` events from every stage.
- **Sync or async transforms** – works equally well for CPU-bound or I/O-bound stages.
- **Concurrency control** – with `Pump`, feed the pipeline jobs at a controlled rate and process multiple items in parallel.
- **Gauged branching** – dynamically choose the next pipe based on live data.

---

## 🚀 Quick Start

```dart
import 'package:pipeman/pipeman.dart';

void main() async {
  final pipeline = Pipeline<String, String>(id: 'root', maxConcurrent: 20)
    .attach(FunctionPipe<String, int>(id: 'len', fn: (s) => s.length))
    .attach(FunctionPipe<int, double>(id: 'half', fn: (n) => n / 2))
    .gauged((current) {
      if (current < 5) {
        return FunctionPipe<double, String>(
          id: 'short',
          fn: (n) => 'short $n',
        );
      }
      return FunctionPipe<double, String>(
        id: 'long',
        fn: (n) => 'long $n',
      );
    });

  // Listen to all stage events
  pipeline.events.listen((event) {
    print('${event.pipeId}: ${event.type} ${event.progress ?? ''}');
  });

  // Run a batch at once
  final results = await pipeline.runAll(['hello', 'world']);
  print(results); // ["short 2.5", "short 2.5"]

  // Or run with concurrency control
  final pump = Pump(pipeline, maxConcurrent: 4);
  pump.feed('hello');
  pump.feed('world');
  await pump.close();
}
```

---

## Installation 💻

**❗ In order to start using Pipeman you must have the [Dart SDK][dart_install_link] installed on your machine.**

Install via `dart pub add`:

```sh
dart pub add pipeman
```

---

## Continuous Integration 🤖

Pipeman comes with a built-in [GitHub Actions workflow][github_actions_link] powered by [Very Good Workflows][very_good_workflows_link] but you can also add your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes. The project uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis options used by our team. Code coverage is enforced using the [Very Good Workflows][very_good_coverage_link].

---

## Running Tests 🧪

To run all unit tests:

```sh
dart pub global activate coverage 1.2.0
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

[dart_install_link]: https://dart.dev/get-dart
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[mason_link]: https://github.com/felangel/mason
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
