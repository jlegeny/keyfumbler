local TabsRenderer = {}
TabsRenderer.__index = TabsRenderer

setmetatable(TabsRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function TabsRenderer.new()
  local self = {}
  setmetatable(self, TabsRenderer)

  self.tabs = {
    '[1] Item',
    '[2] Kbd',
    '[3] Hist',
    '[4] Info',
  }

  self:setup(0, 0, 200, 200)

  return self
end

function TabsRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function TabsRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  local tab_width = self.width / 4

  for i = 0, 3 do 
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.rectangle('fill', i * tab_width, 0, tab_width - 5, self.height)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(self.tabs[i + 1], i * tab_width, 0)
 end

  -- set canvas back to original
  love.graphics.setCanvas()
end

function TabsRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function TabsRenderer:draw(e)
  local tab_width = self.width / 4
  love.graphics.setColor(0, 1, 0.7, 1)
  love.graphics.print(self.tabs[e.sidebar], self.x + (e.sidebar - 1) * tab_width, self.y)
end

return TabsRenderer
