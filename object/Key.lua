local engyne = require 'engyne'

local Key = {}
Key.__index = Key

setmetatable(Key, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

Key.Type = {
  PIN_TUMBLER = 1,
}

Key.Material = {
  BRASS = 1,
  COPPER = 2,
  STEEL = 3,
}

Key.Body = {
  FAB = 1,
}

Key.WIDTH = 180
Key.HEIGHT = 60
Key.DEPTH = 12

function Key.new(key_type, material, body, pinning, wording)
  local self = {}
  setmetatable(self, Key)
  self.kind = 'key'
  self.key_type = key_type
  self.material = material
  self.body = body
  self.pinning = pinning
  self.wording = wording

  self.hole_x = 0
  self.hole_y = 0

  self.voxels = {}

  self.canvas_side = love.graphics.newCanvas(self.WIDTH, self.HEIGHT)
  self.canvas_front = love.graphics.newCanvas(self.DEPTH, self.HEIGHT)
  self.canvas_outline = love.graphics.newCanvas(self.WIDTH, self.HEIGHT)
  self:carve()
  self:render()
  
  return self
end


function Key:carve()
  function ensure(z, y, x)
    if not self.voxels[z] then
      self.voxels[z] = {}
    end
    if y and not self.voxels[z][y] then
      self.voxels[z][y] = {}
    end
  end

  function erase(z, y, x)
    if not self.voxels[z] then
      return
    end
    if not self.voxels[z][y] then
      return
    end
    self.voxels[z][y][x] = nil
  end

  local blade_start_x = 55
  local blade_length = 100
  local blade_height = 0
  local min_depth = 12
  local max_depth = 0
  for _, seg in ipairs(self.wording) do
    blade_height = blade_height + seg[2]
    local min = math.min(unpack(seg[1]))
    local max = math.max(unpack(seg[1]))
    min_depth = math.min(min_depth, min)
    max_depth = math.max(max_depth, max)
  end
  local blade_start_y = math.floor((self.HEIGHT - blade_height) / 2)

  local base_width = 5
  local base_start_z = math.ceil((min_depth + max_depth - (base_width)) / 2)

  local first_pin_x = blade_length - 20
  local pin_spacing = 14
  local middle = 1

  if self.key_type == Key.Type.PIN_TUMBLER then
    -- make the wording
    local y = blade_start_y
    for _, seg in ipairs(self.wording) do
      for dy = 1, seg[2] do
        y = y + 1
        for _, z in ipairs(seg[1]) do
          ensure(z, y)
          for x = blade_start_x, blade_start_x + blade_length do
            self.voxels[z][y][x] = self.material
          end
        end
      end
    end

    -- carve pins
    for pin, depth in ipairs(self.pinning) do
      for z, plane in pairs(self.voxels) do
        for y = blade_start_y + blade_height - depth, blade_start_y + blade_height do
          local w = y - (blade_start_y + blade_height - depth)
          for dx = -w, w do
            local x = blade_start_x + first_pin_x - (pin - 1) * pin_spacing + dx
            erase(z, y, x)
          end
        end
      end
    end

    -- carve the tip
    for z, plane in pairs(self.voxels) do
      for y = blade_start_y + blade_height - 15, blade_start_y + blade_height do
        local w = y - (blade_start_y + blade_height - 15)
        for dx = -w, w do
          local x = blade_start_x + first_pin_x - (0 - 1) * pin_spacing + dx + 10
          erase(z, y, x)
        end
      end
    end
    for z, plane in pairs(self.voxels) do
      for y = blade_start_y, blade_start_y + 5 do
        local w = (blade_start_y + 5) - y
        for dx = -w, 0 do
          local x = blade_start_x + blade_length + dx
          erase(z, y, x)
        end
      end
    end
  end

  if self.body == Key.Body.FAB then
    self.hole_x = 20
    self.hole_y = 30
    local hole_r = 7
    local ring_r = self.HEIGHT / 2
    for z = base_start_z, base_start_z + base_width - 1 do
      for y = 0, ring_r * 2 do
        ensure(z, y)
        for x = 0, ring_r * 2 do
          if (x - ring_r) ^ 2 + (y - ring_r) ^ 2 < ring_r ^ 2 then
            if (x - self.hole_x) ^ 2 + (y - self.hole_y) ^ 2 > hole_r ^ 2 then
              self.voxels[z][y][x] = self.material
            end
          end
        end
      end
    end
  end

end

function Key.material_color(material, light, distance)
  local intensity = math.max(2, math.min(7, light - distance))
  if material == Key.Material.BRASS then
    engyne.set_color('brass', intensity)
  elseif material == Key.Material.COPPER then
    engyne.set_color('copper', intensity)
  elseif material == Key.Material.STEEL then
    engyne.set_color('lightgrey', intensity)
  end
end

function Key:render()
  love.graphics.setCanvas(self.canvas_side)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  engyne.reset_color()

  local stamp_points = {}
  local planes = {}
  for z, _ in pairs(self.voxels) do
    table.insert(planes, z)
  end
  table.sort(planes)

  local minx, maxx = self.WIDTH, 0
  local miny, maxy = self.HEIGHT, 0 

  local last_material = nil
  for zi = #planes, 1, -1 do
    z = planes[zi]
    plane = self.voxels[z]
    local points = {}
    for y, line in pairs(plane) do
      for x, material in pairs(line) do
        minx, maxx = math.min(minx, x), math.max(maxx, x)
        miny, maxy = math.min(miny, y), math.max(maxy, y)
        if material ~= last_material then
          if #points > 0 then
            Key.material_color(last_material, 7, z)
            love.graphics.points(points)
            points = {}
          end
          last_material = material
        end
        table.insert(points, {x + 0.5, y + 0.5})
      end
    end
    Key.material_color(last_material, 7, z)
    love.graphics.points(points)
  end

  love.graphics.setCanvas(self.canvas_outline)
  love.graphics.clear()
  love.graphics.setBlendMode('replace')

  engyne.set_color('red')
  love.graphics.setLineWidth(2)
  love.graphics.rectangle('line', minx + 0.5, minx + 0.5, maxx - minx - 1, maxy - miny - 1)
 
  love.graphics.setCanvas(self.canvas_front)
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  for zi = 1, #planes do
    z = planes[zi]

    for y, line in pairs(self.voxels[z]) do
      local closest_x = nil
      for x, _ in pairs(line) do
        if not closest_x or x > closest_x then
          closest_x = x
        end
      end
      if closest_x then
        Key.material_color(line[closest_x], 7, math.floor((self.WIDTH - closest_x) / 10))

        --engyne.set_color('brass', math.max(2, 7 - math.floor(closest_x / 10)))
        love.graphics.points(z, y)
      end
    end
  end

  engyne.reset_color()

  love.graphics.setCanvas()
end

function Key:draw_side(x, y, angle, scale)
  engyne.reset_color()
  love.graphics.draw(self.canvas_side, x, y, angle, scale, scale, self.hole_x, self.hole_y)
end

function Key:draw_outline(x, y, angle, scale)
  engyne.reset_color()
  love.graphics.draw(self.canvas_outline, x, y, angle, scale * 1.1, scale * 1.1, self.hole_x, self.hole_y)
end

function Key:draw_front(x, y, angle, scale)
  engyne.reset_color()
  love.graphics.draw(self.canvas_front, x, y, angle, scale, scale, 0, self.hole_y)
end


return Key



