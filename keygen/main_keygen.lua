local engyne = require 'engyne'
local Game = require 'game'
local Key = require 'object/key'

local EmptyRenderer = require 'renderer_empty'
local VolumeOverlayRenderer = require 'renderer_volume_overlay'

-- GLOBALS

empty_renderer = EmptyRenderer()
volume_overlay_renderer = VolumeOverlayRenderer(empty_renderer)

-- CONSTANTS

WINDOW_WIDTH = 960
WINDOW_HEIGHT = 720

local brass_key = Key(Key.Type.PIN_TUMBLER, Key.Material.BRASS, Key.Body.FAB, {
   10, 5, 8, 4, 7}, {
     {{0, 1, 2, 3, 4}, 1},
     {{3, 4}, 5},
     {{1, 2, 3}, 1},
     {{0}, 6},
     {{1}, 2},
     {{2}, 2},
     {{3}, 2},
     {{4}, 1},
   })

local copper_key = Key(Key.Type.PIN_TUMBLER, Key.Material.COPPER, Key.Body.FAB, {
   4, 8, 2, 12, 3}, {
     {{0, 1, 2, 3, 4}, 2},
     {{0, 1}, 6},
     {{0, 1, 2, 3, 4}, 2},
     {{3, 4}, 10},
   })

local steel_key = Key(Key.Type.PIN_TUMBLER, Key.Material.STEEL, Key.Body.FAB, {
   6, 5, 8, 6}, {
     {{1, 2}, 3},
     {{2, 3}, 2},
     {{3, 4}, 4},
     {{2, 3}, 2},
     {{1, 2}, 12},
   })


-- OBJECT

local KeygenMain = {}
KeygenMain.__index = KeygenMain

setmetatable(KeygenMain, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local canvas = love.graphics.newCanvas(320, 240)
canvas:setFilter('nearest', 'nearest')

function KeygenMain.load()
  game = Game:new()
  game.player.inventory = {
    [100] = brass_key,
    [101] = copper_key,
    [102] = steel_key,
  }
  game.state.keyring.open = true
  game:update_inventory()

  -- window
  love.window.setTitle("Keygen")
  love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false, 
    vsync = true, 
    resizable = true, 
    minwidth = WINDOW_WIDTH, 
    minheight = WINDOW_HEIGHT})

  -- fonts
  engyne.set_default_font()

  empty_renderer:setup(0, 0, 320, 240)
  brass_key:render()
  copper_key:render()
  steel_key:render()
end

function KeygenMain.resize(w, h)
end

function KeygenMain.quit()
  return false
end

function KeygenMain.keypressed(key, unicode)
  if key == 'r' then
    love.event.quit('restart')
  end
  game:keypressed(key, unicode)
end

function KeygenMain.mousepressed(mx, my, button, istouch)
end

function KeygenMain.textinput(text)
end


function KeygenMain.draw()
  local dt = love.timer.getDelta()

  love.graphics.setCanvas()
  love.graphics.clear()
  engyne.reset_color()

  empty_renderer:draw(true)
  volume_overlay_renderer:draw(nil, game, dt, true)
end

return KeygenMain



