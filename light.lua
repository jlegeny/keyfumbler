local Light = {}
Light.__index = Light

setmetatable(Light, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Light.new(x, y, intensity)
  local self = {}
  setmetatable(self, Light)
  self.kind = 'light'
  self.x = x
  self.y = y
  self.intensity = intensity
  return self
end

return Light



