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
const orange = Color(0xfff58243), ink = Color(0xff232820), paper = Color(0xfff8f7f3);
const mods = ['Знакомство с 1С','Устройство базы','Встроенный язык','Формы и отладка','Складской учёт','Запросы к данным','Отчёты и обработки','Чужая конфигурация','Будни разработчика','Выпускная работа'];
const ends = [6,12,20,26,33,40,45,51,57,60];
const steps = ['Разбор','Тетрадь','Практика','Проверка'];
const games = ['Терминология','Складской счёт','Поиск ошибки','Собери код'];
const gameIcons = [Icons.style_outlined,Icons.inventory_2_outlined,Icons.bug_report_outlined,Icons.code];
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = jsonDecode(await rootBundle.loadString('assets/course.json'));
  Map state = {};
  try {state = jsonDecode(readValue(key.toJS)?.toDart ?? '{}');} catch (_) {}
  runApp(MaterialApp(debugShowCheckedModeBanner:false,title:'Терминал 1С',theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:orange,surface:paper),scaffoldBackgroundColor:paper),home:Course(data,state)));
}
class Course extends StatefulWidget {
  final Map data,state;
  const Course(this.data,this.state,{super.key});
  @override State<Course> createState()=> _CourseState();
}
class _CourseState extends State<Course> {
  Map get st=>widget.state;
  List get lessons=>widget.data['lessons'];
  int tab=0, module=0, stage=0, mode=0;
  String screen='home', feedback='', prompt='',right='',reason='';
  List<String> options=[], ordered=[], selected=[];
  bool graded=false;
  int get i=>(st['at'] as int? ?? 0).clamp(0,59);
  Map get current=>lessons[i];
  Map marks(String field)=>st.putIfAbsent(field,()=>{});
  bool checked(String field,int n)=>marks(field)['$n']==true;
  int get completed=>List.generate(60,(n)=>n).where((n)=>checked('pc',n)&&checked('quiz',n)).length;
  void save(){try{writeValue(key.toJS,jsonEncode(st).toJS);} catch (_) {}}
  void edit(VoidCallback f){setState(f);save();}
  void open(int n){edit((){st['at']=n;stage=((marks('step')['$n'] as int? ?? 1)-1).clamp(0,3);feedback='';screen='lesson';});}
  void move(int s){edit((){stage=s;marks('step')['$i']=s+1;feedback='';});}
  void back(){setState((){if(screen=='lesson'&&stage>0){move(stage-1);}else{screen='home';}});}
  Widget title(String t)=>Text(t,style:const TextStyle(fontSize:31,height:1.12,fontWeight:FontWeight.w800,letterSpacing:-1.4));
  Widget label(String t)=>Text(t,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:Color(0xff60665a)));
  Widget gap([double n=16])=>SizedBox(height:n);
  Widget action(String t,VoidCallback? fn)=>FilledButton(onPressed:fn,style:FilledButton.styleFrom(backgroundColor:orange,foregroundColor:ink,minimumSize:const Size.fromHeight(52),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),child:Text(t,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700)));
  Widget tile(IconData icon,String t,VoidCallback fn,{String? sub})=>Card(color:Colors.white,elevation:0,margin:const EdgeInsets.only(bottom:8),child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:4),leading:Icon(icon,color:ink),title:Text(t),subtitle:sub==null?null:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:fn));
  Widget list(List<Widget> children)=>ListView(padding:const EdgeInsets.fromLTRB(20,12,20,24),children:children);
  Widget home(){
    final m=ends.indexWhere((end)=>i<end);
    return list([title('Моё обучение'),gap(20),Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(28)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.memory_rounded,color:orange),const SizedBox(width:8),Expanded(child:Text(mods[m],style:const TextStyle(color:Colors.white70))),const Text('1С',style:TextStyle(color:orange,fontSize:32,fontWeight:FontWeight.w900))]),
      gap(28),Text('УРОК ${i+1} / 60',style:const TextStyle(color:orange,letterSpacing:1.3,fontWeight:FontWeight.w700,fontSize:12)),gap(8),Text(current['title'],style:const TextStyle(fontSize:29,height:1.1,color:Colors.white,fontWeight:FontWeight.w700)),gap(22),action(st.containsKey('at')?'Продолжить урок':'Начать урок',()=>open(i))
    ])),gap(20),Row(children:[Expanded(child:label('Пройдено уроков')),Text('$completed / 60')]),gap(8),LinearProgressIndicator(value:completed/60,color:orange,backgroundColor:const Color(0xffdfdfd7),minHeight:6,borderRadius:BorderRadius.circular(8)),gap(22),tile(Icons.library_books_outlined,'Программа курса',(){setState((){module=m;screen='catalog';});},sub:'10 модулей · 60 уроков')]);
  }
  Widget catalog(){final start=module==0?0:ends[module-1];return list([title('Программа'),gap(),DropdownButton<int>(isExpanded:true,value:module,items:[for(int n=0;n<mods.length;n++)DropdownMenuItem(value:n,child:Text('${n+1}. ${mods[n]}'))],onChanged:(v)=>setState(()=>module=v!)),gap(),for(int n=start;n<ends[module];n++)tile(checked('quiz',n)&&checked('pc',n)?Icons.check_circle:Icons.article_outlined,lessons[n]['title'],()=>open(n),sub:'Урок ${n+1}')]);}
  Widget lesson(){final fields=['theory','note','practice','question'];return list([label('Урок ${i+1} из 60'),gap(6),title(current['title']),gap(),Wrap(spacing:5,children:[for(int n=0;n<4;n++)ChoiceChip(showCheckmark:false,label:Text(steps[n]),selected:n==stage,onSelected:(_)=>move(n))]),gap(),SelectableText(current[fields[stage]],style:const TextStyle(fontSize:18,height:1.55)),gap(),
    if(stage==2)CheckboxListTile(contentPadding:EdgeInsets.zero,title:const Text('Выполнил в 1С'),value:checked('pc',i),onChanged:(v)=>edit(()=>marks('pc')['$i']=v)),
    if(stage==3)...[for(int n=0;n<current['choices'].length;n++)tile(Icons.radio_button_unchecked,current['choices'][n],()=>edit((){final ok=n==current['answer'];feedback=ok?'Верно!':'Попробуй ещё раз';if(ok)marks('quiz')['$i']=true;})),Text(feedback.isEmpty&&checked('quiz',i)?'Проверка пройдена':feedback)],
    gap(),action(stage<3?'Дальше':i<59?'Следующий урок':'Завершить',(){if(stage<3){move(stage+1);}else if(i<59){open(i+1);}else{setState((){screen='home';tab=2;});}})]);}
  void round(int n){mode=n;screen='round';graded=false;feedback='';selected=[];final r=Random();
    if(n==1){final a=10+r.nextInt(35),b=1+r.nextInt(12),c=1+r.nextInt(8);prompt='В начале смены было $a деталей. Приняли $b, выдали $c. Сколько осталось?';right='${a+b-c}';options=[right,'${a+b}','${a+b+c}'];reason='$a + $b − $c = $right';}
    else{final pool=widget.data[n==0?'terms':n==2?'bugs':'ordering'] as List;final row=pool[r.nextInt(pool.length)] as List;prompt='${row[0]}\n\n${row[1]}';reason=row.last;if(n==3){ordered=List<String>.from(row[2]);options=[...ordered];}else{final pos=n==0?2:3;if(n==2)prompt+='\n\n${row[2]}';right=row[pos];options=List<String>.from(row.sublist(pos,pos+3));}}
    options.shuffle(r);if(n==3&&options.join()==ordered.join()){options.add(options.removeAt(0));}setState((){});
  }
  void grade(bool ok){if(graded)return;edit((){graded=true;feedback=ok?'Верно!':'Разбор ответа';st['total']=(st['total']??0)+1;if(ok)st['good']=(st['good']??0)+1;});}
  Widget gameHome()=>list([title('Тренажёры'),gap(),for(int n=0;n<4;n++)tile(gameIcons[n],games[n],()=>round(n))]);
  Widget gameRound()=>list([label(games[mode]),gap(),SelectableText(prompt,style:const TextStyle(fontSize:20,height:1.4)),gap(),if(mode==3)...[for(final line in selected)ListTile(title:Text(line),onTap:graded?null:()=>setState(()=>selected.remove(line))),for(final line in options.where((s)=>!selected.contains(s)))tile(Icons.add,line,()=>setState(()=>selected.add(line))),if(!graded)action('Проверить',selected.length!=ordered.length?null:()=>grade(selected.join('\n')==ordered.join('\n')))]else if(!graded)for(final answer in options)tile(Icons.radio_button_unchecked,answer,()=>grade(answer==right)),if(graded)...[title(feedback),gap(),Text(reason),if(mode==3)SelectableText(ordered.join('\n')),gap(),action('Ещё задание',()=>round(mode))]]);
  Widget stats()=>list([title('Прогресс'),gap(),for(final pair in [['Завершено уроков','$completed / 60'],['Практика в 1С','${marks('pc').values.where((v)=>v==true).length} / 60'],['Проверки уроков','${marks('quiz').values.where((v)=>v==true).length} / 60'],['Верные ответы в играх',"${st['good']??0} / ${st['total']??0}"]])Card(elevation:0,color:Colors.white,child:ListTile(title:Text(pair[0]),trailing:Text(pair[1]))),gap(),label('Прогресс сохраняется на этом устройстве.')]);
  @override Widget build(BuildContext context){return PopScope(canPop:screen=='home',onPopInvokedWithResult:(p,_) {if(!p)back();},child:Scaffold(appBar:AppBar(backgroundColor:paper,leading:screen=='home'?null:IconButton(onPressed:back,icon:const Icon(Icons.arrow_back)),title:const Text('Терминал 1С',style:TextStyle(fontWeight:FontWeight.w700,fontSize:18)),centerTitle:false),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:620),child:AnimatedSwitcher(duration:const Duration(milliseconds:170),child:KeyedSubtree(key:ValueKey('$screen-$tab-$stage-$i'),child:switch(screen){'lesson'=>lesson(),'catalog'=>catalog(),'round'=>gameRound(),_=>[home,gameHome,stats][tab]() }))))),bottomNavigationBar:screen!='home'?null:NavigationBar(height:68,backgroundColor:paper,indicatorColor:const Color(0xffffd8bf),selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.auto_stories_outlined),selectedIcon:Icon(Icons.auto_stories),label:'Путь'),NavigationDestination(icon:Icon(Icons.sports_esports_outlined),selectedIcon:Icon(Icons.sports_esports),label:'Игры'),NavigationDestination(icon:Icon(Icons.bar_chart_rounded),label:'Прогресс')])));}
}
