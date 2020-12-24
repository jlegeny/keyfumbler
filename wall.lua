local Wall = {}
Wall.__index = Wall

setmetatable(Wall, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Wall.new(id, line)
  local self = {}
  setmetatable(self, Wall)
  self.id = id
  self.kind = 'wall'
  self.line = line
  self.norm_x, self.norm_y = line:norm_vector()
  self.mid_x = (line.ax + line.bx) / 2
  self.mid_y = (line.ay + line.by) / 2
  return self
end

function Wall:vector()
  return self.bx - self.ax, self.by - self.ay
end

function Wall:normalized_vector()
  local x, y = self:vector()
  d = math.sqrt(x * x + y * y)
  return x / d, y / d
end

function Wall:describe()
  print("AX", self.ax)
  print("AY", self.ay)
  print("BX", self.bx)
  print("BY", self.by)
end


return Wall



