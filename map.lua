local util = require 'util'

local geom = require 'geom'
local Light = require 'light'
local lines = require 'lines'
local Line = require 'line'
local Wall = require 'wall'
local raycaster = require 'raycaster'

local EPSILON = 0.001

local Map = {}
Map.__index = Map

setmetatable(Map, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local function get_index_by_id(tab, id)
  for i, v in ipairs (tab) do
    if (v.id == id) then
      return i
    end
  end
end

function Map.new(params)
  if params == nil then
    params = {
      next_id = 1
    }
  end
  local self = {}
  setmetatable(self, Map)
  self.next_id = params.next_id
  self.walls = {}
  self.splits = {}
  self.rooms = {}
  self.lights = {}
  self.things = {}
  self.triggers = {}
  self.aliases = {}
  self.volatile = {
    bsp = {},
    leaves = {},
    raliases = {},
    delegate = nil,
  }
  self:update_bsp()
  return self
end

function Map:set_delegate(delegate)
  self.volatile.delegate = delegate
end

function Map:fix()
  if self.walls == nil then
    self.walls = {}
  end
  for _, w in pairs(self.walls) do
    if w.decals == nil then
      w.decals = {}
    end
  end
  if self.rooms == nil then
    self.rooms = {}
  end
  for _, r in pairs(self.rooms) do
    if r.ambient_light == nil then
      r.ambient_light = 0
    end
  end
  if self.splits == nil then
    self.splits = {}
  end
  for _, s in pairs(self.splits) do
    if s.decals == nil then
      s.decals = {}
    end
    if s.is_door == nil then
      s.is_door = false
      s.open = false
      s.open_per = 0
    end
  end
  if self.lights == nil then
    self.lights = {}
  end
  if self.things == nil then
    self.things = {}
  end
  if self.triggers == nil then
    self.triggers = {}
  end
  if self.aliases == nil then
    self.aliases = {}
  end
  if self.volatile == nil then
    self.volatile = {
      bsp = {},
      leaves = {},
      delegate = nil,
    }
  end
end

function Map:from(other)
  self.next_id = other.next_id
  self.walls = other.walls
  self.rooms = other.rooms
  self.splits = other.splits
  self.lights = other.lights
  self.things = other.things
  self.aliases = other.aliases
  self.triggers = other.triggers
end


function Map:get_object_table(kind)
  if kind == 'wall' then
    return self.walls
  elseif kind == 'split' then
    return self.splits
  elseif kind == 'room' then
    return self.rooms
  elseif kind == 'light' then
    return self.lights
  elseif kind == 'thing' then
    return self.things
  elseif kind == 'trigger' then
    return self.triggers
  end
end

function Map:update_aliases()
  self.volatile.raliases = {}
  for id, alias in pairs(self.aliases) do
    if self.volatile.raliases[alias] then
      io.stderr:write('Alias name [' .. 
      alias .. '] reused for id = ' .. id .. 
      ' and ' .. self.volatile.raliases[alias] .. '\n')
    end
    self.volatile.raliases[alias] = id
  end
end

function Map:add_object(id, obj)
  local table = self:get_object_table(obj.kind)
  table[id] = obj
  self.aliases[id] = nil
  self:update_bsp()
  self:update_aliases()
end

function Map:remove_objects_set(objects)
  for id, kind in pairs(objects) do
    self:remove_object(id, kind)
  end
end

function Map:remove_object(id, kind)
  local kinds
  if kind == nil then
    kinds = { 'wall', 'room', 'split', 'light', 'thing', 'trigger' }
  else
    kinds = { kind }
  end

  for _, k in ipairs(kinds) do
    local ot = self:get_object_table(k)
    ot[id] = nil
  end

  self:update_bsp()
end

function Map:object_at(x, y)
  for _, kind in pairs({'room', 'light', 'thing', 'trigger'}) do
    local ot = self:get_object_table(kind)
    for id, obj in pairs(ot) do
      if obj.x == x and obj.y == y then
        return {
          id = id,
          obj = obj,
        }
      end
    end
  end

  return nil
end

function Map:object_by_id(id)
  kinds = { 'wall', 'room', 'split', 'light', 'thing', 'trigger' }
  for _, k in ipairs(kinds) do
    local ot = self:get_object_table(k)
    if ot[id] ~= nil then
      return ot[id]
    end
  end
end


function Map:get_id()
  local ret = self.next_id
  self.next_id = self.next_id + 1
  return ret
end

function is_point_in(x, y, rect)
  local ax = math.min(rect.ax, rect.bx)
  local ay = math.min(rect.ay, rect.by)
  local bx = math.max(rect.ax, rect.bx)
  local by = math.max(rect.ay, rect.by)
  return x >= ax and x <= bx and y >= ay and y <= by
end

function is_line_in(line, rect)
  return is_point_in(line.ax, line.ay, rect) and is_point_in(line.bx, line.by, rect)
end

function Map:bound_objects_set(rect)
  local objects = {}
  for _, kind in ipairs({'wall', 'split'}) do
    local ot = self:get_object_table(kind)
    for id, obj in pairs(ot) do
      if is_line_in(obj.line, rect) then
        objects[id] = obj.kind
      end
    end
  end
  for _, kind in ipairs({'room', 'light', 'thing', 'trigger'}) do
    local ot = self:get_object_table(kind)
    for id, obj in pairs(ot) do
      if is_point_in(obj.x, obj.y, rect) then
        objects[id] = obj.kind
      end
    end
  end
  return objects
end

function Map:place_line_in_bsp(node, ogid, line, next_id, obj)
  if node.is_leaf then
    local norm_x, norm_y = Line.norm_vector(line)
    local new_node = {
      id = next_id(),
      parent = node.parent,
      ogid = ogid,
      line = line, 
      norm_x = norm_x,
      norm_y = norm_y,
      is_split = obj.kind == 'split',
      up = id,
    }
    local fid = next_id()
    local front = {
      is_leaf = true,
      id = fid,
      parent = new_node,
      up = fid,
    }
    local bid = next_id()
    local back = {
      is_leaf = true,
      id = bid,
      parent = new_node,
      up = bid,
    }
    new_node.front = front
    new_node.back = back
    self.volatile.leaves[fid] = front
    self.volatile.leaves[bid] = back
    self.volatile.leaves[node.id] = nil
    return new_node
  else
    local dota = Line.fast_dot(node.line, line.ax, line.ay)
    local dotb = Line.fast_dot(node.line, line.bx, line.by)
    if dota < EPSILON and dotb < EPSILON then
      node.back = self:place_line_in_bsp(node.back, ogid, line, next_id, obj)
    elseif dota > -EPSILON and dotb > -EPSILON then
      node.front = self:place_line_in_bsp(node.front, ogid, line, next_id, obj)
    else
      local sx, sy = lines.intersection(line, node.line)
      local split1 = Line(line.ax, line.ay, sx, sy)
      local split2 = Line(sx, sy, line.bx, line.by)
      node = self:place_line_in_bsp(node, ogid, split1, next_id, obj)
      node = self:place_line_in_bsp(node, ogid, split2, next_id, obj)
    end
    return node
  end
end

function Map:room_node(node)
  return self.volatile.leaves[self:room_root(node)]
end

function Map:place_room_in_bsp(node, ogid, room)
  if node.is_leaf then
    local room_node = self:room_node(node)
    room_node.room_id = ogid
    room_node.ceiling_height = room.ceiling_height
    room_node.floor_height = room.floor_height
    room_node.ambient_light = room.ambient_light
  else
    local dot = Line.fast_dot(node.line, room.x, room.y)
    if dot < 0 then
      self:place_room_in_bsp(node.back, ogid, room)
    else
      self:place_room_in_bsp(node.front, ogid, room)
    end
  end
end

function Map.print_bsp(node, depth)
  local str = ''
  for i = 1, depth do
    str = str .. '  '
  end
  local parent_id
  if node.parent == nil then
    parent_id = 'nil'
  else
    parent_id = node.parent.id
  end
  if node.is_leaf then
    local room_str = 'nil'
    if node.room_id ~= nil then
      room_str = node.room_id
    end
    local up_str = 'nil'
    if node.up ~= nil then
      up_str = node.up
    end
    str = str .. 'leaf ' .. node.id .. ' parent ' .. parent_id .. ' room ' .. room_str .. ' up ' .. up_str
    print(str)
  else
    if node.is_split then
      str = str .. 'split ' .. node.id .. ' parent ' .. parent_id .. '  w: ' .. node.ogid
    else
      str = str .. 'node ' .. node.id .. ' parent ' .. parent_id .. '  w: ' .. node.ogid
    end
    print(str)
    Map.print_bsp(node.front, depth + 1)
    Map.print_bsp(node.back, depth + 1)
  end
end

function update_polys(node, poly)
  if node.is_leaf then
    node.poly = util.deepcopy(poly)
  else
    local front, back = geom.splitpoly(poly, node.line)
    update_polys(node.front, front)
    update_polys(node.back, back)
  end
end

function chop_chop(polys, line)
  local res = {}
  for _, poly in ipairs(polys) do
    local front, back = geom.splitpoly(poly, line)
    if #front > 2 then
      table.insert(res, front)
    end
    if #back > 2 then
      table.insert(res, back)
    end
  end
  return res
end

function Map:slice_and_dice()
  for id, node in pairs(self.volatile.leaves) do
    node.slices = { node.poly }
    for _, wall in pairs(self.walls) do
      node.slices = chop_chop(node.slices, wall.line)
    end
    for _, split in pairs(self.splits) do
      node.slices = chop_chop(node.slices, split.line)
    end
  end
end

function Map:room_root(node)
  if node.up == node.id then
    return node.id
  end

  local up_node = self.volatile.leaves[node.up]
  if up_node.up == up_node.id then
    return up_node.id
  end

  node.up = up_node.up
  return self:room_root(up_node)
end

function Map:room_union(rnode, lnode)
  rnode.up = lnode.id
end

function Map:annotate_connex_rooms()
  for id, node in pairs(self.volatile.leaves) do
    local root = self:room_root(node)

    for _, poly in ipairs(node.slices) do
      if #poly > 2 then
        for i = 1, #poly do
          local j = (i % #poly) + 1
          local line = Line(poly[i][1], poly[i][2], poly[j][1], poly[j][2])
          local nx, ny = line:norm_vector()
          local midx, midy = line:mid()
          local PROBE_SIZE = 0.1
          local probe = Line(midx + PROBE_SIZE * nx, midy + PROBE_SIZE * ny, midx - PROBE_SIZE * nx, midy - PROBE_SIZE * ny)
          local other = raycaster.get_region_node(self.volatile.bsp, midx - PROBE_SIZE * nx, midy - PROBE_SIZE * ny)
          if id ~= other.id and not raycaster.is_cut_by_any_line(self, probe) then
            self:room_union(node, other)
          end
        end
      end
    end
  end
end

function Map:update_bsp()
  local bsp_id = 0

  function next_id()
    bsp_id = bsp_id + 1
    return bsp_id
  end

  self.volatile.bsp = {
    id = bsp_id,
    is_leaf = true,
    parent = nil,
    up = bsp_id,
  }
  self.volatile.leaves = {}

  local sorted_ids = {}
  for k, _ in pairs(self.walls) do
    table.insert(sorted_ids, k)
  end
  table.sort(sorted_ids)

  for i, ogid in ipairs(sorted_ids) do
    local wall = self.walls[ogid]
    self.volatile.bsp = self:place_line_in_bsp(self.volatile.bsp, ogid, wall.line, next_id, wall)
  end

  sorted_ids = {}
  for k, _ in pairs(self.splits) do
    table.insert(sorted_ids, k)
  end
  table.sort(sorted_ids)

  for i, ogid in ipairs(sorted_ids) do
    local split = self.splits[ogid]
    self.volatile.bsp = self:place_line_in_bsp(self.volatile.bsp, ogid, split.line, next_id, split)
  end

  sorted_ids = {}
  for k, _ in pairs(self.rooms) do
    table.insert(sorted_ids, k)
  end
  table.sort(sorted_ids)

  update_polys(self.volatile.bsp, {{0, 0}, {100, 0}, {100, 100}, {0, 100}})
  self:slice_and_dice()

  self:annotate_connex_rooms()

  for i, ogid in ipairs(sorted_ids) do
    local room = self.rooms[ogid]
    self:place_room_in_bsp(self.volatile.bsp, ogid, room)
  end

  if self.volatile.delegate ~= nil then
    self.volatile.delegate.notify('map_updated')
  end
end

return Map
