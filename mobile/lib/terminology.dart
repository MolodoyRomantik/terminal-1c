import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _bg = Color(0xff111412);
const _surface = Color(0xff202720);
const _accent = Color(0xffb4f447);
const _muted = Color(0xffb4c0b2);
const _green = Color(0xff80e5ac);
const _red = Color(0xffffaba3);

class TermOption {
  final String id, text, explanation;
  TermOption(Map<String, dynamic> json)
    : id = json['id'],
      text = json['text'],
      explanation = json['explanation'];
}

class TermCard {
  final String id, term, question, definition, association, image, hint;
  final int lesson;
  final List<TermOption> options;
  TermCard(Map<String, dynamic> json)
    : id = json['id'],
      term = json['term'],
      question = json['question'],
      definition = json['definition'],
      association = json['association'],
      image = json['image'],
      hint = json['hint'],
      lesson = json['lesson'],
      options = (json['options'] as List)
          .map((item) => TermOption(Map<String, dynamic>.from(item)))
          .toList();
}

class TerminologyPage extends StatefulWidget {
  final Map progress;
  final VoidCallback onSave;
  const TerminologyPage({
    super.key,
    required this.progress,
    required this.onSave,
  });
  @override
  State<TerminologyPage> createState() => _TerminologyPageState();
}

class _TerminologyPageState extends State<TerminologyPage> {
  List<TermCard> cards = [], session = [];
  List<TermOption> choices = [];
  final List<TermCard> mistakes = [];
  final scroll = ScrollController();
  final feedbackKey = GlobalKey();
  TermOption? selected;
  String? error;
  bool loading = true, finished = false;
  int index = 0, correct = 0;
  int? pack;
  TermCard get current => session[index];
  Map get records => widget.progress.putIfAbsent('termsV2', () => {});
  int get learned => cards
      .where((card) => (records[card.id] as Map?)?['correct'] == true)
      .length;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final raw =
          jsonDecode(await rootBundle.loadString('assets/terminology.json'))
              as List;
      final loaded = raw
          .map((item) => TermCard(Map<String, dynamic>.from(item)))
          .toList();
      if (!mounted) return;
      setState(() {
        cards = loaded;
        loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          loading = false;
          error = 'Не удалось открыть карточки. Попробуй ещё раз.';
        });
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void start(List<TermCard> items, {int? packIndex}) {
    setState(() {
      session = List.of(items);
      pack = packIndex;
      index = 0;
      correct = 0;
      selected = null;
      finished = false;
      mistakes.clear();
      choices = List.of(current.options)..shuffle(Random());
    });
    top();
  }

  void top() {
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void answer(TermOption option) {
    if (selected != null) return;
    final ok = option.id == current.id;
    HapticFeedback.selectionClick();
    setState(() {
      selected = option;
      if (ok) {
        correct++;
      } else {
        mistakes.add(current);
      }
      final previous = records[current.id] as Map? ?? {};
      records[current.id] = {
        'correct': ok,
        'attempts': (previous['attempts'] as num? ?? 0) + 1,
      };
      widget.progress['total'] = (widget.progress['total'] as num? ?? 0) + 1;
      if (ok)
        widget.progress['good'] = (widget.progress['good'] as num? ?? 0) + 1;
      widget.onSave();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && feedbackKey.currentContext != null) {
        Scrollable.ensureVisible(
          feedbackKey.currentContext!,
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 320),
          alignment: .1,
        );
      }
    });
  }

  void next() {
    if (selected == null) return;
    setState(() {
      if (index + 1 == session.length) {
        finished = true;
      } else {
        index++;
        selected = null;
        choices = List.of(current.options)..shuffle(Random());
      }
    });
    top();
  }

  void home() {
    setState(() {
      session = [];
      finished = false;
      selected = null;
    });
    top();
  }

  Widget button(
    String text,
    VoidCallback? callback, {
    bool secondary = false,
  }) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: callback,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        backgroundColor: secondary ? _surface : _accent,
        foregroundColor: secondary ? Colors.white : _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
  Widget gap([double size = 16]) => SizedBox(height: size);
  Widget heading(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 28,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -.7,
    ),
  );
  Widget body(String text, {Color color = Colors.white}) =>
      Text(text, style: TextStyle(color: color, fontSize: 16, height: 1.45));
  Widget panel(List<Widget> children, {Color color = _surface}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
  List<Widget> library() => [
    heading('Слова становятся понятнее'),
    gap(10),
    body(
      'Короткая ситуация с завода. Четыре ответа. Разбор с картинкой.',
      color: _muted,
    ),
    gap(22),
    panel([
      Row(
        children: [
          const Icon(Icons.auto_stories_rounded, color: _accent, size: 30),
          const SizedBox(width: 12),
          Expanded(child: body('Верно с последней попытки')),
          Text(
            '$learned / ${cards.length}',
            style: const TextStyle(color: _accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      gap(16),
      LinearProgressIndicator(
        value: cards.isEmpty ? 0 : learned / cards.length,
        color: _accent,
        backgroundColor: const Color(0xff394336),
        minHeight: 7,
        borderRadius: BorderRadius.circular(8),
      ),
    ]),
    gap(22),
    for (int n = 0; n < (cards.length / 4).ceil(); n++) ...[
      packTile(n),
      gap(10),
    ],
  ];
  Widget packTile(int n) {
    final items = cards.skip(n * 4).take(4).toList();
    final done = items
        .where((c) => (records[c.id] as Map?)?['correct'] == true)
        .length;
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => start(items, packIndex: n),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: done == items.length
                      ? _accent
                      : const Color(0xff35422e),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  done == items.length ? Icons.check : Icons.play_arrow_rounded,
                  color: done == items.length ? _bg : _accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Тренировка ${n + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    gap(5),
                    Text(
                      items.map((c) => c.term).join(' · '),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    gap(6),
                    Text(
                      '4 вопроса  ·  $done / ${items.length}',
                      style: const TextStyle(color: _accent, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  void zoom(TermCard card) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: _bg,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Закрыть изображение',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Увеличь двумя пальцами',
                      style: TextStyle(color: _muted),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: .5,
                  maxScale: 5,
                  child: Center(
                    child: Image.asset(
                      card.image,
                      fit: BoxFit.contain,
                      semanticLabel: 'Учебная схема. ${card.hint}',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: body(card.hint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget illustration(TermCard card) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        button: true,
        label: 'Увеличить учебную схему',
        child: InkWell(
          onTap: () => zoom(card),
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1200 / 612,
              child: Image.asset(
              card.image,
              width: double.infinity,
              fit: BoxFit.contain,
              semanticLabel: 'Пример в 1С. ${card.hint}',
              errorBuilder: (_, _, _) => const ColoredBox(
                color: _surface,
                child: Center(child: Text('Изображение временно недоступно')),
              ),
            ),
            ),
          ),
        ),
      ),
      gap(7),
      const Row(
        children: [
          Icon(Icons.zoom_in, color: _muted, size: 15),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Учебная схема · нажми, чтобы увеличить',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ),
        ],
      ),
    ],
  );
  Widget optionTile(TermOption option, int number) {
    final answered = selected != null;
    final right = option.id == current.id;
    final picked = option.id == selected?.id;
    final color = answered && right
        ? _green
        : answered && picked
        ? _red
        : _muted;
    return AnimatedContainer(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: answered && right
            ? const Color(0xff153e2b)
            : answered && picked
            ? const Color(0xff442721)
            : _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: answered && (right || picked)
              ? color
              : const Color(0xff354034),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: answered ? null : () => answer(option),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                answered && (right || picked)
                    ? Icon(
                        right ? Icons.check_circle : Icons.cancel_outlined,
                        color: color,
                        size: 24,
                      )
                    : Text(
                        String.fromCharCode(1040 + number),
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      color: answered && (right || picked)
                          ? color
                          : Colors.white,
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> question() => [
    Row(
      children: [
        Expanded(
          child: Text(
            'Вопрос ${index + 1} из ${session.length}',
            style: const TextStyle(color: _muted),
          ),
        ),
        Text('Урок ${current.lesson}', style: const TextStyle(color: _muted)),
      ],
    ),
    gap(10),
    Row(
      children: List.generate(
        session.length,
        (n) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 5),
            height: 5,
            decoration: BoxDecoration(
              color: n <= index ? _accent : _surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    ),
    gap(24),
    Text(
      current.question,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    ),
    gap(20),
    illustration(current),
    gap(20),
    for (int n = 0; n < choices.length; n++) optionTile(choices[n], n),
    if (selected != null) ...[
      gap(6),
      Semantics(
        liveRegion: true,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(current.id),
          tween: Tween(begin: 0, end: 1),
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 280),
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - value)),
              child: child,
            ),
          ),
          child: Container(
            key: feedbackKey,
            child: panel([
              Row(
                children: [
                  Icon(
                    selected!.id == current.id
                        ? Icons.check_circle_rounded
                        : Icons.lightbulb_outline,
                    color: selected!.id == current.id ? _green : _red,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selected!.id == current.id ? 'Верно!' : 'Давай разберём',
                      style: TextStyle(
                        color: selected!.id == current.id ? _green : _red,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              gap(14),
              if (selected!.id != current.id) ...[
                body('Твой ответ — ${selected!.text}', color: _red),
                gap(8),
                body(selected!.explanation, color: _muted),
                gap(16),
              ],
              body('Здесь подходит «${current.term}».'),
              gap(8),
              body(current.hint),
              gap(16),
              const Text(
                'Представь на заводе',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
              ),
              gap(6),
              body(current.association, color: _muted),
            ]),
          ),
        ),
      ),
    ],
  ];
  List<Widget> result() => [
    gap(18),
    Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xff243d25),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.task_alt_rounded, color: _green, size: 58),
      ),
    ),
    gap(26),
    heading(
      correct == session.length ? 'Все ответы верные!' : 'Тренировка завершена',
    ),
    gap(12),
    body('С первой попытки — $correct из ${session.length}.', color: _muted),
    gap(24),
    for (final card in session)
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(
              mistakes.contains(card) ? Icons.replay : Icons.check_circle,
              color: mistakes.contains(card) ? _red : _green,
            ),
            const SizedBox(width: 12),
            Expanded(child: body(card.term)),
          ],
        ),
      ),
    gap(18),
    if (mistakes.isNotEmpty) ...[
      button(
        'Повторить ошибки · ${mistakes.length}',
        () => start(List.of(mistakes)),
      ),
      gap(10),
    ],
    if (pack != null && (pack! + 1) * 4 < cards.length) ...[
      button(
        'Следующие 4 вопроса',
        () => start(
          cards.skip((pack! + 1) * 4).take(4).toList(),
          packIndex: pack! + 1,
        ),
      ),
      gap(10),
    ],
    button('К тренировкам', home, secondary: true),
  ];
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: session.isEmpty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) home();
    },
    child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back),
          onPressed: session.isNotEmpty ? home : () => Navigator.pop(context),
        ),
        title: const Text(
          'Терминология',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: loading
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        body(error!),
                        gap(),
                        button('Попробовать ещё раз', load),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                          children: session.isEmpty
                              ? library()
                              : [Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: finished ? result() : question(),
                                )],
                        ),
                      ),
                      if (session.isNotEmpty && !finished && selected != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: button(
                            index + 1 == session.length
                                ? 'Показать результат'
                                : 'Дальше',
                            next,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}
