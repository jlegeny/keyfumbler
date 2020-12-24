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

  self.speed = 5
  self.rot_speed = math.pi

  self.fov = math.pi / 2
  return self
end

return Player



