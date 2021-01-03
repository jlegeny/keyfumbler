local Map = require 'map'

local Level = {}
Level.__index = Level

setmetatable(Level, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Level.new(params)
  local self = {}
  setmetatable(self, Level)

  self.layers = params.layers
  self.delegate = params.delegate

  return self
end

function Level:set_delegate(delegate)
  self.delegate = delegate
end

function Level:serialize()
end

function Level:udpate_bsp(layer)
  self.layers[layer]:update_bsp()

  if self.delegate ~= nil then
    self.delegate.notify('map_updated')
  end
end

return Level



