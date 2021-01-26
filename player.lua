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

function Player.new()
  local self = {}
  setmetatable(self, Player)
  self.rx = 0
  self.ry = 0
  self.rot = 0
  self.z = 0
  self.h = 1
  self.w = 0.25
  self.chin = 0
  self.no_clip = false

  self.speed = 5
  self.rot_speed = math.pi

  self.region = nil
  self.inventory = {}

  self.fov = math.pi / 2
  return self
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

function Player:step_forward(dt, map)
  dx = dt * math.sin(self.rot) * self.speed
  dy = dt * math.cos(self.rot) * self.speed
  
  self:step(dx, dy, dt, map)
end

function Player:step_backward(dt, map)
  dx = -dt * math.sin(self.rot) * self.speed
  dy = -dt * math.cos(self.rot) * self.speed

  self:step(dx, dy, dt, map)
end

function Player:step(dx, dy, dt, map)
  local obstructed = false
  local bounces = 0
  local collision = nil

  if self.noclip then
    goto make_step
  end

  collision = raycaster.circular_collision(map.volatile.bsp, self.rx + dx, self.ry + dy, self.w ^ 2)
  if collision ~= nil then
    local nx, ny = Line.norm_vector(collision.line)
    local dot = self.rx * nx + self.ry * ny
    dx, dy = Line.unit_vector(collision.line)
    if dot < 0 then
      dx, dy = -self.speed * dx * dt, -self.speed * dy * dt
    else
      dx, dy = self.speed * dx * dt, self.speed * dy * dt
    end

    collision = raycaster.circular_collision(map.volatile.bsp, self.rx + dx, self.ry + dy, self.w ^ 2)
  end

  obstructed = collision ~= nil
 
  ::make_step::
  if not obstructed then
    self.rx = self.rx + dx
    self.ry = self.ry + dy
    self:update(map)
  end

end


return Player



