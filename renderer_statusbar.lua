local util = require 'util'
local engyne = require 'engyne'

local StatusBarRenderer = {}
StatusBarRenderer.__index = StatusBarRenderer

setmetatable(StatusBarRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function StatusBarRenderer.new()
  local self = {}
  setmetatable(self, StatusBarRenderer)

  self.blocks = {}
  self:setup(0, 0, 200, 200)

  return self
end

function StatusBarRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function StatusBarRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)
  
  -- set canvas back to original
  love.graphics.setCanvas()
end

function StatusBarRenderer:draw_canvas()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.canvas, self.x, self.y)
end

function StatusBarRenderer:reset()
  self.blocks = {}
end

function StatusBarRenderer:write(color, template, ...)
  local args = {...}

  for i, v in ipairs(args) do
    template = template:gsub('{}', v, 1)
  end
  table.insert(self.blocks, { color = color, text = template })
end


function StatusBarRenderer:draw(editor_state)
  engyne.set_color('copperoxyde')

  local state = e:state_str() .. ' [' .. e:mode_str() .. ']'
  if editor_state.mode == EditorMode.DRAW then
    state = state .. ' [' .. e:draw_str() .. ']'
  elseif editor_state.mode == EditorMode.PROBE then
    state = state .. ' [' .. e:probe_str() .. ']'
  end

  love.graphics.print(state, self.x, self.y)

  local color = 'lightgrey'
  engyne.set_color(color)

  local px = self.x + 200

  for _, block in ipairs(self.blocks) do
    if block.color ~= color then
      engyne.set_color(color)
      color = block.color
    end
    love.graphics.print(block.text, px, self.y)
    px = px + string.len(block.text) * 10
  end
end

return StatusBarRenderer
