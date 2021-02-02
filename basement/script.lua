local util = require 'util'
local Map = require 'map'
local Key = require 'object/key'

local keys = {
  tunnel_key = Key.random(Key.Material.STEEL),
  entrance_key = Key.random(Key.Material.BRASS),
  cellar_key = Key.random(Key.Material.COPPER),
  fake_key_1 = Key.random(),
  fake_key_2 = Key.random(),
}

local wrong_key_ramble = {
  "Ugh! It doesn't fit!",
  "Wrong key.",
  "Hmm, do I have the right key?",
  "Nope.",
  "I would have sworn this was the right one.",
  "Unf.",
  "Maybe it's bent?",
}

local wkridx = 0

local key_not_turn_ramble = {
  "It fits, but doesn't turn. Must be wrong.",
  "If I turn it any more I might break it.",
}

local kntidx = 0

local locks = {
  ['entrance.door'] = {
    key_type = keys.entrance_key.key_type,
    wording = keys.entrance_key.wording,
    biting = keys.entrance_key.biting,
    locked = true,
    inserted_key = nil,
  },
  ['cellar.door'] = {
    key_type = keys.cellar_key.key_type,
    wording = keys.cellar_key.wording,
    biting = keys.cellar_key.biting,
    locked = true,
    inserted_key = nil,
  },
  ['tunnel.door'] = {
    key_type = keys.tunnel_key.key_type,
    wording = keys.tunnel_key.wording,
    biting = keys.tunnel_key.biting,
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
  for _, key in pairs(keys) do
    Key.render(key)
  end


  -- cheats
  -- entrance key
  -- game.player.inventory[622] = keys.entrance_key
  -- locks['entrance.door'].locked = false
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
  elseif id == 'fireplace.1' then
    game.dialogue = {
      id = 'fireplace.2',
      image = nil,
      text = "It's a bit low, but if I [C]rouch I can fit.",
      color = col_myself,
    }
  elseif id == 'fireplace.2' then
     game.dialogue = nil
  elseif id == 'ramble' then
    game.dialogue = nil
  end
end

function near_door(alias, game)
  if locks[alias].inserted_key then
    if locks[alias].locked then
      game.overlay_text = 'Press [E] to turn the key or [Q] to remove it.'
    else
      game.overlay_text = 'Unlocked. Press [Q] to remove the key.'
    end
  elseif locks[alias].locked then
    if game.volatile.key_count > 0 then
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

function trigger_door(alias, game)
  if locks[alias].inserted_key then
    if locks[alias].locked then
      if Key.turns_in(locks[alias]) then
        locks[alias].locked = false
      else
        game.dialogue = {
          id = 'ramble',
          image = nil,
          text = key_not_turn_ramble[kntidx + 1],
          color = col_myself,
        }
        kntidx = (kntidx + 1) % #key_not_turn_ramble
      end
    end
  elseif not locks[alias].locked then
    local door_id = game.map.volatile.raliases[alias]
    toggle_door(door_id, game)
  elseif game.keyring.state == 'open' and game:chosen_key() then
    local ck = game:chosen_key()
    if Key.fits(ck, locks[alias]) then
      locks[alias].inserted_key = game:chosen_key()
    else
      game.dialogue = {
        id = 'ramble',
        image = nil,
        text = wrong_key_ramble[wkridx + 1],
        color = col_myself,
      }
      wkridx = (wkridx + 1) % #wrong_key_ramble
    end
  end
end

function near(id, game)
  local alias = game.map.aliases[id]
  if alias == '_tunnel.key' and not flags['has.tunnel.key'] then
    game.overlay_text = 'Press [E] to pick up the key.'
  elseif alias == '_entrance.key' and not flags['has.entrance.key'] then
    game.overlay_text = 'Press [E] to pick up the key.'
  elseif alias == '_cellar.keys' and not flags['has.cellar.keys'] then
    game.overlay_text = 'Press [E] to pick up the keys off the wall.'
  elseif alias == '_entrance.door' then
    near_door('entrance.door', game)
  elseif alias == '_entrance.fireplace' then
    if not flags['commented.on.fireplace'] then
      game.dialogue = {
        id = 'fireplace.1',
        image = nil,
        text = "There was originally a fireplace here. But we remade it into a playroom for kids.",
        color = col_myself,
      }
      flags['commented.on.fireplace'] = true
    end
  elseif alias == '_cellar.door' then
    near_door('cellar.door', game)
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
  if alias == '_tunnel.key' then
    id, _ = game.map:pick_up('tunnel.key')
    game.player.inventory[id] = keys.tunnel_key
    game:update_inventory()
    flags['has.tunnel.key'] = true
  elseif alias == '_entrance.key' then
    id, _ = game.map:pick_up('entrance.key')
    game.player.inventory[id] = keys.entrance_key
    game:update_inventory()
    flags['has.entrance.key'] = true
  elseif alias == '_cellar.keys' then
    game.player.inventory[Map.get_id(game.map)] = keys.fake_key_1
    game.player.inventory[Map.get_id(game.map)] = keys.cellar_key
    game.player.inventory[Map.get_id(game.map)] = keys.fake_key_2
    game:update_inventory()
    flags['has.cellar.keys'] = true
  elseif alias == '_entrance.door' then
    trigger_door('entrance.door', game)
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
