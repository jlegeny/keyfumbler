local Line = require 'line'
local lines = require 'lines'
local Wall = require 'wall'

Operation = {
  ADD_WALL = 1,
}

State = {
  IDLE = 0,
  IC_IDLE = 100,
  IC_DRAWING_WALL = 101,
  IC_DRAWING_WALL_NORMAL = 102,
}

undo_stack = {}
redo_stack = {}
walls = {}

state = State.IDLE

zoom_factor = 9
offset_x = 0
offset_y = 0
wall_line_r = nil

WINDOW_WIDTH = 960
WINDOW_HEIGHT = 640
SIDEBAR_WIDTH = 300
HISTORY_HEIGHT = 200

CANVAS_X = 20
CANVAS_Y = 20
PADDING = 4
CANVAS_WIDTH = 600
CANVAS_HEIGHT = 600

info_line = 0

next_id = 1

function getId()
  local ret = next_id
  next_id = next_id + 1
  return ret
end

function interp(s, tab)
  return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

getmetatable("").__mod = interp

function love.load()
  -- window
  love.window.setTitle("Engyne Edytor")
  love.window.setMode(960, 640, {vsync = true})

  -- fonts
  font = love.graphics.newFont("IBMPlexMono-SemiBold.ttf", 15)
  love.graphics.setFont(font)

  hud = love.graphics.newCanvas(WINDOW_WIDTH, WINDOW_HEIGHT)

  offscreen_draw_hud()
end

function offscreen_draw_hud()
  love.graphics.setCanvas(hud)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  -- Draw canvas BG
  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.rectangle('fill', CANVAS_X - 6, CANVAS_Y - 6, CANVAS_WIDTH + 8, CANVAS_HEIGHT + 8)

  -- Tools
  local keyboard_shortcuts = {
    '[ Undo       ] Redo',
    '+ Zoom In    - Zoom out',
  }

  love.graphics.setColor(1, 1, 1, 0.4)
  local kbd_shortcuts_rect_x = WINDOW_WIDTH - SIDEBAR_WIDTH - 20
  local kbd_shortcuts_rect_y = 200
  love.graphics.rectangle('fill', kbd_shortcuts_rect_x, kbd_shortcuts_rect_y, SIDEBAR_WIDTH, table.getn(keyboard_shortcuts) * 16 + PADDING * 2)

  love.graphics.setColor(1, 1, 1, 0.9)
  for line, text in ipairs(keyboard_shortcuts) do
    love.graphics.print(text, kbd_shortcuts_rect_x + PADDING, kbd_shortcuts_rect_y + PADDING + (line - 1) * 16)
  end

  -- History
  love.graphics.setColor(1, 1, 1, 0.4)
  local history_rect_x = WINDOW_WIDTH - SIDEBAR_WIDTH - 20
  local history_rect_y = WINDOW_HEIGHT - HISTORY_HEIGHT - 20
  love.graphics.rectangle('fill', history_rect_x, history_rect_y, SIDEBAR_WIDTH, HISTORY_HEIGHT)

  -- set canvas back to original
  love.graphics.setCanvas()
end

function draw_grid()
  -- draw the grid
  local dots = {} 

  local y = 0
  while y < CANVAS_HEIGHT do
    local x = 0
    while x < CANVAS_WIDTH do
      table.insert(dots, CANVAS_X + x)
      table.insert(dots, CANVAS_Y + y)
      x = x + zoom_factor
    end
    y = y + zoom_factor
  end

  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.points(dots)
end

function draw_history()
  love.graphics.setColor(1, 0, 0.5, 1)
  local i = 0
  for j = 1, #redo_stack do
    local text
    if redo_stack[j].op == Operation.ADD_WALL then
      text = "Wall ${id}" % { id = redo_stack[j].obj.id }
      love.graphics.print(text, WINDOW_WIDTH - SIDEBAR_WIDTH - 20 + PADDING, WINDOW_HEIGHT - HISTORY_HEIGHT - 20 + PADDING + i * 16)
    end
    i = i + 1
  end
  love.graphics.setColor(0.5, 0, 1, 1)
  for j = #undo_stack, 1, -1 do
    local text
    if undo_stack[j].op == Operation.ADD_WALL then
      text = "Wall ${id}" % { id = undo_stack[j].obj.id }
      love.graphics.print(text, WINDOW_WIDTH - SIDEBAR_WIDTH - 20 + PADDING, WINDOW_HEIGHT - HISTORY_HEIGHT - 20 + PADDING + i * 16)
    end
    i = i + 1
  end
end

local function get_index_by_id(tab, id)
  local index = nil
  for i, v in ipairs (tab) do 
    if (v.id == val) then
      index = i 
    end
  end
  return index
end


function undo()
  if table.getn(undo_stack) == 0 then
    return
  end
  local tail = table.remove(undo_stack, #undo_stack)
  print("UNDOING", tail.obj.id)
  table.insert(redo_stack, tail)

  if tail.op == Operation.ADD_WALL then
    local index = get_index_by_id(walls, tail.obj.id)
    table.remove(walls, index)
  end
end

function redo()
  if table.getn(redo_stack) == 0 then
    return
  end
  local tail = table.remove(redo_stack, #redo_stack)
  print("REDOING", tail.obj.id)
  table.insert(undo_stack, tail)
  if tail.op == Operation.ADD_WALL then
    table.insert(walls, tail.obj)
  end
end

function undoable(op, clean_redo_stack)
  if clean_redo_stack == nil then
    clean_redo_stack = true
  end
  table.insert(undo_stack, op)
  if clean_redo_stack then
    for k in pairs(redo_stack) do
      redo_stack[k] = nil
    end
  end
end

function in_canvas(x, y)
  return x >= CANVAS_X and x <= CANVAS_X + CANVAS_WIDTH and y >= CANVAS_Y and y <= CANVAS_Y + CANVAS_HEIGHT
end


function info_print(template, ...)
  local args = {...}

  for i, v in ipairs(args) do
    template = template:gsub('{}', v, 1)
  end
  love.graphics.print(template, 700, 20 + info_line * 16)
  info_line = info_line + 1
end

function draw_state_info()
  local state_str = "Unknown"
  if state == State.IDLE then
    state_str = "Idle"
  elseif state == State.IC then
    state_str = "In Canvas"
  elseif state == State.IC_DRAWING_WALL then
    state_str = "Drawing a Wall"
  elseif state == State.IC_DRAWING_WALL_NORMAL then
    state_str = "Drawing a Wall's Normal"
  end
  love.graphics.setColor(0, 0.8, 0.5, 1)
  info_print(state_str)
end

function love.keypressed(key, unicode)
  if state == State.IDLE or state == State.IC then
    if key == '[' then
      undo()
    elseif key == ']' then
      redo()
    end
  elseif state == State.IC_DRAWING_WALL or state == State.IC_DRAWING_WALL_NORMAL then
    if key == 'escape' then
      state = State.IDLE
    end
  end
end

function love.mousepressed(x, y, button, istouch)
  local rx = math.floor((x - CANVAS_X) / zoom_factor)
  local ry = math.floor((y - CANVAS_Y) / zoom_factor)

  if state == State.IC then
    if button == 1 then
      state = State.IC_DRAWING_WALL
      wall_line_r = Line.create(rx, ry, rx, ry)
    end
  elseif state == State.IC_DRAWING_WALL_NORMAL then
    if button == 1 then
      local wall = Wall(getId(), wall_line_r)
      undoable({
        op = Operation.ADD_WALL,
        obj = wall
      })
      table.insert(walls, wall)
      state = State.IDLE
      love.mouse.setPosition(wall_line_r.bx * zoom_factor + CANVAS_X, wall_line_r.by * zoom_factor + CANVAS_Y)
    end
  end
end

function love.draw()
  info_line = 0
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.draw(hud)
  
  draw_grid()


  local mx, my = love.mouse.getPosition()
  local rx = math.floor((mx - CANVAS_X) / zoom_factor)
  local ry = math.floor((my - CANVAS_Y) / zoom_factor)


  -- state detection
  local is_in_canvas = in_canvas(mx, my)

  if state == State.IDLE then
    if is_in_canvas then
      state = State.IC
    end
  elseif state == State.IC then
    if not is_in_canvas then
      state = State.IDLE
    end
  elseif state == State.IC_DRAWING_WALL then
    if love.mouse.isDown(1) then
      wall_line_r.bx = rx
      wall_line_r.by = ry
    else
      if is_in_canvas then
        if wall_line_r.ax == wall_line_r.bx and wall_line_r.ay == wall_line_r.by then 
          state = State.IC
        else
          state = State.IC_DRAWING_WALL_NORMAL
        end
      else
        state = State.IDLE
      end
    end
  elseif state == State.IC_DRAWING_WALL_NORMAL then
  end
  
  draw_state_info()
  draw_history()

  -- draw all the walls
  for i, w in ipairs(walls) do
    local wall_line_c = Line.create(
    w.line.ax * zoom_factor + CANVAS_X,
    w.line.ay * zoom_factor + CANVAS_Y,
    w.line.bx * zoom_factor + CANVAS_X,
    w.line.by * zoom_factor + CANVAS_Y)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.line(wall_line_c.ax, wall_line_c.ay, wall_line_c.bx, wall_line_c.by)

    local mid_cx, mid_cy = w.mid_x * zoom_factor + CANVAS_X, w.mid_y * zoom_factor + CANVAS_Y

    love.graphics.setColor(0, 1, 1, 0.8)
    love.graphics.line(mid_cx, mid_cy, mid_cx + w.norm_x * 5, mid_cy + w.norm_y * 5)
  end
  
  -- draw the cursor
  if state == State.IDLE or state == State.IC_DRAWING_WALL_NORMAL + 1 then
    love.mouse.setVisible(true)
  elseif state == State.IC or state == State.IC_DRAWING_WALL then
    love.mouse.setVisible(false)
    local cx = rx * zoom_factor + CANVAS_X
    local cy = ry * zoom_factor + CANVAS_Y

    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.line(cx, cy - 10, cx, cy + 10)
    love.graphics.line(cx - 10, cy, cx + 10, cy)
  end

  if state == State.IC_DRAWING_WALL then
    local wall_line_c = Line.create(
     wall_line_r.ax * zoom_factor + CANVAS_X,
     wall_line_r.ay * zoom_factor + CANVAS_Y,
     rx * zoom_factor + CANVAS_X,
     ry * zoom_factor + CANVAS_Y)
 
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.line(wall_line_c.ax, wall_line_c.ay - 10, wall_line_c.ax, wall_line_c.ay + 10)
    love.graphics.line(wall_line_c.ax - 10, wall_line_c.ay, wall_line_c.ax + 10, wall_line_c.ay)

    love.graphics.line(wall_line_c.ax, wall_line_c.ay, wall_line_c.bx, wall_line_c.by)
  end

  if state == State.IC_DRAWING_WALL_NORMAL then 
    local wall_line_c = Line.create(
    wall_line_r.ax * zoom_factor + CANVAS_X,
    wall_line_r.ay * zoom_factor + CANVAS_Y,
    wall_line_r.bx * zoom_factor + CANVAS_X,
    wall_line_r.by * zoom_factor + CANVAS_Y)
 
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.line(wall_line_c.ax, wall_line_c.ay, wall_line_c.bx, wall_line_c.by)

    local mid_x, mid_y = (wall_line_c.ax + wall_line_c.bx) / 2, (wall_line_c.ay + wall_line_c.by) / 2
    local norm_x, norm_y = wall_line_c:norm_vector()

    local dot = (rx - wall_line_r.ax) * norm_x + (ry - wall_line_r.ay) * norm_y
    love.graphics.setColor(1, 0.8, 0, 1)
    info_print('norm_x = {}, norm_y = {}', norm_x, norm_y)
    info_print('dot = {}', dot)

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.line(mid_x, mid_y, mid_x + norm_x * 20, mid_y + norm_y * 20)

    if dot < 0 then
      wall_line_r.ax, wall_line_r.ay, wall_line_r.bx, wall_line_r.by = wall_line_r.bx, wall_line_r.by, wall_line_r.ax, wall_line_r.ay
    end
  end

  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  info_print('mx = {}, my = {}', mx, my)
  info_print('rx = {}, ry = {}', rx, ry)
  info_print('ox = {}, oy = {}', offset_x, offset_y)
end

