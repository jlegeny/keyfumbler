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
  self.audio = {
    ambience = love.audio.newSource("assets/ambience.ogg", "static")
  }
  self.audio.ambience:setVolume(0.25)
  self.audio.ambience:setLooping(true)
  -- self.audio.ambience:play()

  self.player = Player()
  self.level = nil
  self.layer = nil
  self.map = nil
  self.nearest_trigger = nil
  self.overlay_text = nil

  self.keyring = {
    state = 'closed',
    position = 0,
    selected_key = 0,
  }


  self.volatile = {
    key_count = 0,
  }

  self.scripts = {}
  return self
end

function Game:set_level(level, layer)
  self.level = level
  self.layer = layer
  self.map = level.layers[layer]
end

function Game:set_layer(layer)
  self.layer = layer
  self.map = level.layers[layer]
  self:update_player()

  if self.delegate then
    self.delegate.notify('layer_changed')
  end
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

function Game:update_inventory()
  self.volatile.key_count = 0
  for id, object in pairs(self.player.inventory) do
    if object.kind == 'key' then
      self.volatile.key_count = self.volatile.key_count + 1
    end
  end
end

function Game:update_player()
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
    print('noclip', self.player.noclip)
  end

  if self.nearest_trigger and self.level.trigger then
    if key == 'e' then
      self.level.trigger(self.nearest_trigger, self.map.triggers[self.nearest_trigger], self)
    end
  end

  if key == 'c' then
    if self.player.posture == Player.Posture.STAND or 
      self.player.posture == Player.Posture.STANDING then
      self.player.posture = Player.Posture.CROUCHING
    elseif self.player.posture == Player.Posture.CROUCH or
      self.player.posture == Player.Posture.CROUCHING then
      self.player.posture = Player.Posture.STANDING
    end
  end

  if key == 'f' then
    local kr = self.keyring
    if kr.state == 'closed' or kr.state == 'closing' then
      kr.state = 'opening'
    else
      kr.state = 'closing'
    end
  end

  if self.keyring.state == 'open' then
    local sk = self.keyring
    if key == 'right' then
      sk.selected_key = (sk.selected_key + 1) % self.volatile.key_count
    elseif key == 'left' then
      sk.selected_key = (sk.selected_key - 1) % self.volatile.key_count
    end
  end
end


function Game:update(dt)
  self.overlay_text = nil
  -- triggers
  self.nearest_trigger = self:get_trigger()
  if self.nearest_trigger then
    self.level.near(self.nearest_trigger, self)
    --self.overlay_text = self.map.triggers[self.nearest_trigger].name
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
 
  if self.player.posture == Player.Posture.STAND or self.player.posture == Player.Posture.CROUCH then
    -- player controls
    if love.keyboard.isDown('a') then
      self.player:rotate_ccw(dt)
    elseif love.keyboard.isDown('d') then
      self.player:rotate_cw(dt)
    end

    local player_speed = 'walk'
    if self.player.posture == Player.Posture.STAND then
      if love.keyboard.isDown('lshift') then
        player_speed = 'sprint'
      end
    end

    if love.keyboard.isDown('w') then
      self.player:step_forward(dt, player_speed, self.map)
    elseif love.keyboard.isDown('s') then
      self.player:step_backward(dt, player_speed, self.map)
    end
  end

  self.player:update_posture(dt)

  -- after movement
  local new_room_id = 0
  if self.player.region then
    new_room_id = self.player.region.room_id
  end
 
  if new_room_id ~= prev_room_id then
    self.level.entered(self.layer, new_room_id, prev_room_id, self)
  end
end

return Game
