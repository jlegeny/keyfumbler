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
    '[1] Sel',
    '[2] Draw',
    '[3] Item',
    '[4] Kbd',
    '[5] Hist',
    '[6] Info',
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

  for i, text in ipairs(self.tabs) do 
    local c = (i - 1) % 4
    local r = math.floor((i - 1) / 4)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.rectangle('fill', c * tab_width, r * 30, tab_width - 5, 20)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(text, c * tab_width, r * 30)
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
  love.graphics.print(self.tabs[e.sidebar], self.x + ((e.sidebar - 1) % 4) * tab_width, self.y + math.floor((e.sidebar - 1) / 4) * 30)
end

return TabsRenderer
