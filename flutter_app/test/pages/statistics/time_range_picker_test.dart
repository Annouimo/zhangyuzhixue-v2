import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/statistics/widgets/time_range_picker.dart';

void main() {
  group('TimeRangePicker', () {
    testWidgets('renders 5 pills with default selected', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: TimeRangePicker(valueDays: 7, onChanged: (_) {}))));
      expect(find.text('近一周'), findsOneWidget);
      expect(find.text('近一月'), findsOneWidget);
      expect(find.text('近三月'), findsOneWidget);
      expect(find.text('近一年'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      int? result;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: TimeRangePicker(valueDays: 7, onChanged: (v) => result = v))));
      await tester.tap(find.text('近一月'));
      expect(result, 30);
    });
  });
}
