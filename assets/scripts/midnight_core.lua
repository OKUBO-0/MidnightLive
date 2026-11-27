-- Engine-independent rules. The adapter alone owns devices, sound and rendering.
local M = {}
-- The mechanism uses real seconds in both game modes: 0 sends ten pulses.
function M.dialTiming(n)
  local pulses=n==0 and 10 or n
  local wind=.18+.04*pulses
  local returning=.16+.10*pulses
  return {pulses=pulses,wind=wind,returning=returning,total=wind+returning,angle=50+30*pulses}
end
M.numbers = { home = '362026', neighbor = '361121', company = '099090', clock = '117' }
M.endings = {
  saved = { '一、電話のない朝', 'テレビは消えた。ヒロシは、姉の隣で眠っている。', '翌朝、古い家族写真に、ひとり増えていた。' },
  saved_exposed = { '二、こちら側の呼び鈴', 'ヒロシは助かった。けれど番組は、あなたの番号を知った。', '電話には出なかった。それでも、夜ごと呼び鈴がする。' },
  lost = { '三、変わらない写真', '午前零時十五分。番組は、何事もなく終わった。', '古い写真には、やはり姉ひとりしか写っていない。' },
  taken = { '四、次の生中継', '受話器の向こうで、拍手がした。', '「次は、あなたのお宅からお送りします」' },
}
local function copy(t) local r={} for k,v in pairs(t) do r[k]=v end return r end
function M.new(options)
  options=options or {}
  local g={t=0, real=0, duration=options.duration or 900, phase='title', line='idle', offhook=false,
    digits='', cooldown=0, pendingDigit=nil, connection=0, target=nil, talk=0,
    strikes=0, blocked=0, attempts=0, suspicion=0, exposed=false, exposureAt=nil,
    ring=false, ringAt=nil, answered=false, saved=false, ending=nil, room=1, moving=0,
    destination=nil, clue=false, neighbor=false, learnedClock=false, nextCall=78,
    message='茶の間に、古いメモが残されている。', speaker='メモ', messageUntil=0,
    serviceDone=false, paused=false, events={}, history={}, commandCount=0, callerDigits='',callerStep=0,
    warned={},lastCallAt=-100,lastCallBlocked=false}
  function g:emit(kind,value) self.events[#self.events+1]={kind=kind,value=value} end
  function g:say(who,text,seconds)
    self.speaker=who;self.message=text;self.messageUntil=self.t+(seconds or 10)
    self.history[#self.history+1]={time=math.floor(self.t),speaker=who,text=text}
    if #self.history>12 then table.remove(self.history,1) end
    self:emit('dialogue',{who=who,text=text})
  end
  function g:start()
    if self.phase~='title' then return false end
    self.phase='intro';self:say('メモ','「0じの でんわには でないこと」\n裏に、36-2026と書いてある。',14);self:emit('power');return true
  end
  function g:finish(key)
    if self.ending then return end
    self.ending=key;self.phase='ending';self.ring=false;self.line='idle';self.offhook=false
    self:emit('ending',key)
  end
  function g:reveal()
    if self.exposed or self.ending then return end
    self.exposed=true;self.exposureAt=self.t;self.ringAt=self.t+12
    self:say('番組','「邪魔をしていたのは、2026年のお宅でしたか」',12);self:emit('reveal')
  end
  function g:addSuspicion(v)
    self.suspicion=math.min(100,self.suspicion+v)
    if self.suspicion>=100 then self:reveal() end
  end
  function g:pickup()
    if self.phase=='title' then return self:start() end
    if self.ending or self.paused or self.offhook then return false end
    if self.ring then self.answered=true;self:finish('taken');return true end
    self.offhook=true;self.line='dial';self.digits='';self.target=nil
    self:say('受話器','ツー……。数字を回して、電話をかける。',5);self:emit('pickup');return true
  end
  function g:hangup()
    if self.ending or self.paused then return false end
    if not self.offhook then return false end
    self.offhook=false;self.line='idle';self.digits='';self.cooldown=0;self.pendingDigit=nil
    self.target=nil;self.talk=0;self.connection=0;self:emit('hangup');return true
  end
  function g:command(n)
    if self.phase~='act2' then
      self:say('ミドリ','「数字……？ 今は、ヒロシを見ていて」',6);self:addSuspicion(4);return
    end
    if self.moving>0 then self:say('ミドリ','「待って。まだ、そこに着いていない」',4);self:addSuspicion(7);return end
    self.commandCount=self.commandCount+1
    self:addSuspicion(n==0 and 12 or 8)
    if n==1 then self.destination=1;self.moving=4;self:say('ミドリ','「1。茶の間に戻ればいいのね」',6)
    elseif n==2 and self.room==1 then self.destination=2;self.moving=5;self:say('ミドリ','「2……廊下？ 行ってみる」',7)
    elseif n==3 and self.room==2 then self.destination=3;self.moving=6;self:say('ミドリ','「3。台所ね。ヒロシ、そこにいて」',8)
    elseif n==0 and self.room==3 and self.clue then
      self.destination=0;self.moving=5;self:say('ミドリ','「戸棚の上……あった。これを、下げれば……」',7)
    elseif n==0 and self.room==3 then self:say('ミドリ','「暗くて、どこを触ればいいのかわからない」',7)
    else self:addSuspicion(16);self:say('ミドリ','「そこへは、ここから行けないよ。メモを見て」',7) end
  end
  function g:dial(n,physical)
    if self.ending or self.paused or not self.offhook or self.cooldown>0 or self.pendingDigit then return false end
    n=tonumber(n);if not n or n<0 or n>9 or n%1~=0 then return false end
    if self.line~='dial' and not(self.line=='talk' and self.target=='home') then return false end
    self.pendingDigit=n;self.physicalDial=physical or false
    self.dialDuration=physical and .08 or M.dialTiming(n).total
    self.cooldown=self.dialDuration;self:emit('dial',n);return true
  end
  function g:commitDigit(n)
    if self.line=='talk' and self.target=='home' then self:command(n);return end
    if self.line~='dial' then return end
    self.digits=self.digits..tostring(n)
    self:addSuspicion(0.65)
    local found=nil;local prefix=false
    for k,num in pairs(M.numbers) do
      if num==self.digits then found=k end
      if num:sub(1,#self.digits)==self.digits then prefix=true end
    end
    if found then self.target=found;self.line='connecting';self.connection=2.2;self:emit('calling')
    elseif not prefix or #self.digits>=6 then
      self.line='busy';self:say('交換局','「おかけになった番号は、現在使われておりません」',8);self:emit('busy')
    end
  end
  function g:connect()
    self.line='talk';self.talk=0;self.serviceDone=false;self:emit('connect')
    if self.target=='home' then
      self:say('ヒロシ','「もしもし？ ……お姉ちゃん、だれもしゃべらないよ」',9)
    elseif self.target=='company' then self:say('父の会社','「あの家のブレーカー？ ちょっと待ってください……」',8)
    elseif self.target=='neighbor' then self:say('隣家','「こんな時間に？ ……向こうの窓だけ、明るいね」',6)
    elseif self.target=='clock' then
      self.learnedClock=true;self:say('117・時報',string.format('「次の呼び出しは、零時%02d分%02d秒……」',math.floor(self.nextCall/60),math.floor(self.nextCall%60)),9)
    end
  end
  function g:programCall()
    if self.saved or self.ending then return end
    self.attempts=self.attempts+1
    self.lastCallAt=self.t;self.lastCallBlocked=self.line=='talk' and self.target=='home'
    if self.line=='talk' and self.target=='home' then
      self.blocked=self.blocked+1;self:emit('blocked');self:say('番組','「……お話し中のようですね。また、後ほど」',7)
    else
      self.strikes=self.strikes+1;self:emit('step',self.strikes)
      if self.strikes>=3 then
        self:say('番組','「今夜のお客様が、到着しました」',7)
        self:finish(self.exposed and 'taken' or 'lost')
      else self:say('ヒロシ','「テレビのおじさんが、こっちへおいでって……」',9) end
    end
    local intervals={46,58,51,64,48,57}
    self.nextCall=self.nextCall+intervals[(self.attempts-1)%#intervals+1]
  end
  function g:callLead()
    local seconds=0
    for d in M.numbers.home:gmatch('.') do seconds=seconds+M.dialTiming(tonumber(d)).total end
    -- Reserve real reaction time too; a 5x broadcast must not shrink that margin.
    return math.max(20,math.ceil((seconds+6)*900/self.duration+2.2))
  end
  function g:callCue()
    local remaining=math.max(0,self.nextCall-self.t)
    local protected=self.line=='talk' and self.target=='home'
    local level=remaining<=3 and 3 or remaining<=10 and 2 or remaining<=self:callLead() and 1 or 0
    if self.saved or self.ending or self.phase=='title' then level=0 end
    return {remaining=remaining,level=level,protected=protected,
      recent=self.t-self.lastCallAt<6,blocked=self.lastCallBlocked}
  end
  function g:update(realDt)
    if self.phase=='title' or self.ending or self.paused then return end
    local dt=math.max(0,realDt)*900/self.duration
    self.real=self.real+math.max(0,realDt);self.t=self.t+dt
    if self.phase=='intro' and self.t>=60 then self.phase='act1';self:say('番組','「今夜は、留守番中のお宅にお電話しましょう」',10);self:emit('act',1) end
    if self.phase=='act1' and self.t>=300 then self.phase='act2';self:say('ミドリ','「このままじゃ、ずっと終わらない。テレビを止めなきゃ」',12);self:emit('act',2) end
    if self.pendingDigit then
      self.cooldown=math.max(0,self.cooldown-math.max(0,realDt))
      if self.cooldown<=0 then local n=self.pendingDigit;self.pendingDigit=nil;self:commitDigit(n) end
    end
    if self.line=='connecting' then self.connection=self.connection-dt;if self.connection<=0 then self:connect() end end
    if self.line=='talk' then
      self.talk=self.talk+dt
      if self.target=='home' then
        local limit=self.phase=='act2' and 42 or 34
        if self.talk>=limit then self.line='busy';self.target=nil;self:say('ヒロシ','「何も言わないなら、もう切るよ」',7);self:emit('busy') end
      elseif self.target=='company' and self.talk>=8 and not self.serviceDone then
        self.clue=true;self.serviceDone=true;self:say('父の会社','「台所の戸棚の上です。廊下を通って台所へ。\n1は茶の間、2は廊下、3は台所。最後は0を」',13);self:emit('clue','company')
      elseif self.target=='neighbor' and self.talk>=5 and not self.serviceDone then
        self.neighbor=true;self.serviceDone=true;self:say('隣家','「ミドリちゃんが廊下へ出れば、台所は右。\n妙な番組には、番号を聞かせすぎないことだよ」',11);self:emit('clue','neighbor')
      end
      if self.target~='home' and self.talk>=23 then self.line='busy';self.target=nil;self:emit('busy') end
    end
    if self.moving>0 then
      self.moving=math.max(0,self.moving-dt)
      if self.moving<=0 then
        if self.destination==0 then
          self.saved=true;self:emit('breaker');self:say('ミドリ','「消えた……！ ヒロシ、もう大丈夫」',9)
          if not self.exposed then self:finish('saved') else self.saveWaitUntil=self.t+16 end
        else self.room=self.destination;self:say('ミドリ',({'「茶の間に戻ったよ」','「廊下に着いた。次は？」','「台所。戸棚は、どこ……？」'})[self.room],6);self:emit('move',self.room) end
        self.destination=nil
      end
    end
    while self.t>=self.nextCall and not self.ending and not self.saved do self:programCall() end
    local cue=self:callCue()
    if cue.level>0 then
      local key=tostring(self.attempts)..':'..tostring(cue.level)
      if not self.warned[key] then self.warned[key]=true;self:emit('warning',cue.level) end
    end
    if self.exposed and self.ringAt and self.t>=self.ringAt and not self.ring then
      self.ring=true;self:emit('ring');self:say('黒電話','目の前の電話が、鳴っている。\n「鳴ってから、取らないこと」',12)
    end
    if self.exposed and self.exposureAt and not self.ending then
      local digits={3,6,2,0}
      while self.callerStep<4 and self.t>=self.exposureAt+self.callerStep*3 do
        self.callerStep=self.callerStep+1
        self.callerDigits=self.callerDigits..tostring(digits[self.callerStep])
        self:emit('caller_dial',digits[self.callerStep])
      end
    end
    if self.saved and self.exposed and self.saveWaitUntil and self.t>=self.saveWaitUntil then self:finish('saved_exposed') end
    if self.t>=900 and not self.ending then
      if self.saved then self:finish(self.exposed and 'saved_exposed' or 'saved')
      else self:finish(self.exposed and 'taken' or 'lost') end
    end
  end
  function g:drainEvents() local e=self.events;self.events={};return e end
  function g:snapshot()
    return {phase=self.phase,time=self.t,line=self.line,target=self.target,offhook=self.offhook,
      digits=self.digits,strikes=self.strikes,blocked=self.blocked,suspicion=self.suspicion,
      exposed=self.exposed,ring=self.ring,clue=self.clue,neighbor=self.neighbor,room=self.room,
      moving=self.moving,saved=self.saved,ending=self.ending,nextCall=self.nextCall}
  end
  return g
end
return M
