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

geom.print_poly = function(poly, prefix)
  if prefix == nil then
    prefix = ''
  end
  for i, p in ipairs(poly) do
    print('${prefix}${i} : [${x}, ${y}]' % {
      prefix = prefix,
      i = i, x = p[1], y = p[2]
    })
  end
end

geom.sqd = function(ax, ay, bx, by)
  return (ax - bx) ^ 2 + (ay - by) ^ 2
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
      elseif dot > -lines.CROSS_TOLERANCE and dot < lines.CROSS_TOLERANCE then
        local k = #polya
        if #polya == 0 or 
          (poly[i][1] ~= polya[k][1] or poly[i][2] ~= polya[k][2]) then
          table.insert(polya, {poly[i][1], poly[i][2]})
        end
        local k = #polyb
        if #polyb == 0 or
          (poly[i][1] ~= polyb[k][1] or poly[i][2] ~= polyb[k][2]) then
          table.insert(polyb, {poly[i][1], poly[i][2]})
        end
      end
    else
      if crosses == 1 then
        table.insert(polya, {poly[i][1], poly[i][2]})
      elseif crosses == -1 then
        table.insert(polyb, {poly[i][1], poly[i][2]})
      end
    end
  end

  if #polya > 1 then
    if polya[1][1] == polya[#polya][1] and polya[1][2] == polya[#polya][2] then
      table.remove(polya, #polya)
    end
  end
  if #polyb > 1 then
    if polyb[1][1] == polyb[#polyb][1] and polyb[1][2] == polyb[#polyb][2] then    
      table.remove(polyb, #polyb)
    end
  end


  return polya, polyb
end

geom.dedupe_poly = function(poly, line)
  if #poly == 0 then
    return {}
  end
  local res = {poly[1]}
  for i = 2, #poly do
    if poly[i][1] ~= res[#res][1] or poly[i][2] ~= res[#res][2] then
      table.insert(res, poly[i])
    end
  end
  return res
end

function test()
  local unit_square = { {0, 0}, {1, 0}, {1, 1}, {0, 1} }

  --local left, right = geom.splitpoly(unit_square, Line(0.5, 0, 0.5, 1))
  --local left, right = geom.splitpoly(unit_square, Line(2, -1, -1, 2))
  --local left, right = geom.splitpoly(unit_square, Line(0, 0.5, 0.5, 0))
  --local left, right = geom.splitpoly(unit_square, Line(2, 0, 2, 1))

  --local bugged = { {0, 0}, {1, 0}, {1, 1}, {0, 1} }
  --local left, right = geom.splitpoly(bugged, Line(0, 0, 0, 1))
  --print('left')
  --geom.print_poly(right, '  ')
  --print('right')
  --geom.print_poly(left, '  ')

  local bugged2 = { {1, 0}, {1, 1}, {0, 1}, {0, 0} }
  local left, right = geom.splitpoly(bugged2, Line(0, 1, 0, 0))
  print('left')
  geom.print_poly(right, '  ')
  print('right')
  geom.print_poly(left, '  ')
end

-- test()

return geom
