local Feedback=dofile('assets/scripts/midnight_feedback.lua')
local Core=dofile('assets/scripts/midnight_core.lua')
local count=0
local function test(n,f) f();count=count+1;print('PASS '..n) end
local function approx(a,b) assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b)) end
local function rig()
 local y=0;local outstanding=nil;local maxOutstanding=0
 local m=Feedback.receiverMotion(function(dy,seconds,done)
   assert(not outstanding,'Two relative tweens were started concurrently')
   outstanding={dy=dy,done=done};maxOutstanding=math.max(maxOutstanding,1)
 end)
 local function complete() if outstanding then local t=outstanding;outstanding=nil;y=y+t.dy;t.done() end end
 return m,complete,function()return y end
end
test('100 completed pickup/hangup cycles return to exact home position',function()
 local m,complete,y=rig()
 for i=1,100 do m:update(true);complete();approx(y(),-64);m:update(false);complete();approx(y(),0) end
end)
test('rapid reversal during an unfinished lift is queued and bounded',function()
 local m,complete,y=rig();m:update(true)
 for i=1,101 do m:update(i%2==0) end
 complete();m:update(false);complete();approx(y(),0);approx(m.pose,0)
end)
test('return to title while lifting still restores the physical home pose',function()
 local m,complete,y=rig();m:update(true);m:update(false);complete();m:update(false);complete();approx(y(),0)
end)
test('repeated frames at one endpoint cannot accumulate translation',function()
 local m,complete,y=rig();m:update(true);complete();for i=1,500 do m:update(true) end;approx(y(),-64)
end)
test('all ten digits wind clockwise then return monotonically to zero',function()
 for digit=0,9 do
  local t=Core.dialTiming(digit);approx(Feedback.dialAngle(t,t.total),0)
  approx(Feedback.dialAngle(t,t.returning),t.angle)
  local previous=t.angle
  for i=1,100 do local a=Feedback.dialAngle(t,t.returning*(1-i/100));assert(a<=previous+1e-5 and a>=0);previous=a end
  approx(previous,0)
 end
end)
test('zero sends ten pulses; mechanical duration does not change in short mode',function()
 assert(Core.dialTiming(0).pulses==10)
 for _,duration in ipairs({180,900}) do
  local g=Core.new{duration=duration};g:start();g:pickup();g:dial(0);g:update(.1)
  approx(g.cooldown,Core.dialTiming(0).total-.1)
 end
end)
test('warning precedes a call by enough time to finish a real-speed home dial',function()
 for _,duration in ipairs({180,900}) do
  local g=Core.new{duration=duration};g:start()
  local cost=0;for d in Core.numbers.home:gmatch('.') do cost=cost+Core.dialTiming(tonumber(d)).total end
  assert(g:callLead()*duration/900>cost+2.2*duration/900)
  g.t=g.nextCall-g:callLead()-1;assert(g:callCue().level==0)
  g.t=g.nextCall-g:callLead()+.1;assert(g:callCue().level==1)
  g.t=g.nextCall-9;assert(g:callCue().level==2)
  g.t=g.nextCall-2;assert(g:callCue().level==3)
 end
end)
test('forewarning levels only emit once per attempt, and distinguish protected state',function()
 local g=Core.new();g:start();g.t=g.nextCall-10.1;g:drainEvents();g:update(.2)
 local n=0;for _,e in ipairs(g:drainEvents()) do if e.kind=='warning' then n=n+1 end end;assert(n==1)
 g:update(.1);for _,e in ipairs(g:drainEvents()) do assert(e.kind~='warning') end
 g.line='talk';g.target='home';assert(g:callCue().protected)
 g:programCall();assert(g:callCue().recent and g:callCue().blocked)
end)
test('character room changes use absolute destinations rather than accumulating offsets',function()
 local x,y=392,352
 local m=Feedback.offsetMotion(function(dx,dy,done) x=x+dx;y=y+dy;done() end)
 for i=1,50 do m:update(180,-110);m:update(345,-65);approx(x,737);approx(y,287);m:update(0,0);approx(x,392);approx(y,352) end
end)
test('short-mode forewarning retains at least six real seconds of reaction margin',function()
 local g=Core.new{duration=180};local cost=0
 for d in Core.numbers.home:gmatch('.') do cost=cost+Core.dialTiming(tonumber(d)).total end
 assert(g:callLead()/5-cost-2.2/5>=6)
end)
print(count..' feedback regression tests passed')
