local Line = require 'line'

local Split = {}
Split.__index = Split

setmetatable(Split, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Split.new(line, is_door)
  local self = {}
  setmetatable(self, Split)
  self.kind = 'split'
  self.line = line
  self.norm_x, self.norm_y = Line.norm_vector(line)
  self.mid_x = (line.ax + line.bx) / 2
  self.mid_y = (line.ay + line.by) / 2
  self.is_door = is_door
  self.open = false
  self.open_per = 0
  self.decals = {}
  return self
end

return Split



