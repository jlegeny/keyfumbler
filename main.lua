local main = require 'main_editor'
-- local main = require 'main_game'

function love.load()
  main.load()
end

function love.resize(w, h)
  main.resize(w, h)
end

function love.quit()
  main.quit()
end

function love.keypressed(key, unicode)
  main.keypressed(key, unicode)
end

function love.mousepressed(mx, my, button, istouch)
  main.mousepressed(mx, my, button, istouch)
end

function love.draw()
  main.draw()
end

