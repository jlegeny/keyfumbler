local engyne = require 'engyne'
local Decal = require 'decal'

local ItemRenderer = {}
ItemRenderer.__index = ItemRenderer

setmetatable(ItemRenderer, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function ItemRenderer.new()
  local self = {}
  setmetatable(self, ItemRenderer)

  self.id = nil
  self.kind = nil
  self.obj = nil
  self.stats = {}

  self.selected = 1
  self._stat_n = 0
  self._stat_mod = 0

  self.delegate = nil

  self:setup(0, 0, 200, 200)

  return self
end

function ItemRenderer:set_delegate(delegate)
  self.delegate = delegate
end

function ItemRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self:pre_render_canvas()
end

function ItemRenderer:pre_render_canvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  engyne.set_color('darkgrey', 6)
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)

  -- set canvas back to original
  love.graphics.setCanvas()
end

function ItemRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function ItemRenderer:set_item(map, id, kind)
  self.id = id
  self.kind = kind
  self.obj = map:object_by_id(id)
end

function ItemRenderer:reset_item()
  self.id = nil
  self.kind = nil
  self.obj = nil
  self.selected = 1
end

function ItemRenderer:print_stat(name, value, kind)
  if self._stat_n == self.selected then
    engyne.set_color('copperoxyde', 7)
  else
    engyne.set_color('lightgrey', 7)
  end
  if kind == 'bool' then
    if value then
      value = 'true'
    else
      value = 'false'
    end
  end
  love.graphics.print('${name} ${value}' % {
    name = name,
    value = value
  },
  self.x, self.y + self._stat_n * 20)
  self._stat_n = self._stat_n + 1
end

function ItemRenderer:next_stat()
  self.selected = self.selected + 1
end

function ItemRenderer:prev_stat()
  if self.selected > 1 then
    self.selected = self.selected - 1
  end
end

function ItemRenderer:dec_stat()
  self._stat_mod = self._stat_mod - 1
end

function ItemRenderer:inc_stat()
  self._stat_mod = self._stat_mod + 1
end

function ItemRenderer:draw(map, editor_state)
  if self.id == nil then
    engyne.set_color('lightgrey', 5)
    love.graphics.print('Select one item', self.x, self.y)
  end

  self._stat_n = 1

  if self.kind == 'wall' then
    engyne.set_color('lightgrey', 7)
    love.graphics.print('selected wall ${id}' % { id = self.id }, self.x, self.y)
  end

  if self.kind == 'split' then
    engyne.set_color('lightgrey', 7)
    love.graphics.print('selected split ${id}' % { id = self.id }, self.x, self.y)
    if self.selected == self._stat_n then
      if self._stat_mod ~= 0 then
        self.obj.is_door = not self.obj.is_door
      end
    end
    self:print_stat('is_door', self.obj.is_door, 'bool')
  end

  if self.kind == 'wall' or self.kind == 'split' then

    if self.delegate and self.selected == self._stat_n then
      if self._stat_mod == 1 then
        local image_name = 'missing'
        local image_data = self.delegate.image_data()[image_name]
        table.insert(self.obj.decals, Decal(
        image_name, 0, 0, 1, 1
        ))
      end
      if self._stat_mod == -1 and #self.obj.decals > 0 then
        table.remove(self.obj.decals, #self.obj.decals)
      end
    end
    self:print_stat('decals', #self.obj.decals, 'count')

    for i, decal in ipairs(self.obj.decals) do
      if self.selected == self._stat_n then
        local ni = self.delegate.image_data()[decal.name].index
        ni = (((ni - 1) + self._stat_mod) % 2) + 1
        decal.name = self.delegate.image_name(ni)
      end
      self:print_stat('[${i}]:' % {i = i}, decal.name, 'name')
      if self.selected == self._stat_n then
        decal.x = decal.x + self._stat_mod * 0.1
      end
      self:print_stat('  x:', decal.x, 'ratio')
      if self.selected == self._stat_n then
        decal.y = decal.y + self._stat_mod * 0.1
      end
      self:print_stat('  y:', decal.y, 'ratio')
      if self.selected == self._stat_n then
        decal.width = decal.width + self._stat_mod * 0.1
      end
      self:print_stat('  w:', decal.width, 'ratio')
      if self.selected == self._stat_n then
        decal.height = decal.height + self._stat_mod * 0.1
      end
      self:print_stat('  h:', decal.height, 'ratio')
    end
  end


  if self.kind == 'room' then
    engyne.set_color('lightgrey', 7)
    love.graphics.print('selected room ${id}' % { id = self.id }, self.x, self.y)

    if self.selected == self._stat_n then
      self.obj.floor_height = self.obj.floor_height + self._stat_mod * 0.125
    end
    self:print_stat('floor_height', self.obj.floor_height, 'height')
    if self.selected == self._stat_n then
      self.obj.ceiling_height = self.obj.ceiling_height + self._stat_mod * 0.125
    end
    self:print_stat('ceiling_height', self.obj.ceiling_height, 'height')
    if self.selected == self._stat_n then
      self.obj.ambient_light = self.obj.ambient_light + self._stat_mod * 1
    end
    self:print_stat('ambient_light', self.obj.ambient_light, 'light')
  end

  if self.kind == 'light' then
    engyne.set_color('lightgrey', 7)
    love.graphics.print('selected light ${id}' % { id = self.id }, self.x, self.y)

    if self.selected == self._stat_n then
      self.obj.intensity = self.obj.intensity + self._stat_mod * 1
    end
    self:print_stat('intensity', self.obj.intensity, 'light')
  end
 
  if self.delegate ~= nil then
    if self._stat_mod ~= 0 then
      self.delegate.notify('geometry_updated')
    end
  end
  self._stat_mod = 0

  if self.selected >= self._stat_n then
    self.selected = self._stat_n - 1
  end
end

return ItemRenderer
