local line = require 'line'
local lines = require 'lines'

local geom = {}

geom.normalize_line = function(line)
  local ax = math.min(line.ax, line.bx)
  local ay = math.min(line.ay, line.by)
  local bx = math.max(line.ax, line.bx)
  local by = math.max(line.ay, line.by)
  return Line(ax, ay, bx, by)
end

geom.splitpoly = function(poly, line)
  local polya = {}
  local polyb = {}

  line = geom.normalize_line(line)

  for i in 1, #poly do
    local j = (i % #poly) + 1
    local segment = Line(poly[i][0], poly[i][1], poly[j][0], poly[j][1])

    local crosses = lines.segment_crosses_line(segment, line)

    if crosses == 0 then
      local intx, inty = lines.intersection(line, segment)
      local dot = Line.fast_dot(line, poly[i][0], poly[i][1])
      if dot > 0 then
        polya.insert({poly[i][0], poly[i][1]})
        polya.insert({intx, inty})
      else
        polya.insert({intx, inty})
        polyb.insert({poly[i][0], poly[i][1]})
      end
    else
      if crosses == 1 then
        polya.insert({poly[i][0], poly[i][1]})
      elseif crosses == -1 then
        polyb.insert({poly[i][0], poly[i][1]})
      end
    end
  end

  return polya, polyb
end

return geom
