local Line = {}

setmetatable(Line, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Line.new(ax, ay, bx, by)
  local self = {}
  setmetatable(self, Line)
  self.ax = ax
  self.ay = ay
  self.bx = bx
  self.by = by
  return self
end

function Line:swap()
  self.ax, self.bx = self.bx, self.ax
  self.ay, self.by = self.by, self.ay
end

function Line:mid()
  return (self.ax + self.bx) / 2, (self.ay + self.by) / 2
end

function Line:vector()
  return self.bx - self.ax, self.by - self.ay
end

function Line:unit_vector()
  local x, y = Line.vector(self)
  d = math.sqrt(x * x + y * y)
  return x / d, y / d
end

function Line:norm_vector()
  local x, y = Line.unit_vector(self)
  return -y, x
end

function Line:fast_norm()
  return -(self.by - self.ay), (self.bx - self.ax)
end

function Line:point_dot(px, py)
  local nx, ny = Line.norm_vector(self)
  return (px - self.ax) * nx + (py - self.ay) * ny
end

function Line:fast_dot(px, py)
  local nx, ny = Line.fast_norm(self)
  return (px - self.ax) * nx + (py - self.ay) * ny
end


function Line:describe()
  print("{", self.ax, self.ay, self.bx, self.by, "}")
end

Line.__index = Line

return Line



