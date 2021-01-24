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

-- OBJECT

local KeygenMain = {}
KeygenMain.__index = KeygenMain

setmetatable(KeygenMain, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local step = false

local canvas = love.graphics.newCanvas(320, 240)
canvas:setFilter('nearest', 'nearest')

function KeygenMain.load()
  game = Game:new()
  game.player.inventory = {
  }

  local kid = 100
  for i = 1, 13 do
    local key = Key.random()
    game.player.inventory[kid] = key
    kid = kid + 1
  end


  game.keyring.open = true
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

  for id, object in pairs(game.player.inventory) do
    if object.kind == 'key' then
      object:render()
    end
  end

  empty_renderer:setup(0, 0, 320, 240)
end

function KeygenMain.resize(w, h)
end

function KeygenMain.quit()
  return false
end

function KeygenMain.keypressed(key, unicode)
  if key == 'r' then
    love.event.quit('restart')
  elseif key == 'space' then
    step = true
  end
  game:keypressed(key, unicode)
end

function KeygenMain.mousepressed(mx, my, button, istouch)
end

function KeygenMain.textinput(text)
end


function KeygenMain.draw()
  -- local dt = love.timer.getDelta()
  local dt = 0
  if true then
    dt = 0.016
    step = false
  end

  love.graphics.setCanvas()
  love.graphics.clear()
  engyne.reset_color()

  empty_renderer:draw(true)
  volume_overlay_renderer:draw(nil, game, dt, true)
end

return KeygenMain



