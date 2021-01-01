function grey(intensity)
  local grey = ((intensity + 1) / 32) ^ 2.2 * 255
  return { grey, grey, grey }
end

function greys()
  local greys = {}
  for i = 0, 31 do
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
    [0] = { 104, 79, 35 },
    [1] = { 104, 79, 35 },
    [2] = { 104, 79, 35 },
    [3] = { 104, 79, 35 },
    [4] = { 104, 79, 35 },
    [5] = { 104, 79, 35 },
    [6] = { 104, 79, 35 },
    [7] = { 104, 79, 35 },
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
}

function make_palette()
  local pal = {}
  for name, colors in pairs(palette) do
    local cpal = {}
    for i, c in pairs(colors) do
      cpal[i] = { c[1] / 255, c[2] / 255, c[3] / 255 }
      print(name, i, c[1], c[2], c[3])
    end
    pal[name] = cpal
  end
  return pal
end

return make_palette()
