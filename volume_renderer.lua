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

  love.graphics.setColor(1, 1, 1, 0.4)
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

  local eye_rx = player.rx + math.sin(player.rot)
  local eye_ry = player.ry + math.cos(player.rot)
  local eye = Line(player.rx, player.ry, eye_rx, eye_ry)
  local eye_ux, eye_uy = eye:unit_vector()
  local eye_rnx, eye_rny = eye:norm_vector()
  
  -- highlight colliding walls
  local res_v = self.width
  for theta = 0, res_v - 1 do
    love.graphics.setColor(theta / res_v, 0, 0, 1)
    local angle = -player.fov / 2 + theta * player.fov / (res_v - 1)
    local ray = Line(player.rx, player.ry, player.rx + math.sin(player.rot + angle), player.ry + math.cos(player.rot + angle))
    local collisions = raycaster.collisions(map, ray)
    --for i, line in ipairs(collisions) do
    --  self.lr:draw_line(line)
    --end
    if #collisions > 0 then
      local cc = raycaster.closest_collision(collisions)

      local height = 1 / (math.sin(math.pi / 2 - angle) * math.sqrt(cc.sqd)) * self.height
      -- local height = 1 / math.sqrt(cc.sqd) * self.height

      -- love.graphics.line(theta, self.height / 2 - 10, theta, self.height / 2 + 10)
      love.graphics.line(theta, self.height / 2 - height / 2, theta, self.height / 2 + height / 2)
    end
  end

  -- set canvas back to original
  love.graphics.setCanvas()
  love.graphics.draw(self.fpv, self.x, self.y)
end

return VolumeRenderer
