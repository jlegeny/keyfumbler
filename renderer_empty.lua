local EmptyRenderer = {}
EmptyRenderer.__index = EmptyRenderer

setmetatable(EmptyRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function EmptyRenderer.new()
  local self = {}
  setmetatable(self, EmptyRenderer)

  self:setup(0, 0, 200, 200)

  return self
end

function EmptyRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height

  if self.overlay then
    self.overlay:setup()
  end
end

function EmptyRenderer:draw(fullscreen)
  love.graphics.setBlendMode('alpha')

  if fullscreen then
    love.graphics.clear()
  end
  love.graphics.setBlendMode('alpha')
end


return EmptyRenderer
