State = {
  IDLE = 0,
  IC_IDLE = 100,
  IC_DRAWING_WALL = 101,
  IC_DRAWING_WALL_NORMAL = 102,
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
  self.undo_stack = {}
  self.redo_stack = {}

  self.offset_x = 0
  self.offset_y = 0

  -- intermittent state
  self.wall_line_r = nil

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
  end
end

function EditorState:redo(map)
  if table.getn(self.redo_stack) == 0 then
    return
  end
  local tail = table.remove(self.redo_stack, #self.redo_stack)
  table.insert(e.undo_stack, tail)
  if tail.op == Operation.ADD_WALL then
    map:add_wall(tail.obj)
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

function EditorState:state_str()
  local state_str = "Unknown"
  if state == State.IDLE then
    return "Idle"
  elseif state == State.IC then
    return "In Canvas"
  elseif state == State.IC_DRAWING_WALL then
    return "Drawing a Wall"
  elseif state == State.IC_DRAWING_WALL_NORMAL then
    return "Drawing a Wall's Normal"
  end
end

return {
  State = State, 
  EditorState = EditorState,
}
