local Catalog = {}
Catalog.__index = Catalog

setmetatable(Catalog, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

Catalog.decals = {'missing', 'painting-01', 'wood-01', 'wood-02', 'pantry-01', 'pantry-02', 'wine-rack', 'hanging-keyring'}
Catalog.sprites = {'missing', 'key-fab-brass', 'bulb', 'crawler-crouch', 'crawler-standing', 'crawler-stand'}

Catalog.new = function(image_names)
  local self = {}

  self.image_data = {}
  self.count = 0
  self.image_names = image_names

  for i, name in ipairs(image_names) do
    local texture = love.image.newImageData('assets/${name}.png' % { name = name })
    self.image_data[name] = {
      index = i,
      texture = texture,
      height = texture:getHeight(),
      width = texture:getWidth(),
    }
    self.count = self.count + 1
  end

  return self
end

return Catalog



