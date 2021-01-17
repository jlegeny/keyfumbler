local Level = {}
Level.__index = Level

setmetatable(Level, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Level.new()
  local self = {}
  setmetatable(self, Level)
  self.maps = {}
  self.script = nil
  self.data = {}
  return self
end

function Level:restore(maps)
end

function Level:save()
end

return Level



