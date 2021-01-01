local engyne = require 'engyne'

local ItemRenderer = {}
ItemRenderer.__index = ItemRenderer

setmetatable(ItemRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function ItemRenderer.new()
  local self = {}
  setmetatable(self, ItemRenderer)

  self:setup(0, 0, 200, 200)

  return self
end

function ItemRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function ItemRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  engyne.set_color('darkgrey', 6)
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)

  -- set canvas back to original
  love.graphics.setCanvas()
end

function ItemRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function ItemRenderer:draw(editor_state)
  if #editor_state.selection == 0 then
    return
  elseif #editor_state.selection > 1 then
    return
  end
end

return ItemRenderer
