import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_course/terminology.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Every term has an image and four distinct supported choices', () async {
    final terms =
        jsonDecode(await rootBundle.loadString('assets/terminology.json'))
            as List;
    expect(terms.length, 84);
    final ids = terms.map((t) => t['id']).toSet();
    expect(ids.length, 84);
    for (final term in terms) {
      final options = term['options'] as List;
      expect(options.length, 4);
      expect(options.map((o) => o['id']).toSet().length, 4);
      expect(options.where((o) => o['id'] == term['id']).length, 1);
      for (final option in options) {
        expect(ids.contains(option['id']), isTrue);
        expect((option['explanation'] as String).isNotEmpty, isTrue);
      }
      expect(
        (await rootBundle.load(term['image'])).lengthInBytes,
        greaterThan(100),
      );
    }
  });
  for (final width in [320.0, 414.0]) {
    testWidgets('Four answers, feedback, retry and saved progress at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 740);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = <String, dynamic>{};
      int saves = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: TerminologyPage(progress: state, onSave: () => saves++),
        ),
      );
      await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 200)); });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тренировка 1'));
      await tester.pumpAndSettle();
      expect(find.text('Вопрос 1 из 4'), findsOneWidget);
      final terms =
          jsonDecode((await tester.runAsync(() => rootBundle.loadString('assets/terminology.json')))!) as List;
      for (int n = 0; n < 4; n++) {
        final term = terms[n];
        final answer = n == 0 ? term['options'][1]['text'] : term['term'];
        final target = find.text(answer);
        await tester.scrollUntilVisible(target, 150);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.text(n == 0 ? 'Давай разберём' : 'Верно!'), findsOneWidget);
        if (n == 0) {
          expect(find.text(term['options'][1]['explanation']), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        expect(saves, n + 1);
        await tester.tap(find.text(n == 3 ? 'Показать результат' : 'Дальше'));
        await tester.pumpAndSettle();
      }
      expect(find.text('С первой попытки — 3 из 4.'), findsOneWidget);
      expect(state['total'], 4);
      final retry = find.text('Повторить ошибки · 1');
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('Вопрос 1 из 1'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Хозяйственное событие'), 150);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Хозяйственное событие'));
      await tester.pumpAndSettle();
      expect((state['termsV2'] as Map)['T01']['correct'], isTrue);
      expect((state['termsV2'] as Map)['T01']['attempts'], 2);
      expect(saves, 5);
      expect(tester.takeException(), isNull);
    });
  }
}
