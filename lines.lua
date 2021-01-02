local Line = require 'line'

local lines = {}

lines.parallel = function (lhs, rhs)
  local lvx = lhs.bx - lhs.ax
  local lvy = lhs.by - lhs.ay
  local rvx = rhs.bx - rhs.ax
  local rvy = rhs.by - rhs.ay

  return lvx * rvy - rvx * lvy == 0
end

lines.segment_crosses_line = function(segment, line)
  local dota = Line.fast_dot(line, segment.ax, segment.ay)
  local dotb = Line.fast_dot(line, segment.bx, segment.by)
  if dota < 0 and dotb < 0 then
    return -1
  elseif dota > 0 and dotb > 0 then
    return 1
  else
    return 0
  end
end

lines.intersection = function (lhs, rhs)
  local lvx = lhs.bx - lhs.ax
  local lvy = lhs.by - lhs.ay
  local rvx = rhs.bx - rhs.ax
  local rvy = rhs.by - rhs.ay

  local d = lvx * rvy - lvy * rvx
  local a = lhs.ax * lhs.by - lhs.ay * lhs.bx
  local b = rhs.ax * rhs.by - rhs.ay * rhs.bx
  local x = (b * lvx - a * rvx) / d
  local y = (b * lvy - a * rvy) / d

  return x, y
end

lines.swapped = function(line)
  return Line(line.bx, line.by, line.ax, line.ay)
end

lines.__index = lines

return lines
