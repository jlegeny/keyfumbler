local Line = require 'line'
local lines = require 'lines'
local util = require 'util'

local geom = {}

geom.normalize_line = function(line)
  if line.ay < line.by then
    return line
  elseif line.ay > line.by then
    return Line(line.bx, line.by, line.ax, line.ay)
  else
    return Line(math.min(line.ax, line.bx), line.ay, math.max(line.ax, line.bx), line.ay)
  end
end

function print_poly(poly)
  for i, p in ipairs(poly) do
    print('${i} : [${x}, ${y}]' % {
      i = i, x = p[1], y = p[2]
    })
  end
end

geom.splitpoly = function(poly, line)
  local polya = {}
  local polyb = {}

  --line = geom.normalize_line(line)

  for i = 1, #poly do
    local j = (i % #poly) + 1
    local segment = Line(poly[i][1], poly[i][2], poly[j][1], poly[j][2])

    local crosses = lines.segment_crosses_line(segment, line)

    if crosses == 0 then
      local intx, inty = lines.intersection(line, segment)
      local dot = Line.fast_dot(line, poly[i][1], poly[i][2])
      if dot > lines.CROSS_TOLERANCE then
        table.insert(polya, {poly[i][1], poly[i][2]})
        table.insert(polya, {intx, inty})
        table.insert(polyb, {intx, inty})
      elseif dot < -lines.CROSS_TOLERANCE then
        table.insert(polya, {intx, inty})
        table.insert(polyb, {poly[i][1], poly[i][2]})
        table.insert(polyb, {intx, inty})
      end
    else
      if crosses == 1 then
        table.insert(polya, {poly[i][1], poly[i][2]})
      elseif crosses == -1 then
        table.insert(polyb, {poly[i][1], poly[i][2]})
      end
    end
  end

  return polya, polyb
end

function test()
  local unit_square = { {0, 0}, {1, 0}, {1, 1}, {0, 1} }

  local left, right = geom.splitpoly(unit_square, Line(0.5, 0, 0.5, 1))
  local left, right = geom.splitpoly(unit_square, Line(2, -1, -1, 2))
  local left, right = geom.splitpoly(unit_square, Line(0, 0.5, 0.5, 0))
  local left, right = geom.splitpoly(unit_square, Line(2, 0, 2, 1))
end

return geom
