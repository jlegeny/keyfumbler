local Line = require 'line'
local Wall = require 'wall'

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
  self.bsp = {}
  self:update_bsp()
  return self
end

function Map:from(other)
  self.next_id = other.next_id
  self.walls = other.walls
end

function Map:add_wall(id, wall)
  self.walls[id] = wall
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
    kinds = { 'wall' }
  else
    kinds = { kind }
  end

  for _, k in ipairs(kinds) do
    if kind == 'wall' then
      self.walls[id] = nil
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
  return x >= rect.ax and x <= rect.bx and y >= rect.ay and y <= rect.by
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
  return objects
end

function interp(s, tab)
  return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end
getmetatable("").__mod = interp

function place_in_bsp(node, ogid, wall, next_id)

  if node.kind == 'leaf' then
    local id = next_id()
    return {
      kind = 'node',
      id = id,
      ogid = ogid,
      wall = Wall(wall.line), 
      front = {
        kind = 'leaf',
        id = next_id(),
      },
      back = {
        kind = 'leaf',
        id = next_id()
      }
    }
  else
    local dota = Line.point_dot(node.wall.line, wall.line.ax, wall.line.ay)
    local dotb = Line.point_dot(node.wall.line, wall.line.ay, wall.line.by)
    if dota < 0 and dotb < 0 then
      print('wall ${ogid} is back of ${nid} (${nogid})' % {ogid = ogid, nid = node.id, nogid = node.ogid})
      node.back = place_in_bsp(node.back, ogid, wall, next_id)
    elseif dota > 0 and dotb > 0 then
      print('wall ${ogid} is front of ${nid} (${nogid})' % {ogid = ogid, nid = node.id, nogid = node.ogid})
      node.front = place_in_bsp(node.front, ogid, wall, next_id)
    else
      print('wall ' .. ogid .. ' needs to be split')
    end
    return node
  end
end

function print_bsp(node, depth)
  local str = ''
  for i = 1, depth do
    str = str .. '  '
  end
  if node.kind == 'node' then
    str = str .. 'node ' .. node.id .. '  w: ' .. node.ogid
    print(str)
    print_bsp(node.front, depth + 1)
    print_bsp(node.back, depth + 1)
  else
    str = str .. 'leaf ' .. node.id
    print(str)
  end
end

function Map:update_bsp()
  local bsp_id = 0

  function next_id()
    bsp_id = bsp_id + 1
    return bsp_id
  end

  self.bsp = {
    id = bsp_id,
    kind = 'leaf',
  }

  for ogid, wall in pairs(self.walls) do
    self.bsp = place_in_bsp(self.bsp, ogid, wall, next_id)
  end
  print('-- BSP --')
  print_bsp(self.bsp, 0)
  print()

end

return Map
