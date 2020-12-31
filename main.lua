local util = require 'util'
local engyne = require 'engyne'
local raycaster = require 'raycaster'

local bitser = require 'bitser'

local lines = require 'lines'

local Line = require 'line'
local Map = require 'map'
local Player = require 'player'
local Room = require 'room'
local Wall = require 'wall'

local editor = require 'editor_state'
local Draw = editor.Draw
local State = editor.State
local EditorState = editor.EditorState

local LevelRenderer = require 'renderer_level'
local LevelOverlayRenderer = require 'renderer_level_overlay'
local ToolsRenderer = require 'renderer_tools'
local HistoryRenderer = require 'renderer_history'
local InfoRenderer = require 'renderer_info'
local DrawInfoRenderer = require 'renderer_drawinfo'
local TabsRenderer = require 'renderer_tabs'
local StatusBarRenderer = require 'renderer_statusbar'
local VolumeRenderer = require 'renderer_volume'


Operation = {
  ADD_WALL = 1,
  COMPLEX = 2,
}

e = EditorState()

map = Map({ next_id = 1 })
player = Player()
player.rx = 30
player.ry = 30
player.rot = -math.pi

level_renderer = LevelRenderer()
level_overlay_renderer = LevelOverlayRenderer(level_renderer)
tools_renderer = ToolsRenderer()
history_renderer = HistoryRenderer()
info_renderer = InfoRenderer()
drawinfo_renderer = DrawInfoRenderer()
tabs_renderer = TabsRenderer()
volume_renderer = VolumeRenderer()
statusbar_renderer = StatusBarRenderer()

WINDOW_WIDTH = 980
WINDOW_HEIGHT = 640


-- FUNCTIONS

function save(filename)
  local map_str = bitser.dumps(map)
  love.filesystem.write(filename, map_str)
end

function restore(filename)
  local map_str = love.filesystem.newFileData(filename)
  map = bitser.loadData(map_str:getPointer(), map_str:getSize())
  Map.fix(map)
  setmetatable(map, Map)
  map:update_bsp()
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
  love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {vsync = true, resizable = true})

  -- fonts
  engyne.set_default_font()

  setup(WINDOW_WIDTH, WINDOW_HEIGHT)

  if love.filesystem.getInfo('scratch.map') ~= nil then
    restore('scratch.map')
  end
end

function setup(w, h)
  local pad = 10

  local volume_w = 320
  local volume_h = 240

  local bb_w = w - pad * 2
  local bb_h = 20
  local bb_x = pad
  local bb_y = h - bb_h - pad

  local tabs_h = 50
  local tabs_y = volume_h + 2 * pad

  local sb_w = 320
  local sb_y = volume_h + tabs_h + 3 * pad
  local sb_x = w - sb_w - pad
  local sb_h = h - volume_h - tabs_h - bb_h - pad * 5

  local level_w = w - sb_w - 3 * pad
  local level_h = h - bb_h - 3 * pad



  level_renderer:setup(pad, pad, level_w, level_h)
  volume_renderer:setup(sb_x, pad , volume_w, volume_h)

  tabs_renderer:setup(sb_x, tabs_y, sb_w, tabs_h)

  tools_renderer:setup(sb_x, sb_y, sb_w, sb_h)
  history_renderer:setup(sb_x, sb_y, sb_w, sb_h)
  info_renderer:setup(sb_x, sb_y, sb_w, sb_h)
  drawinfo_renderer:setup(sb_x, sb_y, sb_w, sb_h)

  statusbar_renderer:setup(bb_x, bb_y, bb_w, bb_h)

end

function love.resize(w, h)
  setup(w, h)
end

function love.quit()
  map.bsp = {}
  save('scratch.map')
  return false
end

function love.keypressed(key, unicode)
  local shift = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
  if e.state == State.IDLE or e.state == State.IC then
    if key >= '1' and key <= '6' then
      e.sidebar = key - '1' + 1
    elseif key == '[' then
      e:undo(map)
    elseif key == ']' then
      e:redo(map)
    elseif key == 'f1' then
      e.mode = EditorMode.SELECT
      e.sidebar = Sidebar.SELECTION
    elseif key == 'f2' then
      if e.mode == EditorMode.DRAW then
        e:toggle_draw()
      else
        e.mode = EditorMode.DRAW
        e.sidebar = Sidebar.DRAW
      end
    elseif key == 'f5' then
      save('scratch.map')
    elseif key == 'f9' then
      restore('scratch.map')
    elseif key == 'backspace' then
      local pre = util.deepcopy(map)
      map:remove_objects_set(e.selection)
      local post = util.deepcopy(map)
      e:undoable({
        op = Operation.COMPLEX,
        description = "delete",
        pre = pre,
        post = post,
      })
    elseif key == 'r' or key == 'insert' or key == 'kpenter' then
      love.event.quit('restart')
    elseif key == 'q' then
      love.event.quit(0)
    elseif key == 'tab' then
      if shift then
        level_overlay_renderer:toggle_mode()
      else
        level_renderer:toggle_mode()
      end
    elseif key == 'space' then
      local ray = Line(player.rx, player.ry, player.rx + math.sin(player.rot), player.ry + math.cos(player.rot))
      local collisions = raycaster.collisions(map, ray)
      if #collisions > 0 then
        local cc = raycaster.closest_collision(collisions)
        e.selection = {
          [cc.id] = 'wall'
        }
      end
    elseif key == 'c' then
      e.state = State.CONFIRM
      e.confirmable = {
        action = {
          kind = 'clear',
        },
        message = 'Press [c] again to clear all',
        key = 'c',
      }
    elseif key == 'return' then
      local mx, my = love.mouse.getPosition()
      local rx, ry = level_renderer:rel_point(mx, my)
      print('--- ordered nodes ---')
      local nodes = raycaster.get_ordered_nodes(map.bsp, rx, ry)
      for i, node in pairs(nodes) do
        if node.is_leaf then
          print(i, node.id)
        else
          print(i, node.id, ' ', node.ogid, ' ', node.wall.line.ax, ' ', node.wall.line.bx)
        end
      end
      print('--- ordered visible nodes ---')
      local ray = Line(player.rx, player.ry, player.rx + math.sin(player.rot), player.ry + math.cos(player.rot))
      local vnodes = raycaster.get_visible_ordered_nodes(map.bsp, ray.ax, ray.ay, ray.bx, ray.by)
      e.highlight = {}
      for i, node in pairs(vnodes) do
        e.highlight[node.id] = { 'brass', 4 }
        if node.is_leaf then
          print(i, node.id)
        else
          print(i, node.id, ' ', node.ogid, ' ', node.wall.line.ax, ' ', node.wall.line.bx)
        end
      end
      print('--- collisions ---')
      for i, c in ipairs(raycaster.fast_collisions(map, ray)) do
        print(i, c.id)
      end
     end
  elseif e.state == State.IC_DRAWING_WALL or e.state == State.IC_DRAWING_WALL_NORMAL then
    if key == 'escape' then
      e.state = State.IDLE
    end
  elseif e.state == State.CONFIRM then
    if key == e.confirmable.key then
      execute_action(e.confirmable.action)
    end
    e.state = State.IDLE
  end
end

function execute_action(action)
  if action.kind == 'clear' then
    local pre = util.deepcopy(map)
    map = Map({ next_id = 1 })
    local post = util.deepcopy(map)
    e:undoable({
      op = Operation.COMPLEX,
      description = 'clear',
      pre = pre,
      post = post,
    })
  end
end

function love.mousepressed(mx, my, button, istouch)
  local rx, ry = level_renderer:rel_point(mx, my)

  if e.state == State.IC then
    if button == 1 then
      if e.mode == EditorMode.DRAW then
        if e.draw == Draw.WALL then
          e.state = State.IC_DRAWING_WALL
          e.wall_line_r = Line(rx, ry, rx, ry)
        elseif e.draw == Draw.ROOM then
          local objat = map:object_at(rx, ry)
          if objat == nil then
            local id = map:get_id()
            local room = Room(rx, ry, 0, 1)
            map:add_room(id, room)
          end
        end
      end
    elseif button == 2 then
      e.state = State.IC_DRAWING_SELECTION
      e.selection_line_r = Line(rx, ry, rx, ry)
    end
  elseif e.state == State.IC_DRAWING_WALL_NORMAL then
    if button == 1 then
      local id = map:get_id()
      local wall = Wall(e.wall_line_r)
      e:undoable({
        op = Operation.ADD_WALL,
        obj = {
          id = id,
          wall = wall
        },
      })
      map:add_wall(id, wall)
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
  elseif e.sidebar == Sidebar.DRAW then
    drawinfo_renderer:draw_canvas()
  end

  statusbar_renderer:reset()
  statusbar_renderer:draw_canvas()

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
  elseif e.state == State.IC_DRAWING_SELECTION then
    if love.mouse.isDown(2) then
      e.selection_line_r.bx = rx
      e.selection_line_r.by = ry
    else
      e.state = State.IDLE
      e.selection = map:bound_objects_set(e.selection_line_r)
      e.sidebar = Sidebar.SELECTION
    end
  end
  
  level_renderer:draw(map, e)
  level_overlay_renderer:draw(map, player)

  volume_renderer:draw(map, player)


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

    local dot = e.wall_line_r:point_dot(rx, ry)
    info_renderer:write('green', 'norm_x = {}, norm_y = {}', norm_rx, norm_ry)
    info_renderer:write('green', 'dot = {}', dot)

    love.graphics.setColor(1, 0, 0, 1)
    
    level_renderer:draw_line(Line(mid_rx, mid_ry, mid_rx + norm_rx * 2, mid_ry + norm_ry * 2))

    if dot < 0 then
      e.wall_line_r:swap()
    end
  end

  if e.state == State.IC_DRAWING_SELECTION then
    engyne.set_color('copperoxyde')
    level_renderer:draw_rectangle(e.selection_line_r)
  end

  statusbar_renderer:write('grey', 'mx = {}, my = {}', mx, my)
  statusbar_renderer:write('grey', 'rx = {}, ry = {}', rx, ry)
  statusbar_renderer:write('grey', 'ox = {}, oy = {}', e.offset_x, e.offset_y)

  if e.state == State.IC then
    local region = raycaster.get_region_node(map.bsp, rx, ry)
    statusbar_renderer:write('grey', 'region = {}', region.id)
    e.highlight = { [region.id] = { 'darkgrey', 4 } }
    if e.mode == EditorMode.SELECT then
      if region.parent ~= nil then
        local fronttree = raycaster.get_subtree_ids(region.parent.front)
        for _, v in pairs(fronttree) do
          e.highlight[v] = { 'copperoxyde', 3 }
        end
        local backtree = raycaster.get_subtree_ids(region.parent.back)
        for _, v in pairs(backtree) do
          e.highlight[v] = { 'copper', 3 }
        end
        e.highlight[region.parent.id] = { 'brass', 4 }
      end
    end
  end

  if e.state == State.CONFIRM then
    engyne.set_color('copper', 4)
    love.graphics.print(e.confirmable.message, 10, 10)
  end

  if e.sidebar == Sidebar.INFO then
    info_renderer:draw()
  elseif e.sidebar == Sidebar.DRAW then
    drawinfo_renderer:draw(e)
  end

  local dt = love.timer.getDelta()

  -- player controls
  if love.keyboard.isDown('a') then
    player.rot = player.rot + dt * player.rot_speed
  elseif love.keyboard.isDown('d') then
    player.rot = player.rot - dt * player.rot_speed
  end

  if player.rot > math.pi then
    player.rot = player.rot - math.pi * 2
  end

  if player.rot < -math.pi then
    player.rot = player.rot + math.pi * 2
  end

  if love.keyboard.isDown('w') then
    player.rx = player.rx + dt * math.sin(player.rot) * player.speed
    player.ry = player.ry + dt * math.cos(player.rot) * player.speed
  elseif love.keyboard.isDown('s') then
    player.rx = player.rx - dt * math.sin(player.rot) * player.speed
    player.ry = player.ry - dt * math.cos(player.rot) * player.speed
  end

  statusbar_renderer:draw(e, mx, my, rx, ry)

end

