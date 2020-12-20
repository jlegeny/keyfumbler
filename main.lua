local line = require 'line'

Wall = {
  x1 = 0,
  y1 = 0,
  x2 = 0,
  y2 = 0,
  nx = 0,
  ny = 0
}

State = {
  IDLE = 0,
  IC_IDLE = 100,
  IC_DRAWING_WALL = 101,
  IC_DRAWING_WALL_NORMAL = 102,
}

state = State.IDLE

zoom_factor = 10
offset_x = 0
offset_y = 0
wall_line_r = nil

CANVAS_X = 20
CANVAS_Y = 20
CANVAS_WIDTH = 600
CANVAS_HEIGHT = 600

function interp(s, tab)
  return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

getmetatable("").__mod = interp

function love.load()
  -- window
  love.window.setTitle("Engyne Edytor")
  love.window.setMode(960, 640, {vsync = true})

  hud = love.graphics.newCanvas(960, 640)

  love.graphics.setCanvas(hud)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', CANVAS_X, CANVAS_Y, CANVAS_WIDTH, CANVAS_HEIGHT)

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


function in_canvas(x, y)
  return x >= CANVAS_X and x <= CANVAS_X + CANVAS_WIDTH and y >= CANVAS_Y and y <= CANVAS_Y + CANVAS_HEIGHT
end

function love.draw()
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
    if love.mouse.isDown(1) then
      state = State.IC_DRAWING_WALL
      wall_line_r = line.create(rx, ry, rx, ry)
    end
  elseif state == State.IC_DRAWING_WALL then
    if not love.mouse.isDown(1) then
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
  end
  
  -- draw the cross
  if state == State.IDLE then
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
    local wall_line_c = line.create(
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
    local wall_line_c = line.new(
    wall_line_r.ax * zoom_factor + CANVAS_X,
    wall_line_r.ay * zoom_factor + CANVAS_Y,
    wall_line_r.bx * zoom_factor + CANVAS_X,
    wall_line_r.by * zoom_factor + CANVAS_Y)
 
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.line(wall_line_c.ax, wall_line_c.ay, wall_line_c.bx, wall_line_c.by)
  end

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

  love.graphics.print(state_str, 700, 20)
  love.graphics.print('mx = ${x} my = ${y}' % {x = mx, y = my}, 700, 60)
  love.graphics.print('rx = ${x} ry = ${y}' % {x = rx, y = ry}, 700, 70)
  love.graphics.print('ox = ${x} oy = ${y}' % {x = offset_x, y = offset_y}, 700, 80)
end

