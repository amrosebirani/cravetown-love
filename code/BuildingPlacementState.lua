--
-- BuildingPlacementState - state for placing a building on the map
--

require("code/BuildingTypes")

BuildingPlacementState = {}
BuildingPlacementState.__index = BuildingPlacementState

function BuildingPlacementState:Create()
    local this = {
        mBuildingToPlace = nil,
        mCanPlace = true,
        mEdgeScrollSpeed = 400,  -- Pixels per second
        mEdgeScrollMargin = 50,  -- Distance from edge to trigger scrolling
        mSizeAdjustmentSpeed = 5  -- Pixels per scroll tick
    }

    setmetatable(this, self)
    return this
end

function BuildingPlacementState:Enter(params)
    -- Create a new building based on the building type passed in
    local buildingType = (params and params.buildingType) or BuildingTypes.FAMILY_HOME

    self.mBuildingToPlace = Building:Create({
        buildingType = buildingType
    })
end

function BuildingPlacementState:Exit()
    self.mBuildingToPlace = nil

    -- Stop camera following
    gCamera.target_x = nil
    gCamera.target_y = nil
end

function BuildingPlacementState:Update(dt)
    -- Get mouse position in screen coordinates for edge scrolling
    local mouseX, mouseY = love.mouse.getPosition()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Edge scrolling: move camera when mouse is near screen edges
    local dx, dy = 0, 0
    local margin = self.mEdgeScrollMargin

    if mouseX < margin then
        dx = -self.mEdgeScrollSpeed * dt * (1 - mouseX / margin)
    elseif mouseX > screenW - margin then
        dx = self.mEdgeScrollSpeed * dt * ((mouseX - (screenW - margin)) / margin)
    end

    if mouseY < margin then
        dy = -self.mEdgeScrollSpeed * dt * (1 - mouseY / margin)
    elseif mouseY > screenH - margin then
        dy = self.mEdgeScrollSpeed * dt * ((mouseY - (screenH - margin)) / margin)
    end

    if dx ~= 0 or dy ~= 0 then
        gCamera:move(dx, dy)
    end

    -- Handle building size adjustment for variable size buildings
    if self.mBuildingToPlace.mBuildingType.variableSize then
        local sizeChanged = false

        -- Keyboard controls for size adjustment
        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            -- Increase height
            local newHeight = self.mBuildingToPlace.mHeight + self.mSizeAdjustmentSpeed
            if newHeight <= self.mBuildingToPlace.mBuildingType.maxHeight then
                self.mBuildingToPlace.mHeight = newHeight
                sizeChanged = true
            end
        end

        if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            -- Decrease height
            local newHeight = self.mBuildingToPlace.mHeight - self.mSizeAdjustmentSpeed
            if newHeight >= self.mBuildingToPlace.mBuildingType.minHeight then
                self.mBuildingToPlace.mHeight = newHeight
                sizeChanged = true
            end
        end

        if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            -- Increase width
            local newWidth = self.mBuildingToPlace.mWidth + self.mSizeAdjustmentSpeed
            if newWidth <= self.mBuildingToPlace.mBuildingType.maxWidth then
                self.mBuildingToPlace.mWidth = newWidth
                sizeChanged = true
            end
        end

        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            -- Decrease width
            local newWidth = self.mBuildingToPlace.mWidth - self.mSizeAdjustmentSpeed
            if newWidth >= self.mBuildingToPlace.mBuildingType.minWidth then
                self.mBuildingToPlace.mWidth = newWidth
                sizeChanged = true
            end
        end
    end

    -- Get mouse position in world coordinates
    local worldX, worldY = gCamera:getMousePosition()

    -- Update building position to follow mouse (centered on cursor)
    self.mBuildingToPlace:SetPosition(
        worldX - self.mBuildingToPlace.mWidth / 2,
        worldY - self.mBuildingToPlace.mHeight / 2
    )

    -- Check for collisions and boundaries
    local hasCollision = gTown:CheckCollision(self.mBuildingToPlace)
    local isWithinBounds = gTown:IsWithinBoundaries(self.mBuildingToPlace)
    self.mCanPlace = not hasCollision and isWithinBounds

    -- Handle mouse input
    if gMouseReleased then
        if gMouseReleased.button == 1 then -- Left click
            -- Place building if there's no collision
            if self.mCanPlace then
                -- Deduct construction materials from inventory
                local buildingType = self.mBuildingToPlace.mBuildingType
                if buildingType.constructionMaterials then
                    for commodityId, requiredAmount in pairs(buildingType.constructionMaterials) do
                        gTown.mInventory:Remove(commodityId, requiredAmount)
                    end
                end

                -- Create a new instance of the building to place in the town
                local placedBuilding = Building:Create({
                    buildingType = self.mBuildingToPlace.mBuildingType,
                    x = self.mBuildingToPlace.mX,
                    y = self.mBuildingToPlace.mY,
                    width = self.mBuildingToPlace.mWidth,
                    height = self.mBuildingToPlace.mHeight
                })
                gTown:AddBuilding(placedBuilding)
                print("Placed", placedBuilding.mName, "at", placedBuilding.mX, placedBuilding.mY)

                -- If this is a farm, show grain selection modal
                if placedBuilding.mTypeId == "farm" then
                    require("code/GrainSelectionModal")
                    local modal = GrainSelectionModal:Create(placedBuilding)
                    gStateMachine:Change("TownView")
                    gStateStack:Push(modal)
                elseif placedBuilding.mTypeId == "bakery" then
                    require("code/BakerySetupModal")
                    local modal = BakerySetupModal:Create(placedBuilding)
                    gStateMachine:Change("TownView")
                    gStateStack:Push(modal)
                elseif placedBuilding.mTypeId == "mine" then
                    require("code/MineSelectionModal")
                    local modal = MineSelectionModal:Create(placedBuilding)
                    gStateMachine:Change("TownView")
                    gStateStack:Push(modal)
                else
                    -- Return to TownView state
                    gStateMachine:Change("TownView")
                end
            end
        elseif gMouseReleased.button == 2 then -- Right click
            -- Cancel placement and return to TownView state
            gStateMachine:Change("TownView")
        end
    end
end

function BuildingPlacementState:Render()
    -- Apply camera transformation
    gCamera:attach()

    -- Render the town (existing buildings)
    gTown:Render()

    -- Render the building being placed
    if self.mBuildingToPlace then
        self.mBuildingToPlace:Render(self.mCanPlace)

        -- Show size adjustment indicators for variable size buildings
        if self.mBuildingToPlace.mBuildingType.variableSize then
            local building = self.mBuildingToPlace
            local bt = building.mBuildingType

            -- Draw size adjustment guides
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.setLineWidth(1)

            -- Min size box (dashed outline)
            local minX = building.mX + (building.mWidth - bt.minWidth) / 2
            local minY = building.mY + (building.mHeight - bt.minHeight) / 2
            for i = 0, bt.minWidth, 10 do
                love.graphics.line(minX + i, minY, minX + i + 5, minY)
                love.graphics.line(minX + i, minY + bt.minHeight, minX + i + 5, minY + bt.minHeight)
            end
            for i = 0, bt.minHeight, 10 do
                love.graphics.line(minX, minY + i, minX, minY + i + 5)
                love.graphics.line(minX + bt.minWidth, minY + i, minX + bt.minWidth, minY + i + 5)
            end

            -- Max size box (dashed outline)
            local maxX = building.mX - (bt.maxWidth - building.mWidth) / 2
            local maxY = building.mY - (bt.maxHeight - building.mHeight) / 2
            love.graphics.setColor(0.7, 0.7, 1, 0.3)
            for i = 0, bt.maxWidth, 10 do
                love.graphics.line(maxX + i, maxY, maxX + i + 5, maxY)
                love.graphics.line(maxX + i, maxY + bt.maxHeight, maxX + i + 5, maxY + bt.maxHeight)
            end
            for i = 0, bt.maxHeight, 10 do
                love.graphics.line(maxX, maxY + i, maxX, maxY + i + 5)
                love.graphics.line(maxX + bt.maxWidth, maxY + i, maxX + bt.maxWidth, maxY + i + 5)
            end

            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1)
        end
    end

    -- Render out-of-bounds areas (gray fog)
    gTown:RenderOutOfBounds()

    gCamera:detach()

    -- Show UI instructions for variable size buildings
    if self.mBuildingToPlace and self.mBuildingToPlace.mBuildingType.variableSize then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 10, 10, 280, 90)

        love.graphics.setColor(1, 1, 1)
        local font = love.graphics.getFont()
        love.graphics.print("Variable Size Building", 15, 15)
        love.graphics.print(string.format("Size: %d x %d",
            self.mBuildingToPlace.mWidth,
            self.mBuildingToPlace.mHeight), 15, 35)
        love.graphics.print("Arrow Keys/WASD: Adjust size", 15, 55)
        love.graphics.print("Left Click: Place | Right Click: Cancel", 15, 75)
    end

    love.graphics.setColor(1, 1, 1)
end

function BuildingPlacementState:HandleInput()
    -- Input handling if needed
end
