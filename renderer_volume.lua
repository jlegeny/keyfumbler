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

  self.light_cache = {}
  self.effect = love.graphics.newShader [[
  #pragma language glsl3
  #define PI 3.1415926538

  uniform float time;

  float random (vec2 st) {
    return fract(sin(dot(st.xy,
    vec2(12.9898,78.233)))*
    43758.5453123);
  }

  vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
  {
    float st = random(texture_coords + time * 0);
    float x = texture_coords.x;
    float y = texture_coords.y;
    x += mod(st, 0.02);
    st = random(vec2(x, st));
    y += mod(st, 0.02);
    vec2 replace_coords = vec2(x, y);
    vec4 texturecolor = Texel(tex, replace_coords);
    float t = random(texture_coords + time * 0);
    vec3 grain = vec3(mod(t, 0.02));
    return texturecolor * color + vec4(grain, 1);
  }
  ]]
  self:setup(0, 0, 200, 200)
  self.time = 0

  return self
end

function VolumeRenderer:setup(x, y, width, height)
  self.x = x
  self.y = y
  self.mode = 'photo'
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self.fpv = love.graphics.newCanvas(self.width, self.height)
  self.fpv:setFilter("nearest", "nearest")
  self:pre_render_canvas()
end

function VolumeRenderer:invalidate_light_cache(rect)
  if rect == nil then
    self.light_cache = {}
  else
    for x, col in self.light_cache do
      for y, _ in col do
        if x >= rect.ax and x <= rect.bx and y >= rect.ay and y <= rect.by then
          self.light_cache[x][y] = nil
        end
      end
    end
  end
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

function VolumeRenderer:toggle_mode()
  if self.mode == 'photo' then
    self.mode = 'light'
  elseif self.mode == 'light' then
    self.mode = 'surface'
  elseif self.mode == 'surface' then
    self.mode = 'photo'
  end
end

function VolumeRenderer:draw_canvas()
  love.graphics.draw(self.canvas, self.x, self.y)
end

function VolumeRenderer:draw_primitive(map, player)
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
      local light = math.min(illumination + 1 / (math.sqrt(dist / 2)), 1)

      local wall_color = math.floor(light * 31)
      wall_color = math.min(math.max(wall_color, 0), 31)

      local floor_color = math.floor(light * 7)
      floor_color = math.min(math.max(floor_color, 0), 7)

      if cc.is_split then
        if cc.floor_height and prev_floor_height then
          local rheight = scale * (cc.floor_height - prev_floor_height)
          local rtop = scale * (player.h + player.z - prev_floor_height)
          local rbottom = rtop - rheight

          local top = self.height * (rtop + 1) / 2
          local bottom = self.height * (rbottom + 1) / 2
          if  cc.floor_height < prev_floor_height then
            engyne.reset_color()
            engyne.set_color('grey', wall_color)
            love.graphics.line(linex, top, linex, bottom)
          else
            local overhang_height = (cc.floor_height - prev_floor_height) * scale * self.height
            engyne.reset_color()
            engyne.set_color('brass', floor_color)
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
             engyne.set_color('grey', wall_color)
             love.graphics.line(linex, top, linex, bottom)
          end
        end

        prev_floor_height = cc.floor_height
        prev_ceiling_height = cc.ceiling_height
      elseif cc.ceiling_height and cc.floor_height then
        local rheight = scale * (cc.ceiling_height - cc.floor_height)

        engyne.set_color('grey', wall_color)
        
        local rbottom = scale * (player.h + player.z - cc.floor_height)
        local rtop = rbottom - rheight

        local top = self.height * (rtop + 1) / 2
        local bottom = self.height * (rbottom + 1) / 2
        love.graphics.line(linex, liney + top, linex, liney + bottom)

        engyne.set_color('brass', floor_color)
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

local ns = 0
function VolumeRenderer:surface_segment_renderer(ox, oy, s)
  if s.kind == 'floor' then
    if ns == 0 then
      love.graphics.setColor(1, 0, 0, 0.5)
    else
      love.graphics.setColor(0, 1, 0, 0.5)
    end
    ns = (ns + 1) % 2
  elseif s.kind == 'split' then
    love.graphics.setColor(0, 1, 0, 0.5)
    -- engyne.set_color('brass', 3)
  elseif s.kind == 'ceiling' then
    love.graphics.setColor(0, 0, 1, 0.5)
  elseif s.kind == 'wall' then
    love.graphics.setColor(1, 0, 1, 0.5)
  end
  local top = self.height * (s.top + 1) / 2
  local bottom = self.height * (s.bottom + 1) / 2
  love.graphics.line(ox, oy + top, ox, oy + bottom)
end

function VolumeRenderer:light_segment_renderer(ox, oy, s)
  local illumination = 0.0
  local light = math.min(illumination + 1 / (math.sqrt(s.dist / 2)), 1)

  if s.kind == 'wall' or s.kind == 'split' then
    love.graphics.setColor(light, light, light, 1)
  else
    love.graphics.setColor(light / 2, light / 2, light / 2, 1)
    -- engyne.set_color('grey', 0)
  end

  local top = self.height * (s.top + 1) / 2
  local bottom = self.height * (s.bottom + 1) / 2
  love.graphics.line(ox, oy + top, ox, oy + bottom)
end

function VolumeRenderer:photo_segment_renderer(ox, oy, s)
  if s.kind == 'wall' or s.kind == 'split' then
    local illumination = ((s.ambient_light + s.dynamic_light) / 64)
    local light = math.min(illumination * 1 / (math.sqrt(s.dist / 2)), 1)
    --local light = math.min(illumination, 1)

    local wall_color = math.floor(light * 62)
    wall_color = math.min(math.max(wall_color, 0), 62)
    engyne.set_color('grey', wall_color)
    local top = self.height * (s.top + 1) / 2
    local bottom = self.height * (s.bottom + 1) / 2

    love.graphics.line(ox, oy + top, ox, oy + bottom)
  else
    local far_illumination = ((s.ambient_light + s.dynamic_light) / 64)
    local far_light = math.min(far_illumination * 1 / (math.sqrt(s.dist / 2)), 1)
    --local far_light = math.min(far_illumination, 1)
    local far_color = math.floor(far_light * 31)
    far_color = math.min(math.max(far_color, 0), 31)
    local close_illumination = ((s.ambient_light + s.prev_dynamic_light) / 64)
    local close_light = math.min(close_illumination * 1 / (math.sqrt(s.prev_dist / 2)), 1)
    --local close_light = math.min(close_illumination, 1)
    local close_color = math.floor(close_light * 31)
    close_color = math.min(math.max(close_color, 0), 31)

    local top = self.height * (s.top + 1) / 2
    local bottom = self.height * (s.bottom + 1) / 2
    
    if close_color > far_color then
      local steps = close_color - far_color
      local dh = (bottom - top) / steps
      local lh = top
      for i = 0, steps - 1 do
        if s.kind == 'floor' then
          engyne.set_color('grey', far_color + i)
        else
          engyne.set_color('grey', close_color - i)
        end
        local lt = math.floor(top + i * dh)
        local lb = math.floor(top + (i + 1) * dh)
        love.graphics.line(ox, oy + lt, ox, oy + lb)
      end
    elseif close_color < far_color then
      local steps = far_color - close_color
      local dh = (bottom - top) / steps
      local lh = top
      for i = 0, steps - 1 do
        if s.kind == 'floor' then
          engyne.set_color('grey', far_color - i)
        else
          engyne.set_color('grey', close_color + i)
        end
        local lt = math.floor(top + i * dh)
        local lb = math.floor(top + (i + 1) * dh)
        love.graphics.line(ox, oy + lt, ox, oy + lb)
      end
    else
      engyne.set_color('grey', close_color)
      love.graphics.line(ox, oy + top, ox, oy + bottom)
    end
  end

end

 
function VolumeRenderer:draw_segments(map, player, segment_renderer)
  love.graphics.setCanvas(self.fpv)

  engyne.reset_color()
  love.graphics.clear()
  love.graphics.setBlendMode('alpha')

  love.graphics.setLineWidth(0)

  local eye_dx, eye_dy = math.sin(player.rot), math.cos(player.rot)
  local eye_x, eye_y = player.rx + player.chin * eye_dx, player.ry + player.chin * eye_dy

  -- highlight colliding walls
  local res_v = self.width

  local minx, miny = math.sin(player.rot + player.fov / 2), math.cos(player.rot + player.fov / 2)
  local maxx, maxy = math.sin(player.rot - player.fov / 2), math.cos(player.rot - player.fov / 2)
  local dx, dy = (maxx - minx) / res_v, (maxy - miny) / res_v

 for theta = 0, res_v - 1  do
    local linex = theta + 0.5
    local liney = 0.5
    local ray = Line(player.rx, player.ry, player.rx + minx + dx * theta, player.ry + miny + dy * theta)
    local collisions = raycaster.extended_collisions_with_light(map, ray, self.light_cache)
      
    local segments = VolumeRenderer.segments(eye_x, eye_y, eye_dx, eye_dy, player, collisions)
    self:print_segments(segments)
    for _, s in pairs(segments) do
      segment_renderer(self, linex, liney, s)
    end
  end

  -- set canvas back to original
  love.graphics.setCanvas()
end

VolumeRenderer.segments = function(eye_x, eye_y, eye_dx, eye_dy, player, collisions)
  local segments = {}

  if #collisions == 0 then
    return segments
  end

  local prev_top = 1
  local prev_bottom = -1
  local prev_floor_height = collisions[1].floor_height
  local prev_ceiling_height = collisions[1].ceiling_height
  local prev_scale = 1000
  local prev_dist = 0.001
  local prev_dynamic_light = collisions[1].dynamic_light
  local prev_ambient_light = collisions[1].ambient_light

  if prev_floor_height == nil then
    prev_floor_height = -10
  end
  if prev_ceiling_height == nil then
    prev_ceiling_height = 10
  end
  if prev_ambient_light == nil then
    prev_ambient_light = 0
  end
  for i = 1, #collisions do
    local cc = collisions[i]

    if cc.floor_height then
      local dist = (cc.x - eye_x) * eye_dx + (cc.y - eye_y) * eye_dy
      local scale = 1 / dist

      if prev_floor_height < cc.floor_height then
        local height = prev_scale * (cc.floor_height - prev_floor_height)
        local bottom = prev_top
        local top = prev_scale * (player.h + player.z - cc.floor_height)

        table.insert(segments, {
          kind = 'split',
          id = cc.room_id,
          dist = prev_dist,
          scale = prev_scale,
          top = top,
          bottom = bottom,
          height = height,
          ambient_light = prev_ambient_light,
          dynamic_light = prev_dynamic_light,
        })
        prev_top = top
      end

      if prev_ceiling_height > cc.ceiling_height then
        local height = prev_scale * (cc.ceiling_height - prev_ceiling_height)
        local top = prev_bottom
        local bottom = prev_scale * (player.h + player.z - cc.ceiling_height)

        table.insert(segments, {
          kind = 'split',
          id = cc.id,
          dist = prev_dist,
          scale = prev_scale,
          top = top,
          bottom = bottom,
          height = height,
          ambient_light = prev_ambient_light,
          dynamic_light = prev_dynamic_light,
        })
        prev_bottom = bottom
      end


      local floor_top = scale * (player.h + player.z - cc.floor_height)
      if floor_top <= prev_top then
        table.insert(segments, {
          kind = 'floor',
          id = cc.room_id,
          dist = dist,
          prev_dist = prev_dist,
          scale = scale,
          top = floor_top,
          bottom = prev_top,
          ambient_light = cc.ambient_light,
          dynamic_light = cc.dynamic_light,
          prev_dynamic_light = prev_dynamic_light,
        })
        prev_top = floor_top
      end

      local ceiling_bottom = scale * (player.h + player.z - cc.ceiling_height)
      if ceiling_bottom >= prev_bottom then
        table.insert(segments, {
          kind = 'ceiling',
          id = cc.room_id,
          dist = dist,
          prev_dist = prev_dist,
          scale = scale,
          top = prev_bottom,
          bottom = ceiling_bottom,
          ambient_light = cc.ambient_light,
          dynamic_light = cc.dynamic_light,
          prev_dynamic_light = prev_dynamic_light,
        })
        prev_bottom = ceiling_bottom
      end

      if not (cc.is_split or cc.is_spot) then
        table.insert(segments, {
          kind = 'wall',
          id = cc.id,
          dist = dist,
          scale = scale,
          top = prev_top,
          bottom = prev_bottom,
          ambient_light = cc.ambient_light,
          dynamic_light = cc.dynamic_light,
          prev_dynamic_light = prev_dynamic_light,
        })
      end

      prev_floor_height = cc.floor_height
      prev_ceiling_height = cc.ceiling_height
      prev_ambient_light = cc.ambient_light
      prev_dynamic_light = cc.dynamic_light
      prev_scale = scale
      prev_dist = dist
   end
  end
  return segments
end

VolumeRenderer.print_segments = function(segments)
  for _, s in ipairs(segments) do
    print(s.dynamic_light)
    print('${kind} id: ${id} dist: ${dist} scale: ${scale}' % {
      kind = s.kind,
      id = s.id,
      dist = s.dist,
      scale = s.scale,
    })
    print('  top: ${top} bottom: ${bottom}' % {
      top = s.top,
      bottom = s.bottom,
    })
    if s.kind == 'split' then
      print('  height: ${height}' % {
        height = s.height,
      })
    end
    print('  light: ambient ${ambient} dynamic: ${dynamic} prev ${prev}' % {
      ambient = s.ambient_light,
      dynamic = s.dynamic_light,
      prev = s.prev_dynamic_light,
    })
  end
end

function VolumeRenderer:draw(map, player, dt, fullscreen)
  self.time = self.time + dt

  --self.effect:send('time', self.time)
  --love.graphics.setShader(self.effect)

  if self.mode == 'photo' then
    self:draw_segments(map, player, VolumeRenderer.photo_segment_renderer)
  elseif self.mode == 'surface' then
    self:draw_segments(map, player, VolumeRenderer.surface_segment_renderer)
  elseif self.mode == 'light' then
    self:draw_segments(map, player, VolumeRenderer.light_segment_renderer)
  end
  engyne.reset_color()

  love.graphics.setBlendMode('alpha', 'premultiplied')
  if fullscreen then
    local width, height = love.graphics.getDimensions()
    local mult = math.min(height / self.height, width / self.width)
    love.graphics.draw(self.fpv, 0, 0, 0, mult, mult)
  else
    love.graphics.draw(self.fpv, self.x, self.y)
  end
  love.graphics.setBlendMode('alpha')

  love.graphics.setShader()
end


return VolumeRenderer
