// Static presentation previews. Never changes the actual play scene.
// Run build_game.mjs first, then: node tools/preview_scene.mjs saved
import fs from 'node:fs';
const mode=process.argv[2]||'saved';
const scene=JSON.parse(fs.readFileSync('docs/generated/midnight_scene.json','utf8'));
const find=name=>scene.entities.find(e=>e.name===name);
delete find('MidnightDirector').luaScript;
for(const name of ['GameplayRoot','MenuRoot','DiaryRoot','PauseRoot','EndRoot'])find(name).uiRect.visible=false;
if(['saved','saved_exposed','lost','taken'].includes(mode)){
 const source=fs.readFileSync('assets/scripts/midnight_core.lua','utf8');
 const line=source.split('\n').find(l=>l.trim().startsWith(mode+' = {'));
 const parts=[...line.matchAll(/'([^']*)'/g)].map(m=>m[1]);
 find('EndRoot').uiRect.visible=true;
 const numerals={saved:'一',saved_exposed:'二',lost:'三',taken:'四'};
 find('EndEyebrow').uiText.text='放送終了　／　結末 '+numerals[mode];
 find('EndingTitle').uiText.text=parts[0].split('、')[1];
 find('EndingBody').uiText.text=parts[1]+'\n\n'+parts[2];
 find('EndingStats').uiText.text='遮断した電話 5 回　／　ヒロシ 0 歩\n番組の疑い 32';
 const rescued=mode.startsWith('saved');
 find('EndPhotoTint').uiImage.color=rescued?[.24,.30,.18,.12]:[.20,.035,.02,.38];
 find('EndPhotoCaption').uiText.text=({saved:'電話のない、朝が来る。',saved_exposed:'呼び鈴だけが、残った。',lost:'写真は、変わらなかった。',taken:'次は、こちらから生中継。'})[mode];
}else if(mode==='act2'){
 find('GameplayRoot').uiRect.visible=true;find('Act').uiText.text='第二幕　止める';
 find('PhaseAccent').uiImage.color=[.46,.66,.40,1];find('Clock').uiText.text='00:05:12';
 find('Instruction').uiText.text='通話中の数字　2 廊下 → 3 台所 → 0';
 find('ClueStatus').uiText.text='ブレーカー：台所の戸棚の上';
}else throw new Error('Use saved, saved_exposed, lost, taken, or act2');
fs.mkdirSync('docs/generated',{recursive:true});
fs.writeFileSync('docs/generated/preview_'+mode+'.json',JSON.stringify(scene,null,2));
console.log('Prepared '+mode+' preview');
