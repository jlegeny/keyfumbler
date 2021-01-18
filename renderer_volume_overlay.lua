local engyne = require 'engyne'

local VolumeOverlayRenderer = {}
VolumeOverlayRenderer.__index = VolumeOverlayRenderer

setmetatable(VolumeOverlayRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function VolumeOverlayRenderer.new(volume_renderer)
  local self = {}
  setmetatable(self, VolumeOverlayRenderer)

  self.vr = volume_renderer
  self.vr.overlay = self
  self:setup()

  self.mode = 'lines'

  return self
end

function VolumeOverlayRenderer:setup()
  self.x = self.vr.x
  self.y = self.vr.y
  self.width = self.vr.width
  self.height = self.vr.height
  self.hud = love.graphics.newCanvas(self.width, self.height)
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function VolumeOverlayRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.hud)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  --engyne.set_color('red')
  --love.graphics.rectangle('line', 0, 0, self.width, self.height)

  -- set canvas back to original
  love.graphics.setCanvas()
end

function VolumeOverlayRenderer:draw(map, game, fullscreen)
  -- love.graphics.setScissor(self.vr.x, self.vr.y, self.vr.width, self.vr.height)
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  if game.overlay_text then
    engyne.set_color('amber', 5)
    love.graphics.printf(game.overlay_text, self.width / 2 - 100, 10, 200, 'center')
  end

  love.graphics.setCanvas()

  if fullscreen then
    local width, height = love.graphics.getDimensions()
    local mult = math.min(height / self.height, width / self.width)
    love.graphics.draw(self.hud, (width - self.width * mult) / 2, 0, 0, mult, mult)
    love.graphics.draw(self.canvas, (width - self.width * mult) / 2, 0, 0, mult, mult)
  else
    love.graphics.draw(self.hud, self.x, self.y)
    love.graphics.draw(self.canvas, self.x, self.y)
  end

  --love.graphics.setScissor()
end

return VolumeOverlayRenderer
