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
  self:setup()

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
  -- draw the player
  local player_cx, player_cy = self.lr:canvas_point(player.rx, player.ry)
  love.graphics.set_color('red')
  love.graphics.circle('line', player_cx, player_cy, 2)

  local eye_cx = player_cx + math.sin(player.rot) * 10
  local eye_cy = player_cy + math.cos(player.rot) * 10

  love.graphics.line(player_cx, player_cy, eye_cx, eye_cy)

  -- highlight colliding walls
  local res_v = 10
  for theta = 0, res_v - 1 do
    local angle = -player.fov / 2 + theta * player.fov / res_v
    local ray = Line(player.rx, player.ry, player.rx + math.sin(player.rot + angle), player.ry + math.cos(player.rot + angle))
    local collisions = raycaster.collisions(map, ray)
    --for i, line in ipairs(collisions) do
    --  self.lr:draw_line(line)
    --end
    if #collisions > 0 then
      local closest_collision = raycaster.closest_collision(collisions)

      local ccx, ccy = self.lr:canvas_point(closest_collision.x, closest_collision.y)
      love.graphics.line(player_cx, player_cy, ccx, ccy)
      love.graphics.line(ccx - 4, ccy - 4, ccx + 4, ccy + 4)
      love.graphics.line(ccx + 4, ccy - 4, ccx - 4, ccy + 4)
    end
  end
end

return LevelOverlayRenderer
