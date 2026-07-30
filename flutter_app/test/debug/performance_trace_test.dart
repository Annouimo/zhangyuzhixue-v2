import 'package:flutter_app/debug/performance_trace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final trace = PerformanceTrace.instance;

  setUp(() {
    trace
      ..setEnabled(true)
      ..clear()
      ..configureRun('test-run');
  });

  tearDown(() {
    trace
      ..clear()
      ..setEnabled(false);
  });

  test('records async spans and result metadata', () async {
    final result = await trace.measureAsync(
      'dao',
      'loadRows',
      () async => [1, 2, 3],
      resultMetadata: (rows) => {'rows': rows.length},
    );

    expect(result, [1, 2, 3]);
    final report = trace.report(runName: 'unit');
    expect(report['eventCount'], 1);
    final events = report['events']! as List<Object?>;
    final event = events.single! as Map<String, Object?>;
    expect(event['category'], 'dao');
    expect(event['name'], 'loadRows');
    expect(event['runId'], 'test-run');
    expect(event['spanId'], 1);
    expect(event['metadata'], {'rows': 3});
  });

  test('links nested async spans to their parent', () async {
    await trace.measureAsync('journey', 'openPage', () async {
      await trace.measureAsync('repository', 'loadPage', () async => 1);
    });

    final events = trace.report()['events']! as List<Object?>;
    final repository = events.cast<Map<String, Object?>>().singleWhere(
      (event) => event['category'] == 'repository',
    );
    final journey = events.cast<Map<String, Object?>>().singleWhere(
      (event) => event['category'] == 'journey',
    );
    expect(repository['parentSpanId'], journey['spanId']);
  });

  test('records row counts without row contents', () {
    trace.recordRows('questions', 42, metadata: {'scale': 'normal'});

    final events = trace.report()['events']! as List<Object?>;
    final event = events.single! as Map<String, Object?>;
    expect(event['category'], 'data');
    expect(event['metadata'], {'scale': 'normal', 'rows': 42});
  });

  test('records failed spans without swallowing the error', () async {
    await expectLater(
      trace.measureAsync<void>('repository', 'failure', () async {
        throw StateError('failed');
      }),
      throwsStateError,
    );

    final report = trace.report();
    final events = report['events']! as List<Object?>;
    final event = events.single! as Map<String, Object?>;
    expect(event['metadata'], {'failed': true, 'errorType': 'StateError'});
  });
}
