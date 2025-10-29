-- Hot reloading
local lurker = require("lurker")

require("code/StateMachine")
require("code/StateStack")
require("code/Building")
require("code/Town")
require("code/TownNameModal")
require("code/TownViewState")
require("code/BuildingPlacementState")
require("code/BuildingMenu")

-- Camera library
Camera = require("code/Camera")

function love.load()
    -- Initialize random seed for randomization
    math.randomseed(os.time())

    -- Set up window
    love.window.setTitle("CraveTown")
    love.window.setMode(1280, 720, {
        resizable = true,
        minwidth = 800,
        minheight = 600
    })

    -- Set white background color
    love.graphics.setBackgroundColor(1, 1, 1)

    -- Configure hot reloading
    lurker.postswap = function(f)
        print("Hot reloaded: " .. f)
    end
    lurker.interval = 0.5 -- Check for changes every 0.5 seconds

    -- Initialize global game state
    gTown = Town:Create({ name = "Cravetown" })

    -- Initialize camera at world origin
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    gCamera = Camera.new(0, 0, screenW, screenH)
    gCamera:setFollowLerp(0.1)  -- Smooth camera following with lag

    -- Set camera bounds to match town boundaries
    local minX, minY, maxX, maxY = gTown:GetBoundaries()
    gCamera:setBounds(minX, minY, maxX - minX, maxY - minY)

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

    -- Background music with fade-in after 2s
    gMusic = {
        source = nil,
        delay = 2.0,
        timer = 0,
        fadingIn = false,
        fadeDuration = 3.0,
        fadeTimer = 0
    }
    local ok, src = pcall(love.audio.newSource, "Fikrimin İnce Gülü.mp3", "stream")
    if ok and src then
        gMusic.source = src
        gMusic.source:setLooping(true)
        gMusic.source:setVolume(0)
    else
        -- Try alternative filename without diacritics if needed
        local ok2, src2 = pcall(love.audio.newSource, "Fikrimin Ince Gulu.mp3", "stream")
        if ok2 and src2 then
            gMusic.source = src2
            gMusic.source:setLooping(true)
            gMusic.source:setVolume(0)
        end
    end

    -- Push town name modal
    local nameModal = TownNameModal:Create()
    gStateStack:Push(nameModal)
end

function love.update(dt)
    -- Hot reload files
    lurker.update()

    -- Update camera
    gCamera:update(dt)

    gStateMachine:Update(dt)
    gStateStack:Update(dt)

    -- Handle background music fade in
    if gMusic and gMusic.source then
        if not gMusic.fadingIn then
            gMusic.timer = gMusic.timer + dt
            if gMusic.timer >= gMusic.delay then
                gMusic.fadingIn = true
                gMusic.fadeTimer = 0
                gMusic.source:play()
            end
        else
            gMusic.fadeTimer = gMusic.fadeTimer + dt
            local t = math.min(1, gMusic.fadeTimer / gMusic.fadeDuration)
            gMusic.source:setVolume(t)
        end
    end

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

function love.resize(w, h)
    -- Update camera dimensions when window is resized
    gCamera.w = w
    gCamera.h = h

    -- Recalculate UI layouts for all states in the state stack
    for _, state in ipairs(gStateStack.mStates) do
        if state.RecalculateLayout then
            state:RecalculateLayout()
        end
    end
end

function love.keypressed(key)
    -- forward to focused modal (for name input)
    for i = #gStateStack.mStates, 1, -1 do
        local state = gStateStack.mStates[i]
        if state.keypressed then
            state:keypressed(key)
            break
        end
    end
    -- Toggle fullscreen with F11 or Alt+Enter
    if key == "f11" or (key == "return" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"))) then
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
    end
end

function love.textinput(t)
    for i = #gStateStack.mStates, 1, -1 do
        local state = gStateStack.mStates[i]
        if state.textinput then
            state:textinput(t)
            break
        end
    end
end