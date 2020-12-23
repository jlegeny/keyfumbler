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

function Line:vector()
  return self.bx - self.ax, self.by - self.ay
end

function Line:unit_vector()
  local x, y = self:vector()
  d = math.sqrt(x * x + y * y)
  return x / d, y / d
end

function Line:norm_vector()
  local x, y = self:unit_vector()
  return -y, x
end

function Line:describe()
  print("AX", self.ax)
  print("AY", self.ay)
  print("BX", self.bx)
  print("BY", self.by)
end

Line.__index = Line

return Line



