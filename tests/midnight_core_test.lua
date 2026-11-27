local Core=dofile('assets/scripts/midnight_core.lua')
local count=0
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function advance(g,t) for _=1,math.floor(t*20) do g:update(.05) end end
local function number(g,s) for d in s:gmatch('.') do assert(g:dial(tonumber(d))); advance(g,2.1) end;advance(g,2.5) end
local function ready() local g=Core.new();g:start();g.t=300;g.phase='act2';g.nextCall=400;return g end
test('title does not tick; start enters timed intro',function() local g=Core.new();g:update(5);eq(g.t,0);g:start();advance(g,60.1);eq(g.phase,'act1') end)
test('short mode preserves the same 15-minute broadcast timeline',function() local g=Core.new{duration=180};g:start();advance(g,12.1);eq(g.phase,'act1');assert(g.t>60) end)
test('receiver, rotary return and prefix validation',function()
 local g=ready();eq(g:dial(3),false);g:pickup();assert(g:dial(3));eq(g:dial(6),false);advance(g,2);eq(g.digits,'3');g:hangup();eq(g.digits,'');g:pickup();number(g,'5');eq(g.line,'busy')
end)
test('home protects only once connected, then child hangs up',function()
 local g=ready();g:pickup();number(g,Core.numbers.home);eq(g.target,'home');eq(g.line,'talk');g:programCall();eq(g.blocked,1);eq(g.strikes,0);advance(g,43);eq(g.line,'busy');g:programCall();eq(g.strikes,1)
end)
test('dialing does not protect; three successful program calls lose Hiroshi',function()
 local g=ready();g:pickup();g:dial(3);g:programCall();g:programCall();eq(g.strikes,2);eq(g.ending,nil);g:programCall();eq(g.ending,'lost')
end)
test('117 announces actual next-call timestamp',function()
 local g=ready();g:pickup();number(g,'117');assert(g.learnedClock);eq(g.target,'clock');assert(g.message:find('06分40秒',1,true))
end)
test('investigation has a vulnerable delay and yields distinct clues',function()
 local g=ready();g:pickup();number(g,Core.numbers.company);eq(g.clue,false);advance(g,8.1);eq(g.clue,true);g:programCall();eq(g.strikes,1)
 g:hangup();g:pickup();number(g,Core.numbers.neighbor);advance(g,5.1);eq(g.neighbor,true)
end)
test('breaker requires route, clue and completed movement',function()
 local g=ready();g:command(3);eq(g.room,1);g:command(2);advance(g,5.1);eq(g.room,2);g:command(3);advance(g,6.1);eq(g.room,3);g:command(0);eq(g.saved,false);g.clue=true;g:command(0);advance(g,5.1);eq(g.ending,'saved')
end)
test('too many numbers reveal caller; new pickup answers ringing phone',function()
 local g=ready();g:addSuspicion(100);eq(g.exposed,true);advance(g,12.1);eq(g.ring,true);g:pickup();eq(g.answered,true);eq(g.ending,'taken');eq(g.ring,false)
end)
test('already lifted receiver must be replaced before answering new call',function()
 local g=ready();g:pickup();g:reveal();advance(g,12.1);eq(g:pickup(),false);eq(g.ending,nil);g:hangup();g:pickup();eq(g.ending,'taken')
end)
test('rescue after discovery waits through the dangerous real-world ringing',function()
 local g=ready();g:reveal();g.clue=true;g.room=3;g:command(0);advance(g,5.1);eq(g.saved,true);eq(g.ending,nil);advance(g,12);eq(g.ring,true);advance(g,5);eq(g.ending,'saved_exposed')
end)
test('four endings and terminal state are stable',function()
 for key in pairs(Core.endings) do local g=ready();g:finish(key);g:update(999);g:pickup();g:hangup();eq(g.ending,key);eq(g.ring,false) end
end)
test('pause freezes time and input',function()
 local g=ready();g.paused=true;g:update(20);eq(g.t,300);eq(g:pickup(),false)
end)
test('fifteen minutes without shutting broadcast chooses loss',function()
 local g=ready();g.t=899;g.nextCall=1000;g:update(2);eq(g.ending,'lost')
end)
test('the adversary actually dials 3, 6, 2, 0 before ringing',function()
 local g=ready();g:reveal();advance(g,9.2);eq(g.callerDigits,'3620');eq(g.ring,false);advance(g,3);eq(g.ring,true)
end)
local function untilTime(g,t) while g.t<t and not g.ending do g:update(.05) end end
local function home(g) g:hangup();g:pickup();number(g,Core.numbers.home) end
local function campaign(expose,answer)
 local g=Core.new();g:start()
 for _,call in ipairs({78,124,182,233,297}) do untilTime(g,call-20);home(g);untilTime(g,call+1) end
 untilTime(g,301);eq(g.phase,'act2');g:hangup();g:pickup();number(g,Core.numbers.company);advance(g,8.1);assert(g.clue)
 home(g)
 if expose then for i=1,3 do assert(g:dial(3));advance(g,2.1) end end
 assert(g:dial(2));advance(g,7.2)
 if answer then
   assert(g.exposed);untilTime(g,g.ringAt+.2);g:hangup();g:pickup();return g
 end
 assert(g:dial(3));advance(g,8.2);assert(g:dial(0));advance(g,7.2)
 if expose then assert(g.exposed);advance(g,17) end
 return g
end
test('complete campaign: protect five calls, investigate, navigate, rescue',function()
 local g=campaign(false,false);eq(g.ending,'saved');assert(g.blocked>=5);eq(g.strikes,0)
end)
test('complete campaign: rescue after exposure while refusing the ringing phone',function()
 local g=campaign(true,false);eq(g.ending,'saved_exposed')
end)
test('complete campaign: answering the present-day call is terminal',function()
 local g=campaign(true,true);eq(g.ending,'taken');eq(g.answered,true)
end)
test('complete campaign: doing nothing loses the child on the third call',function()
 local g=Core.new();g:start();untilTime(g,200);eq(g.ending,'lost');eq(g.strikes,3)
end)
print(string.format('%d rule tests passed',count))
