local textures = {}
textures.__index = Light

setmetatable(textures, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

textures.image_data = {}
textures.image_names = {'missing', 'painting-01', 'wood-01', 'pantry-01', 'pantry-02'}
textures.count = 0

textures.load = function()
  for i, name in ipairs(textures.image_names) do
    local texture = love.image.newImageData('assets/${name}.png' % { name = name })
    textures.image_data[name] = {
      index = i,
      texture = texture,
      height = texture:getHeight(),
      width = texture:getWidth(),
    }
    textures.count = textures.count + 1
  end
end

return textures



