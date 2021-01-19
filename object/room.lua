local Room = {}
Room.__index = Room

setmetatable(Room, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Room.new(x, y, floor_height, ceiling_height, ambient_light)
  local self = {}
  setmetatable(self, Room)
  self.kind = 'room'
  self.x = x
  self.y = y
  self.floor_height = floor_height
  self.ceiling_height = ceiling_height
  self.ambient_light = ambient_light
  return self
end

return Room



