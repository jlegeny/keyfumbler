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
  self.chin = 0

  self.speed = 5
  self.rot_speed = math.pi

  self.fov = math.pi / 2
  return self
end

function Player:update(map)
  local region = raycaster.get_region_node(map.bsp, self.rx, self.ry)
  if region.floor_height ~= nil then
    self.z = region.floor_height
  end
end

return Player



