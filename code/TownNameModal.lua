--
-- TownNameModal - ask player to choose a town name before starting
--

TownNameModal = {}
TownNameModal.__index = TownNameModal

function TownNameModal:Create()
    local this = {
        mIsTownNameModal = true,
        mModalWidth = 560,
        mModalHeight = 260,
        mInput = "Cravetown",
        mCursorVisible = true,
        mCursorTimer = 0
    }
    setmetatable(this, self)
    return this
end

function TownNameModal:Enter() end
function TownNameModal:Exit() end

function TownNameModal:HandleInput()
    return true
end

function TownNameModal:Update(dt)
    self.mCursorTimer = self.mCursorTimer + dt
    if self.mCursorTimer > 0.5 then
        self.mCursorVisible = not self.mCursorVisible
        self.mCursorTimer = 0
    end

    if gMouseReleased and gMouseReleased.button == 1 then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local modalX = (screenW - self.mModalWidth) / 2
        local modalY = (screenH - self.mModalHeight) / 2

        -- Generate button
        local btnX, btnY, btnW, btnH = modalX + 180, modalY + 170, 200, 40
        local mx, my = gMouseReleased.x, gMouseReleased.y
        if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
            -- Apply town name and close
            if gTown then
                gTown.mName = self.mInput ~= "" and self.mInput or "Cravetown"
            end
            gStateStack:Pop()
            return false
        end
    end
    return true
end

function TownNameModal:textinput(t)
    -- Allow letters, numbers, spaces, dashes
    if string.match(t, "[A-Za-z0-9%- ]") then
        self.mInput = (self.mInput or "") .. t
    end
end

function TownNameModal:keypressed(key)
    if key == "backspace" then
        -- Remove last character (simple approach for ASCII text)
        if #self.mInput > 0 then
            self.mInput = string.sub(self.mInput, 1, -2)
        end
    elseif key == "return" or key == "kpenter" then
        if gTown then
            gTown.mName = self.mInput ~= "" and self.mInput or "Cravetown"
        end
        gStateStack:Pop()
    end
end

function TownNameModal:Render()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Title on top
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Welcome to Cravetown", (screenW - love.graphics.getFont():getWidth("Welcome to Cravetown")) / 2, 30)

    -- Modal panel
    love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", modalX, modalY, self.mModalWidth, self.mModalHeight, 10, 10)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, self.mModalWidth, self.mModalHeight, 10, 10)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Choose town name", modalX + 20, modalY + 20)

    -- Input field
    local inputX, inputY, inputW, inputH = modalX + 20, modalY + 80, self.mModalWidth - 40, 40
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", inputX, inputY, inputW, inputH, 5, 5)
    love.graphics.setColor(1, 1, 1)
    local text = self.mInput or ""
    love.graphics.print(text, inputX + 10, inputY + 10)
    if self.mCursorVisible then
        local w = love.graphics.getFont():getWidth(text)
        love.graphics.print("|", inputX + 10 + w + 2, inputY + 10)
    end

    -- Generate button
    local buttonLabel = "Generate " .. (self.mInput ~= "" and self.mInput or "Cravetown")
    love.graphics.setColor(0.3, 0.6, 0.3)
    love.graphics.rectangle("fill", modalX + 180, modalY + 170, 200, 40, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(buttonLabel, modalX + 190, modalY + 180)
end

return TownNameModal


