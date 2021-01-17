function grey(intensity)
  local grey = ((intensity + 1) / 64) ^ 2.2 * 255
  return { grey, grey, grey }
end

function greys()
  local greys = {}
  for i = 0, 63 do
    greys[i] = grey(i)
  end
  return greys
end

local palette = {
  grey = greys(),
  copper = {
    [0] = { 3, 1, 1 },
    [1] = { 34, 3, 0 },
    [2] = { 89, 15, 8 },
    [3] = { 128, 42, 22 },
    [4] = { 161, 64, 40 },
    [5] = { 199, 114, 80 },
    [6] = { 239, 190, 158 },
    [7] = { 253, 210, 188 },
  },
  brass = {
    [0] = { 2, 1, 0 },
    [1] = { 8, 5, 1 },
    [2] = { 19, 11, 1 },
    [3] = { 37, 25, 4 },
    [4] = { 75, 46, 10 },
    [5] = { 104, 79, 35 },
    [6] = { 156, 141, 74 },
    [7] = { 204, 175, 109 },
  },
  copperoxyde = {
    [0] = { 20, 90, 52 },
    [1] = { 20, 90, 52 },
    [2] = { 20, 90, 52 },
    [3] = { 20, 90, 52 },
    [4] = { 55, 139, 92 },
    [5] = { 52, 141, 95 },
    [6] = { 77, 154, 107 },
    [7] = { 124, 204, 152 },
  },
  amber = {
    [5] = { 240, 200, 7 },
    [6] = { 250, 215, 8 },
    [7] = { 255, 240, 10 },
  }
}

function make_palette()
  local pal = {}
  for name, colors in pairs(palette) do
    local cpal = {}
    for i, c in pairs(colors) do
      cpal[i] = { c[1] / 255, c[2] / 255, c[3] / 255 }
    end
    pal[name] = cpal
  end
  return pal
end

return make_palette()
