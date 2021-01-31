local util = require 'util'
local Map = require 'map'
local Key = require 'object/key'

local data = {
  items = {
    entrance_key = Key.random(Key.Material.BRASS),
  }
}

function init(game)
end

function near(id, game)
  local alias = game.map.aliases[id]
  if alias == '_entrance.key' then
    game.overlay_text = 'Press E to pick up the key.'
  elseif alias == '_entrance.door' then
    if game.player:has(game.map, 'entrance.key') then
      game.overlay_text = 'Press F to whip out the key.'
    else
      game.overlay_text = 'The door is locked and you have no keys.'
    end
  end
end

function trigger(id, trigger, game)
  local alias = game.map.aliases[id]

  print('triggered', id, alias)
  if alias == '_entrance.key' then
    id, _ = game.map:pick_up('entrance.key')
    game.player.inventory[id] = data.items.entrance_key
  end
  if id == 621 then
    local door = game.map.splits[608]
    if door.open or (not door.open and door.open_per < 1) then
      door.open = false
      game:run_loop(1, 608, true, function (dt)
        door.open_per = door.open_per + 1 * dt
        if door.open_per >= 1 then
          door.open_per = 1
          return true
        end
        return false
      end)
    else
      game:run_loop(1, 608, true, function (dt)
        door.open_per = door.open_per - 1 * dt
        if door.open_per <= 0 then
          door.open_per = 0
          door.open = true
          return true
        end
        return false
      end)
    end
  end
end

function entered(map_id, room_id, from_id, game)
  local alias = game.map.aliases[room_id]
  print('layer ' .. map_id .. ' entered room ' .. util.str(room_id) .. ' [' .. util.str(alias) .. '] from ' .. util.str(from_id))

  -- level 01-02 teleport
  if map_id == 1 then
    if room_id == 530 and from_id == 529 then
      game:set_layer(2)
    end
  end

  if map_id == 2 then
    if room_id == 529 and from_id == 530 then
      game:set_layer(1)
    end
  end

end

local script = {
  init = init,
  near = near,
  trigger = trigger,
  entered = entered,
}

return script
