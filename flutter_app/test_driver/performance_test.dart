import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  await integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      final report = data ?? <String, dynamic>{};
      final repoRoot = Directory.current.parent;
      final outputDir = Directory(
        '${repoRoot.path}${Platform.pathSeparator}.hermes'
        '${Platform.pathSeparator}tmp${Platform.pathSeparator}performance',
      );
      await outputDir.create(recursive: true);
      final configuredBaseline = Platform.environment['PERFORMANCE_BASELINE'];
      final environment = report['environment'] as Map<String, dynamic>?;
      final dataScale =
          environment?['dataScale']?.toString().toLowerCase() ?? 'normal';
      final baselineFile = File(
        configuredBaseline?.isNotEmpty == true
            ? configuredBaseline!
            : '${repoRoot.path}${Platform.pathSeparator}performance'
                  '${Platform.pathSeparator}baselines${Platform.pathSeparator}'
                  '$dataScale.json',
      );
      Map<String, dynamic>? baseline;
      if (await baselineFile.exists()) {
        baseline =
            jsonDecode(await baselineFile.readAsString())
                as Map<String, dynamic>;
      }
      report['summary'] = _buildSummary(report, baseline: baseline);
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('.', '-');
      final jsonFile = File(
        '${outputDir.path}${Platform.pathSeparator}performance-$stamp.json',
      );
      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
      );
      final latestFile = File(
        '${outputDir.path}${Platform.pathSeparator}performance-latest.json',
      );
      await latestFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
      );
      final markdown = _buildMarkdown(report);
      await File(
        '${outputDir.path}${Platform.pathSeparator}performance-latest.md',
      ).writeAsString(markdown);
      final summary = report['summary'] as Map<String, dynamic>;
      if (report['failure'] != null) {
        throw StateError(
          'Performance journey failed: ${jsonEncode(report['failure'])}',
        );
      }
      if (summary['status'] == 'FAIL') {
        throw StateError('Performance thresholds failed; inspect $jsonFile');
      }
    },
  );
}

String _buildMarkdown(Map<String, dynamic> data) {
  final buffer = StringBuffer()
    ..writeln('# Flutter Performance Report')
    ..writeln()
    ..writeln('Generated: ${DateTime.now().toIso8601String()}')
    ..writeln();

  final environment = data['environment'] as Map<String, dynamic>?;
  if (environment != null) {
    buffer
      ..writeln('## Environment')
      ..writeln()
      ..writeln('| Metric | Value |')
      ..writeln('| --- | ---: |');
    for (final entry in environment.entries) {
      buffer.writeln('| ${entry.key} | ${entry.value} |');
    }
    buffer.writeln();
  }

  buffer
    ..writeln('## Frame Summaries')
    ..writeln()
    ..writeln(
      '| Journey | Total ms | Build P90 ms | Raster P90 ms | Slow | Severe | Baseline change | Status |',
    )
    ..writeln('| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |');
  final summary = data['summary'] as Map<String, dynamic>? ?? const {};
  final journeys = summary['journeys'] as List<dynamic>? ?? const [];
  for (final item in journeys.whereType<Map<String, dynamic>>()) {
    buffer.writeln(
      '| ${item['name']} | ${item['durationMs']} '
      '| ${item['buildP90Ms']} | ${item['rasterP90Ms']} '
      '| ${item['slowFrames']} | ${item['severeFrames']} '
      '| ${item['baselineChangePercent'] ?? '-'} | ${item['status']} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('Overall status: **${summary['status'] ?? 'NO_BASELINE'}**')
    ..writeln()
    ..writeln(
      'Thresholds: operation <= 1500ms, slow frame > 33ms, severe frame > 100ms, regression > 20%.',
    );

  final aggregates = summary['aggregates'] as List<dynamic>? ?? const [];
  if (aggregates.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Journey Aggregates')
      ..writeln()
      ..writeln(
        '| Journey | Cold ms | Hot median ms | Hot P90 ms | Hot worst ms |',
      )
      ..writeln('| --- | ---: | ---: | ---: | ---: |');
    for (final item in aggregates.whereType<Map<String, dynamic>>()) {
      buffer.writeln(
        '| ${item['name']} | ${item['coldMs'] ?? '-'} '
        '| ${item['hotMedianMs'] ?? '-'} | ${item['hotP90Ms'] ?? '-'} '
        '| ${item['hotWorstMs'] ?? '-'} |',
      );
    }
  }

  final trace = data['trace'] as Map<String, dynamic>?;
  final events = trace?['events'] as List<dynamic>? ?? const [];
  final sorted = events.whereType<Map<String, dynamic>>().toList()
    ..sort(
      (a, b) => ((b['durationMs'] as num?) ?? 0).compareTo(
        (a['durationMs'] as num?) ?? 0,
      ),
    );
  buffer
    ..writeln()
    ..writeln('## Slowest Operations')
    ..writeln()
    ..writeln('| Category | Operation | Duration ms | Metadata |')
    ..writeln('| --- | --- | ---: | --- |');
  for (final event in sorted.take(20)) {
    buffer.writeln(
      '| ${event['category']} | ${event['name']} | ${event['durationMs']} '
      '| `${jsonEncode(event['metadata'] ?? const {})}` |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Slowest Timeline Events')
    ..writeln()
    ..writeln('| Timeline | Event | Category | Duration ms |')
    ..writeln('| --- | --- | --- | ---: |');
  final timelineEvents = <Map<String, Object?>>[];
  for (final entry in data.entries.where(
    (entry) => entry.key.startsWith('timeline_'),
  )) {
    final timeline = entry.value as Map<String, dynamic>? ?? const {};
    final events = timeline['traceEvents'] as List<dynamic>? ?? const [];
    for (final event in _timelineDurations(events)) {
      final durationMicros = event.durationMicros;
      if (durationMicros < 1000) continue;
      timelineEvents.add({
        'timeline': entry.key,
        'name': event.name,
        'category': event.category,
        'durationMs': durationMicros / 1000,
      });
    }
  }
  timelineEvents.sort(
    (a, b) => ((b['durationMs'] as num?) ?? 0).compareTo(
      (a['durationMs'] as num?) ?? 0,
    ),
  );
  for (final event in timelineEvents.take(30)) {
    buffer.writeln(
      '| ${event['timeline']} | ${event['name']} | ${event['category']} '
      '| ${event['durationMs']} |',
    );
  }
  return buffer.toString();
}

Map<String, dynamic> _buildSummary(
  Map<String, dynamic> data, {
  Map<String, dynamic>? baseline,
}) {
  final durations = _journeyDurations(data);
  final baselineDurations = baseline == null
      ? const <String, double>{}
      : _journeyDurations(baseline);
  final journeys = <Map<String, dynamic>>[];
  var failed = false;
  for (final entry in data.entries.where(
    (entry) => entry.key.startsWith('frames_'),
  )) {
    final frames = entry.value as Map<String, dynamic>? ?? const {};
    final duration = durations[entry.key];
    final baselineDuration = baselineDurations[entry.key];
    final change =
        duration != null && baselineDuration != null && baselineDuration > 0
        ? ((duration - baselineDuration) / baselineDuration) * 100
        : null;
    final durationFailure = duration != null && duration > 1500;
    final regressionFailure = change != null && change > 20;
    final status = durationFailure || regressionFailure ? 'FAIL' : 'PASS';
    if (status == 'FAIL') failed = true;
    journeys.add({
      'name': entry.key,
      'durationMs': duration == null ? null : _round(duration),
      'buildP90Ms': _number(frames['90th_percentile_frame_build_time_millis']),
      'rasterP90Ms': _number(
        frames['90th_percentile_frame_rasterizer_time_millis'],
      ),
      'worstFrameMs': _number(frames['worst_frame_total_time_millis']),
      'slowFrames': frames['slow_frame_count'] ?? 0,
      'severeFrames': frames['severe_frame_count'] ?? 0,
      'baselineMs': baselineDuration == null ? null : _round(baselineDuration),
      'baselineChangePercent': change == null ? null : _round(change),
      'status': status,
      if (durationFailure) 'failureReason': 'operation_over_1500ms',
      if (regressionFailure)
        'regressionReason': 'baseline_regression_over_20_percent',
    });
  }
  return {
    'status': failed ? 'FAIL' : (baseline == null ? 'NO_BASELINE' : 'PASS'),
    'baselineLoaded': baseline != null,
    'thresholds': {
      'operationFailureMs': 1500,
      'slowFrameMs': 33,
      'severeFrameMs': 100,
      'regressionPercent': 20,
    },
    'journeys': journeys,
    'aggregates': _aggregateJourneys(journeys),
  };
}

List<Map<String, dynamic>> _aggregateJourneys(
  List<Map<String, dynamic>> journeys,
) {
  final groups = <String, List<Map<String, dynamic>>>{};
  final variantPattern = RegExp(r'_(cold|hot_\d+)$');
  for (final journey in journeys) {
    final name = journey['name'].toString();
    final logicalName = name.replaceFirst(variantPattern, '');
    groups.putIfAbsent(logicalName, () => []).add(journey);
  }
  return groups.entries.map((entry) {
    final cold = entry.value
        .where((item) => item['name'].toString().endsWith('_cold'))
        .map((item) => item['durationMs'] as num?)
        .whereType<num>()
        .map((value) => value.toDouble())
        .firstOrNull;
    final hot =
        entry.value
            .where(
              (item) => RegExp(r'_hot_\d+$').hasMatch(item['name'].toString()),
            )
            .map((item) => item['durationMs'] as num?)
            .whereType<num>()
            .map((value) => value.toDouble())
            .toList()
          ..sort();
    return {
      'name': entry.key,
      'coldMs': cold,
      'hotMedianMs': hot.isEmpty ? null : _round(_percentileValue(hot, 0.5)),
      'hotP90Ms': hot.isEmpty ? null : _round(_percentileValue(hot, 0.9)),
      'hotWorstMs': hot.isEmpty ? null : _round(hot.last),
    };
  }).toList();
}

double _percentileValue(List<double> sorted, double percentile) {
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index];
}

Map<String, double> _journeyDurations(Map<String, dynamic> data) {
  final baselineJourneys = data['journeys'];
  if (baselineJourneys is Map<String, dynamic>) {
    return {
      for (final entry in baselineJourneys.entries)
        entry.key: ((entry.value as Map<String, dynamic>)['durationMs'] as num)
            .toDouble(),
    };
  }
  final trace = data['trace'] as Map<String, dynamic>?;
  final events = trace?['events'] as List<dynamic>? ?? const [];
  return {
    for (final event in events.whereType<Map<String, dynamic>>().where(
      (event) => event['category'] == 'journey',
    ))
      event['name'].toString(): ((event['durationMs'] as num?) ?? 0).toDouble(),
  };
}

double? _number(Object? value) =>
    value is num ? _round(value.toDouble()) : null;

double _round(double value) => (value * 100).round() / 100;

Iterable<_TimelineDuration> _timelineDurations(List<dynamic> rawEvents) sync* {
  final stacks = <String, List<Map<String, dynamic>>>{};
  for (final event in rawEvents.whereType<Map<String, dynamic>>()) {
    final phase = event['ph'];
    final duration = event['dur'] as num?;
    if (duration != null) {
      yield _TimelineDuration(
        name: event['name']?.toString() ?? '-',
        category: event['cat']?.toString() ?? '-',
        durationMicros: duration.toDouble(),
      );
      continue;
    }

    final processId = event['pid'];
    final threadId = event['tid'];
    final key = '$processId:$threadId';
    if (phase == 'B') {
      (stacks[key] ??= []).add(event);
      continue;
    }
    if (phase != 'E') continue;

    final stack = stacks[key];
    if (stack == null || stack.isEmpty) continue;
    final begin = stack.removeLast();
    final startedAt = begin['ts'] as num?;
    final finishedAt = event['ts'] as num?;
    if (startedAt == null || finishedAt == null || finishedAt < startedAt) {
      continue;
    }
    yield _TimelineDuration(
      name: begin['name']?.toString() ?? '-',
      category: begin['cat']?.toString() ?? '-',
      durationMicros: (finishedAt - startedAt).toDouble(),
    );
  }
}

class _TimelineDuration {
  const _TimelineDuration({
    required this.name,
    required this.category,
    required this.durationMicros,
  });

  final String name;
  final String category;
  final double durationMicros;
}
