local Room = {}
Room.__index = Room

setmetatable(Room, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Room.new(x, y, floor_height, ceiling_height)
  local self = {}
  setmetatable(self, Room)
  self.kind = 'room'
  self.x = x
  self.y = y
  self.floor_height = floor_height
  self.ceiling_height = ceiling_height
  return self
end

return Room



