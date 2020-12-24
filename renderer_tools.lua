local ToolsRenderer = {}
ToolsRenderer.__index = ToolsRenderer

setmetatable(ToolsRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function ToolsRenderer.new()
  local self = {}
  setmetatable(self, ToolsRenderer)

  -- Tools
  self.keyboard_shortcuts = {
    '[ Undo       ] Redo',
    '+ Zoom In    - Zoom out',
  }

  self:setup(0, 0, 200, 200)

  return self
end

function ToolsRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function ToolsRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)

  love.graphics.setColor(1, 1, 1, 0.9)
  for line, text in ipairs(self.keyboard_shortcuts) do
    love.graphics.print(text, 0, (line - 1) * 16)
  end

  -- set canvas back to original
  love.graphics.setCanvas()
end

function ToolsRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function ToolsRenderer:draw(editor_state)
end

return ToolsRenderer
