local engyne = require 'engyne'
local raycaster = require 'raycaster'

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
  self.mode = 'map'

  self:setup(0, 0, 200, 200)

  return self
end

function LevelRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function LevelRenderer.set_mode(mode)
  self.mode = mode
end

function LevelRenderer:toggle_mode(mode)
  if self.mode == 'map' then
    self.mode = 'bsp'
  elseif self.mode == 'bsp' then
    self.mode = 'bsp_r'
  elseif self.mode == 'bsp_r' then
    self.mode = 'map'
  end
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
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)
  --
  -- draw the grid
  local dots = {} 

  local y = 0
  while y < self.height do
    local x = 0
    while x < self.width do
      table.insert(dots, x + self.zoom_factor / 2)
      table.insert(dots, y + self.zoom_factor / 2)
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
  love.graphics.draw(self.canvas, self.x, self.y)
end

function LevelRenderer:draw_map(map, editor_state)
  -- draw all the walls
  for id, w in pairs(map.walls) do
    local cline = self:canvas_line(w.line)

    if editor_state.selection[id] ~= nil then
      engyne.set_color('copper', 4)
    else
      engyne.set_color('lightgrey', 6)
    end
    love.graphics.line(cline.ax, cline.ay, cline.bx, cline.by)

    local mid_cx, mid_cy = cline:mid()

    engyne.set_color('copperoxyde')
    love.graphics.line(mid_cx, mid_cy, mid_cx + w.norm_x * 5, mid_cy + w.norm_y * 5)
    engyne.set_small_font()
    local label_x = mid_cx - w.norm_x * 5
    if w.norm_x > 0 then
      label_x = label_x - 10
    end
    love.graphics.print(id, label_x, mid_cy - w.norm_y * 5 - 5)
    engyne.set_default_font()
  end
end

function LevelRenderer:draw_node(node, editor_state)
  if node.is_leaf then
    return
  end

  local cline = self:canvas_line(node.wall.line)
  local hl = editor_state.highlight[node.id] 

  if editor_state.selection[node.ogid] ~= nil then
    engyne.set_color('copper', 4)
  elseif hl ~= nil then
    engyne.set_color(hl[1], hl[2])
  else
    engyne.set_color('lightgrey', 7)
  end
  love.graphics.line(cline.ax, cline.ay, cline.bx, cline.by)

  local mid_cx, mid_cy = cline:mid()

  engyne.set_color('copperoxyde')
  love.graphics.line(mid_cx, mid_cy, mid_cx + node.wall.norm_x * 5, mid_cy + node.wall.norm_y * 5)

  engyne.set_small_font()
  local label_x = mid_cx - node.wall.norm_x * 5
  if node.wall.norm_x > 0 then
    label_x = label_x - 10
  end
  love.graphics.print(node.id, label_x, mid_cy - node.wall.norm_y * 5 - 5)
  engyne.set_default_font()
 
  self:draw_node(node.front, editor_state)
  self:draw_node(node.back, editor_state)
end

function LevelRenderer:draw_bsp(map, editor_state)
  self:draw_node(map.bsp, editor_state)
end

function LevelRenderer:draw_bsp_regions(map, editor_state)
  local dots = {} 

  local y = 0
  while y < self.height / self.zoom_factor do
    local x = 0
    while x < self.width / self.zoom_factor do
      local region_id = raycaster.get_region_id(map.bsp, x, y)
  
      local cx, cy = self:canvas_point(x, y)

      if dots[region_id] == nil then
        dots[region_id] = {}
      end

      table.insert(dots[region_id], cx)
      table.insert(dots[region_id], cy)
      x = x + 0.250
    end
    y = y + 0.250
  end

  for region_id, dts in pairs(dots) do 
    local hl = editor_state.highlight[region_id]
    if self.mode == 'bsp_r' then
      if hl ~= nil then
        engyne.set_color(hl[1], hl[2])
      else
        engyne.hash_color(region_id)
      end
      love.graphics.points(dts)
    elseif hl ~= nil then
      engyne.set_color(hl[1], hl[2])
      love.graphics.points(dts)
    end
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

function LevelRenderer:draw_rectangle(rline)
  local cline = self:canvas_line(rline)

  love.graphics.line(cline.ax, cline.ay, cline.bx, cline.ay)
  love.graphics.line(cline.bx, cline.ay, cline.bx, cline.by)
  love.graphics.line(cline.bx, cline.by, cline.ax, cline.by)
  love.graphics.line(cline.ax, cline.by, cline.ax, cline.ay)
end

function LevelRenderer:draw(map, editor_state)
  love.graphics.setScissor(self.x, self.y, self.width, self.height)
  if self.mode == 'map' then
    self:draw_map(map, editor_state)
  elseif self.mode == 'bsp' then
    self:draw_bsp(map, editor_state)
    self:draw_bsp_regions(map, editor_state)
  elseif self.mode == 'bsp_r' then
    self:draw_bsp(map, editor_state)
    self:draw_bsp_regions(map, editor_state)
  end

  local mode_str = self:mode_str()
  local mode_x = self.x + self.width - 15 - string.len(mode_str) * 7
  local mode_y = self.y + 5
  engyne.set_color('darkgrey', 0)
  love.graphics.rectangle('fill', mode_x, mode_y, string.len(mode_str) * 7 + 10, 20)
  engyne.set_color('copper', 5)
  love.graphics.print(mode_str, mode_x + 5, mode_y)

  love.graphics.setScissor()
end

function LevelRenderer:mode_str()
  if self.mode == 'map' then
    return 'Map'
  end
  if self.mode == 'bsp' then
    return 'BSP'
  end
  if self.mode == 'bsp_r' then
    return 'BSP Regions'
  end
  return 'Unknown'
end
return LevelRenderer
