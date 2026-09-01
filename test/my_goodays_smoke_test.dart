import 'package:cap_mobile/swapp/pages/goodays/my_goodays_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyGoodaysPage se rend sans overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MyGoodaysPage()));
    await tester.pumpAndSettle();

    expect(find.text('SWApp'), findsOneWidget);
    expect(find.text('4.51'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(find.text('ÉVOLUTION DU SCORE'), findsOneWidget);

    // Changement de période puis d'onglet.
    await tester.tap(find.text('Année'));
    await tester.pumpAndSettle();
    expect(find.text('4.39'), findsOneWidget);

    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();
    expect(find.text('ÉVOLUTION DES CLIENTS'), findsOneWidget);
  });
}
