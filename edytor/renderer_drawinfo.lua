local engyne = require 'engyne'

local DrawInfoRenderer = {}
DrawInfoRenderer.__index = DrawInfoRenderer

setmetatable(DrawInfoRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function DrawInfoRenderer.new()
  local self = {}
  setmetatable(self, DrawInfoRenderer)

  self:setup(0, 0, 200, 200)

  return self
end

function DrawInfoRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function DrawInfoRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  engyne.set_color('darkgrey', 6)
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)

  -- set canvas back to original
  love.graphics.setCanvas()
end

function DrawInfoRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function DrawInfoRenderer:draw(editor_state)
end

return DrawInfoRenderer
