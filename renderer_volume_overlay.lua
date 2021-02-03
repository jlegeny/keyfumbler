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

  self.ring_pos = 0
  self.target_ring_pos = 0

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

  local posy = 200 - game.keyring.position * 100

  local key_n = 0

  local selected_key = nil
  for id, object in pairs(game.player.inventory) do
    if not object.kind == 'key' then
      goto continue
    end

    local kc = math.max(8, game.volatile.key_count + 1)
    local angle = 2 * math.pi * (key_n - self.ring_pos) / kc - math.pi / 2
    local center_x = self.width / 2 + math.cos(angle) * 30
    local center_y = self.height / 2 + math.sin(angle) * 30 + posy

    local scale = 0.5
    if key_n == game.keyring.selected_key then
      -- Key.draw_outline(object, center_x, center_y, angle, 0.5)
      self.target_ring_pos = key_n
      selected_key = object
      if game.keyring.key_inserted then
        scale = 0.6
      end
    else
      if game.keyring.key_inserted then
        scale = 0.3
      else
        scale = 0.45
      end
    end

    Key.draw_side(object, center_x, center_y, angle, scale)


    
    key_n = key_n + 1
    ::continue::
  end
  if selected_key then
    Key.draw_front(selected_key, self.width / 2 - 6, self.height / 2 + posy, 0, 1)
  end
end


local VRR = 12
local VKO = 5
local blink = 0

function VolumeOverlayRenderer:draw(map, game, dt, fullscreen)
  blink = blink + dt
  -- love.graphics.setScissor(self.vr.x, self.vr.y, self.vr.width, self.vr.height)
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  if game.overlay_text then
    engyne.set_color('amber', 5)
    love.graphics.printf(game.overlay_text, self.width / 2 - 100, 10, 200, 'center')
  end

  if game.dialogue then
    engyne.set_color('darkgrey', 4)
    love.graphics.rectangle('fill', self.width / 2 - 120, 10, 240, 80)
    engyne.set_color(unpack(game.dialogue.color))
    love.graphics.printf(game.dialogue.text, self.width / 2 - 80, 10, 200, 'left')
    if blink % 1 < 0.5 then
      love.graphics.printf('[space]', self.width / 2 - 120, 70, 240, 'center')
    end
  end

  if game.keyring.state ~= 'closed'  then
    self:render_keyring(game)
    if game.keyring.state == 'opening' then
      game.keyring.position = game.keyring.position + dt * VKO
      if game.keyring.position >= 1 then
        game.keyring.position = 1
        game.keyring.state = 'open'
      end
    elseif game.keyring.state == 'closing' then
      game.keyring.position = game.keyring.position - dt * VKO
      if game.keyring.position <= 0 then
        game.keyring.position = 0
        game.keyring.state = 'closed'
      end
    end
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
  local diff = self.target_ring_pos - self.ring_pos
  local diffn = (self.target_ring_pos - game.volatile.key_count) - self.ring_pos
  local diffp = (self.target_ring_pos + game.volatile.key_count) - self.ring_pos

  local pos_diff = diff
  if math.abs(diffn) < math.abs(diff) then
    pos_diff = diffn
  elseif math.abs(diffp) < math.abs(diff) then
    pos_diff = diffp
  end

  if pos_diff > 0 then
    pos_diff = pos_diff - VRR * dt
    self.ring_pos = self.ring_pos + VRR * dt
    if pos_diff <= 0 then
      self.ring_pos = self.target_ring_pos
    end
  elseif pos_diff < 0 then
    pos_diff = pos_diff + VRR * dt
    self.ring_pos = self.ring_pos - VRR * dt
    if pos_diff >= 0 then
      self.ring_pos = self.target_ring_pos
    end
  end


  --love.graphics.setScissor()
end

return VolumeOverlayRenderer
