local engyne = require 'engyne'

local Line = require 'line'
local raycaster = require 'raycaster'

local LevelOverlayRenderer = {}
LevelOverlayRenderer.__index = LevelOverlayRenderer

setmetatable(LevelOverlayRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function LevelOverlayRenderer.new(level_renderer)
  local self = {}
  setmetatable(self, LevelOverlayRenderer)

  self.lr = level_renderer
  self.lr.overlay = self
  self:setup()

  self.mode = 'lines'

  return self
end

function LevelOverlayRenderer:setup()
  self.x = self.lr.x
  self.y = self.lr.y
  self.width = self.lr.width
  self.height = self.lr.height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function LevelOverlayRenderer:set_mode(mode)
  self.mode = mode
end

function LevelOverlayRenderer:toggle_mode(mode)
  if self.mode == 'lines' then
    self.mode = 'fill'
  elseif self.mode == 'fill' then
    self.mode = 'distance'
  elseif self.mode == 'distance' then
    self.mode = 'cross'
  elseif self.mode == 'cross' then
    self.mode = 'crossfill'
  elseif self.mode == 'crossfill' then
    self.mode = 'lines'
  end
end

function LevelOverlayRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  -- set canvas back to original
  love.graphics.setCanvas()
end

function LevelOverlayRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function LevelOverlayRenderer:draw(map, player)
  love.graphics.setScissor(self.lr.x, self.lr.y, self.lr.width, self.lr.height)
  love.graphics.setBlendMode('alpha')
  -- draw the player
  local player_cx, player_cy = self.lr:canvas_point(player.rx, player.ry)
  engyne.set_color('copper', 5)
  love.graphics.circle('line', player_cx, player_cy, 2)

  local eye_cx = player_cx + math.sin(player.rot) * 10
  local eye_cy = player_cy + math.cos(player.rot) * 10

  love.graphics.line(player_cx, player_cy, eye_cx, eye_cy)

  -- highlight colliding walls
  local res_v
  if self.mode == 'fill' or self.mode == 'crossfill' then
    res_v = 320
  elseif self.mode == 'lines' then
    res_v = 9
  else
    res_v = 5
  end

  local eye = Line(0, 0, math.sin(player.rot), math.cos(player.rot))

  for theta = 0, res_v - 1 do
    
    
    if theta == math.floor(res_v/2) then
      engyne.set_color('copperoxyde')
    else
      engyne.set_color('copper', 3)
    end

    local angle = -player.fov / 2 + theta * player.fov / (res_v - 1)
    local ray = Line(player.rx, player.ry, player.rx + math.sin(player.rot + angle), player.ry + math.cos(player.rot + angle))

    if self.mode == 'cross' or self.mode == 'crossfill' then
      local collisions = raycaster.extended_collisions(map, ray)
      local lx, ly = self.lr:canvas_point(player.rx, player.ry)
      for i, c in ipairs(collisions) do
        local ccx, ccy = self.lr:canvas_point(c.x, c.y)
        engyne.set_color('copper', 8 - math.min(7, i))
        love.graphics.line(lx, ly, ccx, ccy)
        lx, ly = ccx, ccy
      end
    else
      local collisions = raycaster.fast_collisions(map, ray)
      if #collisions > 0 then
        local cc = collisions[1]

        local ccx, ccy = self.lr:canvas_point(cc.x, cc.y)
        love.graphics.line(player_cx, player_cy, ccx, ccy)

        if self.mode == 'line' or self.mode == 'distance' then
          love.graphics.line(ccx - 4, ccy - 4, ccx + 4, ccy + 4)
          love.graphics.line(ccx + 4, ccy - 4, ccx - 4, ccy + 4)
        end

        if self.mode == 'distance' then
          local dist = (cc.x - player.rx) * eye.bx + (cc.y - player.ry) * eye.by
          love.graphics.print(dist, ccx, ccy + theta * 16)

          local step = math.floor(math.sqrt(cc.sqd) / 4)
          local illumination = 0.5
          local light = 1/step
          love.graphics.print(light, ccx, ccy + theta * 16 + 14)
        end
      end
    end
  end
  love.graphics.setScissor()
end

return LevelOverlayRenderer
