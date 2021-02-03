local Map = require 'map'
local raycaster = require 'raycaster'
local Line = require 'line'

local Player = {}
Player.__index = Player

setmetatable(Player, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

Player.Posture = {
  STAND = 1,
  CROUCH = 2,
  STANDING = 3,
  CROUCHING = 4,
}

function Player.new()
  local self = {}
  setmetatable(self, Player)
  self.rx = 0
  self.ry = 0
  self.rot = 0
  self.z = 0
  self.w = 0.25
  self.chin = 0
  self.no_clip = false

  self.posture = self.Posture.STAND
  self.rot_speed = math.pi

  self.region = nil
  self.inventory = {}

  self.crouch = 0

  self.fov = math.pi / 2
  return self
end

function Player:speed(gait)
  if gait == 'walk' then
    return 1
  elseif gait == 'sprint' then
    return 5
  elseif gait == 'crouch' then
    return 0.5
  end
end

function Player:has(map, alias)
  local id = map.volatile.raliases[alias]
  if not id then
    return nil
  end
  return self.inventory[id]
end

function Player:height()
  return 1.3 - self.crouch
end

function Player:eye_height()
  return 1 - self.crouch
end

function Player:update(map)
  local region = map:room_node(raycaster.get_region_node(map.volatile.bsp, self.rx, self.ry))
  if region then
    self.region = region
  end
  if region.floor_height ~= nil then
    self.z = region.floor_height
  end
end

function Player:update_posture(dt)
  if self.posture == Player.Posture.CROUCHING then
    self.crouch = self.crouch + dt
    if self.crouch >= 0.5 then
      self.crouch = 0.5
      self.posture = Player.Posture.CROUCH
    end
  elseif self.posture == Player.Posture.STANDING then
    self.crouch = self.crouch - dt
    if self.region and self:height() > (self.region.ceiling_height - self.region.floor_height) then
      self.posture = Player.Posture.CROUCHING
    end
    if self.crouch <= 0 then
      self.crouch = 0
      self.posture = Player.Posture.STAND
    end
  end
end

function Player:rotate_cw(dt)
  self.rot = self.rot - dt * self.rot_speed
  if self.rot < -math.pi then
    self.rot = self.rot + math.pi * 2
  end
end

function Player:rotate_ccw(dt)
  self.rot = self.rot + dt * self.rot_speed
  if self.rot > math.pi then
    self.rot = self.rot - math.pi * 2
  end
end

function Player:step_forward(dt, gait, map)
  dx = dt * math.sin(self.rot) * self:speed(gait)
  dy = dt * math.cos(self.rot) * self:speed(gait)
  
  self:step(dx, dy, dt, map)
end

function Player:step_backward(dt, gait, map)
  dx = -dt * math.sin(self.rot) * self:speed(gait)
  dy = -dt * math.cos(self.rot) * self:speed(gait)

  self:step(dx, dy, dt, map)
end

function Player:step(dx, dy, dt, map)
  local obstructed = false
  local bounces = 0
  local collision = nil

  if self.noclip then
    goto make_step
  end

  glob.first_collision = nil
  glob.second_collision = nil

  collision = raycaster.circular_collision(map, self.rx, self.ry, dx, dy, self.w ^ 2, self.h)
  if collision ~= nil then
    local wx, wy = Line.vector(collision.line)
    local a1 = (wx * dx + wy * dy) / math.sqrt(wx ^ 2 + wy ^ 2)
    local ux, uy = Line.unit_vector(collision.line)
    dx, dy = a1 * ux, a1 * uy

    glob.first_collision = collision.id
    collision = raycaster.circular_collision(map, self.rx, self.ry, dx, dy, self.w ^ 2, self.h)
    if collision ~= nil then
      glob.second_collision = collision.id
    end
  end

  obstructed = collision ~= nil
  
  if not obstructed then
    local next_region = raycaster.get_region_node(map.volatile.bsp, self.rx + dx, self.ry + dy)
    if next_region then
      local next_room = map:room_node(next_region)
      if next_room.ceiling_height - next_room.floor_height < self:height() then
        obstructed = true
      end
    end
  end

  ::make_step::
  if not obstructed then
    self.rx = self.rx + dx
    self.ry = self.ry + dy
    self:update(map)
  end
end

return Player
