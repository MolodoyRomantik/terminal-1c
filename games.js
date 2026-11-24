(() => {
  "use strict";
  const terms = [
    ["Бухта кабеля", "Кладовщик хочет один раз внести марку кабеля, а затем выбирать её во всех накладных. Где хранить список марок?", "Справочник", "Документ", "Отчёт", "Справочник хранит объекты, которые многократно выбирают в разных операциях."],
    ["Партия подшипников", "На склад привезли 40 подшипников. Чем зарегистрировать эту конкретную поставку?", "Документ поступления", "Перечисление", "Карточка склада", "У поставки есть дата, склад и состав. Такой факт хозяйственной деятельности оформляют документом."],
    ["Место хранения", "В карточке детали появилось поле «Ячейка». Как называется такое отдельное свойство?", "Реквизит", "Отчёт", "Команда", "Реквизит хранит одно свойство объекта. Для ячейки это может быть строка «Б-02»."],
    ["Пять позиций", "В одной накладной указаны пять разных деталей с количеством. Где хранить повторяющиеся строки?", "Табличная часть", "Один реквизит", "Перечисление", "Табличная часть содержит набор однотипных строк одного документа."],
    ["Остатки склада", "Нужно учитывать приход и расход по каждой паре «склад и деталь». Какой объект выбрать?", "Регистр накопления", "Справочник цехов", "План обмена", "В регистре накопления вида «Остатки» движения изменяют количество по выбранным измерениям."],
    ["Цена на дату", "Требуется хранить цены деталей и узнавать цену, действовавшую в день закупки. Что подойдёт?", "Периодический регистр сведений", "Перечисление", "Форма списка", "Периодический регистр сведений позволяет хранить значения с момента их вступления в силу."],
    ["Рабочее место мастера", "Мастер может читать накладные, но не должен их проводить. Чем задаются такие разрешения?", "Роль", "Реквизит", "Табличная часть", "Роль задаёт набор разрешённых операций над объектами конфигурации."]
  ];
  const bugs = [
    ["Последняя деталь", "На складе осталось ровно 8 болтов. Кладовщик просит выдать 8 и получает отказ.", "Если Количество >= Остаток Тогда\n    Отказ = Истина;\nКонецЕсли;", "Поменять >= на >", "Поменять >= на =", "Поменять >= на <", "Ровно 8 болтов можно выдать. Отказывать следует только при превышении остатка."],
    ["Пропавшая сумма", "В документе две строки стоимостью 100 и 200 рублей. Итог равен 200.", "Итого = 0;\nДля Каждого Строка Из Детали Цикл\n    Итого = Строка.Сумма;\nКонецЦикла;", "Прибавлять сумму строки к итогу", "Начать с единицы", "Изменить порядок строк", "Присваивание заменяет итог на каждой итерации. Нужно Итого = Итого + Строка.Сумма;"],
    ["Пустая позиция", "Кладовщик ввёл 5 штук и забыл выбрать деталь. Проверка пропустила строку.", "Если Не ЗначениеЗаполнено(Деталь)\n    И Количество <= 0 Тогда\n    Отказ = Истина;\nКонецЕсли;", "Заменить И на ИЛИ", "Заменить <= на <", "Поменять условия местами", "Достаточно одного нарушения. ИЛИ обнаружит пустую деталь даже при допустимом количестве."],
    ["Ведущие нули", "Артикул детали 00125 после записи отображается как 125. Тип реквизита выбран так:", "Артикул — Число(8, 0)", "Хранить артикул строкой", "Увеличить длину числа", "Прибавить два нуля справа", "Артикул служит обозначением. Строка сохранит ведущие нули и позволит использовать буквы."],
    ["Перепутанные единицы", "Для трёх деталей по 50 рублей форма показывает итог 53 рубля.", "Сумма = Количество + Цена;", "Умножить количество на цену", "Разделить цену на количество", "Вычесть количество из цены", "Сумма для трёх одинаковых позиций равна 3 × 50 = 150."]
  ];
  const ordering = [
    ["Проверка количества", "Собери условие, которое предупредит о нулевом количестве.", ["Если Количество = 0 Тогда", '    Сообщить("Введите количество");', "КонецЕсли;"], "Блок начинается условием, затем выполняет команду и завершается словом КонецЕсли."],
    ["Итог по строкам", "Сначала подготовь счётчик, затем посчитай количество деталей во всех строках.", ["Итого = 0;", "Для Каждого Строка Из Детали Цикл", "    Итого = Итого + Строка.Количество;", "КонецЦикла;"], "Итог обнуляют один раз перед циклом. Каждая итерация добавляет количество очередной строки."],
    ["Стоимость партии", "Определи функцию для расчёта стоимости партии деталей.", ["Функция Стоимость(Количество, Цена)", "    Сумма = Количество * Цена;", "    Возврат Сумма;", "КонецФункции"], "После вычисления функция возвращает результат вызывающему коду."],
    ["Список артикулов", "Создай пустой массив, добавь в него артикул и покажи первую запись.", ["Артикулы = Новый Массив;", 'Артикулы.Добавить("00125");', "Сообщить(Артикулы[0]);"], "Новый массив пуст. После добавления элемент доступен по индексу 0."]
  ];
  const modes = [
    ["terms","Словарь цеха","Узнай термин по ситуации на заводе.","Ая"],
    ["balance","Складской счёт","Восстанови остаток по движениям.","±"],
    ["code","Собери код","Расставь строки программы по порядку.","{ }"],
    ["bugs","Найди ошибку","Почини одну поломанную проверку.","!?"]
  ];
  const css = `
  .gx{color:var(--ink,#24271e);max-width:980px;margin-inline:auto;font:inherit}.gx *{box-sizing:border-box}.gx h2,.gx h3,.gx p{margin:0}.gx h2{font-size:clamp(2rem,6vw,3.5rem);letter-spacing:-.055em;line-height:1.04;margin:.5em 0}.gx h3{font-size:clamp(1.4rem,4vw,2rem);letter-spacing:-.025em;line-height:1.12}.gx button{font:inherit;cursor:pointer;color:inherit}.gx button:focus-visible{outline:3px solid #6d753f;outline-offset:3px}.gx-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));border-top:1px solid #777b65}.gx-card{display:grid;grid-template-columns:3.2rem 1fr;text-align:left;align-items:center;gap:.9rem;background:transparent;border:0;border-bottom:1px solid #a6a797;padding:1.35rem .6rem;min-height:108px}.gx-card:hover,.gx-option:hover:enabled,.gx-chip:hover:enabled{background:#e8e9d8}.gx-card strong,.gx-card small{display:block}.gx-card strong{font-size:1.2rem}.gx-card small{font-size:.9rem;margin-top:.35rem;line-height:1.4}.gx-mark{background:#e0e4cb;color:#48532c;border:1px solid #9ca580;width:3rem;height:3rem;display:grid;place-items:center;font:700 1.3rem monospace}.gx-back{border:0;background:transparent;text-decoration:underline;text-underline-offset:4px;padding:.65rem 0}.gx-tag{display:block;text-transform:uppercase;letter-spacing:.09em;font:700 .8rem monospace;color:#606744;margin:1.25rem 0 .6rem}.gx-prompt{font-size:1.08rem;line-height:1.5;max-width:65ch;margin:.8rem 0 1rem!important}.gx-code,.gx-slots{white-space:pre-wrap;overflow-wrap:anywhere;background:#e7e8da;color:#303823;padding:1rem;border-left:3px solid #677845;font: .95rem/1.55 monospace;margin:1rem 0}.gx-options,.gx-slots{display:grid;gap:.5rem}.gx-option,.gx-chip{padding:.8rem 1rem;background:transparent;border:1px solid #a5aa91;text-align:left;min-height:44px}.gx-option[disabled],.gx-chip[disabled]{cursor:default}.gx-correct{background:#dce6ca!important;border-color:#617a42}.gx-miss{border-style:dashed}.gx-answer{margin:1rem 0;line-height:1.5}.gx-answer strong{display:block}.gx-primary{border:1px solid #4b5934;background:#505e38;color:#fff!important;padding:.75rem 1rem;margin:.65rem 0;min-height:44px}.gx-wrap{display:flex;flex-wrap:wrap;gap:.5rem}.gx-chip{font-family:monospace!important;font-size:.92rem!important;white-space:pre-wrap;overflow-wrap:anywhere}.gx-chip:disabled{opacity:.5}.gx-ledger{border-collapse:collapse;width:100%;max-width:30rem;margin:1rem 0}.gx-ledger td{padding:.5rem;border-bottom:1px solid #b3b5a1}.gx-ledger td:last-child{text-align:right;font-family:monospace}.gx-slots:empty::before{content:"Здесь появятся выбранные строки";color:#65694f}.gx-slots button{display:block;background:transparent;border:0;padding:.35rem;text-align:left;font:inherit;white-space:pre-wrap}.gx-primary:disabled{opacity:.45}.gx-note{font-size:.9rem;line-height:1.45}.gx-actions{display:flex;align-items:center;gap:1rem;flex-wrap:wrap}@media(max-width:620px){.gx-grid{grid-template-columns:1fr}.gx-card{min-height:88px}.gx-chip{width:100%}}
  `;
  const shuffle = list => {
    const copy = [...list];
    for(let i=copy.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[copy[i],copy[j]]=[copy[j],copy[i]];}
    return copy;
  };
  function element(tag,cls,txt) {
    const node=document.createElement(tag);
    if(cls)node.className=cls;
    if(txt!==undefined)node.textContent=txt;
    return node;
  }
  function button(cls,label,action){
    const node=element("button",cls,label);node.type="button";node.onclick=action;return node;
  }
  window.renderGames = function(container,onResult) {
    if(!document.getElementById("gx-style")){const style=element("style","",css);style.id="gx-style";document.head.append(style);}
    const root=element("div","gx");container.replaceChildren(root);
    const queues={};
    function pick(mode,list){if(!queues[mode]?.length)queues[mode]=shuffle(list);return queues[mode].pop();}
    function menu(){
      root.replaceChildren(element("h2","","Игры"));
      const grid=element("div","gx-grid");
      modes.forEach(([key,title,desc,symbol])=>{
        const card=button("gx-card","",()=>round(key));
        const info=element("span");info.append(element("strong","",title),element("small","",desc));card.append(element("span","gx-mark",symbol),info);grid.append(card);
      });root.append(grid);
    }
    function round(mode){
      const modeName=modes.find(item=>item[0]===mode)[1];
      root.replaceChildren(button("gx-back","Все игры",menu),element("span","gx-tag",modeName));
      let settled=false;
      function finish(ok,reason){
        if(settled)return;settled=true;
        root.querySelectorAll(".gx-option,.gx-chip,.gx-slots button,.gx-primary").forEach(n=>n.disabled=true);
        const box=element("div","gx-answer");box.setAttribute("role","status");
        box.append(element("strong","",ok?"Верно":"Разбор ответа"),element("p","",reason));
        root.append(box,button("gx-primary","Следующее задание",()=>round(mode)));
        if(typeof onResult==="function")onResult(ok);
      }
      function heading(title,prompt){root.append(element("h3","",title),element("p","gx-prompt",prompt));}
      function choice(options,correct,reason){
        const group=element("div","gx-options");root.append(group);
        shuffle(options).forEach(option=>{
          const b=button("gx-option",option,()=>{
            if(settled)return;
            [...group.children].find(n=>n.textContent===correct).classList.add("gx-correct");
            if(option!==correct)b.classList.add("gx-miss");
            finish(option===correct,(option===correct?"":"Ответ: "+correct+". ")+reason);
          });group.append(b);
        });
      }
      if(mode==="terms"||mode==="bugs"){
        const row=pick(mode,mode==="terms"?terms:bugs);heading(row[0],row[1]);
        if(mode==="bugs")root.append(element("pre","gx-code",row[2]));
        const index=mode==="terms"?2:3;choice(row.slice(index,index+3),row[index],row[index+3]);return;
      }
      if(mode==="balance"){
        const items=["Подшипники 6205","Шайбы М10","Ремни привода","Датчики положения","Болты М12"];
        const start=10+Math.floor(Math.random()*25),inc=3+Math.floor(Math.random()*10),out=2+Math.floor(Math.random()*7);
        const shifted=1+Math.floor(Math.random()*3);
        const scenario=pick("balance",[0,1,2]);
        heading(pick("parts",items),"Сколько штук осталось на основном складе после этих операций?");
        const ledger=element("table","gx-ledger");
        const entries=[["На начало",start],["Приход на основной склад","+"+inc],["Выдача с основного склада","−"+out]];
        entries.push(scenario===0?["Выдачу отменили","+"+out]:scenario===1?["Переместили на ремонтный склад","−"+shifted]:["Приход на соседний склад","+"+shifted]);
        entries.forEach(([label,value])=>{const tr=element("tr");tr.append(element("td","",label),element("td","",value));ledger.append(tr);});root.append(ledger);
        const result=start+inc-(scenario===0?0:out)-(scenario===1?shifted:0);
        const opts=[result,result+shifted,result-out];const reason=scenario===0?"Отмена выдачи вернула детали на склад.":scenario===1?"Перемещение уменьшает остаток на складе-источнике.":"Поступление на другой склад не меняет остаток основного.";
        choice(opts.map(v=>v+" шт."),result+" шт.",reason+" Остаток: "+result+" шт.");return;
      }
      const [title,prompt,lines,reason]=pick("code",ordering);heading(title,prompt);
      const slots=element("div","gx-slots");slots.setAttribute("aria-label","Собранный код");
      const pool=element("div","gx-wrap"), selected=[];const order=shuffle(lines);
      if(order.every((line,i)=>line===lines[i]))order.push(order.shift());
      const check=button("gx-primary","Проверить",()=>{
        const ok=selected.every((line,i)=>line===lines[i]);
        finish(ok,reason);if(!ok)root.insertBefore(element("pre","gx-code",lines.join("\n")),root.lastChild);
      });
      function refresh(){
        slots.replaceChildren();pool.replaceChildren();
        selected.forEach((line,index)=>slots.append(button("",line,()=>{selected.splice(index,1);refresh();})));
        order.forEach(line=>{const b=button("gx-chip",line.trim(),()=>{selected.push(line);refresh();});b.disabled=selected.includes(line);pool.append(b);});
        check.disabled=selected.length!==lines.length;
      }
      root.append(element("p","gx-note","Нажимай строки по порядку. Чтобы убрать строку, коснись её в собранном коде."),slots,pool,check);refresh();
    }
    menu();
  };
})();

