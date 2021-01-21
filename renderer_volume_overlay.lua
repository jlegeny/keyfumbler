local engyne = require 'engyne'

local Key = require 'object/key'

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

  self.ring_pos = {}
  self.ring_offset_x = 0

  self.target_ring_pos = 0
  self.target_ring_offset_x = 0

  return self
end

function VolumeOverlayRenderer:setup()
  self.x = self.vr.x
  self.y = self.vr.y
  self.width = self.vr.width
  self.height = self.vr.height
  self.hud = love.graphics.newCanvas(self.width, self.height)
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self.canvas:setFilter('nearest', 'nearest')
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

function VolumeOverlayRenderer:render_keyring(game)

  local posy = 50

  local keys_per_ring = game.state.keyring.max_size
  local key_n = 0
  local keyring_n = 0

  for id, object in pairs(game.player.inventory) do
    if not object.kind == 'key' then
      goto continue
    end
    if not self.ring_pos[keyring_n] then
      self.ring_pos[keyring_n] = 0
    end

    local angle = 2 * math.pi * (key_n - self.ring_pos[keyring_n]) / keys_per_ring - math.pi / 2
    local center_x = self.width / 2 + math.cos(angle) * 20
    local center_y = self.height / 2 + math.sin(angle) * 20

    local kx = center_x + keyring_n * 100 - self.ring_offset_x
    
    if keyring_n == game.state.keyring.selected_keyring and key_n == game.state.keyring.selected_key then
      Key.draw_outline(object, kx, center_y, angle, 0.5)
      self.target_ring_pos = key_n
      self.target_ring_offset_x = keyring_n * 100
    end

    Key.draw_side(object, kx, center_y, angle, 0.5)
    
    key_n = key_n + 1
    if key_n == keys_per_ring then
      key_n = 0
      keyring_n = keyring_n + 1
    end
    ::continue::
  end
end


local VRR = 1
local VRT = 500

function VolumeOverlayRenderer:draw(map, game, dt, fullscreen)
  -- love.graphics.setScissor(self.vr.x, self.vr.y, self.vr.width, self.vr.height)
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  if game.overlay_text then
    engyne.set_color('amber', 5)
    love.graphics.printf(game.overlay_text, self.width / 2 - 100, 10, 200, 'center')
  end

  if game.state.keyring.open then
    self:render_keyring(game)
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

  -- update keyring
  if self.ring_offset_x < self.target_ring_offset_x then
    self.ring_offset_x = math.min(self.ring_offset_x + VRT * dt, self.target_ring_offset_x)
  elseif self.ring_offset_x > self.target_ring_offset_x then
    self.ring_offset_x = math.max(self.ring_offset_x - VRT * dt, self.target_ring_offset_x)
  end

  local skr = game.state.keyring.selected_keyring
  if not self.ring_pos[skr] then
    self.ring_pos[skr] = 0
  end

  local positive_diff = self.target_ring_pos - self.ring_pos[skr]
  local negative_diff = self.target_ring_pos + 3 - self.ring_pos[skr]

  if math.abs(positive_diff) < math.abs(negative_diff) then
    pos_diff = positive_diff
  else
    pos_diff = negative_diff
  end

  --if angle_diff > math.pi then
  --  angle_diff = angle_diff - math.pi
  --elseif angle_diff < -math.pi then
  --  angle_diff = angle_diff + math.pi
  --end

  if pos_diff > 0 then
    print(self.target_ring_pos, self.ring_pos[skr], pos_diff)
    self.ring_pos[skr] = math.min(self.ring_pos[skr] + VRR * dt, self.target_ring_pos)
  elseif pos_diff < 0 then
    print(self.target_ring_pos, self.ring_pos[skr], pos_diff)
    self.ring_pos[skr] = math.max(self.ring_pos[skr] - VRR * dt, self.target_ring_pos)
  end


  --love.graphics.setScissor()
end

return VolumeOverlayRenderer
