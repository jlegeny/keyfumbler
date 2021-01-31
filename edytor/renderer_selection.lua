local engyne = require 'engyne'
local editor = require 'edytor/editor_state'

local SelectionRenderer = {}
SelectionRenderer.__index = SelectionRenderer

setmetatable(SelectionRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function SelectionRenderer.new()
  local self = {}
  setmetatable(self, SelectionRenderer)

  self:setup(0, 0, 200, 200)

  return self
end

function SelectionRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function SelectionRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  engyne.set_color('darkgrey', 6)
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)

  -- set canvas back to original
  love.graphics.setCanvas()
end

function SelectionRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function SelectionRenderer:draw(editor_state)
  local mx, my = love.mouse.getPosition()
  local i = 0
  for id, kind in pairs(editor_state.selection) do
    if mx > self.x and mx < self.x + self.width and my > self.y + i * 12 and my < self.y + (i + 1) * 12 then
      if love.mouse.isDown(1) then
        editor_state.selection = { [id] = kind }
        editor_state.state = State.RESET_INFO
      end
      engyne.set_color('copper', 4)
    else
      engyne.set_color('lightgrey', 4)
    end
    love.graphics.print(id .. ' : ' .. kind, self.x, self.y + i * 12)
    i = i + 1
  end
end

return SelectionRenderer
