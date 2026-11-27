"""Original procedural rotary, line and broadcast sounds. No external sound licenses."""
import math, pathlib, random, struct, wave
root=pathlib.Path('assets/audio');root.mkdir(parents=True,exist_ok=True)
rate=22050
rng=random.Random(19891224)
def write(name,seconds,fn,fade=True):
    samples=[]
    for i in range(int(seconds*rate)):
        t=i/rate; envelope=min(1,t/.008,(seconds-t)/.025) if fade else 1
        samples.append(int(max(-1,min(1,fn(t)))*max(0,envelope)*22000))
    with wave.open(str(root/(name+'.wav')),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(struct.pack('<%dh'%len(samples),*samples))
def tone(f,t):return math.sin(2*math.pi*f*t)
write('dial',1.95,lambda t: ((rng.random()*2-1)*.35+tone(140,t)*.15) * (1 if t%.1<.022 else .04))
write('pickup',.2,lambda t:(rng.random()*2-1)*math.exp(-t*24)*.75)
write('hangup',.28,lambda t:(rng.random()*2-1)*math.exp(-t*17)*.8)
write('connect',.42,lambda t:(tone(440,t)+tone(480,t))*.15)
write('busy',1.1,lambda t:(tone(400,t)+tone(450,t))*.12*(1 if t%.45<.2 else 0))
write('ring',2.8,lambda t:(tone(980+90*tone(22,t),t)*.25+tone(1420,t)*.12)*(1 if t<1 else 0))
write('clock',1.2,lambda t:tone(1000 if t>.8 else 500,t)*.25*(1 if t%.4<.09 else 0))
write('step',.8,lambda t:(tone(55,t)*.55+(rng.random()*2-1)*.2)*math.exp(-t*8))
write('breaker',1.2,lambda t:((rng.random()*2-1)*.6 if t<.12 else tone(65,t)*.18*math.exp(-t*7)))
write('power',2.5,lambda t:(tone(50,t)*.08+tone(820+240*t,t)*.08+rng.random()*.05)*math.exp(-t*.8))
write('reveal',3,lambda t:(tone(62,t)+tone(64,t)+tone(125,t)*.4)*.11)
write('ambience',8,lambda t: tone(50,t)*.055+tone(100,t)*.015+(rng.random()*2-1)*.018)
# Japanese public-line cues: 400 Hz; ringback 1 s on / 2 s off;
# busy 0.5 s on / 0.5 s off. These are synthesized approximations, not recordings.
# Reference: NTT West, analog telephone interface technical reference, audible tones.
def gate(t,on,period):
    x=t%period
    return min(1,x/.006,(on-x)/.006) if x<on else 0
write('dialtone',1,lambda t:tone(400,t)*.21,fade=False)
write('ringback',3,lambda t:tone(400,t)*(.55+.45*tone(16,t))*.28*gate(t,1,3))
write('busy',1,lambda t:tone(400,t)*.25*gate(t,.5,1))
def tap(t,f=1550):
    if t<0:return 0
    return (tone(f,t)*.6+tone(f*1.43,t)*.25+(rng.random()*2-1)*.15)*math.exp(-t*135)
for digit in range(10):
    pulses=10 if digit==0 else digit
    wind=.18+.04*pulses
    returning=.16+.10*pulses
    def rotary(t):
        if t<wind:
            return (rng.random()*2-1)*.055+tone(180,t)*.025
        u=t-wind
        # Each contact opening/closing pair belongs to one pulse, not a DTMF note.
        v=sum(tap(u-.08-i*.1)*.6+tap(u-.14-i*.1,1150)*.32 for i in range(pulses))
        return v+tap(u-returning+.018,820)*.45
    write('dial_'+str(digit),wind+returning,rotary)
write('pickup',.24,lambda t:tap(t,860)*.7+tap(t-.045,1240)*.38+tap(t-.095,2100)*.18)
write('hangup',.32,lambda t:tap(t,320)*.9+tap(t-.035,510)*.7+tap(t-.075,1800)*.25)
write('connect',.12,lambda t:tap(t,1240)*.30+tap(t-.025,680)*.15)
def bell(t):
    if t>1.22:return 0
    return sum((tone(820,t-i*.04)+tone(1237,t-i*.04)*.6+tone(1890,t-i*.04)*.18)*math.exp(-(t-i*.04)*24)*.12
               for i in range(25) if t>=i*.04)
write('ring',3,bell)
write('program_alert',.45,lambda t:(tone(680,t)*.11+tone(1020,t)*.04)*math.exp(-t*9))
write('program_urgent',.6,lambda t:sum(tap(t-i*.17,780)*.30 for i in range(3)))
write('program_click',.2,lambda t:(rng.random()*2-1)*.15*math.exp(-t*35))
print('Generated 27 WAV files: rotary, line and broadcast effects')
