local util = require 'util'
local engyne = require 'engyne'
local raycaster = require 'raycaster'

local lines = require 'lines'

local Catalog = require 'catalog'
local Game = require 'game'
local Line = require 'line'
local Map = require 'map'
local Level = require 'level'
local Room = require 'object/room'
local Light = require 'object/light'
local Split = require 'object/split'
local Thing = require 'object/thing'
local Trigger = require 'object/trigger'
local Wall = require 'object/wall'

local editor = require 'edytor/editor_state'
local Draw = editor.Draw
local State = editor.State
local Probe = editor.Probe
local EditorState = editor.EditorState

local LevelRenderer = require 'edytor/renderer_level'
local LevelOverlayRenderer = require 'edytor/renderer_level_overlay'
local ToolsRenderer = require 'edytor/renderer_tools'
local SelectionRenderer = require 'edytor/renderer_selection'
local HistoryRenderer = require 'edytor/renderer_history'
local InfoRenderer = require 'edytor/renderer_info'
local DrawInfoRenderer = require 'edytor/renderer_drawinfo'
local ItemRenderer = require 'edytor/renderer_item'
local TabsRenderer = require 'edytor/renderer_tabs'
local StatusBarRenderer = require 'edytor/renderer_statusbar'
local VolumeRenderer = require 'renderer_volume'
local VolumeOverlayRenderer = require 'renderer_volume_overlay'

-- Globals and Types

Operation = {
  ADD_WALL = 1,
  COMPLEX = 2,
  ADD_SPLIT = 3,
}

glob = {}
e = EditorState()

level = Level('basement', {
  [0] = 'scratch',
  [1] = 'map01',
  [2] = 'map02',
})
local mapindex = 1
local map = nil
local game = nil
local level_renderer = LevelRenderer()
local level_overlay_renderer = LevelOverlayRenderer(level_renderer)
local tools_renderer = ToolsRenderer()
local selection_renderer = SelectionRenderer()
local history_renderer = HistoryRenderer()
local info_renderer = InfoRenderer()
local drawinfo_renderer = DrawInfoRenderer()
local item_renderer = ItemRenderer()
local tabs_renderer = TabsRenderer()
local volume_renderer = VolumeRenderer()
local volume_overlay_renderer = VolumeOverlayRenderer(volume_renderer)
local statusbar_renderer = StatusBarRenderer()
local decals = Catalog.new(Catalog.decals)
local sprites = Catalog.new(Catalog.sprites)

WINDOW_WIDTH = 980
WINDOW_HEIGHT = 640

fullscreen = false

-- Map Delegate

local delegate = {}
delegate.notify = function(event)
  if event == 'geometry_updated' then
    map:update_bsp()
  elseif event == 'map_updated' then
    volume_renderer:invalidate_light_cache()
  elseif event == 'layer_changed' then
    map = game.map
    e.undo_stack = {}
    e.redo_stack = {}
    volume_renderer:invalidate_light_cache()
  end
end

delegate.image_name = function(index)
  return decals.image_names[index]
end

delegate.image_data = function()
  return decals.image_data
end

delegate.image_count = function()
  return decals.count
end

delegate.sprite_name = function(index)
  return sprites.image_names[index]
end

delegate.sprite_data = function()
  return sprites.image_data
end

delegate.sprite_count = function()
  return sprites.count
end


-- FUNCTIONS

function setmap()
  map = level.layers[mapindex]
  game:set_level(level, mapindex)
  game:update_player()
  volume_renderer:invalidate_light_cache()
  e.undo_stack = {}
  e.redo_stack = {}
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
  volume_renderer:setup(sb_x, pad , volume_w, volume_h, decals.image_data, sprites.image_data)

  tabs_renderer:setup(sb_x, tabs_y, sb_w, tabs_h)

  tools_renderer:setup(sb_x, sb_y, sb_w, sb_h)
  history_renderer:setup(sb_x, sb_y, sb_w, sb_h)
  info_renderer:setup(sb_x, sb_y, sb_w, sb_h)
  drawinfo_renderer:setup(sb_x, sb_y, sb_w, sb_h)
  item_renderer:setup(sb_x, sb_y, sb_w, sb_h)
  selection_renderer:setup(sb_x, sb_y, sb_w, sb_h)

  statusbar_renderer:setup(bb_x, bb_y, bb_w, bb_h)

  item_renderer:set_delegate(delegate)
end

function undoable(description, closure)
  local pre = util.deepcopy(map)
  closure()
  local post = util.deepcopy(map)
  e:undoable({
    description = description,
    pre = pre,
    post = post,
  })
end

function execute_action(action)
  if action.kind == 'clear' then
    undoable('clear', function()
      map = Map({ next_id = 1 })
    end)
  end
end


-- Object

local EditorMain = {}
EditorMain.__index = EditorMain

setmetatable(EditorMain, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function EditorMain.load()
  game = Game:new()
  game.script_enabled = false
  game.delegate = delegate

  -- window
  love.window.setTitle("Engyne Edytor")
  love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {fullscreen = false, vsync = true, resizable = true, minwidth = WINDOW_WIDTH, minheight = WINDOW_HEIGHT})

  -- fonts
  engyne.set_default_font()

  setmap()
  -- game:set_player_position(54.25, 48.25, -math.pi) -- hole
  game:set_player_position(50, 54, -math.pi / 2) -- first key
  --game:set_player_position(51.75, 54.25, -math.pi / 2) -- door to cubby

  e.mode = EditorMode.DRAW
  e.probe = Draw.WALL
  level_renderer.zoom_factor = 40
  level_renderer.offset_x = -45
  level_renderer.offset_y = -45
  level_renderer.snap = 4
  level_renderer.mode = 'map'

  setup(WINDOW_WIDTH, WINDOW_HEIGHT)
end

function EditorMain.resize(w, h)
  setup(w, h)
end

function EditorMain.quit()
  level:save(mapindex)
  return false
end

function EditorMain.keypressed(key, unicode)
  local shift = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
  local ctrl = love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')
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
    elseif key == 'f3' then
      if e.mode == EditorMode.PROBE then
        e:toggle_probe()
      else
        e.mode = EditorMode.PROBE
      end
    elseif key == 'f5' then
      if e.selection_count() == 1 then
        e.text_input = ""
        local id, _ = next(e.selection)
        if map.aliases[id] then
          e.text_input = map.aliases[id]
        end
        e.state = State.TI_NAMING_ALIAS
      end
    elseif key == 'f6' then
      level:save(mapindex)
    elseif key == 'f7' then
      level:restore()
      setmap()
      map.aliases[603] = nil
    elseif key == 'backspace' then
      undoable('delete', function ()
        map:remove_objects_set(e.selection)
      end)
    elseif key == 'r' then
      love.event.quit('restart')
    elseif key == 'q' then
      love.event.quit(0)
    elseif key == 'kpenter' or key == 'f' then
      fullscreen = not fullscreen
    elseif key == 'tab' then
      if shift then
        level_overlay_renderer:toggle_mode()
      elseif ctrl then
        volume_renderer:toggle_mode()
      else
        level_renderer:toggle_mode()
      end
    elseif key == 'space' then
      local ray = game:eye_vector()
      local collisions = raycaster.fast_collisions(map, ray)
      if #collisions > 0 then
        local cc = raycaster.closest_collision(collisions)
        local kind = cc.is_split and 'split' or 'wall'
        e.selection = {
          [cc.id] = kind
        }
        item_renderer:set_item(map, cc.id, kind)
      end
    elseif key == '=' and shift then
      level_renderer:zoom_in()
    elseif key == '-' then
      level_renderer:zoom_out()
    elseif key == '0' then
      level_renderer:zoom_reset()
    elseif key == 'delete' then
      e.state = State.CONFIRM
      e.confirmable = {
        action = {
          kind = 'clear',
        },
        message = 'Press [delete] again to clear all',
        key = 'delete',
      }
    elseif key == 'pageup' then
      e:save_selection(mapindex)
      mapindex = (mapindex - 1) % level.layer_count
      setmap()
      e:restore_selection(mapindex)
    elseif key == 'pagedown' then
      e:save_selection(mapindex)
      mapindex = (mapindex + 1) % level.layer_count
      setmap()
      e:restore_selection(mapindex)
    elseif key == 'down' then
      if e.sidebar == Sidebar.ITEM then
        item_renderer:next_stat()
      end
    elseif key == 'up' then
      if e.sidebar == Sidebar.ITEM then
        item_renderer:prev_stat()
      end
    elseif key == 'left' then
      if e.sidebar == Sidebar.ITEM then
        item_renderer:dec_stat(shift)
      end
    elseif key == 'right' then
      if e.sidebar == Sidebar.ITEM then
        item_renderer:inc_stat(shift)
      end
    elseif key == 'l' then
      volume_renderer.flat_light = not volume_renderer.flat_light
    elseif key == '/' then
      e.state = State.DUMP
    end
  elseif e.state == State.IC_DRAWING_WALL or e.state == State.IC_DRAWING_WALL_NORMAL
    or e.state == State.IC_DRAWING_SPLIT then
    if key == 'escape' then
      e.state = State.IDLE
    end
  elseif e.state == State.TI_NAMING_ALIAS then
    if key == 'return' then
      e.state = State.IDLE
      local id, _ = next(e.selection)
      map.aliases[id] = e.text_input
      map:update_aliases()
    elseif key == 'backspace' then
      if e.text_input:len() > 0 then
        e.text_input = e.text_input:sub(1, -2)
      end
    elseif key == 'escape' then
      e.state = State.IDLE
    end
  elseif e.state == State.CONFIRM then
    if key == e.confirmable.key then
      execute_action(e.confirmable.action)
    end
    e.state = State.IDLE
  elseif e.state == State.DUMP then
    if key == 'f1' then
      Map.print_bsp(map.volatile.bsp, 0)
      e.state = State.IDLE
    elseif key == 'f2' then
      for id, thing in pairs(map.things) do
        print(id .. ' => ' .. thing.x .. ', ' .. thing.y)
      end
      e.state = State.IDLE
    elseif key == 'escape' then
      e.state = State.IDLE
    end
  end
  if e.state == State.IDLE or e.state == State.IC then
    game:keypressed(key, unicode)
  end
end

function EditorMain.mousepressed(mx, my, button, istouch)
  local rx, ry = level_renderer:rel_point(mx, my)

  if e.state == State.IC then
    if button == 1 then
      if e.mode == EditorMode.DRAW then
        if e.draw == Draw.WALL then
          e.state = State.IC_DRAWING_WALL
          e.current_rline = Line(rx, ry, rx, ry)
        elseif e.draw == Draw.SPLIT then
          e.state = State.IC_DRAWING_SPLIT
          e.current_rline = Line(rx, ry, rx, ry)
        else
          local objat = map:object_at(rx, ry)
          if objat == nil then
            local id = map:get_id()
            local obj = nil
            if e.draw == Draw.ROOM then
              local lr = nil
              if e.last_selected_room then
                lr = map.rooms[e.last_selected_room]
              end
              if lr then
                obj = Room(rx, ry, lr.floor_height, lr.ceiling_height, lr.ambient_light)
              else
                obj = Room(rx, ry, 0, 2, 32)
              end
            elseif e.draw == Draw.LIGHT then
              obj = Light(rx, ry, 4)
            elseif e.draw == Draw.THING then
              obj = Thing('missing', rx, ry, 1, 1, 1, {})
            elseif e.draw == Draw.TRIGGER then
              obj = Trigger(rx, ry, 1, 'trigger')
            end
            undoable('add_' .. obj.kind, function() map:add_object(id, obj) end)
          end
        end
      elseif e.mode == EditorMode.PROBE then
        if e.probe == Probe.VISIBILITY then
          e.state = State.IC_DRAWING_VISIBILITY
          e.current_rline = Line(rx, ry, rx, ry)
        elseif e.probe == Probe.CONNECTIVITY then
          e.state = State.IC_DRAWING_CONNECTIVITY
          e.current_rline = Line(rx, ry, rx, ry)
         end
       end
    elseif button == 2 then
      e.state = State.IC_DRAWING_SELECTION
      e.selection_line_r = Line(rx, ry, rx, ry)
    end
  elseif e.state == State.IC_DRAWING_WALL_NORMAL then
    if button == 1 then
      local id = map:get_id()
      local wall = Wall(e.current_rline)
      undoable('add_wall', function() map:add_object(id, wall) end)
      e.state = State.IDLE
      local cx, cy = level_renderer:canvas_point(e.current_rline.bx, e.current_rline.by)
      love.mouse.setPosition(cx, cy)
    end
  end
end

EditorMain.textinput = function(text)
  e.text_input = e.text_input .. text
end

function EditorMain.draw()
  love.graphics.setColor(1, 1, 1, 1)

  level_renderer:draw_canvas()

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
  elseif e.sidebar == Sidebar.ITEM then
    item_renderer:draw_canvas()
  elseif e.sidebar == Sidebar.DRAW then
    drawinfo_renderer:draw_canvas()
  elseif e.sidebar == Sidebar.SELECTION then
    selection_renderer:draw_canvas()
    selection_renderer:draw(e)
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
      e.current_rline.bx = rx
      e.current_rline.by = ry
    else
      if is_in_canvas then
        if e.current_rline.ax == e.current_rline.bx and e.current_rline.ay == e.current_rline.by then 
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
      e.selection = map:bound_objects_set(e.selection_line_r)
      e.state = State.RESET_INFO
    end
  elseif e.state == State.RESET_INFO then
    item_renderer:reset_item()
    if e:selection_count() == 1 then
      local id, kind = next(e.selection)
      item_renderer:set_item(map, id, kind)
      e.sidebar = Sidebar.ITEM
      if kind == 'room' then
        e.last_selected_room = id
      end
    elseif e:selection_count() > 1 then
      e.sidebar = Sidebar.SELECTION
    end
    e.state = State.IDLE
  elseif e.state == State.IC_DRAWING_SPLIT then
    if love.mouse.isDown(1) then
      e.current_rline.bx = rx
      e.current_rline.by = ry
    else
      if is_in_canvas and (
        e.current_rline.ax ~= e.current_rline.bx or e.current_rline.ay ~= e.current_rline.by)
        then 
          local id = map:get_id()
          local split = Split(e.current_rline)
          undoable('add_split', function () map:add_object(id, split) end)
          e.state = State.IDLE
          local cx, cy = level_renderer:canvas_point(e.current_rline.bx, e.current_rline.by)
          love.mouse.setPosition(cx, cy)
      end
      e.state = State.IDLE
    end
  elseif e.state == State.IC_DRAWING_WALL_NORMAL then
  elseif e.state == State.IC_DRAWING_VISIBILITY or e.state == State.IC_DRAWING_CONNECTIVITY then
    if love.mouse.isDown(1) then
      e.current_rline.bx = rx
      e.current_rline.by = ry
    else
      e.state = State.IDLE
    end
  end

  level_renderer:draw(map, e)
  level_overlay_renderer:draw(map, game.player)

  -- draw the cursor
  if e.state == State.IDLE or e.state == State.IC_DRAWING_WALL_NORMAL then
    love.mouse.setVisible(true)
  elseif e.state == State.IC or e.state == State.IC_DRAWING_WALL then

    --love.mouse.setVisible(false)

    love.graphics.setColor(1, 1, 0, 1)
    level_renderer:draw_cross(rx, ry)
  end

  if e.state == State.IC_DRAWING_WALL or e.state == State.IC_DRAWING_SPLIT then
    love.graphics.setColor(1, 0, 0, 1)
    level_renderer:draw_cross(e.current_rline.bx, e.current_rline.by)
    level_renderer:draw_line(e.current_rline)
  end

  if e.state == State.IC_DRAWING_WALL_NORMAL then 
    local wall_line_c = level_renderer:canvas_line(e.current_rline) 

    love.graphics.setColor(1, 0.8, 0, 1)
    level_renderer:draw_line(e.current_rline)

    local mid_rx, mid_ry = e.current_rline:mid()
    local norm_rx, norm_ry = e.current_rline:norm_vector()

    local dot = e.current_rline:point_dot(rx, ry)
    info_renderer:write('green', 'norm_x = {}, norm_y = {}', norm_rx, norm_ry)
    info_renderer:write('green', 'dot = {}', dot)

    love.graphics.setColor(1, 0, 0, 1)

    level_renderer:draw_line(Line(mid_rx, mid_ry, mid_rx + norm_rx * 2, mid_ry + norm_ry * 2))

    if dot < 0 then
      e.current_rline:swap()
    end
  end

  if e.state == State.IC_DRAWING_SELECTION then
    engyne.set_color('copperoxyde')
    level_renderer:draw_rectangle(e.selection_line_r)
  end

  if e.state == State.IC_DRAWING_VISIBILITY or e.state == State.IC_DRAWING_CONNECTIVITY then
    local obstructed

    if e.state == State.IC_DRAWING_VISIBILITY then
      obstructed = raycaster.is_cut_by_wall(map, e.current_rline)
    elseif e.state == State.IC_DRAWING_CONNECTIVITY then
      obstructed = raycaster.is_cut_by_any_line(map, e.current_rline)
    end

    if obstructed then
      engyne.set_color('red')
    else
      engyne.set_color('green')
    end
    level_renderer:draw_cross(e.current_rline.bx, e.current_rline.by)
    level_renderer:draw_line(e.current_rline)
  end


  info_renderer:write('grey', 'fps = {}', love.timer.getFPS())
  statusbar_renderer:write('grey', 'mx = {}, my = {}', mx, my)
  statusbar_renderer:write('grey', 'rx = {}, ry = {}', rx, ry)
  statusbar_renderer:write('grey', '{}', map.volatile.mapname)

  if e.state == State.IC then
    local region = raycaster.get_region_node(map.volatile.bsp, rx, ry)
    if region ~= nil then
      statusbar_renderer:write('grey', 'region = {} up = {}', region.id, region.up)
      local room = map:room_node(region)
      if room then
        info_renderer:write('grey', 'room_id = {}', room.room_id)
      end
    end
    if region ~= nil and e.mode == EditorMode.PROBE then
      e.highlight = {}
      if e.probe == Probe.CONNECTIVITY then
        e.highlight = { [region.id] = { 'green', 33 } }

        if region.poly and region.slices then
          for i, p in ipairs(region.poly) do
            info_renderer:write('grey', 'p{} {},{}', i, p[1], p[2])
          end
          --level_renderer:draw_poly(region.poly, {'red'})
          for _, poly in ipairs(region.slices) do
            for i = 1, #poly do
              local j = (i % #poly) + 1
              local line = Line(poly[i][1], poly[i][2], poly[j][1], poly[j][2])
              local nx, ny = line:norm_vector()
              local midx, midy = line:mid()
              local PROBE_SIZE = 1/32
              local probe = Line(midx + PROBE_SIZE * nx, midy + PROBE_SIZE * ny, midx - PROBE_SIZE * nx, midy - PROBE_SIZE * ny)
              local other = raycaster.get_region_node(map.volatile.bsp, midx - PROBE_SIZE * nx, midy - PROBE_SIZE * ny)
              if region.id == other.id then
                e.highlight[other.id] = { 'blue', 33 }
                engyne.set_color('blue')
              elseif not raycaster.is_cut_by_any_line(map, probe) then
                e.highlight[other.id] = { 'fuchsia', 33 }
                engyne.set_color('green')
              else
                engyne.set_color('red')
                e.highlight[other.id] = { 'blue', 33 }
              end
              level_renderer:draw_line(probe)
            end
          end
        end

        if map.volatile.leaves ~= nil and map.volatile.leaves[region.id] ~= nil then
          local acth = e.highlight[map:room_root(region)]
          if acth == nil then
            e.highlight[map:room_root(region)] = { 'red', 50 }
          else
            e.highlight[map:room_root(region)] = { acth[1], 100 }
          end
        end
      end
      if e.probe == Probe.REGION_PARENT_SUBTREE then
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
      elseif e.probe == Probe.REGION_ANCESTORS then
        if region.parent ~= nil then
          local frontleaves = raycaster.get_bounding_line_ids(region.parent)
          for _, v in pairs(frontleaves) do
            e.highlight[v] = { 'copperoxyde', 6 }
          end
          e.highlight[region.id] = { 'brass', 4 }
        end
      end
    end
  end

  if e.sidebar == Sidebar.INFO then
    info_renderer:write('grey', 'light_at {}', raycaster.light_at(map, rx, ry))
    info_renderer:draw()
  elseif e.sidebar == Sidebar.DRAW then
    drawinfo_renderer:draw(e)
  elseif e.sidebar == Sidebar.ITEM then
    item_renderer:draw(map, e)
  end

  statusbar_renderer:draw(e, mx, my, rx, ry)

  local width, height = love.graphics.getDimensions()
  if e.state == State.TI_NAMING_ALIAS or e.state == State.CONFIRM then
    engyne.set_color('darkgrey', 0)
    love.graphics.rectangle('fill', 0, height / 2 - 30, width, 60)
  end

  local mid_text = ''
  if e.state == State.TI_NAMING_ALIAS then
    engyne.set_color('copper', 6)
    mid_text = 'Alias name [' .. e.text_input .. ']'
  elseif e.state == State.CONFIRM then
    engyne.set_color('copper', 4)
    mid_text = e.confirmable.message
  end
  love.graphics.printf(mid_text, 20, height / 2 - 10, width - 40, 'center')


  -- Panning
  

  if e.sidebar ~= Sidebar.ITEM then
    if love.keyboard.isDown('down') then
      level_renderer:pan(0, -1)
    end
    if love.keyboard.isDown('up') then
      level_renderer:pan(0, 1)
    end
    if love.keyboard.isDown('left') then
      level_renderer:pan(1, 0)
    end
    if love.keyboard.isDown('right') then
      level_renderer:pan(-1, 0)
    end
  end


  -- 3D View

  local dt = love.timer.getDelta()
  volume_renderer:draw(map, game, dt, fullscreen)
  volume_overlay_renderer:draw(map, game, dt, fullscreen)
  if e.state == State.IDLE or e.state == State.IC then
    game:update(dt)
  end

end

return EditorMain



