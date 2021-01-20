local Trigger = {}
Trigger.__index = Trigger

setmetatable(Trigger, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Trigger.new(x, y, r, name)
  local self = {}
  setmetatable(self, Trigger)
  self.kind = 'trigger'
  self.x = x
  self.y = y
  self.r = r
  self.name = name
  return self
end

return Trigger



