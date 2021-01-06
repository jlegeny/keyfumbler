local util = require 'util'

local geom = require 'geom'
local Light = require 'light'
local lines = require 'lines'
local Line = require 'line'
local Wall = require 'wall'

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
  self.volatile = {
    bsp = {},
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
  if self.lights == nil then
    self.lights = {}
  end
  if self.volatile == nil then
    self.volatile = {
      bsp = {},
      delegate = nil,
    }
  end
end

function Map:from(other)
  self.next_id = other.next_id
  self.walls = other.walls
  self.rooms = other.rooms
  self.splits = other.splits
end

function Map:add_wall(id, wall)
  self.walls[id] = wall
  self:update_bsp()
end

function Map:add_split(id, split)
  self.splits[id] = split
  self:update_bsp()
end

function Map:object_at(x, y)
  for id, r in pairs(self.rooms) do
    if r.x == x and r.y == y then
      return {
        id = id,
        obj = r,
      }
    end
  end

  return nil
end

function Map:object_by_id(id)
  if self.walls[id] ~= nil then
    return self.walls[id]
  end
  if self.rooms[id] ~= nil then
    return self.rooms[id]
  end
  if self.splits[id] ~= nil then
    return self.splits[id]
  end
  if self.lights[id] ~= nil then
    return self.lights[id]
  end
end

function Map:add_room(id, room)
  self.rooms[id] = room
  self:update_bsp()
end

function Map:add_light(id, light)
  self.lights[id] = light
  self:update_bsp()
end

function Map:remove_objects_set(objects)
  for id, kind in pairs(objects) do
    self:remove_object(id, kind)
  end
end

function Map:remove_object(id, kind)
  local kinds
  if kind == nil then
    kinds = { 'wall', 'room', 'split', 'light' }
  else
    kinds = { kind }
  end

  for _, k in ipairs(kinds) do
    if kind == 'wall' then
      self.walls[id] = nil
    elseif kind == 'room' then
      self.rooms[id] = nil
    elseif kind == 'split' then
      self.splits[id] = nil
    elseif kind == 'light' then
      self.lights[id] = nil
    end
  end

  self:update_bsp()
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
  for id, wall in pairs(self.walls) do
    if is_line_in(wall.line, rect) then
      objects[id] = 'wall'
    end
  end
  for id, split in pairs(self.splits) do
    if is_line_in(split.line, rect) then
      objects[id] = 'split'
    end
  end
  for id, room in pairs(self.rooms) do
    if is_point_in(room.x, room.y, rect) then
      objects[id] = 'room'
    end
  end
  for id, light in pairs(self.lights) do
    if is_point_in(light.x, light.y, rect) then
      objects[id] = 'light'
    end
  end
  return objects
end

function place_line_in_bsp(node, ogid, line, next_id, is_split)
  if node.is_leaf then
    local norm_x, norm_y = Line.norm_vector(line)
    local new_node = {
      id = next_id(),
      parent = node.parent,
      ogid = ogid,
      line = line, 
      norm_x = norm_x,
      norm_y = norm_y,
      is_split = is_split,
    }
    local front = {
      is_leaf = true,
      id = next_id(),
      parent = new_node,
    }
    local back = {
      is_leaf = true,
      id = next_id(),
      parent = new_node,
    }
    new_node.front = front
    new_node.back = back
    return new_node
  else
    local dota = Line.fast_dot(node.line, line.ax, line.ay)
    local dotb = Line.fast_dot(node.line, line.bx, line.by)
    if dota < EPSILON and dotb < EPSILON then
      node.back = place_line_in_bsp(node.back, ogid, line, next_id, is_split)
    elseif dota > -EPSILON and dotb > -EPSILON then
      node.front = place_line_in_bsp(node.front, ogid, line, next_id, is_split)
    else
      local sx, sy = lines.intersection(line, node.line)
      local split1 = Line(line.ax, line.ay, sx, sy)
      local split2 = Line(sx, sy, line.bx, line.by)
      node = place_line_in_bsp(node, ogid, split1, next_id, is_split)
      node = place_line_in_bsp(node, ogid, split2, next_id, is_split)
    end
    return node
  end
end

function place_room_in_bsp(node, ogid, room)
  if node.is_leaf then
    node.room_id = ogid
    node.ceiling_height = room.ceiling_height
    node.floor_height = room.floor_height
    node.ambient_light = room.ambient_light
  else
    local dot = Line.fast_dot(node.line, room.x, room.y)
    if dot < 0 then
      place_room_in_bsp(node.back, ogid, room)
    else
      place_room_in_bsp(node.front, ogid, room)
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
    str = str .. 'leaf ' .. node.id .. ' parent ' .. parent_id .. ' room ' .. room_str
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

function Map:generate_leaf_lookup(node)
  if node.is_leaf then
    self.volatile.leaves[node.id] = node
  else
    self:generate_leaf_lookup(node.front)
    self:generate_leaf_lookup(node.back)
  end
end

function Map:generate_connex_rooms_lookup()
  for id, node in pairs(self.volatile.leaves) do

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
  }

  local sorted_ids = {}
  for k, _ in pairs(self.walls) do
    table.insert(sorted_ids, k)
  end
  table.sort(sorted_ids)

  for i, ogid in ipairs(sorted_ids) do
    local wall = self.walls[ogid]
    self.volatile.bsp = place_line_in_bsp(self.volatile.bsp, ogid, wall.line, next_id, false)
  end

  sorted_ids = {}
  for k, _ in pairs(self.splits) do
    table.insert(sorted_ids, k)
  end
  table.sort(sorted_ids)

  for i, ogid in ipairs(sorted_ids) do
    local split = self.splits[ogid]
    self.volatile.bsp = place_line_in_bsp(self.volatile.bsp, ogid, split.line, next_id, true)
  end

  sorted_ids = {}
  for k, _ in pairs(self.rooms) do
    table.insert(sorted_ids, k)
  end
  table.sort(sorted_ids)

  for i, ogid in ipairs(sorted_ids) do
    local room = self.rooms[ogid]
    place_room_in_bsp(self.volatile.bsp, ogid, room)
  end

  self.volatile.leaves = {}
  self:generate_leaf_lookup(self.volatile.bsp)
  update_polys(self.volatile.bsp, {{0, 0}, {100, 0}, {100, 100}, {0, 100}})
  self.volatile.crooms = {}
  self:generate_connex_rooms_lookup()

  if self.volatile.delegate ~= nil then
    self.volatile.delegate.notify('map_updated')
  end
end

return Map
