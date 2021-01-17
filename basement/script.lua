function trigger(id, trigger, game)
  print('triggered', id)
  if id == 621 then
    game.map.splits[608].open = not game.map.splits[608].open
  end
end

function entered(room, from, game)
  print('entered room', room)
end

local script = {
  trigger = trigger,
  entered = entered,
}

return script
