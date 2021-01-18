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

  self.scripts = {}
  return self
end

function Game:set_level(level, layer)
  self.level = level
  self.layer = layer
  self.map = level.layers[layer]
end

function Game:run_loop(layer, id, override, script)
  if self.scripts[layer] == nil then
    self.scripts[layer] = {}
  end
  if self.scripts[layer][id] and not override then
    return
  end
  self.scripts[layer][id] = script
end

function Game:set_player_position(x, y, rot)
  self.player.rx = x
  self.player.ry = y
  self.player.rot = rot
  self.player:update(self.map)
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
    if self.nearest_trigger and self.level.trigger then
      self.level.trigger(self.nearest_trigger, self.map.triggers[self.nearest_trigger], self)
    end
  end
end


function Game:update(dt)
  self.overlay_text = nil
  -- triggers
  self.nearest_trigger = self:get_trigger()
  if self.nearest_trigger then
    self.overlay_text = self.map.triggers[self.nearest_trigger].name
  end

  -- scripts
  for layer, scripts in pairs(self.scripts) do
    local finished_scripts = {}
    for id, script in pairs(scripts) do
      local finished = script(dt)
      if finished then
        table.insert(finished_scripts, id)
      end
    end
    for _, id in pairs(finished_scripts) do
      scripts[id] = nil
    end
  end

  -- before movement
  local prev_room_id = 0
  if self.player.region then
    prev_room_id = self.player.region.room_id
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

  -- after movement
 local new_room_id = 0
  if self.player.region then
    new_room_id = self.player.region.room_id
  end
 
  if new_room_id ~= prev_room_id then
    self.level.entered(new_room_id, prev_room_id)
  end
end

return Game
