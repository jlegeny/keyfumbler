function trigger(id, trigger, game)
  local alias = game.map.aliases[id]

  print('triggered', id)
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

function entered(room_id, from_id, game)
  local alias = game.map.aliases[room_id]
  local alias_str = ''
  if alias then
    alias_str = alias
  end
  print('entered room ' .. room_id .. ' [' .. alias_str .. '] from ' .. from_id)
end

local script = {
  trigger = trigger,
  entered = entered,
}

return script
