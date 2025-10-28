-- Hot reloading
local lurker = require("lurker")

require("code/StateMachine")
require("code/StateStack")
require("code/Building")
require("code/Town")
require("code/TownViewState")
require("code/BuildingPlacementState")
require("code/BuildingMenu")

-- Camera library
Camera = require("code/Camera")

function love.load()
    -- Set up window
    love.window.setTitle("CraveTown")
    love.window.setMode(1280, 720, {resizable=false})

    -- Set white background color
    love.graphics.setBackgroundColor(1, 1, 1)

    -- Configure hot reloading
    lurker.postswap = function(f)
        print("Hot reloaded: " .. f)
    end
    lurker.interval = 0.5 -- Check for changes every 0.5 seconds

    -- Initialize global game state
    gTown = Town:Create()

    -- Initialize camera at world origin
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    gCamera = Camera.new(0, 0, screenW, screenH)
    gCamera:setFollowLerp(0.1)  -- Smooth camera following with lag

    gStateStack = StateStack:Create()

    -- Mouse state tracking
    gMousePressed = nil
    gMouseReleased = nil

    -- Create state machine with main game states
    gStateMachine = StateMachine:Create({
        ['TownView'] = function()
            return TownViewState:Create()
        end,
        ['BuildingPlacement'] = function()
            return BuildingPlacementState:Create()
        end
    })

    -- Start in TownView state
    gStateMachine:Change("TownView")
end

function love.update(dt)
    -- Hot reload files
    lurker.update()

    -- Update camera
    gCamera:update(dt)

    gStateMachine:Update(dt)
    gStateStack:Update(dt)

    -- Clear mouse events after processing
    gMousePressed = nil
    gMouseReleased = nil
end

function love.draw()
    gStateMachine:Render()

    -- Draw debug info
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Buildings: " .. gTown:GetBuildingCount(), 10, 10)
    love.graphics.print("Camera: " .. math.floor(gCamera.x) .. ", " .. math.floor(gCamera.y), 10, 30)

    -- Debug: show building positions
    local buildings = gTown:GetBuildings()
    for i, b in ipairs(buildings) do
        love.graphics.print(string.format("B%d: %.0f, %.0f", i, b.mX, b.mY), 10, 50 + (i-1)*20)
    end

    love.graphics.setColor(1, 1, 1)

    gStateStack:Render()
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Store mouse press for state handling
    gMousePressed = {x = x, y = y, button = button}
end

function love.mousereleased(x, y, button, istouch, presses)
    -- Store mouse release for state handling
    gMouseReleased = {x = x, y = y, button = button}
end

function love.wheelmoved(dx, dy)
    -- Handle mouse wheel for scrolling in UI elements
    -- Pass to state stack states (like InventoryDrawer)
    for i = #gStateStack.mStates, 1, -1 do
        local state = gStateStack.mStates[i]
        if state.OnMouseWheel then
            state:OnMouseWheel(dx, dy)
            break
        end
    end
end