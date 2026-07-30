import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/pop_back_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<bool> noRating(
    BuildContext context,
    String pageName,
    DateTime enteredAt,
  ) async => false;

  testWidgets('pops a guarded page when the router can pop', (tester) async {
    late BuildContext guardedContext;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/guarded',
          builder: (context, _) {
            guardedContext = context;
            return const Text('guarded');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/guarded');
    await tester.pumpAndSettle();

    await PopBackGuard(
      showExitRating: noRating,
    ).handlePop(guardedContext, 'test');
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('does nothing after the route was replaced', (tester) async {
    late BuildContext guardedContext;
    final router = GoRouter(
      initialLocation: '/guarded',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/guarded',
          builder: (context, _) {
            guardedContext = context;
            return const Text('guarded');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final guard = PopBackGuard(showExitRating: noRating);
    router.go('/');
    await tester.pumpAndSettle();
    await expectLater(guard.handlePop(guardedContext, 'test'), completes);

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('consumes repeated callbacks only once', (tester) async {
    late BuildContext context;
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const Text('page');
          },
        ),
      ),
    );
    final guard = PopBackGuard(
      showExitRating: (context, pageName, enteredAt) async {
        calls++;
        return false;
      },
    );

    expect(await guard.consume(context, 'test'), isTrue);
    expect(await guard.consume(context, 'test'), isFalse);
    expect(calls, 1);
  });
}
