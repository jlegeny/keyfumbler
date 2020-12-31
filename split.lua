local Line = require 'line'

local Split = {}
Split.__index = Split

setmetatable(Split, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Split.new(line)
  local self = {}
  setmetatable(self, Split)
  self.kind = 'split'
  self.line = line
  self.norm_x, self.norm_y = Line.norm_vector(line)
  self.mid_x = (line.ax + line.bx) / 2
  self.mid_y = (line.ay + line.by) / 2
  return self
end

function Split:vector()
  return self.bx - self.ax, self.by - self.ay
end

function Split:normalized_vector()
  local x, y = self:vector()
  d = math.sqrt(x * x + y * y)
  return x / d, y / d
end

function Split:describe()
  print("AX", self.ax)
  print("AY", self.ay)
  print("BX", self.bx)
  print("BY", self.by)
end


return Split



