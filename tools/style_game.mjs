// Presentation only. Coordinates for the moving receiver and rotary stay in
// build_game.mjs so styling cannot change their mechanical origin.
export function styleGame(ui) {
 const {E,rect,text,image,canvas,game,menu,diary,pause,end,named,place}=ui;
 const ink=[.055,.075,.065,1],bone=[.91,.89,.80,1],paper=[.76,.73,.62,1];
 const muted=[.62,.65,.58,1],brass=[.76,.65,.40,1],dark=[.022,.032,.027,1];
 const ordered=(id,order)=>{E[id].uiRect.order=order;return id;};
 const before=(id,name)=>ordered(id,E.indexOf(named(name))-1);
 const label=(name,size,color=bone)=>Object.assign(named(name).uiText,{fontSize:size,color});

 // Consistent controls: solid ivory for the primary action, quiet borders for
 // secondary actions, a real hover state, and roomy labels.
 for(const e of E){
  if(!e.uiButton||/^Dial|^ReceiverAssembly/.test(e.name))continue;
  e.uiImage.color=[.065,.085,.071,1];e.uiImage.cornerRadius=3;
  e.uiImage.outlineWidth=1;e.uiImage.outlineColor=[.29,.33,.27,1];
  e.uiButton.normalColor=[.065,.085,.071,1];e.uiButton.hoverColor=[.14,.18,.14,1];
  e.uiButton.pressedColor=[.24,.28,.20,1];
 }
 for(const name of ['StartButton','DiaryResume','ResumeButton','EndReset']){
  const e=named(name);e.uiImage.color=bone;e.uiImage.outlineColor=bone;
  e.uiButton.normalColor=bone;e.uiButton.hoverColor=[1,.96,.82,1];e.uiButton.pressedColor=paper;
  const child=E.find(x=>x.parent===E.indexOf(e)&&x.uiText);child.uiText.color=ink;
 }

 // Title: type on a calm left page, the missing night on the right.
 before(rect('TitleGround',0,0,1600,900,dark,menu),'TitleRoom');
 place('TitleRoom',784,88,736,648);named('TitleRoom').uiImage.color=[1,1,1,1];
 place('TitleShade',0,0,736,900);named('TitleShade').uiImage.color=dark;
 place('TitleLiveBadge',80,64,48,40);place('TitleLive',80,64,48,40);
 place('TitleLiveEnglish',152,64,544,40);label('TitleLiveEnglish',24,muted);
 place('TitleEyebrow',80,168,640,40);label('TitleEyebrow',24,brass);
 place('Title',72,248,656,216);Object.assign(named('Title').uiText,{text:'深夜0時の\n生中継',fontSize:84,wrap:true,alignV:0,color:bone});
 place('TitleTagline',80,488,640,56);label('TitleTagline',32,brass);
 place('TitleDescription',80,560,632,88);Object.assign(named('TitleDescription').uiText,{text:'黒電話で、過去の家を「話し中」にする。\n声は届かない。届くのは、数字だけ。',fontSize:26,color:muted});
 place('StartButton',80,688,360,64);place('StartButtonLabel',8,0,344,64);
 named('StartButtonLabel').uiText.text='放送を始める  [Enter]';label('StartButtonLabel',27,ink);
 place('ShortButton',80,768,360,56);place('ShortButtonLabel',8,0,344,56);
 named('ShortButtonLabel').uiText.text='三分の短縮版  [Q]';label('ShortButtonLabel',25);
 place('TitleFoot',784,760,736,40);named('TitleFoot').uiText.text='一人用 / 通常版15分 / ヘッドホン推奨';label('TitleFoot',23,muted);
 place('TitleHelp',784,816,736,40);named('TitleHelp').uiText.text='E 受話器　数字 ダイヤル　Tab メモ　Esc 一時停止';label('TitleHelp',22,muted);
 rect('TitleRule',80,128,616,1,[.30,.33,.27,1],menu);

 // Play: a broadcast, a ledger, and a telephone, each with a stable place.
 named('DarkRoom').uiImage.color=[.025,.033,.029,1];
 for(let i=0;i<13;i++)named('WallBoard'+i).uiImage.color=[.048,.058,.046,1];
 named('Desk').uiImage.color=[.09,.067,.043,1];
 named('TVBody').uiImage.color=[.185,.125,.077,1];
 named('TVInnerWood').uiImage.color=[.24,.17,.104,1];
 named('MemoPaper').uiImage.color=paper;named('MemoPaper').uiImage.cornerRadius=2;
 place('MemoPaper',1080,64,464,192);place('MemoShadow',1088,72,464,192);
 named('MemoHeading').uiText.text='電話帳';label('MemoHeading',24,ink);
 ['MemoHome','MemoNeighbor','MemoCompany','MemoClock'].forEach((n,i)=>{place(n,1104,112+i*36,416,36);label(n,25,ink);});
 label('MemoHome',26,[.31,.14,.09,1]);
 label('SuspicionText',23,muted);named('SuspicionText').uiText.alignH=0;
 label('ReturnStatus',20,muted);label('LineStatus',25,bone);label('Digits',36,brass);
 place('Digits',1080,376,464,48);
 before(rect('LinePanel',1080,344,464,88,[.045,.062,.050,1],game,3,{outlineWidth:1,outlineColor:[.20,.25,.20,1]}),'LineStatus');
 named('PhoneMat').uiImage.color=[.14,.12,.085,1];
 named('PhoneBase').uiImage.color=[.06,.073,.066,1];
 named('DialRim').uiImage.color=[.48,.47,.38,1];
 named('DialCenter').uiImage.color=[.66,.64,.51,1];
 label('PhoneNumber',23,ink);
 named('CallBand').uiImage.cornerRadius=2;
 ordered(rect('CallAccent',32,8,4,48,brass,game),E.indexOf(named('CallBand'))+1);
 label('CallForecast',28,bone);label('CallCountdown',30,brass);
 named('FooterBand').uiImage.color=[.034,.047,.037,1];
 ordered(rect('PhaseAccent',32,752,4,136,brass,game),0);
 label('Act',28,brass);label('Instruction',25,bone);label('Threat',23,muted);
 label('SubtitleWho',23,brass);label('Subtitle',30,bone);
 named('SubtitleShade').uiImage.color=[.015,.023,.018,.97];

 // Notebook: two readable columns, route and current clue on separate lines.
 place('DiaryPaper',144,64,1312,776);named('DiaryPaper').uiImage.color=paper;
 place('DiaryHeading',208,96,1168,64);label('DiaryHeading',40,ink);
 text('DiaryDefenseHeading',208,184,536,48,'電話で守る',30,diary,ink);
 text('DiaryInvestigationHeading',840,184,536,48,'調べて止める',30,diary,ink);
 rect('DiaryDivider',792,184,1,376,[.43,.44,.35,1],diary);
 place('DiaryBody',208,248,536,296);Object.assign(named('DiaryBody').uiText,{fontSize:26,color:ink,text:'子どもの家　36-2026\n\n通話が成立している間だけ、番組の電話を遮断できる。\n切れたら受話器を戻して、かけ直す。\n\n番組が三回つながると、ヒロシが失われる。',wrap:true,alignV:0});
 text('DiaryInvestigation',840,248,536,232,'第二幕になったら、父の会社でブレーカーの場所を調べる。\n\n117は、番組の次の発信時刻を教えてくれる。調査中も電話の防衛を忘れずに。',26,diary,ink,{wrap:true,alignV:0});
 place('ClueStatus',840,496,536,72);Object.assign(named('ClueStatus').uiText,{fontSize:25,color:[.32,.24,.13,1],wrap:true});
 place('DiaryRoute',208,592,1168,56);label('DiaryRoute',28,ink);
 place('DiaryWarning',208,664,1168,40);label('DiaryWarning',24,[.44,.18,.12,1]);
 place('DiaryResume',208,744,360,56);place('DiaryResumeLabel',8,0,344,56);
 rect('DiaryRule',208,168,1168,1,[.43,.44,.35,1],diary);

 // Pause: one compact surface, with equally clear resume and return actions.
 before(rect('PausePanel',400,216,800,432,[.036,.052,.040,1],pause,3,{outlineWidth:1,outlineColor:[.26,.31,.24,1]}),'PauseTitle');
 place('PauseTitle',448,280,704,80);named('PauseTitle').uiText.text='放送を、止めています。';label('PauseTitle',44,bone);
 named('PauseTitle').uiText.alignH=0;
 text('PauseDescription',448,384,704,48,'電話も時計も、このまま待っています。',25,pause,muted);
 place('ResumeButton',448,496,336,64);place('ResumeButtonLabel',8,0,320,64);
 place('PauseReset',816,496,336,64);place('PauseResetLabel',8,0,320,64);

 // Endings: a quiet record beside the room. The adapter chooses its mood.
 named('EndDim').uiImage.color=dark;
 place('EndEyebrow',96,128,816,48);label('EndEyebrow',25,brass);
 place('EndingTitle',88,248,832,96);label('EndingTitle',56,bone);
 place('EndingBody',96,392,816,224);Object.assign(named('EndingBody').uiText,{fontSize:29,color:bone,wrap:true,alignV:0});
 place('EndingStats',96,624,816,80);Object.assign(named('EndingStats').uiText,{fontSize:23,color:muted,wrap:true,alignV:0});
 place('EndReset',96,744,360,64);place('EndResetLabel',8,0,344,64);
 rect('EndRule',96,208,816,1,[.30,.34,.28,1],end);
 rect('EndPhotoPaper',992,152,528,560,paper,end,1);
 image('EndRoom',1008,168,496,464,'textures/1989_room.png',end);
 rect('EndPhotoTint',1008,168,496,464,[.1,.15,.12,.12],end);
 text('EndPhotoCaption',1024,648,464,48,'1989年12月24日　茶の間',23,end,ink,{alignH:1});
}
