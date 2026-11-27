-- App layer. Core is injected by tools/build_game.mjs; no require/IO at runtime.
properties = { {name='device',type='string',default='midnight_phone',label='黒電話デバイス'} }
local labels={idle='受話器を取る',dial='番号を回す',connecting='呼び出し中',talk='通話中',busy='ツー、ツー……'}
local roomLabels={'茶の間','廊下','台所'}
local function entity(self,name)
  if not self.handles[name] then self.handles[name]=scene:findEntity(name) end
  return self.handles[name]
end
local function text(self,name,value)
  value=tostring(value or '')
  if self.textCache[name]~=value then scene:setUiText(entity(self,name),value);self.textCache[name]=value end
end
local function visible(self,name,value)
  if self.visibleCache[name]~=value then scene:setUiVisible(entity(self,name),value);self.visibleCache[name]=value end
end
local function sound(name,volume,loop)
  return audio:play('audio/'..name..'.wav',{bus='sfx',volume=volume or .55,loop=loop or false})
end
local function stop(id) if id and id>=0 then audio:stopVoice(id,.08) end end
local function clearPhoneAudio(self)
  for _,key in ipairs({'ringing','rotary','callerVoice','lineTone','speech'}) do stop(self[key]);self[key]=nil end
  self.lineToneKind=nil
end
local function begin(self,duration)
  clearPhoneAudio(self)
  self.game=Core.new{duration=duration};self.game:start();self.lastEnding=nil;self.notes=false
  visible(self,'MenuRoot',false);visible(self,'EndRoot',false);visible(self,'GameplayRoot',true)
  visible(self,'PauseRoot',false);visible(self,'DiaryRoot',false)
  if self.device.connected then self.device:set('bell',0) end
end
local function hook(self)
  if self.hookLock>0 then return end
  if not self.game or self.game.phase=='title' then return end
  self.hookLock=.14
  if self.game.offhook then self.game:hangup() else self.game:pickup() end
end
local function reset(self)
  clearPhoneAudio(self)
  self.game=Core.new();visible(self,'MenuRoot',true);visible(self,'EndRoot',false)
  visible(self,'GameplayRoot',false);visible(self,'PauseRoot',false);visible(self,'DiaryRoot',false)
  if self.device.connected then self.device:set('bell',0) end
end
function OnStart(self)
  self.handles={};self.textCache={};self.visibleCache={};self.device=hw.device(self.device)
  self.game=Core.new();self.ringPulse=0;self.lastHook=false;self.lastSequence=nil
  self.hookLock=0
  self.receiverMotion=Feedback.receiverMotion(function(dy,seconds,done)
    scene:tweenUi(entity(self,'ReceiverAssembly'),{dy=dy,duration=seconds,easing='inOut',onComplete=done})
  end)
  self.midoriMotion=Feedback.offsetMotion(function(dx,dy,done)
    local seconds=math.max(.3,math.min(5,self.game.moving*self.game.duration/900))
    scene:tweenUi(entity(self,'Midori'),{dx=dx,dy=dy,duration=seconds,easing='inOut',onComplete=done})
  end)
  self.hiroshiMotion=Feedback.offsetMotion(function(dx,dy,done)
    scene:tweenUi(entity(self,'Hiroshi'),{dx=dx,dy=dy,duration=.8,easing='inOut',onComplete=done})
  end)
  self.ambient=audio:play('audio/ambience.wav',{bus='ambience',volume=.4,loop=true})
  self.voices=VoicePaths;self.muted=false
  audio:setBusLowpass('voice',3200)
  local function bind(ev,fn) events:on(ev,function() self.uiActionFrame=time.frame();fn(self) end) end
  bind('midnight_start',function(s) begin(s,900) end)
  bind('midnight_short',function(s) begin(s,180) end)
  bind('midnight_hook',hook)
  bind('midnight_reset',reset)
  bind('midnight_resume',function(s) s.game.paused=false;s.notes=false end)
  for n=0,9 do local digit=n;bind('midnight_digit_'..n,function(s) s.game:dial(digit) end) end
  bind('midnight_notes',function(s) if s.game.phase~='title' and not s.game.ending then s.notes=not s.notes;s.game.paused=s.notes end end)
  reset(self)
end
local function updateInput(self)
  local g=self.game
  if keyPressed('M') then self.muted=not self.muted;audio:setBusMute('sfx',self.muted);audio:setBusMute('ambience',self.muted);audio:setBusMute('voice',self.muted) end
  if self.uiActionFrame==time.frame() then return end
  if keyPressed('ENTER') and not input:isUiCapturingNav() then
    if g.phase=='title' then begin(self,900) elseif g.ending then reset(self) end
  end
  if g.phase=='title' then if keyPressed('Q') then begin(self,180) end;return end
  if g.ending then return end
  if keyPressed('ESC') then g.paused=not g.paused;self.notes=false end
  if keyPressed('TAB') then self.notes=not self.notes;g.paused=self.notes end
  if g.paused then return end
  if keyPressed('E') or (keyPressed('SPACE') and not input:isUiCapturingNav()) then hook(self) end
  if keyPressed('BACKSPACE') then g:hangup() end
  for n=0,9 do
    if input:isKeyPressed(48+n) or input:isKeyPressed(96+n) then g:dial(n) end
  end
  local d=self.device
  if d.connected then
    local lifted=d:down('hook')
    if lifted~=self.lastHook then if lifted then g:pickup() else g:hangup() end;self.lastHook=lifted end
    local seq=d:raw('sequence')
    if self.lastSequence~=nil and seq~=self.lastSequence then g:dial(d:raw('digit'),true) end
    self.lastSequence=seq
  else self.lastSequence=nil;self.lastHook=false end
end
local function updateEvents(self,dt)
  local g=self.game
  for _,ev in ipairs(g:drainEvents()) do
    local k=ev.kind
    if k=='dial' then
      stop(self.rotary)
      if not g.physicalDial then self.rotary=sound('dial_'..ev.value,.48) end
    elseif k=='ring' then self.ringPulse=0
    elseif k=='caller_dial' then
      stop(self.callerVoice);self.callerVoice=sound('dial_'..ev.value,.58)
    elseif k=='dialogue' then
      -- Recorded dialogue uses an exact-text lookup; missing lines remain captioned.
      local path=self.voices[ev.value.text]
      if path then stop(self.speech);self.speech=audio:play(path,{bus='voice',volume=.8}) end
    elseif k=='ending' then
      clearPhoneAudio(self)
      if ev.value=='taken' or ev.value=='lost' then sound('reveal',.45) else sound('breaker',.55) end
    elseif k=='clue' then sound('clock',.3)
    elseif k=='blocked' then sound('program_click',.25)
    elseif k=='warning' then sound(ev.value>=2 and 'program_urgent' or 'program_alert',.32)
    elseif k=='hangup' then stop(self.speech);sound('hangup',.45)
    elseif k=='move' then sound('step',.28)
    elseif k=='step' then sound('step',.65)
    elseif k~='act' then
      local sounds={power=true,pickup=true,connect=true,breaker=true,reveal=true}
      if sounds[k] then sound(k) end
    end
  end
  if self.rotary and not g.pendingDigit then stop(self.rotary);self.rotary=nil end
  if g.ring and not g.ending and not g.paused then
    self.ringPulse=self.ringPulse-dt
    if self.ringPulse<=0 then stop(self.callerVoice);self.ringing=sound('ring',.52);self.ringPulse=3 end
  else stop(self.ringing);self.ringing=nil end
  if self.device.connected then self.device:set('bell',(g.ring and not g.paused and not g.ending) and 1 or 0) end
  local tone=nil
  if not g.paused and not g.ending and g.offhook then
    if g.line=='dial' and g.digits=='' and not g.pendingDigit then tone='dialtone'
    elseif g.line=='connecting' then tone='ringback'
    elseif g.line=='busy' then tone='busy' end
  end
  if tone~=self.lineToneKind then
    stop(self.lineTone);self.lineTone=nil;self.lineToneKind=tone
    if tone then self.lineTone=sound(tone,.24,true) end
  end
end
local function updateScene(self)
  local g=self.game
  if g.phase=='title' then return end
  visible(self,'GameplayRoot',not g.ending and not g.paused)
  visible(self,'DiaryRoot',self.notes and not g.ending)
  visible(self,'PauseRoot',g.paused and not self.notes and not g.ending)
  text(self,'Clock',string.format('00:%02d:%02d',math.floor(g.t/60),math.floor(g.t%60)))
  text(self,'Act',(g.phase=='act2' and '第二幕　止める' or g.phase=='intro' and 'はじまり' or '第一幕　守る')..(g.duration==180 and '［時計5倍］' or ''))
  scene:setUiColor(entity(self,'PhaseAccent'),g.phase=='act2' and .46 or .76,g.phase=='act2' and .66 or .65,.40,1)
  text(self,'SubtitleWho',g.t<=g.messageUntil and g.speaker or '')
  text(self,'Subtitle',g.t<=g.messageUntil and g.message or '……')
  text(self,'LineStatus',g.ring and 'こちら側に着信 ―― 取らないこと' or g.pendingDigit and '回転中 ―― 戻るまでお待ちください' or (labels[g.line] or ''))
  text(self,'Digits',g.digits=='' and '― ― ― ― ― ―' or g.digits)
  text(self,'HookLabel',g.offhook and '受話器を置く  [E]' or '受話器を取る  [E]')
  text(self,'Threat',g.strikes==0 and 'ヒロシは、まだ茶の間にいる。' or string.format('ヒロシが %d / 3 歩、近づいた。',g.strikes))
  text(self,'MidoriLocation','ミドリ：'..roomLabels[g.room]..(g.moving>0 and ' → 移動中' or ''))
  text(self,'ClueStatus',g.clue and 'ブレーカー：台所の戸棚の上' or 'ブレーカー：父の会社に聞く')
  text(self,'Instruction',g.phase=='act2' and (g.clue and '通話中の数字　2 廊下 → 3 台所 → 0' or '117で時刻を読み、回線が空く間に父の会社を調べる。') or '先に 36-2026 へ。通話中なら、番組は入れない。')
  text(self,'SuspicionText',g.exposed and '発覚：番組はこちらを見ている' or g.suspicion>=65 and '疑念：数字の音を聞かれている' or '番組は、まだ気づいていない')
  scene:setUiFill(entity(self,'SuspicionFill'),g.suspicion/100)
  scene:setUiColor(entity(self,'SuspicionFill'),g.suspicion>=65 and .72 or .58,g.suspicion>=65 and .16 or .49,.24,1)
  text(self,'ReturnStatus',g.pendingDigit and '回して、指を離す。数字は戻りきってから届く。' or '番号を間違えたら、受話器を置いてかけ直す。')
  scene:setUiFill(entity(self,'ReturnFill'),g.pendingDigit and 1-g.cooldown/g.dialDuration or 0)
  visible(self,'ThreatTint',g.strikes>0 or g.exposed)
  if g.strikes>0 or g.exposed then scene:setUiColor(entity(self,'ThreatTint'),.35,.015,.01,g.exposed and .12 or .035*g.strikes) end
  visible(self,'ExposedText',g.exposed and not g.saved)
  visible(self,'ExposedBackdrop',g.exposed and not g.saved)
  text(self,'ExposedText',g.ring and '3620　こちら側の電話が鳴る' or ('番組が回している番号　'..g.callerDigits))
  visible(self,'PowerOff',g.saved)
  for n=0,9 do visible(self,'Dial'..n..'Label',not g.pendingDigit) end
  text(self,'PhoneNumber',g.pendingDigit and tostring(g.pendingDigit) or '3620')
  if g.pendingDigit then
    scene:setUiRotation(entity(self,'DialControls'),g.physicalDial and 0 or Feedback.dialAngle(Core.dialTiming(g.pendingDigit),g.cooldown))
  else scene:setUiRotation(entity(self,'DialControls'),0) end
  local cue=g:callCue()
  local forecast='次の発信は、117で時刻を確認できます'
  local counter=''
  if g.ring then forecast='こちら側の黒電話に着信中。受話器を取らない';counter='3620'
  elseif cue.recent then forecast=cue.blocked and '番組の電話を「話し中」で遮断した' or '番組がつながった ―― ヒロシが一歩近づいた';counter=cue.blocked and '遮断成功' or (g.strikes..' / 3')
  elseif cue.level>0 or g.learnedClock then
    forecast=cue.protected and '番組が発信準備中 ―― 家の回線は保護されています' or '番組がまもなく電話します ―― 子どもの家へかけて'
    counter=string.format('放送あと %02d 秒',math.ceil(cue.remaining))
  end
  text(self,'CallForecast',forecast);text(self,'CallCountdown',counter)
  text(self,'Protection',cue.protected and '回線保護中' or '家の回線は無防備')
  local warning=g.ring or (cue.level>0 and not cue.protected) or (cue.recent and not cue.blocked)
  scene:setUiColor(entity(self,'CallBand'),warning and .19 or .055,warning and .08 or .075,.045,1)
  scene:setUiColor(entity(self,'CallCountdown'),warning and .97 or .77,warning and .65 or .83,.38,1)
  visible(self,'PhoneRingGlow',g.ring and math.floor(g.real*4)%2==0)
  visible(self,'Hiroshi',g.strikes<3 and not g.saved)
  if g.ending then
    local ending=Core.endings[g.ending]
    visible(self,'EndRoot',true);visible(self,'MenuRoot',false)
    local numbers={saved='一',saved_exposed='二',lost='三',taken='四'}
    text(self,'EndEyebrow','放送終了　／　結末 '..numbers[g.ending])
    text(self,'EndingTitle',ending[1]:gsub('^.-、',''));text(self,'EndingBody',ending[2]..'\n\n'..ending[3])
    text(self,'EndingStats',string.format('遮断した電話 %d 回　／　ヒロシ %d 歩\n番組の疑い %d',g.blocked,g.strikes,math.floor(g.suspicion)))
    local rescued=g.ending=='saved' or g.ending=='saved_exposed'
    scene:setUiColor(entity(self,'EndPhotoTint'),rescued and .24 or .20,rescued and .30 or .035,rescued and .18 or .02,rescued and .12 or .38)
    text(self,'EndPhotoCaption',g.ending=='saved' and '電話のない、朝が来る。' or g.ending=='saved_exposed' and '呼び鈴だけが、残った。' or g.ending=='lost' and '写真は、変わらなかった。' or '次は、こちらから生中継。')
    if self.lastEnding~=g.ending then
      self.lastEnding=g.ending;savePersist('midnight_ending_'..g.ending,1)
    end
  end
  -- Shared read-only telemetry for MCP runtime checks, not a gameplay shortcut.
  saveNum('midnight.time',g.t);saveNum('midnight.strikes',g.strikes);saveNum('midnight.blocked',g.blocked)
  saveNum('midnight.phase',g.phase=='act2' and 2 or g.phase=='act1' and 1 or 0)
  saveNum('midnight.clue',g.clue and 1 or 0);saveNum('midnight.room',g.room)
  saveNum('midnight.exposed',g.exposed and 1 or 0);saveNum('midnight.saved',g.saved and 1 or 0)
end
function OnUpdate(self,dt)
  self.hookLock=math.max(0,self.hookLock-dt)
  updateInput(self)
  self.game:update(dt)
  updateEvents(self,dt)
  self.receiverMotion:update(self.game.offhook and not self.game.ending)
  local room=(self.game.destination and self.game.destination>0) and self.game.destination or self.game.room
  self.midoriMotion:update(({0,180,345})[room],({0,-110,-65})[room])
  self.hiroshiMotion:update(self.game.strikes*65,-self.game.strikes*34)
  updateScene(self)
end
