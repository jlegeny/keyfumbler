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
  self.id = id
  self.x = x
  self.y = y
  self.r = r
  self.name = name
  self.data = {}
  return self
end

return Trigger



