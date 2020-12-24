local bitser = require 'bitser'

local lines = require 'lines'
local Line = require 'line'
local Map = require 'map'
local Wall = require 'wall'
local Player = require 'player'
local editor = require 'editor_state'

local State = editor.State
local EditorState = editor.EditorState

local LevelRenderer = require 'renderer_level'
local LevelOverlayRenderer = require 'renderer_level_overlay'
local ToolsRenderer = require 'renderer_tools'
local HistoryRenderer = require 'renderer_history'
local InfoRenderer = require 'renderer_info'
local TabsRenderer = require 'renderer_tabs'
local VolumeRenderer = require 'volume_renderer'


love.graphics.set_color = function(color)
  if color == 'grey' then
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
  elseif color == 'red' then
    love.graphics.setColor(1, 0.4, 0, 1)
  end
end

Operation = {
  ADD_WALL = 1,
}

e = EditorState()

map = Map({ next_id = 1 })
player = Player()
player.rx = 50
player.ry = 5
player.rot = -math.pi

level_renderer = LevelRenderer()
level_overlay_renderer = LevelOverlayRenderer(level_renderer)
tools_renderer = ToolsRenderer()
history_renderer = HistoryRenderer()
info_renderer = InfoRenderer()
tabs_renderer = TabsRenderer()
volume_renderer = VolumeRenderer()

WINDOW_WIDTH = 960
WINDOW_HEIGHT = 640


-- FUNCTIONS

function save(filename)
  local map_str = bitser.dumps(map)
  love.filesystem.write(filename, map_str)
end

function restore(filename)
  local map_str = love.filesystem.newFileData(filename)
  map = bitser.loadData(map_str:getPointer(), map_str:getSize())
  setmetatable(map, Map)
  e.undo_stack = {}
  e.redo_stack = {}
end

-- DRAW FUNCTIONS

-- LOVE

function love.load()
  -- bitser
  -- bitser.registerClass(Map)

  -- window
  love.window.setTitle("Engyne Edytor")
  love.window.setMode(960, 640, {vsync = true})

  -- fonts
  font = love.graphics.newFont("IBMPlexMono-SemiBold.ttf", 15)
  love.graphics.setFont(font)

  level_renderer:setup(20, 20, 500, 500)

  tabs_renderer:setup(540, 20, 320, 20)

  tools_renderer:setup(540, 60, 320, 500)
  history_renderer:setup(540, 60, 320, 500)
  info_renderer:setup(540, 60, 320, 500)

  volume_renderer:setup(540, 300, 320, 200)

  if love.filesystem.getInfo('scratch.map') ~= nil then
    restore('scratch.map')
  end
end

function love.quit()
  save('scratch.map')
  return false
end

function love.keypressed(key, unicode)
  if e.state == State.IDLE or e.state == State.IC then
    if key >= '1' and key <= '4' then
      e.sidebar = key - '1' + 1
    elseif key == '[' then
      e:undo(map)
    elseif key == ']' then
      e:redo(map)
    elseif key == 'f5' then
      save('scratch.map')
    elseif key == 'f9' then
      restore('scratch.map')
    elseif key == 'r' then
      love.event.quit('restart')
    elseif key == 'q' then
      love.event.quit(0)
    elseif key == 't' then
      level_overlay_renderer:toggle_mode()
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
  love.graphics.setColor(1, 1, 1, 1)

  level_renderer:draw_canvas()
  volume_renderer:draw_canvas()
  
  tabs_renderer:draw_canvas()
  tabs_renderer:draw(e)
  love.graphics.setColor(1, 1, 1, 1)
  if e.sidebar == Sidebar.TOOLS then
    tools_renderer:draw_canvas()
  elseif e.sidebar == Sidebar.HISTORY then
    history_renderer:draw_canvas()
    history_renderer:draw(e)
  elseif e.sidebar == Sidebar.INFO then
    info_renderer:reset()
    info_renderer:draw_canvas()
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
  level_overlay_renderer:draw(map, player)

  volume_renderer:draw(map, player)

  info_renderer:write('green', e:state_str())

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
    info_renderer:write('green', 'norm_x = {}, norm_y = {}', norm_rx, norm_ry)
    info_renderer:write('green', 'dot = {}', dot)

    love.graphics.setColor(1, 0, 0, 1)
    
    level_renderer:draw_line(Line(mid_rx, mid_ry, mid_rx + norm_rx * 2, mid_ry + norm_ry * 2))

    if dot < 0 then
      e.wall_line_r:swap()
    end
  end

  info_renderer:write('grey', 'mx = {}, my = {}', mx, my)
  info_renderer:write('grey', 'rx = {}, ry = {}', rx, ry)
  info_renderer:write('grey', 'ox = {}, oy = {}', e.offset_x, e.offset_y)

  if e.sidebar == Sidebar.INFO then
    info_renderer:draw()
  end

  local dt = love.timer.getDelta()

  -- player controls
  if love.keyboard.isDown('a') then
    player.rot = player.rot + dt * player.rot_speed
  elseif love.keyboard.isDown('d') then
    player.rot = player.rot - dt * player.rot_speed
  end

  if love.keyboard.isDown('w') then
    player.rx = player.rx + dt * math.sin(player.rot) * player.speed
    player.ry = player.ry + dt * math.cos(player.rot) * player.speed
  elseif love.keyboard.isDown('s') then
    player.rx = player.rx - dt * math.sin(player.rot) * player.speed
    player.ry = player.ry - dt * math.cos(player.rot) * player.speed
  end

end

