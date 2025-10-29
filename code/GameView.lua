--
-- GameView - main game state, ties everything together
--

require("code/Building")

GameView = {}
GameView.__index = GameView

function GameView:Create()
    local this = {
        -- Core Systems
        mTown = Town:Create(),
        mBuildingMenu = BuildingMenu:Create(),
        mCharacterMenu = CharacterMenu:Create(),
        
        -- Camera (start at world origin, screen center shows world 0,0)
        mCameraX = 0,
        mCameraY = 0,
        mCameraSpeed = 300,
        
        -- UI State
        mActiveMenu = "buildings", -- "buildings" or "characters"
        mSelectedBuilding = nil, -- Building type to place
        mSelectedCharacter = nil, -- Character to assign
        mPlacingBuilding = false,
        mAssigningCharacter = false,
        
        -- Mouse state
        mMouseWorldX = 0,
        mMouseWorldY = 0
    }
    
    setmetatable(this, self)
    
    -- Link character pool to character menu
    this.mCharacterMenu:SetCharacterPool(this.mTown.mCharacterPool)
    
    return this
end

function GameView:Enter()
    gGameView = self -- Global reference for menus
end

function GameView:Exit()
    gGameView = nil
end

function GameView:Update(dt)
    -- Camera movement (WASD)
    if love.keyboard.isDown("w") then
        self.mCameraY = self.mCameraY - self.mCameraSpeed * dt
    end
    if love.keyboard.isDown("s") then
        self.mCameraY = self.mCameraY + self.mCameraSpeed * dt
    end
    if love.keyboard.isDown("a") then
        self.mCameraX = self.mCameraX - self.mCameraSpeed * dt
    end
    if love.keyboard.isDown("d") then
        self.mCameraX = self.mCameraX + self.mCameraSpeed * dt
    end
    
    -- Calculate mouse world position
    local screenCenterX = love.graphics.getWidth() / 2
    local screenCenterY = love.graphics.getHeight() / 2
    self.mMouseWorldX = gMouse.x - screenCenterX + self.mCameraX
    self.mMouseWorldY = gMouse.y - screenCenterY + self.mCameraY
    
    -- Switch between menus (Tab key)
    if gKeyPressed == "tab" then
        if self.mActiveMenu == "buildings" then
            self.mActiveMenu = "characters"
            self.mSelectedBuilding = nil
            self.mPlacingBuilding = false
        else
            self.mActiveMenu = "buildings"
            self.mSelectedCharacter = nil
            self.mAssigningCharacter = false
        end
    end
    
    -- Cancel current action (Escape)
    if gKeyPressed == "escape" then
        self.mSelectedBuilding = nil
        self.mSelectedCharacter = nil
        self.mPlacingBuilding = false
        self.mAssigningCharacter = false
        self.mCharacterMenu:ClearWorkplaceFilter()
        self.mActiveMenu = "buildings"
    end
    
    -- Handle building placement (after character is selected)
    if self.mSelectedBuilding and self.mSelectedCharacter and gMouseReleased and gMouseButton == 1 then
        -- Check if click is not on menu
        local menuY = love.graphics.getHeight() - 120
        if gMouse.y < menuY then
            -- Create building object at mouse world position
            local building = Building:Create({
                buildingType = self.mSelectedBuilding,
                x = self.mMouseWorldX,
                y = self.mMouseWorldY
            })
            
            -- Place building in town (don't check collision, just add it)
            self.mTown:AddBuilding(building)
            
            -- Automatically assign the selected character to the building
            if self.mSelectedCharacter then
                self.mTown:AssignCharacterToBuilding(self.mSelectedCharacter, building)
            end
            
            -- Reset selection state
            self.mSelectedBuilding = nil
            self.mSelectedCharacter = nil
            self.mPlacingBuilding = false
            self.mAssigningCharacter = false
            
            -- Clear workplace filter and switch back to building menu
            self.mCharacterMenu:ClearWorkplaceFilter()
            self.mActiveMenu = "buildings"
        end
    end
    
    -- Update active menu
    if self.mActiveMenu == "buildings" then
        self.mBuildingMenu:Update(dt)
    else
        self.mCharacterMenu:Update(dt)
    end
    
    -- Update town
    self.mTown:Update(dt)
end

function GameView:Render()
    -- Apply camera transform (center camera world position on screen)
    love.graphics.push()
    local screenCenterX = love.graphics.getWidth() / 2
    local screenCenterY = love.graphics.getHeight() / 2
    love.graphics.translate(screenCenterX - self.mCameraX, screenCenterY - self.mCameraY)
    
    -- Render town (buildings and placed characters)
    self.mTown:Render()
    
    -- Render ghost building if placing
    if self.mSelectedBuilding then
        local def = GetBuildingDefinition(self.mSelectedBuilding)
        if def then
            love.graphics.setColor(def.color[1], def.color[2], def.color[3], 0.5)
            love.graphics.rectangle("fill", 
                self.mMouseWorldX - def.width / 2, 
                self.mMouseWorldY - def.height / 2, 
                def.width, 
                def.height
            )
            love.graphics.setColor(0, 1, 0, 0.8)
            love.graphics.rectangle("line", 
                self.mMouseWorldX - def.width / 2, 
                self.mMouseWorldY - def.height / 2, 
                def.width, 
                def.height
            )
        end
    end
    
    -- Render ghost character if assigning
    if self.mSelectedCharacter then
        local def = GetCharacterDefinition(self.mSelectedCharacter.mType)
        if def then
            love.graphics.setColor(def.color[1], def.color[2], def.color[3], 0.5)
            love.graphics.circle("fill", self.mMouseWorldX, self.mMouseWorldY, 15)
            love.graphics.setColor(0, 1, 0, 0.8)
            love.graphics.circle("line", self.mMouseWorldX, self.mMouseWorldY, 15)
        end
    end
    
    -- Check if hovering over a mine and highlight it
    local hoverMine = self.mTown:GetMineAtPosition(self.mMouseWorldX, self.mMouseWorldY)
    if hoverMine then
        -- Draw highlight circle
        love.graphics.setColor(1, 1, 0, 0.3)  -- Yellow highlight
        love.graphics.circle("fill", hoverMine.x, hoverMine.y, hoverMine.size + 5)
        love.graphics.setColor(1, 1, 0, 0.6)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", hoverMine.x, hoverMine.y, hoverMine.size + 5)
        love.graphics.setLineWidth(1)
        
        -- Store hover mine for tooltip rendering after pop
        self.mHoverMine = hoverMine
    else
        self.mHoverMine = nil
    end
    
    love.graphics.pop()
    
    -- Render active menu
    if self.mActiveMenu == "buildings" then
        self.mBuildingMenu:Render()
    else
        self.mCharacterMenu:Render()
    end
    
    -- Draw instructions at top
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("WASD: Move Camera | TAB: Switch Menu | ESC: Cancel", 10, 10)
    
    if self.mSelectedBuilding and self.mSelectedCharacter then
        love.graphics.print("Ready to place! LEFT CLICK on world to place building and assign " .. self.mSelectedCharacter.mName, 10, 30)
    elseif self.mSelectedBuilding then
        love.graphics.print("Select a character from the menu below", 10, 30)
    elseif self.mActiveMenu == "buildings" then
        love.graphics.print("Select a building type from the menu below", 10, 30)
    elseif self.mActiveMenu == "characters" then
        love.graphics.print("Select a character from the menu below", 10, 30)
    end
    
    -- Render mine tooltip if hovering over a mine
    if self.mHoverMine then
        local tooltipText = "Mine: " .. self.mHoverMine.oreName
        local tooltipY = 55
        local tooltipPadding = 8
        
        -- Get text dimensions
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(tooltipText)
        local textHeight = font:getHeight()
        
        -- Draw tooltip background
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 10 - tooltipPadding, tooltipY - tooltipPadding, 
            textWidth + tooltipPadding * 2, textHeight + tooltipPadding * 2)
        
        -- Draw tooltip border
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 10 - tooltipPadding, tooltipY - tooltipPadding, 
            textWidth + tooltipPadding * 2, textHeight + tooltipPadding * 2)
        love.graphics.setLineWidth(1)
        
        -- Draw tooltip text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(tooltipText, 10, tooltipY)
    end
    
    love.graphics.setColor(1, 1, 1)
end

-- Called by BuildingMenu when a building button is clicked
function GameView:SetSelectedBuilding(buildingType)
    self.mSelectedBuilding = buildingType
    self.mPlacingBuilding = true
    self.mSelectedCharacter = nil
    self.mAssigningCharacter = false
    
    -- Automatically switch to character menu to select suitable character
    self.mActiveMenu = "characters"
    
    -- Get building workplace type and filter characters
    local def = GetBuildingDefinition(buildingType)
    if def then
        -- Filter character menu to show only suitable characters
        self.mCharacterMenu:SetWorkplaceFilter(def.workplaceType)
        print("Select a " .. def.workplaceType .. " to assign to this building")
    end
end

-- Called by CharacterMenu when a character button is clicked
function GameView:SetSelectedCharacter(character)
    self.mSelectedCharacter = character
    self.mAssigningCharacter = true
    self.mSelectedBuilding = nil
    self.mPlacingBuilding = false
end

-- Helper function to find building at world position
function GameView:FindBuildingAtPosition(worldX, worldY)
    for _, building in ipairs(self.mTown.mBuildings) do
        if building then
            local bx, by = building.mX, building.mY
            local def = GetBuildingDefinition(building.mType)
            if def then
                local halfW = def.width / 2
                local halfH = def.height / 2
                
                if worldX >= bx - halfW and worldX <= bx + halfW and
                   worldY >= by - halfH and worldY <= by + halfH then
                    return building
                end
            end
        end
    end
    return nil
end