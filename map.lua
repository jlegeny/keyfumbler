local Map = {}
Map.__index = Map

setmetatable(Map, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local function get_index_by_id(tab, id)
  local index = nil
  for i, v in ipairs (tab) do
    if (v.id == val) then
      index = i
    end
  end
  return index
end

function Map.new(params)
  local self = {}
  setmetatable(self, Map)
  self.next_id = params.next_id
  self.walls = {}
  return self
end

function Map:add_wall(wall)
    table.insert(self.walls, wall)
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

return Map
