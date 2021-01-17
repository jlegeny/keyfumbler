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
  self.map = nil
  return self
end

function Game:set_map(map)
  self.map = map
end

function Game:keypressed(key, unicode)
  if key == 'insert' then
    self.player.noclip = not self.player.noclip
  end
end

function Game:set_player_position(x, y, rot)
  self.player.rx = x
  self.player.ry = y
  self.player.rot = rot
end

function Game:eye_vector()
  return Line(self.player.rx, self.player.ry, self.player.rx + math.sin(self.player.rot), self.player.ry + math.cos(self.player.rot))
end

function Game:update(dt)
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
