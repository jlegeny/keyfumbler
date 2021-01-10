local Line = require 'line'

local Decal = {}
Decal.__index = Decal

setmetatable(Decal, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Decal.new(name, x, y, width, height)
  local self = {}
  setmetatable(self, Decal)
  self.kind = 'decal'
  self.name = name
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  return self
end

return Decal
