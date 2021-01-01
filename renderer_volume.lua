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

  engyne.reset_color()
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
  local eye_px, eye_py = player.rx + player.chin * eye_x, player.ry + player.chin * eye_y

  -- highlight colliding walls
  local res_v = self.width

  local minx, miny = math.sin(player.rot + player.fov / 2), math.cos(player.rot + player.fov / 2)
  local maxx, maxy = math.sin(player.rot - player.fov / 2), math.cos(player.rot - player.fov / 2)
  local dx, dy = (maxx - minx) / res_v, (maxy - miny) / res_v

  for theta = 0, res_v - 1  do
    local linex = theta + 0.5
    local liney = 0.5
    local ray = Line(player.rx, player.ry, player.rx + minx + dx * theta, player.ry + miny + dy * theta)
    local collisions = raycaster.fast_collisions(map, ray)
    local top
    local bottom
    local prev_floor_height = nil
    local prev_ceiling_height = nil
    for i = #collisions, 1, - 1 do
      local cc = collisions[i]
      local dist = (cc.x - eye_px) * eye_x + (cc.y - eye_py) * eye_y
      local scale = 1 / dist
      local illumination = 0.0
      local light = 1 / (math.sqrt(dist / 2))

      local final = math.min(illumination + light, 1)
      local color = math.floor(final * 31)
 
      color = math.min(math.max(color, 0), 31)

      if cc.is_split then
        if cc.floor_height and prev_floor_height then
          local rheight = scale * (cc.floor_height - prev_floor_height)
          local rtop = scale * (player.h + player.z - prev_floor_height)
          local rbottom = rtop - rheight

          local top = self.height * (rtop + 1) / 2
          local bottom = self.height * (rbottom + 1) / 2
          if  cc.floor_height < prev_floor_height then
            engyne.reset_color()
            engyne.set_color('grey', color)
            love.graphics.line(linex, top, linex, bottom)
          else
            local overhang_height = (cc.floor_height - prev_floor_height) * scale * self.height
            engyne.reset_color()
            engyne.set_color('brass', 3)
            love.graphics.line(linex, bottom, linex, bottom + overhang_height)
            love.graphics.setBlendMode('alpha')
          end

        end

        if cc.ceiling_height and prev_ceiling_height then
          local rheight = scale * (prev_ceiling_height - cc.ceiling_height)
          local rbottom = scale * (player.h + player.z - cc.ceiling_height)
          local rtop = rbottom - rheight

          local top = self.height * (rtop + 1) / 2
          local bottom = self.height * (rbottom + 1) / 2

          if cc.ceiling_height > prev_ceiling_height then
             engyne.set_color('grey', color)

             love.graphics.line(linex, top, linex, bottom)
          end
        end

        prev_floor_height = cc.floor_height
        prev_ceiling_height = cc.ceiling_height
      elseif cc.ceiling_height and cc.floor_height then
        local rheight = scale * (cc.ceiling_height - cc.floor_height)

        engyne.set_color('grey', color)
        
        local rbottom = scale * (player.h + player.z - cc.floor_height)
        local rtop = rbottom - rheight

        local top = self.height * (rtop + 1) / 2
        local bottom = self.height * (rbottom + 1) / 2
        love.graphics.line(linex, liney + top, linex, liney + bottom)

        engyne.set_color('brass', 3)
        love.graphics.line(linex, liney + bottom, linex, liney + self.y + self.height)

        prev_floor_height = cc.floor_height
        prev_ceiling_height = cc.ceiling_height
      end
      engyne.reset_color()
    end
  end

  -- set canvas back to original
  love.graphics.setCanvas()
  engyne.reset_color()
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.draw(self.fpv, self.x, self.y)
  love.graphics.setBlendMode('alpha')
end

return VolumeRenderer
