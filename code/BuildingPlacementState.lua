--
-- BuildingPlacementState - state for placing a building on the map
--

BuildingPlacementState = {}
BuildingPlacementState.__index = BuildingPlacementState

function BuildingPlacementState:Create()
    local this = {
        mBuildingToPlace = nil,
        mCanPlace = true,
        mEdgeScrollSpeed = 400,  -- Pixels per second
        mEdgeScrollMargin = 50   -- Distance from edge to trigger scrolling
    }

    setmetatable(this, self)
    return this
end

function BuildingPlacementState:Enter(params)
    -- Create a new building based on the type passed in
    local buildingType = params and params.type or "house"

    self.mBuildingToPlace = Building:Create({
        type = buildingType,
        label = "H",
        color = {0.2, 0.4, 0.8}
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

    -- Get mouse position in world coordinates
    local worldX, worldY = gCamera:getMousePosition()

    -- Update building position to follow mouse (centered on cursor)
    self.mBuildingToPlace:SetPosition(
        worldX - self.mBuildingToPlace.mWidth / 2,
        worldY - self.mBuildingToPlace.mHeight / 2
    )

    -- Check for collisions
    self.mCanPlace = not gTown:CheckCollision(self.mBuildingToPlace)

    -- Handle mouse input
    if gMouseReleased then
        if gMouseReleased.button == 1 then -- Left click
            -- Place building if there's no collision
            if self.mCanPlace then
                -- Create a deep copy of the building to place in the town
                local placedBuilding = Building:Create({
                    type = self.mBuildingToPlace.mType,
                    label = self.mBuildingToPlace.mLabel,
                    color = {self.mBuildingToPlace.mColor[1], self.mBuildingToPlace.mColor[2], self.mBuildingToPlace.mColor[3]},
                    x = self.mBuildingToPlace.mX,
                    y = self.mBuildingToPlace.mY,
                    width = self.mBuildingToPlace.mWidth,
                    height = self.mBuildingToPlace.mHeight
                })
                gTown:AddBuilding(placedBuilding)
                print("Placed building at", placedBuilding.mX, placedBuilding.mY)

                -- Return to TownView state
                gStateMachine:Change("TownView")
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
    end

    gCamera:detach()
end

function BuildingPlacementState:HandleInput()
    -- Input handling if needed
end
