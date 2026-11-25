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

  testWidgets('Receiving exercise explains the answer using its receipt', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(414, 768);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: course.Course({
      'lessons':[{'title':'Зачем заводу 1С'}],
      'terms':[['Партия подшипников','Что открыть?','Документ поступления','Отчёт','Справочник','Каждая поставка — свой документ.']],
      'termCards':[['Приёмка на склад','Деталь','Подшипник 6205','Принято','40 шт.']]
    },{})));
    await tester.tap(find.text('Игры'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Терминология'));
    await tester.pumpAndSettle();
    expect(find.text('40 шт.'), findsOneWidget);
    await tester.ensureVisible(find.text('Отчёт'));
    await tester.tap(find.text('Отчёт'));
    await tester.pumpAndSettle();
    expect(find.text('Твой ответ — Отчёт'),findsOneWidget);
    expect(find.text('Документ поступления'),findsOneWidget);
    expect(find.text('Ещё задание').hitTestable(),findsOneWidget);
    await tester.tap(find.text('Ещё задание'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Документ поступления'));
    await tester.tap(find.text('Документ поступления'));
    await tester.pumpAndSettle();
    expect(find.text('Верно!'),findsOneWidget);
    expect(find.text('Документ поступления'),findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
