import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@JS('localStorage.getItem')
external JSString? readValue(JSString key);
@JS('localStorage.setItem')
external void writeValue(JSString key, JSString value);

const key = 'terminal-course-v1';
const orange = Color(0xfff58243),
    ink = Color(0xff17333b),
    paper = Color(0xfff4f7f8);
const mods = [
  'Знакомство с 1С',
  'Устройство базы',
  'Встроенный язык',
  'Формы и отладка',
  'Складской учёт',
  'Запросы к данным',
  'Отчёты и обработки',
  'Чужая конфигурация',
  'Будни разработчика',
  'Выпускная работа',
];
const ends = [6, 12, 20, 26, 33, 40, 45, 51, 57, 60];
const steps = ['Разбор', 'Тетрадь', 'Практика', 'Проверка'];
const games = ['Терминология', 'Складской счёт', 'Поиск ошибки', 'Собери код'];
const gameIcons = [
  Icons.style_outlined,
  Icons.inventory_2_outlined,
  Icons.bug_report_outlined,
  Icons.code,
];
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = jsonDecode(await rootBundle.loadString('assets/course.json'));
  Map state = {};
  try {
    state = jsonDecode(readValue(key.toJS)?.toDart ?? '{}');
  } catch (_) {}
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Терминал 1С',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: orange, surface: paper),
        scaffoldBackgroundColor: paper,
      ),
      home: Course(data, state),
    ),
  );
}

class Course extends StatefulWidget {
  final Map data, state;
  const Course(this.data, this.state, {super.key});
  @override
  State<Course> createState() => _CourseState();
}

class _CourseState extends State<Course> {
  Map get st => widget.state;
  List get lessons => widget.data['lessons'];
  int tab = 0, module = 0, stage = 0, mode = 0;
  String screen = 'home', feedback = '', prompt = '', right = '', reason = '';
  List<String> options = [], ordered = [], selected = [];
  bool graded = false;
  int get i => (st['at'] as int? ?? 0).clamp(0, 59);
  Map get current => lessons[i];
  Map marks(String field) => st.putIfAbsent(field, () => {});
  bool checked(String field, int n) => marks(field)['$n'] == true;
  int get completed => List.generate(
    60,
    (n) => n,
  ).where((n) => checked('pc', n) && checked('quiz', n)).length;
  void save() {
    try {
      writeValue(key.toJS, jsonEncode(st).toJS);
    } catch (_) {}
  }

  void edit(VoidCallback f) {
    setState(f);
    save();
  }

  void open(int n) {
    edit(() {
      st['at'] = n;
      stage = ((marks('step')['$n'] as int? ?? 1) - 1).clamp(0, 3);
      feedback = '';
      screen = 'lesson';
    });
  }

  void move(int s) {
    edit(() {
      stage = s;
      marks('step')['$i'] = s + 1;
      feedback = '';
    });
  }

  void back() {
    setState(() {
      if (screen == 'lesson' && stage > 0) {
        move(stage - 1);
      } else {
        screen = 'home';
      }
    });
  }

  Widget title(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 31,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.4,
    ),
  );
  Widget label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xff53666a),
    ),
  );
  Widget gap([double n = 16]) => SizedBox(height: n);
  Widget action(String t, VoidCallback? fn) => FilledButton(
    onPressed: fn,
    style: FilledButton.styleFrom(
      backgroundColor: orange,
      foregroundColor: ink,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Text(
      t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );
  Widget tile(IconData icon, String t, VoidCallback fn, {String? sub}) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xffe5eff0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: ink, size: 21),
      ),
      title: Text(t),
      subtitle: sub == null ? null : Text(sub),
      trailing: const Icon(Icons.chevron_right),
      onTap: fn,
    ),
  );
  Widget list(List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: children,
  );
  Widget home() {
    final m = ends.indexWhere((end) => i < end);
    return list([
      title('Мой путь'),
      gap(20),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory_rounded, color: orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mods[m],
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const Text(
                  '1С',
                  style: TextStyle(
                    color: orange,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            gap(14),
            const WinterPostcard(),
            gap(18),
            Text(
              'УРОК ${i + 1} / 60',
              style: const TextStyle(
                color: orange,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            gap(8),
            Text(
              current['title'],
              style: const TextStyle(
                fontSize: 29,
                height: 1.1,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            gap(22),
            action(
              st.containsKey('at') ? 'Продолжить урок' : 'Начать урок',
              () => open(i),
            ),
          ],
        ),
      ),
      gap(20),
      Row(
        children: [
          Expanded(child: label('Пройдено уроков')),
          Text('$completed / 60'),
        ],
      ),
      gap(8),
      LinearProgressIndicator(
        value: completed / 60,
        color: orange,
        backgroundColor: const Color(0xffdfdfd7),
        minHeight: 6,
        borderRadius: BorderRadius.circular(8),
      ),
      gap(22),
      tile(
        Icons.library_books_outlined,
        'Программа курса',
        () {
          setState(() {
            module = m;
            screen = 'catalog';
          });
        },
        sub: '10 модулей · 60 уроков',
      ),
      gap(8),
      tile(
        Icons.route_outlined,
        'Маршрут детали',
        launchBoard,
        sub: 'Головоломка мастерской',
      ),
    ]);
  }

  Widget catalog() {
    final start = module == 0 ? 0 : ends[module - 1];
    return list([
      title('Программа'),
      gap(),
      DropdownButton<int>(
        isExpanded: true,
        value: module,
        items: [
          for (int n = 0; n < mods.length; n++)
            DropdownMenuItem(value: n, child: Text('${n + 1}. ${mods[n]}')),
        ],
        onChanged: (v) => setState(() => module = v!),
      ),
      gap(),
      for (int n = start; n < ends[module]; n++)
        tile(
          checked('quiz', n) && checked('pc', n)
              ? Icons.check_circle
              : Icons.article_outlined,
          lessons[n]['title'],
          () => open(n),
          sub: 'Урок ${n + 1}',
        ),
    ]);
  }

  Future<void> chooseStage() async {
    final n = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int n = 0; n < steps.length; n++)
              ListTile(
                leading: Icon(stepIcons[n]),
                title: Text(steps[n]),
                trailing: n == stage ? const Icon(Icons.check_circle) : null,
                onTap: () => Navigator.pop(ctx, n),
              ),
          ],
        ),
      ),
    );
    if (n != null && mounted) move(n);
  }

  static const stepIcons = [
    Icons.chrome_reader_mode_outlined,
    Icons.edit_note_rounded,
    Icons.computer_rounded,
    Icons.task_alt_rounded,
  ];
  Widget lesson() {
    final field = ['theory', 'note', 'practice', 'question'][stage];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              for (int n = 0; n < 4; n++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: n <= stage ? orange : const Color(0xffe3e8e9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: list([
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: chooseStage,
                icon: Icon(stepIcons[stage], size: 18),
                label: Text('${steps[stage]}  ·  ${stage + 1} из 4  ⌄'),
              ),
            ),
            gap(8),
            title(current['title']),
            gap(24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xffe3e8e9)),
              ),
              child: SelectableText(
                current[field],
                style: TextStyle(
                  fontSize: 18,
                  height: 1.54,
                  color: ink,
                  fontFamily:
                      stage == 1 && current[field].toString().contains(';')
                      ? 'monospace'
                      : null,
                ),
              ),
            ),
            if (stage == 2)
              CheckboxListTile(
                title: const Text('Выполнил в 1С'),
                value: checked('pc', i),
                onChanged: (v) => edit(() => marks('pc')['$i'] = v),
              ),
            if (stage == 3) ...[
              gap(),
              for (int n = 0; n < current['choices'].length; n++)
                tile(
                  Icons.radio_button_unchecked,
                  current['choices'][n],
                  () => edit(() {
                    final ok = n == current['answer'];
                    feedback = ok ? 'Верно!' : 'Попробуй ещё раз';
                    if (ok) marks('quiz')['$i'] = true;
                  }),
                ),
              Semantics(
                liveRegion: true,
                child: Text(
                  feedback.isEmpty && checked('quiz', i)
                      ? 'Проверка пройдена'
                      : feedback,
                ),
              ),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: action(
            [
              'Перейти к записи',
              'Открыть практику',
              'Проверить себя',
              i < 59 ? 'Следующий урок' : 'Завершить',
            ][stage],
            () {
              if (stage < 3) {
                move(stage + 1);
              } else if (i < 59) {
                open(i + 1);
              } else {
                setState(() {
                  screen = 'home';
                  tab = 2;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  void round(int n) {
    mode = n;
    screen = 'round';
    graded = false;
    feedback = '';
    selected = [];
    final r = Random();
    if (n == 1) {
      final a = 10 + r.nextInt(35), b = 1 + r.nextInt(12), c = 1 + r.nextInt(8);
      prompt =
          'В начале смены было $a деталей. Приняли $b, выдали $c. Сколько осталось?';
      right = '${a + b - c}';
      options = [right, '${a + b}', '${a + b + c}'];
      reason = '$a + $b − $c = $right';
    } else {
      final pool =
          widget.data[n == 0
                  ? 'terms'
                  : n == 2
                  ? 'bugs'
                  : 'ordering']
              as List;
      final row = pool[r.nextInt(pool.length)] as List;
      prompt = '${row[0]}\n\n${row[1]}';
      reason = row.last;
      if (n == 3) {
        ordered = List<String>.from(row[2]);
        options = [...ordered];
      } else {
        final pos = n == 0 ? 2 : 3;
        if (n == 2) prompt += '\n\n${row[2]}';
        right = row[pos];
        options = List<String>.from(row.sublist(pos, pos + 3));
      }
    }
    options.shuffle(r);
    if (n == 3 && options.join() == ordered.join()) {
      options.add(options.removeAt(0));
    }
    setState(() {});
  }

  void grade(bool ok) {
    if (graded) return;
    edit(() {
      graded = true;
      feedback = ok ? 'Верно!' : 'Разбор ответа';
      st['total'] = (st['total'] ?? 0) + 1;
      if (ok) st['good'] = (st['good'] ?? 0) + 1;
    });
  }

  void launchBoard() {
    setState(() {
      tab = 1;
      screen = 'board';
    });
  }

  Widget gameHome() => list([
    title('Игровая мастерская'),
    gap(),
    RouteCover(onTap: launchBoard),
    gap(24),
    label('Тренажёры'),
    gap(8),
    for (int n = 0; n < games.length; n++)
      tile(
        gameIcons[n],
        games[n],
        () => round(n),
        sub: [
          'Вспомнить слово',
          'Посчитать остаток',
          'Исправить код',
          'Расставить строки',
        ][n],
      ),
  ]);
  Widget gameRound() => list([
    label(games[mode]),
    gap(),
    SelectableText(prompt, style: const TextStyle(fontSize: 20, height: 1.4)),
    gap(),
    if (mode == 3) ...[
      for (final line in selected)
        ListTile(
          title: Text(line),
          onTap: graded ? null : () => setState(() => selected.remove(line)),
        ),
      for (final line in options.where((s) => !selected.contains(s)))
        tile(Icons.add, line, () => setState(() => selected.add(line))),
      if (!graded)
        action(
          'Проверить',
          selected.length != ordered.length
              ? null
              : () => grade(selected.join('\n') == ordered.join('\n')),
        ),
    ] else if (!graded)
      for (final answer in options)
        tile(
          Icons.radio_button_unchecked,
          answer,
          () => grade(answer == right),
        ),
    if (graded) ...[
      title(feedback),
      gap(),
      Text(reason),
      if (mode == 3) SelectableText(ordered.join('\n')),
      gap(),
      action('Ещё задание', () => round(mode)),
    ],
  ]);
  Widget stats() => list([
    title('Прогресс'),
    gap(20),
    LinearProgressIndicator(
      value: completed / 60,
      minHeight: 8,
      borderRadius: BorderRadius.circular(8),
      color: orange,
      backgroundColor: const Color(0xffdbe5e7),
    ),
    gap(),
    for (final pair in [
      ['Завершено уроков', '$completed / 60'],
      [
        'Практика в 1С',
        '${marks('pc').values.where((v) => v == true).length} / 60',
      ],
      [
        'Проверки уроков',
        '${marks('quiz').values.where((v) => v == true).length} / 60',
      ],
      ['Верные ответы в играх', "${st['good'] ?? 0} / ${st['total'] ?? 0}"],
    ])
      Card(
        elevation: 0,
        color: Colors.white,
        child: ListTile(title: Text(pair[0]), trailing: Text(pair[1])),
      ),
    gap(),
    label('Прогресс сохраняется на этом устройстве.'),
  ]);
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: screen == 'home',
      onPopInvokedWithResult: (p, _) {
        if (!p) back();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: paper,
          leading: screen == 'home'
              ? null
              : IconButton(onPressed: back, icon: const Icon(Icons.arrow_back)),
          title: Text(
            screen == 'lesson' ? 'Урок ${i + 1} из 60' : 'Терминал 1С',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 170),
                child: KeyedSubtree(
                  key: ValueKey('$screen-$tab-$stage-$i'),
                  child: switch (screen) {
                    'lesson' => lesson(),
                    'catalog' => catalog(),
                    'round' => gameRound(),
                    'board' => RouteBoard(memory: st, persist: save),
                    _ => [home, gameHome, stats][tab](),
                  },
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: screen != 'home'
            ? null
            : NavigationBar(
                height: 66,
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xffd3e8e9),
                selectedIndex: tab,
                onDestinationSelected: (v) => setState(() => tab = v),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.auto_stories_outlined),
                    selectedIcon: Icon(Icons.auto_stories),
                    label: 'Путь',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sports_esports_outlined),
                    selectedIcon: Icon(Icons.sports_esports),
                    label: 'Игры',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_rounded),
                    label: 'Прогресс',
                  ),
                ],
              ),
      ),
    );
  }
}

/// A two-colour industrial skyline, drawn in the proportions of a postal print.
class WinterPostcard extends StatelessWidget {
  const WinterPostcard({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label:
        'Зимняя открытка: вечерний завод, заснеженные ели и трамвай с огоньками',
    child: AspectRatio(
      aspectRatio: 2.65,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: CustomPaint(painter: WinterPrint()),
      ),
    ),
  );
}

class WinterPrint extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 440, size.height / 166);
    const night = Color(0xff24545a), distance = Color(0xff628581);
    const spruce = Color(0xff163e40), snow = Color(0xfff3e9ce);
    const shadow = Color(0xffacc8ba), amber = Color(0xffffb56f);
    const rust = Color(0xffd46b40);
    final brush = Paint()..isAntiAlias = true;
    void box(double x, double y, double w, double h, Color c) {
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), brush..color = c);
    }

    void dot(double x, double y, double r, Color c) {
      canvas.drawCircle(Offset(x, y), r, brush..color = c);
    }

    void line(double x, double y, double u, double v, double w, Color c) {
      canvas.drawLine(
        Offset(x, y),
        Offset(u, v),
        brush
          ..color = c
          ..strokeWidth = w,
      );
    }

    void shape(List<double> xy, Color c) {
      final p = Path()..moveTo(xy[0], xy[1]);
      for (int i = 2; i < xy.length; i += 2) {
        p.lineTo(xy[i], xy[i + 1]);
      }
      canvas.drawPath(p..close(), brush..color = c);
    }

    void pine(double x, double y, double h) {
      box(x - h * .035, y - h * .55, h * .07, h * .55, spruce);
      for (var j = 0; j < 3; j++) {
        final top = y - h + j * h * .19, half = h * (.12 + j * .045);
        shape([
          x,
          top,
          x - half,
          top + h * .43,
          x + half,
          top + h * .43,
        ], spruce);
        shape([
          x,
          top,
          x - half * .55,
          top + h * .22,
          x - 1,
          top + h * .17,
          x + half * .42,
          top + h * .2,
        ], snow);
      }
    }

    box(0, 0, 440, 166, night);
    dot(321, 42, 24, snow);
    final rng = Random(26);
    for (int n = 0; n < 110; n++) {
      dot(
        rng.nextDouble() * 440,
        rng.nextDouble() * 132,
        .45 + rng.nextDouble() * .95,
        shadow,
      );
    }
    for (final star in [
      const Offset(56, 36),
      const Offset(224, 38),
      const Offset(372, 25),
    ]) {
      final x = star.dx, y = star.dy;
      shape([
        x,
        y - 5,
        x + 1,
        y - 1,
        x + 4,
        y,
        x + 1,
        y + 1,
        x,
        y + 5,
        x - 1,
        y + 1,
        x - 4,
        y,
        x - 1,
        y - 1,
      ], snow);
    }
    shape([
      0,
      103,
      48,
      87,
      86,
      95,
      153,
      81,
      208,
      96,
      287,
      83,
      341,
      92,
      392,
      81,
      440,
      90,
      440,
      135,
      0,
      135,
    ], distance);
    for (final x in [86.0, 111.0]) {
      shape([x, 96, x + 2, 49, x + 8, 49, x + 10, 96], spruce);
      box(x + 1, 48, 8, 3, snow);
      for (int j = 0; j < 4; j++) {
        dot(x + 8 + j * 6, 44 - j * 3, 2.5 + j * .6, distance);
      }
    }
    shape([
      49,
      117,
      49,
      86,
      70,
      78,
      70,
      86,
      92,
      78,
      92,
      86,
      114,
      78,
      114,
      86,
      139,
      78,
      139,
      117,
    ], spruce);
    for (int k = 0; k < 4; k++) {
      line(49 + k * 22, 86, 69 + k * 22, 78, 2, snow);
    }
    for (int j = 0; j < 10; j++) {
      box(54 + j * 8, 96, 4, 6, j % 3 == 0 ? shadow : amber);
    }
    shape([
      0,
      120,
      63,
      110,
      132,
      114,
      207,
      104,
      296,
      111,
      362,
      99,
      440,
      107,
      440,
      166,
      0,
      166,
    ], shadow);
    pine(24, 129, 66);
    pine(40, 123, 42);
    pine(369, 117, 55);
    pine(398, 128, 85);
    pine(425, 129, 60);
    shape([
      0,
      135,
      66,
      124,
      151,
      131,
      249,
      119,
      317,
      126,
      387,
      118,
      440,
      129,
      440,
      166,
      0,
      166,
    ], snow);
    for (int j = 0; j < 4; j++) {
      line(
        20 + j * 57,
        144 + j % 2 * 4,
        41 + j * 57,
        143 + j % 2 * 4,
        .85,
        shadow,
      );
    }
    line(0, 158, 440, 130, 1.4, distance);
    canvas.save();
    canvas.translate(216, 133);
    canvas.rotate(-.06);
    dot(9, 7, 4, spruce);
    dot(68, 7, 4, spruce);
    shape([0, 5, 0, -13, 5, -20, 68, -20, 77, -12, 78, 5], rust);
    box(5, -18, 62, 2, snow);
    for (int j = 0; j < 8; j++) {
      box(5 + j * 8, -14, 6, 9, amber);
    }
    box(1, -2, 75, 2, snow);
    dot(75, 1, 2, amber);
    line(42, -21, 49, -32, 1.5, spruce);
    line(49, -32, 38, -36, 1.5, spruce);
    canvas.restore();
    final wire = Path()
      ..moveTo(0, 9)
      ..quadraticBezierTo(110, 44, 217, 8);
    canvas.drawPath(
      wire,
      Paint()
        ..color = spruce
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (int j = 1; j < 12; j++) {
      final t = j / 12,
          x = 217 * t,
          y = (1 - t) * (1 - t) * 9 + 2 * t * (1 - t) * 44 + t * t * 8;
      line(x, y, x, y + 3, 1, spruce);
      dot(x, y + 4, 1.9, j.isEven ? amber : snow);
    }
    for (int j = 0; j < 950; j++) {
      dot(
        rng.nextDouble() * 440,
        rng.nextDouble() * 166,
        .35,
        const Color(0x27716d53),
      );
    }
  }

  @override
  bool shouldRepaint(WinterPrint oldDelegate) => false;
}

const panel = Color(0xff102a35),
    gridInk = Color(0xff34535f),
    live = Color(0xff6ee7c7),
    steel = Color(0xffb4c1c4);
const layouts = <List<int>>[
  [4, 5, 1, 2, 6, 7],
  [10, 11, 6, 7, 12, 17, 18, 13, 14],
  [18, 19, 13, 7, 8, 14, 20, 21, 15, 9, 10, 16, 22, 23],
];
const widths = [4, 5, 6];
int spin(int v) => ((v << 1) & 15) | (v >> 3);
int direction(int a, int b, int w) => b == a - w
    ? 1
    : b == a + 1
    ? 2
    : b == a + w
    ? 4
    : 8;
List<int> blueprint(int level) {
  final w = widths[level], path = layouts[level], rng = Random(137 + level);
  final masks = List.generate(w * w, (i) => [0, 0, 3, 5][rng.nextInt(4)]);
  for (int k = 0; k < path.length; k++) {
    final i = path[k];
    masks[i] =
        (k == 0 ? 8 : direction(i, path[k - 1], w)) |
        (k == path.length - 1 ? 2 : direction(i, path[k + 1], w));
  }
  return masks;
}

Set<int> connected(List<int> m, int w, int start) {
  final found = <int>{};
  if (m[start] & 8 == 0) return found;
  final todo = [start];
  while (todo.isNotEmpty) {
    final i = todo.removeLast();
    if (!found.add(i)) continue;
    for (var k = 0; k < 4; k++) {
      final x = i % w + [0, 1, 0, -1][k], y = i ~/ w + [-1, 0, 1, 0][k];
      if (x < 0 || x >= w || y < 0 || y >= w || m[i] & (1 << k) == 0) continue;
      final j = y * w + x;
      if (m[j] & (1 << ((k + 2) % 4)) != 0 && !found.contains(j)) todo.add(j);
    }
  }
  return found;
}

class TrackInk extends CustomPainter {
  final int mask;
  final bool active;
  TrackInk(this.mask, this.active);
  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero),
        p = Paint()..strokeCap = StrokeCap.round;
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(6)),
      p..color = const Color(0xff1b3843),
    );
    if (mask == 0) {
      c.drawCircle(center, 1.4, p..color = gridInk);
      return;
    }
    final ends = [
      Offset(center.dx, 0),
      Offset(s.width, center.dy),
      Offset(center.dx, s.height),
      Offset(0, center.dy),
    ];
    for (final width in [0.19, 0.075]) {
      p.strokeWidth = s.shortestSide * width;
      p.color = width > .1
          ? panel
          : active
          ? live
          : steel;
      for (int k = 0; k < 4; k++) {
        if (mask & (1 << k) != 0) c.drawLine(center, ends[k], p);
      }
    }
    c.drawCircle(
      center,
      s.shortestSide * .085,
      p..color = active ? live : steel,
    );
    c.drawCircle(center, s.shortestSide * .038, p..color = panel);
  }

  @override
  bool shouldRepaint(TrackInk old) => old.mask != mask || old.active != active;
}

class RouteCover extends StatelessWidget {
  final VoidCallback onTap;
  const RouteCover({required this.onTap, super.key});
  @override
  Widget build(BuildContext context) => Material(
    color: panel,
    borderRadius: BorderRadius.circular(25),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Маршрут детали',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.route, color: live),
              ],
            ),
            const SizedBox(height: 14),
            ExcludeSemantics(
              child: SizedBox(
                height: 75,
                child: Row(
                  children: [
                    for (final m in [10, 9, 6, 10, 10])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: CustomPaint(
                            painter: TrackInk(m, true),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(
                  child: Text('Склад → цех', style: TextStyle(color: steel)),
                ),
                Icon(Icons.play_circle_fill, color: orange, size: 39),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class RouteBoard extends StatefulWidget {
  final Map memory;
  final VoidCallback persist;
  const RouteBoard({required this.memory, required this.persist, super.key});
  @override
  State<RouteBoard> createState() => _BoardState();
}

class _BoardState extends State<RouteBoard> {
  int level = 0, moves = 0;
  List<int> cells = [];
  Set<int> lit = {};
  bool won = false;
  @override
  void initState() {
    super.initState();
    final v = widget.memory['routeBoard'];
    if (v is Map &&
        v['level'] is int &&
        (v['level'] as int) >= 0 &&
        (v['level'] as int) < layouts.length) {
      level = v['level'];
      final data = v['cells'];
      if (data is List &&
          data.length == widths[level] * widths[level] &&
          data.every((x) => x is int && x >= 0 && x < 16)) {
        cells = List<int>.from(data);
        moves = v['moves'] ?? 0;
        refresh();
        return;
      }
    }
    start(0);
  }

  void refresh() {
    final path = layouts[level];
    lit = connected(cells, widths[level], path.first);
    won = lit.contains(path.last) && cells[path.last] & 2 != 0;
  }

  void save() {
    widget.memory['routeBoard'] = {
      'level': level,
      'moves': moves,
      'cells': cells,
    };
    widget.persist();
  }

  void start(int n) {
    level = n;
    moves = 0;
    cells = blueprint(n);
    final rng = Random(687 + n);
    for (int i = 0; i < cells.length; i++) {
      final r = rng.nextInt(4);
      for (int j = 0; j < r; j++) {
        cells[i] = spin(cells[i]);
      }
    }
    final start = layouts[n].first;
    while (cells[start] & 8 != 0) {
      cells[start] = spin(cells[start]);
    }
    refresh();
    save();
  }

  void rotate(int i) {
    if (won || cells[i] == 0) return;
    setState(() {
      cells[i] = spin(cells[i]);
      moves++;
      refresh();
      save();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widths[level], path = layouts[level];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Text(
          'Маршрут детали',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          won
              ? 'Деталь доставлена в цех.'
              : 'Нажимай на секции, чтобы повернуть их. Соедини склад слева с цехом справа.',
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Схема ${level + 1} / 3',
                    style: const TextStyle(
                      color: live,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text('Ходы: $moves', style: const TextStyle(color: steel)),
                ],
              ),
              const SizedBox(height: 12),
              for (int row = 0; row < w; row++)
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      child: row == path.first ~/ w
                          ? const Icon(
                              Icons.double_arrow,
                              size: 18,
                              color: live,
                            )
                          : null,
                    ),
                    for (int col = 0; col < w; col++)
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: Semantics(
                              button: cells[row * w + col] != 0,
                              label: 'Секция ${row + 1}, ${col + 1}',
                              child: GestureDetector(
                                onTap: () => rotate(row * w + col),
                                child: CustomPaint(
                                  painter: TrackInk(
                                    cells[row * w + col],
                                    lit.contains(row * w + col),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: 18,
                      child: row == path.last ~/ w
                          ? Icon(
                              Icons.flag,
                              size: 18,
                              color: won ? live : orange,
                            )
                          : null,
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.double_arrow, color: live, size: 16),
                  Text(' Склад', style: TextStyle(color: steel)),
                  Spacer(),
                  Text('Цех ', style: TextStyle(color: steel)),
                  Icon(Icons.flag, color: orange, size: 16),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (won)
          FilledButton(
            onPressed: () => setState(() => start((level + 1) % 3)),
            child: Text(level == 2 ? 'Пройти заново' : 'Следующая схема'),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => start(level)),
              icon: const Icon(Icons.replay),
              label: const Text('Сначала'),
            ),
          ),
      ],
    );
  }
}
