import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imovio/src/constants/app_theme.dart';

void main() {
  Future<void> openSecondPage(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          for (final p in TargetPlatform.values)
            p: const SwipeBackPageTransitionsBuilder(),
        }),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('segunda')),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('segunda'), findsOneWidget);
  }

  testWidgets('deslizar a meio do ecrã para a direita volta atrás',
      (tester) async {
    await openSecondPage(tester);
    await tester.dragFrom(const Offset(300, 300), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('segunda'), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('deslizar para a esquerda não volta atrás', (tester) async {
    await openSecondPage(tester);
    await tester.dragFrom(const Offset(500, 300), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('segunda'), findsOneWidget);
  });

  testWidgets('um toque continua a funcionar na página', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          for (final p in TargetPlatform.values)
            p: const SwipeBackPageTransitionsBuilder(),
        }),
      ),
      home: Scaffold(
        body: Center(
          child: TextButton(onPressed: () => taps++, child: const Text('x')),
        ),
      ),
    ));
    await tester.tap(find.text('x'));
    expect(taps, 1);
  });
}
