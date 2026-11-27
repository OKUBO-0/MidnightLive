-- One relative engine tween at a time, with a tracked absolute endpoint.
-- Reversals are queued, never piled onto an unfinished relative translation.
local F={}
function F.receiverMotion(startTween)
  local m={pose=0,target=0,active=false,generation=0}
  function m:update(lifted)
    self.target=lifted and 1 or 0
    if self.active or self.pose==self.target then return end
    local destination=self.target
    local delta=-64*(destination-self.pose)
    self.active=true;self.generation=self.generation+1
    local generation=self.generation
    startTween(delta,.20,function()
      if generation~=self.generation then return end
      self.pose=destination;self.active=false
    end)
  end
  return m
end
function F.dialAngle(timing,remaining)
  local elapsed=math.max(0,timing.total-remaining)
  if elapsed<timing.wind then
    local p=elapsed/timing.wind
    return timing.angle*(p*p*(3-2*p))
  end
  return timing.angle*math.max(0,1-(elapsed-timing.wind)/timing.returning)
end
function F.offsetMotion(startTween)
  local m={x=0,y=0,active=false}
  function m:update(x,y)
    self.targetX=x;self.targetY=y
    if self.active or (self.x==x and self.y==y) then return end
    self.active=true
    startTween(x-self.x,y-self.y,function()
      self.x=x;self.y=y;self.active=false
    end)
  end
  return m
end
return F
