local Line = require 'line'

local Wall = {}
Wall.__index = Wall

setmetatable(Wall, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Wall.new(line)
  local self = {}
  setmetatable(self, Wall)
  self.kind = 'wall'
  self.line = line
  self.norm_x, self.norm_y = Line.norm_vector(line)
  self.mid_x = (line.ax + line.bx) / 2
  self.mid_y = (line.ay + line.by) / 2
  self.decals = {}
  return self
end

return Wall



