local engyne = require 'engyne'
local Line = require 'line'
local raycaster = require 'raycaster'

local VolumeRenderer = {}
VolumeRenderer.__index = VolumeRenderer

setmetatable(VolumeRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function VolumeRenderer.new()
  local self = {}
  setmetatable(self, VolumeRenderer)

  self:setup(0, 0, 200, 200)

  return self
end

function VolumeRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self.fpv = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function VolumeRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  engyne.set_color('darkgrey', 4)
  love.graphics.rectangle('line', 0, 0, self.width, self.height)

  -- set canvas back to original
  love.graphics.setCanvas()
end

function VolumeRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function VolumeRenderer:draw(map, player)
  love.graphics.setCanvas(self.fpv)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')


  local eye_rx = player.rx + math.sin(player.rot)
  local eye_ry = player.ry + math.cos(player.rot)
  local eye = Line(player.rx, player.ry, eye_rx, eye_ry)
  local eye_ux, eye_uy = eye:unit_vector()
  local eye_rnx, eye_rny = eye:norm_vector()
  
  local ll = 0

  love.graphics.setLineWidth(0)

  local eye_x, eye_y = math.sin(player.rot), math.cos(player.rot)
  local eye_px, eye_py = player.rx, player.ry

  -- highlight colliding walls
  local res_v = self.width
  for theta = 0, res_v - 1 do
    local angle = player.fov / 2 - theta * player.fov / (res_v - 1)
    local ray = Line(player.rx, player.ry, player.rx + math.sin(player.rot + angle), player.ry + math.cos(player.rot + angle))
    local collisions = raycaster.fast_collisions(map, ray)
    if #collisions > 0 then
      local cc = collisions[1]


      local dist = (cc.x - eye_px) * eye_x + (cc.y - eye_py) * eye_y
      local scale = 1 / dist
      local height = scale * self.height

      local step = dist / 4
      local illumination = 0.0
      local light = 1/step

      local final = math.min(illumination + light, 1)
      local color = math.floor(final * 31)
      engyne.set_color('grey', color)
      love.graphics.line(theta, self.height / 2 - height / 2, theta, self.height / 2 + height / 2)
      engyne.reset_color()
    end
  end

  -- set canvas back to original
  love.graphics.setCanvas()
  love.graphics.setBlendMode('alpha')
  love.graphics.draw(self.fpv, self.x + 0.5, self.y)
end

return VolumeRenderer
