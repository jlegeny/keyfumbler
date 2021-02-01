local util = require 'util'
local Map = require 'map'
local Key = require 'object/key'

local items = {
  entrance_key = Key.random(Key.Material.BRASS),
}

local locks = {
  ['entrance.door'] = {
    key_type = items.entrance_key.key_type,
    wording = items.entrance_key.wording,
    biting = items.entrance_key.biting,
    locked = true,
    inserted_key = nil,
  }
}

local flags = {}

local col_myself = { 'amber', 6 }
local col_partner = { 'copper', 6 }

function init(game)
  game.audio.club:play()
  game.dialogue = {
    id = 'intro.01',
    image = nil,
    text = 'Ahhh! Finally I can rest my ears for a while.',
    color = col_myself,
  }
  game.dialogue = nil
  Key.render(items.entrance_key)


  -- cheats
  -- entrance key
  -- game.player.inventory[622] = items.entrance_key
  locks['entrance.door'].locked = false
  game:update_inventory()
end

function dialogue(id)
  if id == 'intro.01' then
    game.dialogue = {
      id = 'intro.02',
      image = nil,
      text = 'Man, I wish I had a smoke on me.',
      color = col_myself,
    }
  elseif id == 'intro.02' then
    game.dialogue = {
      id = 'intro.03',
      image = nil,
      text = 'Honey, what are you doing down there? Have you found the wine?',
      color = col_partner,
    }
  elseif id == 'intro.03' then
    game.dialogue = {
      id = 'intro.04',
      image = nil,
      text = 'Right... the wine. Now where did I put that cellar key?',
      color = col_myself,
    }
  elseif id == 'intro.04' then
    game.dialogue = nil
  elseif id == 'ramble.keyinlock' then
    game.dialogue = nil
  end
end

function near(id, game)
  local alias = game.map.aliases[id]
  if alias == '_entrance.key' and not flags['has.entrance.key'] then
    game.overlay_text = 'Press [E] to pick up the key.'
  elseif alias == '_entrance.door' then
    if locks['entrance.door'].inserted_key then
      if locks['entrance.door'].locked then
        game.overlay_text = 'Press [E] to turn the key or [Q] to remove it.'
      else
        game.overlay_text = 'Unlocked. Press [Q] to remove the key.'
      end
    elseif locks['entrance.door'].locked then
      if game.player:has(game.map, 'entrance.key') then
        if game.keyring.state == 'closed' then
          game.overlay_text = 'Press [F] to whip out the key.'
        elseif game.keyring.state == 'open' then
          game.overlay_text = 'Press [E] to insert the key.'
        end
      else
        game.overlay_text = 'The door is locked and you have no keys.'
      end
    else
      game.overlay_text = 'Press [E] to open or close the door.'
    end
  end
end

function toggle_door(id, game)
  local door = game.map.splits[id]
  if door.open or (not door.open and door.open_per < 1) then
    door.open = false
    game:run_loop(1, id, true, function (dt)
      door.open_per = door.open_per + 1 * dt
      if door.open_per >= 1 then
        door.open_per = 1
        return true
      end
      return false
    end)
  else
    game:run_loop(1, id, true, function (dt)
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

function trigger(id, trigger, game)
  local alias = game.map.aliases[id]

  print('triggered', id, alias)
  if alias == '_entrance.key' then
    id, _ = game.map:pick_up('entrance.key')
    print('picked up ' .. id)
    game.player.inventory[id] = items.entrance_key
    game:update_inventory()
    flags['has.entrance.key'] = true
  elseif alias == '_entrance.door' then
    if locks['entrance.door'].inserted_key then
      if locks['entrance.door'].locked then
        if Key.turns_in(locks['entrance.door']) then
          locks['entrance.door'].locked = false
        end
      end
    elseif not locks['entrance.door'].locked then
      local door_id = game.map.volatile.raliases['entrance.door']
      toggle_door(door_id, game)
    elseif game.keyring.state == 'open' and game:chosen_key() then
      local ck = game:chosen_key()
      if Key.fits(ck, locks['entrance.door']) then
        locks['entrance.door'].inserted_key = game:chosen_key()
      end
    end
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

function alttrigger(id, trigger, game)
  local alias = game.map.aliases[id]

  print('alt-triggered', id, alias)

  if alias == '_entrance.door' then
    if locks['entrance.door'].inserted_key then
      locks['entrance.door'].inserted_key = nil
    end
  end
 
end

function entered(map_id, room_id, from_id, game)
  local alias = game.map.aliases[room_id]
  local falias = nil
  if from_id then
    falias = game.map.aliases[from_id]
  end
  print('layer ' .. map_id .. ' entered room ' .. util.str(room_id) .. ' [' .. util.str(alias) .. '] from ' .. util.str(from_id) .. ' [' .. util.str(falias) .. ']')

  -- music fadeout
  if map_id == 1 then
    goto entered_entrance
  elseif map_id == 2 then
    goto entered_cellar
  end

  ::entered_entrance::
  if alias == 'down.step.2' and falias == 'down.step.1' then
    game.audio.club:setVolume(0.8)
  elseif alias == 'down.step.3' and falias == 'down.step.2' then
    game.audio.club:setVolume(0.6)
  elseif alias == 'down.step.4' and falias == 'down.step.3' then
    game.audio.club:setVolume(0.4)
  elseif alias == 'down.step.5' and falias == 'down.step.4' then
    game.audio.club:setVolume(0.4)
    game.audio.ambience:setVolume(0.1)
    game.audio.ambience:play()
  elseif alias == 'down.step.6' and falias == 'down.step.5' then
    game.audio.club:setVolume(0.2)
    game.audio.ambience:setVolume(0.3)
  elseif alias == 'down.step.7' and falias == 'down.step.6' then
    game.audio.club:setVolume(0.1)
    game.audio.ambience:setVolume(0.5)
  elseif alias == 'down.step.8' and falias == 'down.step.7' then
    game.audio.ambience:setVolume(1)
    game.audio.club:setVolume(0.05)
  elseif alias == 'down.step.7' and falias == 'down.step.8' then
  elseif alias == 'down.step.6' and falias == 'down.step.7' then
    game.audio.club:setVolume(0.1)
    game.audio.ambience:setVolume(0.5)
  elseif alias == 'down.step.5' and falias == 'down.step.6' then
    game.audio.club:setVolume(0.2)
    game.audio.ambience:setVolume(0.3)
  elseif alias == 'down.step.4' and falias == 'down.step.5' then
    game.audio.club:setVolume(0.4)
    game.audio.ambience:setVolume(0.1)
  elseif alias == 'down.step.3' and falias == 'down.step.4' then
    game.audio.club:setVolume(0.4)
    game.audio.ambience:stop()
  elseif alias == 'down.step.2' and falias == 'down.step.3' then
    game.audio.club:setVolume(0.6)
  elseif alias == 'down.step.1' and falias == 'down.step.2' then
    game.audio.club:setVolume(0.8)
  elseif alias == nil and falias == 'down.step.1' then
    game.audio.club:setVolume(1)
  end


  -- level 01-02 teleport
  if room_id == 530 and from_id == 529 then
    game:set_layer(2)
    game.audio.club:stop()
  end

  ::entered_cellar::
  if room_id == 529 and from_id == 530 then
    game:set_layer(1)
    game.audio.club:play()
  end

end

local script = {
  init = init,
  dialogue = dialogue,
  near = near,
  trigger = trigger,
  alttrigger = alttrigger,
  entered = entered,
}

return script
