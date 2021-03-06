local engyne = require 'engyne'
local raycaster = require 'raycaster'

local Line = require 'line'

local hl_color = { 'copperoxyde', 7 }

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
  self.zoom_factor = 20
  self.snap = 1
  self.mode = 'map'

  self.offset_x = 0
  self.offset_y = 0

  self.layers = {
    lights = true
  }

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

function LevelRenderer:pan(dx, dy)
  self.offset_x = self.offset_x + dx
  self.offset_y = self.offset_y + dy
end

function LevelRenderer:set_snap()
  print(self.zoom_factor)
  if self.zoom_factor < 15 then
    self.snap = 1
  elseif self.zoom_factor < 40 then
    self.snap = 2
  elseif self.zoom_factor < 54 then
    self.snap = 4
  else
    self.snap = 8
  end
end

function LevelRenderer:zoom_in()
  self.zoom_factor = self.zoom_factor + 1
  local offs_x = math.floor(self.width / self.zoom_factor - self.width / (self.zoom_factor + 1))
  local offs_y = math.floor(self.height / self.zoom_factor - self.height / (self.zoom_factor + 1))
  self.offset_x = self.offset_x - offs_x
  self.offset_y = self.offset_y - offs_y
  self:set_snap()
  self:pre_render_canvas()
end

function LevelRenderer:zoom_out()
  self.zoom_factor = self.zoom_factor - 1
  local offs_x = math.floor(self.width / (self.zoom_factor - 1) - self.width / self.zoom_factor)
  local offs_y = math.floor(self.height / (self.zoom_factor - 1)- self.height / self.zoom_factor)
  self.offset_x = self.offset_x + offs_x
  self.offset_y = self.offset_y + offs_y
  self:set_snap()
  self:pre_render_canvas()
end

function LevelRenderer:zoom_reset()
  self.zoom_factor = 9
  self.snap = 1
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
    self.mode = 'slices'
  elseif self.mode == 'slices' then
    self.mode = 'map'
  end
end

function LevelRenderer:in_canvas(x, y)
  return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function LevelRenderer:rel_point(x, y)
  local cx = (x - self.x) / self.zoom_factor * self.snap
  local rx = math.floor(cx + 0.5) / self.snap - self.offset_x
  local cy = (y - self.y) / self.zoom_factor * self.snap
  local ry = math.floor(cy + 0.5) / self.snap - self.offset_y

  return rx, ry
end

function LevelRenderer:rel_line(line)
  local rax, ray = self:rel_point(line.ax, line.ay)
  local rbx, rby = self:rel_point(line.bx, line.by)

  return Line(rax, ray, rbx, rby)
end

function LevelRenderer:canvas_point(rx, ry)
  local cx = (rx + self.offset_x) * self.zoom_factor + self.x
  local cy = (ry + self.offset_y) * self.zoom_factor + self.y

  return cx, cy
end

function LevelRenderer:canvas_line(rline)
  local cax, cay = self:canvas_point(rline.ax, rline.ay)
  local cbx, cby = self:canvas_point(rline.bx, rline.by)

  return Line(cax, cay, cbx, cby)
end

function LevelRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function LevelRenderer:draw_rooms(map, editor_state)
  for id, r in pairs(map.rooms) do
    local cx, cy = self:canvas_point(r.x, r.y)
    engyne.set_color('copper', 4)
    if editor_state.selection[id] ~= nil then
      engyne.set_color(unpack(hl_color))
    end
    love.graphics.circle('line', cx, cy, 3)
  end
end

function LevelRenderer:draw_lights(map, editor_state)
  for id, l in pairs(map.lights) do
    local cx, cy = self:canvas_point(l.x, l.y)
    engyne.set_color('copper', 6)
    if editor_state.selection[id] ~= nil then
      engyne.set_color('brass', 5)
      love.graphics.circle('line', cx, cy, math.sqrt(l.intensity * 2) * self.zoom_factor)
      engyne.set_color(unpack(hl_color))
      love.graphics.circle('line', cx, cy, math.sqrt(l.intensity) * self.zoom_factor)
    end
    love.graphics.circle('line', cx, cy, 3)
  end
end

function LevelRenderer:draw_things(map, editor_state)
  for id, t in pairs(map.things) do
    local cx, cy = self:canvas_point(t.x, t.y)
    engyne.set_color('copper', 6)
    if editor_state.selection[id] ~= nil then
      engyne.set_color(unpack(hl_color))
    end
    love.graphics.polygon('line', cx, cy - math.sqrt(2), cx - 2, cy + 2, cx + 2, cy + 2)
  end
end


function LevelRenderer:draw_triggers(map, editor_state)
  for id, t in pairs(map.triggers) do
    local cx, cy = self:canvas_point(t.x, t.y)
    engyne.set_color('copper', 2)
    if editor_state.selection[id] ~= nil then
      engyne.set_color('copper', 1)
      love.graphics.circle('line', cx, cy, t.r * self.zoom_factor)
    end
    love.graphics.circle('line', cx, cy, 3)
  end
end


function LevelRenderer:draw_bsp(map, editor_state)
  self:draw_node(map.volatile.bsp, editor_state)
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
  local dots2 = {}
  local dots4 = {}

  local y = -self.zoom_factor
  while y < self.height do
    local x = -self.zoom_factor
    while x < self.width do
      local px, py = x + self.zoom_factor, y + self.zoom_factor
      table.insert(dots, px)
      table.insert(dots, py)
      if self.snap >= 2 then
        local off = self.zoom_factor / 2
        table.insert(dots2, px + 0)
        table.insert(dots2, py + off)
        table.insert(dots2, px + off)
        table.insert(dots2, py + 0)
        table.insert(dots2, px + off)
        table.insert(dots2, py + off)
      end
      if self.snap >= 4 then
        local off = self.zoom_factor / 4
        for dy = 0, 3 do
          for dx = 0, 3 do
            if (dx == 0 and dy == 0) or (dx == 2 and dy == 0) or (dx == 0 and dy == 2) or (dx == 2 and dy == 2) then
              goto continue
            end
            table.insert(dots4, px + dx * off)
            table.insert(dots4, py + dy * off)
            ::continue::
          end
        end
      end
       x = x + self.zoom_factor
    end
    y = y + self.zoom_factor
  end

  engyne.set_color('lightgrey', 3)
  love.graphics.points(dots)
  engyne.set_color('lightgrey', 1)
  love.graphics.points(dots2)
  engyne.set_color('darkgrey', 3)
  love.graphics.points(dots4)
   
  -- set canvas back to original
  love.graphics.setCanvas()

  if self.overlay ~= nil then
    self.overlay:pre_render_canvas()
  end
end

function LevelRenderer:draw_map(map, editor_state)
  -- draw all the walls
  for id, w in pairs(map.walls) do
    local cline = self:canvas_line(w.line)

    engyne.set_color('lightgrey', 6)
    if editor_state.selection[id] ~= nil then
      engyne.set_color(unpack(hl_color))
    end
    love.graphics.line(cline.ax, cline.ay, cline.bx, cline.by)

    local mid_cx, mid_cy = cline:mid()

    engyne.set_color('copperoxyde', 6)
    love.graphics.line(mid_cx, mid_cy, mid_cx + w.norm_x * 5, mid_cy + w.norm_y * 5)
    engyne.set_small_font()
    local label_x = mid_cx - w.norm_x * 5
    if w.norm_x > 0 then
      label_x = label_x - 10
    end
    love.graphics.print(id, label_x, mid_cy - w.norm_y * 5 - 5)
    engyne.set_default_font()
  end

  for id, w in pairs(map.splits) do
    local cline = self:canvas_line(w.line)

    if w.is_door then
      engyne.set_color('copper', 5)
    else
      engyne.set_color('brass', 5)
    end
    if editor_state.selection[id] ~= nil then
      engyne.set_color(unpack(hl_color))
    end
    love.graphics.line(cline.ax, cline.ay, cline.bx, cline.by)

    local mid_cx, mid_cy = cline:mid()

    engyne.set_color('copperoxyde', 6)
    engyne.set_small_font()
    local label_x = mid_cx - w.norm_x * 5
    if w.norm_x > 0 then
      label_x = label_x - 10
    end
    love.graphics.print(id, label_x, mid_cy - w.norm_y * 5 - 5)
    engyne.set_default_font()
  end


  for id, r in pairs(map.rooms) do
    local cx, cy = self:canvas_point(r.x, r.y)
    engyne.set_color('copper', 6)
    if editor_state.selection[id] ~= nil then
      engyne.set_color(unpack(hl_color))
    end
    love.graphics.circle('line', cx, cy, 3)
  end
end

function LevelRenderer:draw_node(node, editor_state)
  if node.is_leaf then
    return
  end

  local cline = self:canvas_line(node.line)
  local hl = editor_state.highlight[node.id] 

  if editor_state.selection[node.ogid] ~= nil then
    engyne.set_color('copper', 4)
  elseif hl ~= nil then
    engyne.set_color(hl[1], hl[2])
  elseif node.is_split then
    engyne.set_color('brass', 3)
  else
    engyne.set_color('lightgrey', 7)
  end
  if glob.first_collision == node.id then
    engyne.set_color('green')
  elseif glob.second_collision == node.id then
    engyne.set_color('red')
  end
  love.graphics.line(cline.ax, cline.ay, cline.bx, cline.by)

  local mid_cx, mid_cy = cline:mid()

  engyne.set_color('copperoxyde', 6)
  if not node.is_split then
    love.graphics.line(mid_cx, mid_cy, mid_cx + node.norm_x * 5, mid_cy + node.norm_y * 5)
  end

  engyne.set_small_font()
  local label_x = mid_cx - node.norm_x * 5
  if node.norm_x > 0 then
    label_x = label_x - 10
  end
  love.graphics.print(node.id, label_x, mid_cy - node.norm_y * 5 - 5)
  engyne.set_default_font()
 
  self:draw_node(node.front, editor_state)
  self:draw_node(node.back, editor_state)
end

function LevelRenderer:draw_bsp_polygons(node, editor_state)
  if node.is_leaf then
    local hl = editor_state.highlight[node.id]
    if self.mode == 'bsp_r' then
      engyne.hash_color(node.id, 0.3)
      self:draw_poly(node.poly, 'fill')
    end
    if hl ~= nil then
      engyne.set_color(hl[1], hl[2])
      self:draw_poly(node.poly, 'line')
      --self:draw_poly_normals(node.poly)
    end
  else
    self:draw_bsp_polygons(node.front, editor_state)
    self:draw_bsp_polygons(node.back, editor_state)
  end
end

function LevelRenderer:draw_bsp_regions(map, editor_state)
  self:draw_bsp_polygons(map.volatile.bsp, editor_state)
end

function LevelRenderer:draw_bsp_slices(map, editor_state)
  for id, node in pairs(map.volatile.leaves) do
    for i, poly in ipairs(node.slices) do
      engyne.hash_color(node.id + i, 0.3)
      self:draw_poly(poly, 'fill')
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

function LevelRenderer:draw_poly(poly, mode)
  if #poly < 3 then
    return
  end
  local vertices = {}
  for i = 1, #poly do
    local j = (i % #poly) + 1
    local ax, ay = self:canvas_point(unpack(poly[i]))
    local bx, by = self:canvas_point(unpack(poly[j]))
    table.insert(vertices, ax)
    table.insert(vertices, ay)
  end
  love.graphics.polygon(mode, vertices)
end

function LevelRenderer:draw_poly_normals(poly)
  if #poly < 2 then
    return
  end
  for i = 1, #poly do
    local j = (i % #poly) + 1
    local line = Line(poly[i][1], poly[i][2], poly[j][1], poly[j][2])
    local nx, ny = line:norm_vector()
    local midx, midy = line:mid()
    self:draw_line(Line(midx, midy, midx + nx, midy + ny))
  end
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
  elseif self.mode == 'slices' then
    self:draw_bsp(map, editor_state)
    self:draw_bsp_slices(map)
  end

  self:draw_rooms(map, editor_state)
  self:draw_things(map, editor_state)
  self:draw_triggers(map, editor_state)

  if self.layers.lights then
    self:draw_lights(map, editor_state)
  end

  local mode_str = self:mode_str()
  local mode_x = self.x + self.width - 15 - string.len(mode_str) * 7
  local mode_y = self.y + 5
  engyne.set_color('darkgrey', 0)
  love.graphics.rectangle('fill', mode_x, mode_y, string.len(mode_str) * 7 + 10, 20)
  love.graphics.rectangle('fill', self.x + 10, mode_y, string.len(map.volatile.mapname) * 7 + 10, 20)

  engyne.set_color('copper', 5)
  love.graphics.print(mode_str, mode_x + 5, mode_y)
  love.graphics.print(map.volatile.mapname, self.x + 15, mode_y)

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
  if self.mode == 'slices' then
    return 'Slices'
  end
  return 'Unknown'
end
return LevelRenderer
