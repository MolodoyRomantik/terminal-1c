import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_course/main.dart' as course;

void main() {
  for (final size in [const Size(414, 768), const Size(320, 568)]) {
    testWidgets('Home content stays above tabs at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: course.Course({
        'lessons': [{'title': 'Зачем заводу 1С'}],
      }, {})));
      await tester.pumpAndSettle();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final bar = tester.getRect(find.byWidget(scaffold.bottomNavigationBar!));
      expect(bar.height, lessThan(100));
      expect(bar.bottom, size.height);
      expect(tester.getRect(find.text('Начать урок')).bottom, lessThan(bar.top));
      await tester.tap(find.text('Игры'));
      await tester.pumpAndSettle();
      expect(find.text('Игровая мастерская').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
