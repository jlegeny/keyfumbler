State = {
  IDLE = 0,
  CONFIRM = 1,
  IC_IDLE = 100,
  IC_DRAWING_WALL = 101,
  IC_DRAWING_WALL_NORMAL = 102,
  IC_DRAWING_SELECTION = 103,
  IC_DRAWING_SPLIT = 104,
}

EditorMode = {
  SELECT = 0,
  DRAW = 1,
  PROBE = 2,
}

Draw = {
  WALL = 0,
  SPLIT = 2,
  ROOM = 3,
  LIGHT = 4,
}

Probe = {
  REGION_PARENT_SUBTREE = 0,
  REGION_ANCESTORS = 1,
}

Sidebar = {
  SELECTION = 1,
  DRAW = 2,
  ITEM = 3,
  TOOLS = 4,
  HISTORY = 5,
  INFO = 6,
}

local EditorState = {}
EditorState.__index = EditorState

setmetatable(EditorState, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function EditorState.new()
  local self = {}
  setmetatable(self, EditorState)
  self.state = State.IDLE
  self.mode = EditorMode.SELECT
  self.draw = Draw.WALL
  self.probe = Probe.REGION_ANCESTORS
  self.sidebar = Sidebar.INFO
  self.undo_stack = {}
  self.redo_stack = {}

  self.confirmable = {}
  self.selection = {}
  self.highlight = {}

  self.offset_x = 0
  self.offset_y = 0

  -- intermittent state
  self.wall_line_r = nil
  self.selection_line_r = nil

  return self
end

function EditorState:undo(map)
  if table.getn(self.undo_stack) == 0 then
    return
  end
  local tail = table.remove(self.undo_stack, #self.undo_stack)
  table.insert(e.redo_stack, tail)

  if tail.op == Operation.ADD_WALL then
    map:remove_object(tail.obj.id, 'wall')
  elseif tail.op == Operation.ADD_SPLIT then
    map:remove_object(tail.obj.id, 'split')
  elseif tail.op == Operation.COMPLEX then
    map:from(tail.pre)
  end
end

function EditorState:redo(map)
  if table.getn(self.redo_stack) == 0 then
    return
  end
  local tail = table.remove(self.redo_stack, #self.redo_stack)
  table.insert(e.undo_stack, tail)
  if tail.op == Operation.ADD_WALL then
    map:add_wall(tail.obj.id, tail.obj.wall)
  elseif tail.op == Operation.ADD_SPLIT then
    map:add_split(tail.obj.id, tail.obj.split)
  elseif tail.op == Operation.COMPLEX then
    map:from(tail.post)
  end
end

function EditorState:undoable(op, clean_redo_stack)
  if clean_redo_stack == nil then
    clean_redo_stack = true
  end
  table.insert(self.undo_stack, op)
  if clean_redo_stack then
    for k in pairs(self.redo_stack) do
      self.redo_stack[k] = nil
    end
  end
end

function EditorState:toggle_draw()
  if self.draw == Draw.WALL then
    self.draw = Draw.SPLIT
  elseif self.draw == Draw.SPLIT then
    self.draw = Draw.ROOM
  elseif self.draw == Draw.ROOM then
    self.draw = Draw.WALL
  end
end

function EditorState:toggle_probe()
  if self.probe == Probe.REGION_ANCESTORS then
    self.probe = Probe.REGION_PARENT_SUBTREE
  elseif self.probe == Probe.REGION_PARENT_SUBTREE then
    self.probe = Probe.REGION_ANCESTORS
  end
end

function EditorState:state_str()
  if self.state == State.IDLE then
    return "Idle"
  elseif self.state == State.CONFIRM then
    return "Confirm Action"
  elseif self.state == State.IC then
    return "In Canvas"
  elseif self.state == State.IC_DRAWING_WALL then
    return "Drawing Wall"
  elseif self.state == State.IC_DRAWING_WALL_NORMAL then
    return "Drawing Normal"
  elseif self.state == State.IC_DRAWING_SELECTION then
    return "Drawing Selection"
  elseif self.state == State.IC_DRAWING_SPLIT then
    return "Drawing Split"
  else
    return "Unknown State"
  end
end

function EditorState:draw_str()
  if self.draw == Draw.WALL then
    return 'Wall'
  elseif self.draw == Draw.ROOM then
    return 'Room'
  elseif self.draw == Draw.SPLIT then
    return 'Split'
  elseif self.draw == Draw.LIGHT then
    return 'Light'
  end
end

function EditorState:probe_str()
  if self.probe == Probe.REGION_PARENT_SUBTREE then
    return 'RPS'
  elseif self.probe == Probe.REGION_ANCESTORS then
    return 'RA'
  else
    return 'Unknown Probe'
  end
end

function EditorState:mode_str()
  if self.mode == EditorMode.PROBE then
    return "Probe"
  elseif self.mode == EditorMode.SELECT then
    return "Select"
  elseif self.mode == EditorMode.DRAW then
    return "Draw"
  else
    return "Unknown Mode"
  end
end

return {
  Draw = Draw,
  State = State,
  Probe = Probe,
  EditorState = EditorState,
}
