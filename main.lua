local lines = require 'lines'
local Line = require 'line'
local Map = require 'map'
local Wall = require 'wall'
local editor = require 'editor_state'

local State = editor.State
local EditorState = editor.EditorState

local LevelRenderer = require 'renderer_level'
local ToolsRenderer = require 'renderer_tools'

Operation = {
  ADD_WALL = 1,
}

e = EditorState()

map = Map({ next_id = 1 })
level_renderer = LevelRenderer()
tools_renderer = ToolsRenderer()

WINDOW_WIDTH = 960
WINDOW_HEIGHT = 640

info_line = 0

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

  level_renderer:setup(20, 20, 500, 500)
  tools_renderer:setup(540, 20, 250, 500)
end

function draw_history()
  love.graphics.setColor(1, 0, 0.5, 1)
  local i = 0
  for j = 1, #e.redo_stack do
    local text
    if e.redo_stack[j].op == Operation.ADD_WALL then
      text = "Wall ${id}" % { id = e.redo_stack[j].obj.id }
      love.graphics.print(text, WINDOW_WIDTH - SIDEBAR_WIDTH - 20 + PADDING, WINDOW_HEIGHT - HISTORY_HEIGHT - 20 + PADDING + i * 16)
    end
    i = i + 1
  end
  love.graphics.setColor(0.5, 0, 1, 1)
  for j = #e.undo_stack, 1, -1 do
    local text
    if e.undo_stack[j].op == Operation.ADD_WALL then
      text = "Wall ${id}" % { id = e.undo_stack[j].obj.id }
      love.graphics.print(text, WINDOW_WIDTH - SIDEBAR_WIDTH - 20 + PADDING, WINDOW_HEIGHT - HISTORY_HEIGHT - 20 + PADDING + i * 16)
    end
    i = i + 1
  end
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
  love.graphics.setColor(0, 0.8, 0.5, 1)
  info_print(e:state_str())
end

function love.keypressed(key, unicode)
  if e.state == State.IDLE or e.state == State.IC then
    if key == '[' then
      e:undo(map)
    elseif key == ']' then
      e:redo(map)
    end
  elseif e.state == State.IC_DRAWING_WALL or e.state == State.IC_DRAWING_WALL_NORMAL then
    if key == 'escape' then
      e.state = State.IDLE
    end
  end
end

function love.mousepressed(mx, my, button, istouch)
  local rx, ry = level_renderer:rel_point(mx, my)

  if e.state == State.IC then
    if button == 1 then
      e.state = State.IC_DRAWING_WALL
      e.wall_line_r = Line(rx, ry, rx, ry)
    end
  elseif e.state == State.IC_DRAWING_WALL_NORMAL then
    if button == 1 then
      local wall = Wall(map:get_id(), e.wall_line_r)
      e:undoable({
        op = Operation.ADD_WALL,
        obj = wall
      })
      map:add_wall(wall)
      e.state = State.IDLE
      local cx, cy = level_renderer:canvas_point(e.wall_line_r.bx, e.wall_line_r.by)
      love.mouse.setPosition(cx, cy)
    end
  end
end

function love.draw()
  info_line = 0
  love.graphics.setColor(1, 1, 1, 1)

  level_renderer:draw_canvas()
  
  if e.sidebar == Sidebar.TOOLS then
    tools_renderer:draw_canvas()
  end

  local mx, my = love.mouse.getPosition()
  local rx, ry = level_renderer:rel_point(mx, my)

  -- state detection
  local is_in_canvas = level_renderer:in_canvas(mx, my)

  if e.state == State.IDLE then
    if is_in_canvas then
      e.state = State.IC
    end
  elseif e.state == State.IC then
    if not is_in_canvas then
      e.state = State.IDLE
    end
  elseif e.state == State.IC_DRAWING_WALL then
    if love.mouse.isDown(1) then
      e.wall_line_r.bx = rx
      e.wall_line_r.by = ry
    else
      if is_in_canvas then
        if e.wall_line_r.ax == e.wall_line_r.bx and e.wall_line_r.ay == e.wall_line_r.by then 
          e.state = State.IC
        else
          e.state = State.IC_DRAWING_WALL_NORMAL
        end
      else
        e.state = State.IDLE
      end
    end
  elseif e.state == State.IC_DRAWING_WALL_NORMAL then
  end
  
  level_renderer:draw(map, e)
  draw_state_info()

  -- draw the cursor
  if e.state == State.IDLE or e.state == State.IC_DRAWING_WALL_NORMAL then
    love.mouse.setVisible(true)
  elseif e.state == State.IC or e.state == State.IC_DRAWING_WALL then
    love.mouse.setVisible(false)

    love.graphics.setColor(1, 1, 0, 1)
    level_renderer:draw_cross(rx, ry)
  end

  if e.state == State.IC_DRAWING_WALL then
    love.graphics.setColor(1, 0, 0, 1)
    level_renderer:draw_cross(e.wall_line_r.bx, e.wall_line_r.by)
    level_renderer:draw_line(e.wall_line_r)
  end

  if e.state == State.IC_DRAWING_WALL_NORMAL then 
    local wall_line_c = level_renderer:canvas_line(e.wall_line_r) 

    love.graphics.setColor(1, 0.8, 0, 1)
    level_renderer:draw_line(e.wall_line_r)

    local mid_rx, mid_ry = e.wall_line_r:mid()
    local norm_rx, norm_ry = e.wall_line_r:norm_vector()

    local dot = (rx - e.wall_line_r.ax) * norm_rx + (ry - e.wall_line_r.ay) * norm_ry
    love.graphics.setColor(1, 0.8, 0, 1)
    info_print('norm_x = {}, norm_y = {}', norm_rx, norm_ry)
    info_print('dot = {}', dot)

    love.graphics.setColor(1, 0, 0, 1)
    
    level_renderer:draw_line(Line(mid_rx, mid_ry, mid_rx + norm_rx * 2, mid_ry + norm_ry * 2))

    if dot < 0 then
      e.wall_line_r:swap()
    end
  end

  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  info_print('mx = {}, my = {}', mx, my)
  info_print('rx = {}, ry = {}', rx, ry)
  info_print('ox = {}, oy = {}', e.offset_x, e.offset_y)
end

