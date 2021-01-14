local util = require 'util'

local HistoryRenderer = {}
HistoryRenderer.__index = HistoryRenderer

setmetatable(HistoryRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function HistoryRenderer.new()
  local self = {}
  setmetatable(self, HistoryRenderer)

  self:setup(0, 0, 200, 200)

  return self
end

function HistoryRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function HistoryRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)

  -- set canvas back to original
  love.graphics.setCanvas()
end

function HistoryRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function HistoryRenderer:draw(e)
  love.graphics.setColor(1, 0, 0.5, 1)
  local i = 0
  for j = 1, #e.redo_stack do
    local text = e.redo_stack[j].description
    love.graphics.print(text, self.x, self.y + i * 16)
    i = i + 1
  end
  love.graphics.setColor(0.5, 0, 1, 1)
  for j = #e.undo_stack, 1, -1 do
    local text = e.undo_stack[j].description
    love.graphics.print(text, self.x, self.y + i * 16)
    i = i + 1
  end
end

return HistoryRenderer
