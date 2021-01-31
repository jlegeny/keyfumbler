local Thing = {}
Thing.__index = Thing

setmetatable(Thing, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Thing.new(name, x, y, z, width, height, meta)
  local self = {}
  setmetatable(self, Thing)
  self.kind = 'thing'
  self.x = x
  self.y = y
  self.z = z
  self.width = width
  self.height = height
  self.name = name
  self.meta = meta
  return self
end

function Thing:draw()
end

return Thing



