--
-- TownViewState - main state for viewing the town and moving around
--

require("code/TopBar")

TownViewState = {}
TownViewState.__index = TownViewState

function TownViewState:Create()
    local this = {
        mCameraSpeed = 300,
        mBuildingMenu = nil,
        mTopBar = nil
    }

    setmetatable(this, self)
    return this
end

function TownViewState:Enter(params)
    -- Create and push UI elements onto the state stack
    self.mTopBar = TopBar:Create()
    self.mBuildingMenu = BuildingMenu:Create()

    gStateStack:Push(self.mTopBar)
    gStateStack:Push(self.mBuildingMenu)
end

function TownViewState:Exit()
    -- Pop the menu from the state stack
    if gStateStack:Top() == self.mBuildingMenu then
        gStateStack:Pop()
    end
end

function TownViewState:Update(dt)
    -- Update town (river animation, etc.)
    gTown:Update(dt)

    -- Camera movement with WASD
    local dx, dy = 0, 0
    if love.keyboard.isDown('w') then
        dy = dy - self.mCameraSpeed * dt
    end
    if love.keyboard.isDown('s') then
        dy = dy + self.mCameraSpeed * dt
    end
    if love.keyboard.isDown('a') then
        dx = dx - self.mCameraSpeed * dt
    end
    if love.keyboard.isDown('d') then
        dx = dx + self.mCameraSpeed * dt
    end

    if dx ~= 0 or dy ~= 0 then
        gCamera:move(dx, dy)
    end
end

function TownViewState:Render()
    -- Apply camera transformation
    gCamera:attach()

    -- Render the town (buildings in world space)
    gTown:Render()

    -- Render out-of-bounds areas (gray fog)
    gTown:RenderOutOfBounds()

    gCamera:detach()
end

function TownViewState:HandleInput()
    -- Input handling if needed
end
