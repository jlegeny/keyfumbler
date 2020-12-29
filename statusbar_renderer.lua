local engyne = require 'engyne'

local StatusBarRenderer = {}
StatusBarRenderer.__index = StatusBarRenderer

setmetatable(StatusBarRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function StatusBarRenderer.new()
  local self = {}
  setmetatable(self, StatusBarRenderer)

  self:setup(0, 0, 200, 200)

  return self
end

function StatusBarRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function StatusBarRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)
  
  -- set canvas back to original
  love.graphics.setCanvas()
end

function StatusBarRenderer:draw_canvas()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.canvas, self.x, self.y)
end

function StatusBarRenderer:draw(editor_state)
  engyne.set_color('moss')
  love.graphics.print(e:state_str(), self.x, self.y)
end

return StatusBarRenderer
