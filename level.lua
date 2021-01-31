local bitser = require 'bitser'
local util = require 'util'
local Map = require 'map'

local Level = {}
Level.__index = Level


setmetatable(Level, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Level.new(name, maps, delegate)
  local self = {}
  setmetatable(self, Level)

  self.name = name
  self.maps = maps
  self.layers = {}
  self.layer_count = 0
  self.delegate = delegate

  self.script = {}

  self:restore()

  return self
end

function Level:set_delegate(delegate)
  self.delegate = delegate
  for _, map in self.layers do
    map:set_delegate(delegate)
  end
end

function Level:restore()
  self.layers = {}
  self.script = {}
  self.layer_count = 0
  self.map = nil

  local leveldir = '/' .. self.name
  if love.filesystem.getInfo(leveldir, 'directory') == nil then
    print('Level does not exist', leveldir)
    os.exit(1)
  end

  local scriptfile = leveldir .. '/' .. 'script.lua'
  if not love.filesystem.getInfo(scriptfile, 'file') then
    print('Level has no script', mapfile)
  end
  local chunk = love.filesystem.load(scriptfile)
  self.script = chunk()
  
  for index, mapname in pairs(self.maps) do
    local mapfile = leveldir .. '/' .. mapname .. '.map'
    if not love.filesystem.getInfo(mapfile, 'file') then
      print('Map does not exist', mapfile)
      --os.exit(1)
    end

    local map_str = love.filesystem.newFileData(mapfile)
    local map = bitser.loadData(map_str:getPointer(), map_str:getSize())
    Map.fix(map)
    setmetatable(map, Map)
    map:set_delegate(self.delegate)
    map:update_bsp()
    map:update_aliases()
    map.volatile.mapname = mapname
    self.layers[index] = map
    self.layer_count = self.layer_count + 1
  end
end

function Level:save(index)
  local leveldir = util.gamedir() .. '/' .. self.name
  local mapfile = leveldir .. '/' .. self.maps[index] .. '.map'
  print('Saving ' .. mapfile)

  local tmp = Map:new()
  tmp:from(self.layers[index])
  local map_str = bitser.dumps(tmp)

  file = io.open(mapfile, "w")
  file:write(map_str)
  file:close()
end


return Level



