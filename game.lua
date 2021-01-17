local geom = require 'geom'
local Line = require 'line'

local Player = require 'player'

local Game = {}
Game.__index = Game

setmetatable(Game, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Game.new()
  local self = {}
  setmetatable(self, Game)
  self.player = Player()
  self.level = nil
  self.layer = nil
  self.map = nil
  self.nearest_trigger = nil
  self.overlay_text = nil
  return self
end

function Game:set_level(level, layer)
  self.level = level
  self.layer = layer
  self.map = level.layers[layer]
end

function Game:set_player_position(x, y, rot)
  self.player.rx = x
  self.player.ry = y
  self.player.rot = rot
end

function Game:eye_vector()
  return Line(self.player.rx, self.player.ry, self.player.rx + math.sin(self.player.rot), self.player.ry + math.cos(self.player.rot))
end

function Game:get_trigger()
  local nearest = nil
  local ld = 100000
  for id, t in pairs(self.map.triggers) do
    local sqd = geom.sqd(self.player.rx, self.player.ry, t.x, t.y)
    if sqd <= t.r ^ 2 and sqd <= ld then
      nearest = id
    end
  end
  return nearest
end

function Game:keypressed(key, unicode)
  if key == 'insert' then
    self.player.noclip = not self.player.noclip
  elseif key == 'e' then
    if self.nearest_trigger and level.trigger then
      level.trigger(self.nearest_trigger, map.triggers[self.nearest_trigger], self)
    end
  end
end


function Game:update(dt)
  self.overlay_text = nil
  -- triggers
  self.nearest_trigger = self:get_trigger()
  if self.nearest_trigger then
    self.overlay_text = map.triggers[self.nearest_trigger].name
  end
  -- player controls
  if love.keyboard.isDown('a') then
    self.player:rotate_ccw(dt)
  elseif love.keyboard.isDown('d') then
    self.player:rotate_cw(dt)
  end

  if love.keyboard.isDown('w') then
    self.player:step_forward(dt, self.map)
  elseif love.keyboard.isDown('s') then
    self.player:step_backward(dt, self.map)
  end
  self.player:update(self.map)
end

return Game
