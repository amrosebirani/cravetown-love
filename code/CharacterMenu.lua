--
-- CharacterMenu - bottom menu showing all 23 characters to assign
--

CharacterMenu = {}
CharacterMenu.__index = CharacterMenu

function CharacterMenu:Create()
    local this = {
        mHeight = 120,
        mPadding = 10,
        mButtonWidth = 60,
        mButtonHeight = 60,
        mButtons = {},
        mScrollOffset = 0,
        mMaxScroll = 0,
        mCharacterPool = {}, -- Reference to Town's character pool
        mWorkplaceFilter = nil -- Filter to show only characters of specific workplace type
    }

    setmetatable(this, self)
    return this
end

function CharacterMenu:SetCharacterPool(characterPool)
    self.mCharacterPool = characterPool
    self:UpdateButtons()
end

function CharacterMenu:SetWorkplaceFilter(workplaceType)
    self.mWorkplaceFilter = workplaceType
    self:UpdateButtons()
end

function CharacterMenu:ClearWorkplaceFilter()
    self.mWorkplaceFilter = nil
    self:UpdateButtons()
end

function CharacterMenu:UpdateButtons()
    -- Clear existing buttons
    self.mButtons = {}
    
    -- Create buttons for filtered characters in the pool
    local x = self.mPadding
    local y = love.graphics.getHeight() - self.mHeight + self.mPadding
    
    for i, character in ipairs(self.mCharacterPool) do
        -- Apply workplace filter if set
        if not self.mWorkplaceFilter or character.mWorkplaceType == self.mWorkplaceFilter then
            -- Skip already placed characters
            if not character:IsPlaced() then
                table.insert(self.mButtons, {
                    character = character,
                    index = i,
                    x = x,
                    y = y,
                    width = self.mButtonWidth,
                    height = self.mButtonHeight
                })
                
                x = x + self.mButtonWidth + self.mPadding
            end
        end
    end
    
    -- Calculate max scroll based on total button width
    local totalWidth = (#self.mButtons) * (self.mButtonWidth + self.mPadding)
    self.mMaxScroll = math.max(0, totalWidth - love.graphics.getWidth() + self.mPadding * 2)
end

function CharacterMenu:Enter()
end

function CharacterMenu:Exit()
end

function CharacterMenu:Update(dt)
    -- Handle mouse wheel scrolling
    if gMouseWheel then
        self.mScrollOffset = self.mScrollOffset - gMouseWheel * 20
        self.mScrollOffset = math.max(0, math.min(self.mScrollOffset, self.mMaxScroll))
    end
    
    -- Check for mouse clicks on character buttons
    if gMouseReleased and gMouseButton == 1 then
        local mx, my = gMouse.x, gMouse.y
        
        for _, button in ipairs(self.mButtons) do
            local adjustedX = button.x - self.mScrollOffset
            local isInButton = mx >= adjustedX and mx <= adjustedX + button.width and
                              my >= button.y and my <= button.y + button.height
            
            if isInButton then
                -- Character clicked - set as selected character
                if gGameView and gGameView.SetSelectedCharacter then
                    gGameView:SetSelectedCharacter(button.character)
                end
                break
            end
        end
    end
end

function CharacterMenu:Render()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Draw menu background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", 0, screenH - self.mHeight, screenW, self.mHeight)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CHARACTERS (Click to Select, Right-Click Building to Assign)", 10, screenH - self.mHeight + 5)
    
    -- Draw character buttons
    for _, button in ipairs(self.mButtons) do
        local character = button.character
        if character then
            local adjustedX = button.x - self.mScrollOffset
            
            -- Skip if off-screen
            if adjustedX + button.width < 0 or adjustedX > screenW then
                goto continue
            end
            
            -- Check if mouse is hovering
            local mx, my = gMouse.x, gMouse.y
            local isHovering = mx >= adjustedX and mx <= adjustedX + button.width and
                              my >= button.y and my <= button.y + button.height
            
            -- Get character color from definition
            local def = GetCharacterDefinition(character.mType)
            local color = def and def.color or {0.5, 0.5, 0.5}
            
            -- Draw character circle (representing the character)
            if isHovering then
                love.graphics.setColor(color[1] * 1.3, color[2] * 1.3, color[3] * 1.3)
            else
                love.graphics.setColor(color[1], color[2], color[3])
            end
            
            local centerX = adjustedX + button.width / 2
            local centerY = button.y + button.height / 2
            love.graphics.circle("fill", centerX, centerY, 20)
            
            -- Draw border (highlight if character is placed)
            if character:IsPlaced() then
                love.graphics.setColor(0, 1, 0) -- Green if placed
                love.graphics.setLineWidth(3)
            else
                love.graphics.setColor(0, 0, 0) -- Black if unplaced
                love.graphics.setLineWidth(1)
            end
            love.graphics.circle("line", centerX, centerY, 20)
            love.graphics.setLineWidth(1)
            
            -- Draw character initials in the circle
            love.graphics.setColor(1, 1, 1)
            local initials = string.sub(character.mName, 1, 1) .. string.sub(character.mRole, 1, 1)
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(initials)
            local textHeight = font:getHeight()
            love.graphics.print(
                initials,
                centerX - textWidth / 2,
                centerY - textHeight / 2
            )
            
            -- Draw character name below circle
            love.graphics.setColor(1, 1, 1)
            local nameWidth = font:getWidth(character.mName)
            local scale = 1
            if nameWidth > button.width - 4 then
                scale = (button.width - 4) / nameWidth
            end
            
            love.graphics.push()
            love.graphics.translate(centerX, button.y + button.height - 5)
            love.graphics.scale(scale, scale)
            love.graphics.print(
                character.mName,
                -nameWidth / 2,
                0
            )
            love.graphics.pop()
            
            ::continue::
        end
    end
    
    love.graphics.setColor(1, 1, 1)
end

function CharacterMenu:HandleInput()
end