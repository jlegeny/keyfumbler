local map = require 'map'
local raycaster = require 'raycaster'

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
  self.w = 0.5
  self.chin = 0

  self.speed = 5
  self.rot_speed = math.pi

  self.fov = math.pi / 2
  return self
end

function Player:update(map)
  local region = raycaster.get_region_node(map.volatile.bsp, self.rx, self.ry)
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
  wx = math.sin(self.rot) * self.w
  wy = math.cos(self.rot) * self.w

  local obstructed = self.no_clip and raycaster.is_cut_by_wall(map, Line(self.rx, self.ry, self.rx + wx, self.ry + wy))
  self.rx = self.rx + dx
  self.ry = self.ry + dy
  self:update(map)
end

function Player:step_backward(dt, map)
  dx = -dt * math.sin(self.rot) * self.speed
  dy = -dt * math.cos(self.rot) * self.speed
  wx = -math.sin(self.rot) * self.w
  wy = -math.cos(self.rot) * self.w

  local obstructed = self.no_clip and raycaster.is_cut_by_wall(map, Line(self.rx, self.ry, self.rx + wx, self.ry + wy))
  self.rx = self.rx + dx
  self.ry = self.ry + dy
  self:update(map)
end


return Player



