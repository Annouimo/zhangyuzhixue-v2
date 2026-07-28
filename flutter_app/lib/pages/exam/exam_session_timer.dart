import 'dart:async';
import 'package:flutter/material.dart';

class ExamSessionTimer extends ChangeNotifier {
  ExamSessionTimer._();

  static final ExamSessionTimer instance = ExamSessionTimer._();

  Timer? _ticker;
  DateTime? _startedAt;
  int? examId;

  bool get isRunning => _startedAt != null;
  Duration get elapsed => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);

  void start(int id) {
    _ticker?.cancel();
    examId = id;
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
    notifyListeners();
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    examId = null;
    notifyListeners();
  }

  String get formatted {
    final value = elapsed;
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class ExamTimerAction extends StatelessWidget {
  const ExamTimerAction({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ExamSessionTimer.instance,
      builder: (context, _) {
        if (!ExamSessionTimer.instance.isRunning) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Tooltip(
              message: '本次试卷用时',
              child: Text(
                ExamSessionTimer.instance.formatted,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
