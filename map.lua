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
  return self
end

function Map:add_wall(wall)
    table.insert(self.walls, wall)
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
      local index = get_index_by_id(self.walls, id)
      table.remove(self.walls, index)
    end
  end
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
  for i, wall in ipairs(self.walls) do
    if is_line_in(wall.line, rect) then
      objects[wall.id] = 'wall'
    end
  end
  return objects
end

return Map
