import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/scheduler.dart';

class PerformanceEvent {
  const PerformanceEvent({
    required this.runId,
    required this.spanId,
    required this.parentSpanId,
    required this.category,
    required this.name,
    required this.startedAt,
    required this.duration,
    required this.metadata,
  });

  final String runId;
  final int spanId;
  final int? parentSpanId;
  final String category;
  final String name;
  final DateTime startedAt;
  final Duration duration;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson({required Duration slowThreshold}) => {
    'runId': runId,
    'spanId': spanId,
    if (parentSpanId != null) 'parentSpanId': parentSpanId,
    'category': category,
    'name': name,
    'startedAt': startedAt.toIso8601String(),
    'durationMs': duration.inMicroseconds / 1000,
    'slow': duration >= slowThreshold,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

class PerformanceSpan {
  PerformanceSpan._(
    this._owner,
    this.category,
    this.name,
    this.startedAt,
    this._stopwatch,
    this._timelineTask,
    this._initialMetadata,
    this.spanId,
    this.parentSpanId,
  );

  final PerformanceTrace _owner;
  final String category;
  final String name;
  final DateTime startedAt;
  final Stopwatch _stopwatch;
  final developer.TimelineTask? _timelineTask;
  final Map<String, Object?> _initialMetadata;
  final int spanId;
  final int? parentSpanId;
  bool _finished = false;

  void finish([Map<String, Object?> metadata = const {}]) {
    if (_finished) return;
    _finished = true;
    _stopwatch.stop();
    _timelineTask?.finish(arguments: metadata);
    _owner._record(
      PerformanceEvent(
        runId: _owner.runId,
        spanId: spanId,
        parentSpanId: parentSpanId,
        category: category,
        name: name,
        startedAt: startedAt,
        duration: _stopwatch.elapsed,
        metadata: {..._initialMetadata, ...metadata},
      ),
    );
  }
}

class PerformanceTrace {
  PerformanceTrace._();

  static final PerformanceTrace instance = PerformanceTrace._();

  static const bool _enabledByBuild = bool.fromEnvironment(
    'PERFORMANCE_TRACE',
    defaultValue: false,
  );

  static const Duration slowThreshold = Duration(milliseconds: 100);
  static const int _maxEvents = 2000;

  final List<PerformanceEvent> _events = [];
  bool _enabled = _enabledByBuild;
  String _runId = 'unconfigured';
  int _nextSpanId = 1;

  static final Object _activeSpanZoneKey = Object();

  bool get enabled => _enabled;
  String get runId => _runId;

  void configureRun(String runId) {
    _runId = runId;
  }

  void setEnabled(bool value) => _enabled = value;

  void clear() {
    _events.clear();
    _nextSpanId = 1;
  }

  PerformanceSpan start(
    String category,
    String name, {
    Map<String, Object?> metadata = const {},
  }) {
    final spanId = _nextSpanId++;
    final parentSpanId = Zone.current[_activeSpanZoneKey] as int?;
    final stopwatch = Stopwatch()..start();
    developer.TimelineTask? task;
    if (_enabled) {
      task = developer.TimelineTask()
        ..start('$category.$name', arguments: metadata);
    }
    return PerformanceSpan._(
      this,
      category,
      name,
      DateTime.now(),
      stopwatch,
      task,
      metadata,
      spanId,
      parentSpanId,
    );
  }

  PerformanceSpan startAction(
    String name, {
    Map<String, Object?> metadata = const {},
  }) => start('action', name, metadata: metadata);

  PerformanceSpan startPage(
    String name, {
    Map<String, Object?> metadata = const {},
  }) => start('page', name, metadata: metadata);

  Future<T> measureAsync<T>(
    String category,
    String name,
    Future<T> Function() action, {
    Map<String, Object?> metadata = const {},
    Map<String, Object?> Function(T result)? resultMetadata,
  }) async {
    if (!_enabled) return action();
    final span = start(category, name, metadata: metadata);
    try {
      final result = await runZoned(
        action,
        zoneValues: {_activeSpanZoneKey: span.spanId},
      );
      span.finish(resultMetadata?.call(result) ?? const {});
      return result;
    } catch (error) {
      span.finish({'failed': true, 'errorType': error.runtimeType.toString()});
      rethrow;
    }
  }

  T measureSync<T>(
    String category,
    String name,
    T Function() action, {
    Map<String, Object?> metadata = const {},
    Map<String, Object?> Function(T result)? resultMetadata,
  }) {
    if (!_enabled) return action();
    final span = start(category, name, metadata: metadata);
    try {
      final result = runZoned(
        action,
        zoneValues: {_activeSpanZoneKey: span.spanId},
      );
      span.finish(resultMetadata?.call(result) ?? const {});
      return result;
    } catch (error) {
      span.finish({'failed': true, 'errorType': error.runtimeType.toString()});
      rethrow;
    }
  }

  Future<Duration> waitForNextFrame(
    String name, {
    Map<String, Object?> metadata = const {},
  }) async {
    if (!_enabled) return Duration.zero;
    final span = start('frame', name, metadata: metadata);
    final completer = Completer<Duration>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      span.finish();
      completer.complete(span._stopwatch.elapsed);
    });
    SchedulerBinding.instance.scheduleFrame();
    return completer.future;
  }

  Future<Duration> markContentReady(
    String page, {
    Map<String, Object?> metadata = const {},
  }) => waitForNextFrame('$page.contentReady', metadata: metadata);

  void recordRows(
    String operation,
    int rows, {
    Map<String, Object?> metadata = const {},
  }) {
    if (!_enabled) return;
    final span = start('data', operation, metadata: metadata);
    span.finish({'rows': rows});
  }

  Map<String, Object?> report({String? runName}) {
    final events = _events
        .map((event) => event.toJson(slowThreshold: slowThreshold))
        .toList(growable: false);
    final slowEvents = _events.where(
      (event) => event.duration >= slowThreshold,
    );
    return {
      'runName': runName,
      'runId': _runId,
      'generatedAt': DateTime.now().toIso8601String(),
      'slowThresholdMs': slowThreshold.inMilliseconds,
      'eventCount': events.length,
      'slowEventCount': slowEvents.length,
      'events': events,
    };
  }

  void _record(PerformanceEvent event) {
    if (!_enabled) return;
    _events.add(event);
    if (_events.length > _maxEvents) {
      _events.removeRange(0, _events.length - _maxEvents);
    }
  }
}
