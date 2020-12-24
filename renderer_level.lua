local Line = require 'line'

local LevelRenderer = {}
LevelRenderer.__index = LevelRenderer

setmetatable(LevelRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function LevelRenderer.new()
  local self = {}
  setmetatable(self, LevelRenderer)
  self.zoom_factor = 9

  self:setup(0, 0, 200, 200)

  return self
end

function LevelRenderer:setup(x, y, width, height)
  self.x = x
  self.y = x
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function LevelRenderer:in_canvas(x, y)
  return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function LevelRenderer:rel_point(x, y)
  local rx = math.floor((x - self.x) / self.zoom_factor)
  local ry = math.floor((y - self.y) / self.zoom_factor)
  
  return rx, ry
end

function LevelRenderer:rel_line(line)
  local rax, ray = self:rel_point(line.ax, line.ay)
  local rbx, rby = self:rel_point(line.bx, line.by)

  return Line(rax, ray, rbx, rby)
end

function LevelRenderer:canvas_point(rx, ry)
  local cx = rx * self.zoom_factor + self.x + self.zoom_factor / 2
  local cy = ry * self.zoom_factor + self.y + self.zoom_factor / 2

  return cx, cy
end

function LevelRenderer:canvas_line(rline)
  local cax, cay = self:canvas_point(rline.ax, rline.ay)
  local cbx, cby = self:canvas_point(rline.bx, rline.by)

  return Line(cax, cay, cbx, cby)
end

function LevelRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
  --
  -- draw the grid
  local dots = {} 

  local y = 0
  while y < self.height do
    local x = 0
    while x < self.width do
      table.insert(dots, self.x + x + self.zoom_factor / 2)
      table.insert(dots, self.y + y + self.zoom_factor / 2)
      x = x + self.zoom_factor
    end
    y = y + self.zoom_factor
  end

  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.points(dots)
  
  -- set canvas back to original
  love.graphics.setCanvas()
end

function LevelRenderer:draw_canvas()
  love.graphics.draw(self.canvas)
end

function LevelRenderer:draw(map, editor_state)
  -- draw all the walls
  for i, w in ipairs(map.walls) do
    local cline = self:canvas_line(w.line)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.line(cline.ax, cline.ay, cline.bx, cline.by)

    local mid_cx, mid_cy = cline:mid()

    love.graphics.setColor(0, 1, 1, 0.8)
    love.graphics.line(mid_cx, mid_cy, mid_cx + w.norm_x * 5, mid_cy + w.norm_y * 5)
  end
end

function LevelRenderer:draw_cross(rx, ry)
  local cx, cy = self:canvas_point(rx, ry)

  love.graphics.line(cx, cy - 10, cx, cy + 10)
  love.graphics.line(cx - 10, cy, cx + 10, cy)
end

function LevelRenderer:draw_line(rline)
  local cline = self:canvas_line(rline)

  love.graphics.line(cline.ax, cline.ay, cline.bx, cline.by)
end

return LevelRenderer
