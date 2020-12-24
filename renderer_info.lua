local InfoRenderer = {}
InfoRenderer.__index = InfoRenderer

setmetatable(InfoRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function InfoRenderer.new()
  local self = {}
  setmetatable(self, InfoRenderer)

  self.lines = {}
  self:setup(0, 0, 200, 200)

  return self
end

function InfoRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function InfoRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  -- set canvas back to original
  love.graphics.setCanvas()
end

function InfoRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function InfoRenderer:draw()
  local color = 'grey'
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  for i, line in ipairs(self.lines) do
    if line.color ~= color then
      color = line.color
      if color == 'grey' then
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
      elseif color == 'green' then
        love.graphics.setColor(0, 0.8, 0.5, 1)
      end
    end
    love.graphics.print(line.text, self.x, self.y + (i - 1) * 16)
  end
end

function InfoRenderer:reset()
  self.lines = {}
end

function InfoRenderer:write(color, template, ...)
  local args = {...}

  for i, v in ipairs(args) do
    template = template:gsub('{}', v, 1)
  end
  table.insert(self.lines, { color = color, text = template })
end

return InfoRenderer
