local Line = {}

function Line.create(ax, ay, bx, by)
  local self = {}
  setmetatable(self, Line)
  self.ax = ax
  self.ay = ay
  self.bx = bx
  self.by = by
  return self
end

function Line:describe()
  print("AX", self.ax)
  print("AY", self.ay)
  print("BX", self.bx)
  print("BY", self.by)
end

Line.__index = Line

return Line



