function love.load()
    love.window.setTitle("CraveTown")

    font = love.graphics.newFont(24)
    love.graphics.setFont(font)
end

function love.update(dt)
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Hello, CraveTown!", 0, love.graphics.getHeight() / 2 - 12, love.graphics.getWidth(), "center")
end