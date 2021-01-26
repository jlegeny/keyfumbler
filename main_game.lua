local engyne = require 'engyne'
local Game = require 'game'
local Key = require 'object/key'
local Level = require 'level'
local textures = require 'textures'

local VolumeRenderer = require 'renderer_volume'
local VolumeOverlayRenderer = require 'renderer_volume_overlay'

-- GLOBALS

volume_renderer = VolumeRenderer()
volume_overlay_renderer = VolumeOverlayRenderer(volume_renderer)

level = Level('basement', {
  [0] = 'scratch',
  [1] = 'map01',
  [2] = 'map02',
})

-- MAP DELEGATE

local delegate = {}
delegate.notify = function(event)
  if event == 'geometry_updated' then
    map:update_bsp()
  elseif event == 'map_updated' then
    volume_renderer:invalidate_light_cache()
  elseif event == 'layer_changed' then
    volume_renderer:invalidate_light_cache()
   end
end

delegate.image_name = function(index)
  return textures.image_names[index]
end

delegate.image_data = function()
  return textures.image_data
end


-- CONSTANTS

WINDOW_WIDTH = 960
WINDOW_HEIGHT = 720


-- OBJECT

local GameMain = {}
GameMain.__index = GameMain

setmetatable(GameMain, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function GameMain.load()
  game = Game:new()
  game.delegate = delegate

  -- window
  love.window.setTitle("Keyfumbler")
  love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false, 
    vsync = true, 
    resizable = true, 
    minwidth = WINDOW_WIDTH, 
    minheight = WINDOW_HEIGHT})

  textures.load()
  -- fonts
  engyne.set_default_font()
  game:set_level(level, 1)
  game:set_player_position(51.5, 54.5, math.pi / 2)

  local kid = 10000
  for i = 1, 13 do
    local key = Key.random()
    game.player.inventory[kid] = key
    kid = kid + 1
    key:render()
  end
  game:update_inventory()

  volume_renderer:setup(0, 0 , 320, 240, textures.image_data)
end

function GameMain.resize(w, h)
end

function GameMain.quit()
  return false
end

function GameMain.keypressed(key, unicode)
  if key == 'r' then
    love.event.quit('restart')
  end
  game:keypressed(key, unicode)
end

function GameMain.mousepressed(mx, my, button, istouch)
end

GameMain.textinput = function(text)
end

function GameMain.draw()
  local dt = love.timer.getDelta()
  volume_renderer:draw(game.map, game, dt, true)
  volume_overlay_renderer:draw(game.map, game, dt, true)
  game:update(dt)
end

return GameMain



