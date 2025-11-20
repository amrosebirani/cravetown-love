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

-- Prototype states
require("code/PrototypeLauncher")
require("code/Prototype1State")
require("code/Prototype2State")
require("code/InfoSystemState")

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

    -- Mouse state tracking
    gMousePressed = nil
    gMouseReleased = nil

    -- Global mode: "launcher", "main", "prototype1", "prototype2"
    gMode = "launcher"
    gPrototypeLauncher = PrototypeLauncher:Create()

    -- These will be initialized when a mode is selected
    gTown = nil
    gCamera = nil
    gStateStack = nil
    gStateMachine = nil
    gMusic = nil
    gPrototype1 = nil
    gPrototype2 = nil
    gInfoSystem = nil
end

function InitializeMainGame()
    print("Initializing Main Game...")

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

    gMode = "main"
end

function InitializePrototype1()
    print("Initializing Prototype 1...")
    gPrototype1 = Prototype1State:Create()
    gPrototype1:Enter()
    gMode = "prototype1"
end

function InitializePrototype2()
    print("Initializing Prototype 2...")
    gPrototype2 = Prototype2State:Create()
    gPrototype2:Enter()
    gMode = "prototype2"
end

function InitializeInfoSystem()
    print("Initializing Information System...")
    gInfoSystem = InfoSystemState:Create()
    gInfoSystem:Enter()
    gMode = "infosystem"
end

function ReturnToLauncher()
    print("Returning to launcher...")
    -- Clean up current mode
    gTown = nil
    gCamera = nil
    gStateStack = nil
    gStateMachine = nil
    gMusic = nil
    gPrototype1 = nil
    gPrototype2 = nil
    gInfoSystem = nil
    gMode = "launcher"
end

function love.update(dt)
    -- Hot reload files
    lurker.update()

    if gMode == "launcher" then
        -- Update launcher
        local launched = gPrototypeLauncher:Update(dt)
        if launched then
            local selected = gPrototypeLauncher:GetSelectedPrototype()
            if selected == "main" then
                InitializeMainGame()
            elseif selected == "infosystem" then
                InitializeInfoSystem()
            elseif selected == "prototype1" then
                InitializePrototype1()
            elseif selected == "prototype2" then
                InitializePrototype2()
            end
        end

    elseif gMode == "main" then
        -- Update camera
        if gCamera then
            gCamera:update(dt)
        end

        if gStateMachine then
            gStateMachine:Update(dt)
        end

        if gStateStack then
            gStateStack:Update(dt)
        end

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

    elseif gMode == "prototype1" then
        if gPrototype1 then
            gPrototype1:Update(dt)
        end

    elseif gMode == "prototype2" then
        if gPrototype2 then
            gPrototype2:Update(dt)
        end

    elseif gMode == "infosystem" then
        if gInfoSystem then
            gInfoSystem:Update(dt)
        end
    end

    -- Clear mouse events after processing
    gMousePressed = nil
    gMouseReleased = nil
end

function love.draw()
    if gMode == "launcher" then
        gPrototypeLauncher:Render()

    elseif gMode == "main" then
        if gStateMachine then
            gStateMachine:Render()
        end

        -- Draw debug info
        if gTown then
            love.graphics.setColor(0, 0, 0)
            love.graphics.print("Buildings: " .. gTown:GetBuildingCount(), 10, 10)
            if gCamera then
                love.graphics.print("Camera: " .. math.floor(gCamera.x) .. ", " .. math.floor(gCamera.y), 10, 30)
            end

            -- Debug: show building positions
            local buildings = gTown:GetBuildings()
            for i, b in ipairs(buildings) do
                love.graphics.print(string.format("B%d: %.0f, %.0f", i, b.mX, b.mY), 10, 50 + (i-1)*20)
            end

            love.graphics.setColor(1, 1, 1)
        end

        if gStateStack then
            gStateStack:Render()
        end

    elseif gMode == "prototype1" then
        if gPrototype1 then
            gPrototype1:Render()
        end

    elseif gMode == "prototype2" then
        if gPrototype2 then
            gPrototype2:Render()
        end

    elseif gMode == "infosystem" then
        if gInfoSystem then
            gInfoSystem:Render()
        end
    end
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
    if gMode == "main" then
        -- Handle mouse wheel for scrolling in UI elements
        -- Pass to state stack states (like InventoryDrawer)
        if gStateStack then
            for i = #gStateStack.mStates, 1, -1 do
                local state = gStateStack.mStates[i]
                if state.OnMouseWheel then
                    state:OnMouseWheel(dx, dy)
                    break
                end
            end
        end
    elseif gMode == "prototype2" then
        if gPrototype2 and gPrototype2.OnMouseWheel then
            gPrototype2:OnMouseWheel(dx, dy)
        end
    elseif gMode == "prototype1" then
        if gPrototype1 and gPrototype1.OnMouseWheel then
            gPrototype1:OnMouseWheel(dx, dy)
        end
    elseif gMode == "infosystem" then
        if gInfoSystem and gInfoSystem.OnMouseWheel then
            gInfoSystem:OnMouseWheel(dx, dy)
        end
    end
end

function love.resize(w, h)
    if gMode == "main" then
        -- Update camera dimensions when window is resized
        if gCamera then
            gCamera.w = w
            gCamera.h = h
        end

        -- Recalculate UI layouts for all states in the state stack
        if gStateStack then
            for _, state in ipairs(gStateStack.mStates) do
                if state.RecalculateLayout then
                    state:RecalculateLayout()
                end
            end
        end
    end
end

function love.keypressed(key)
    -- ESC to return to launcher (from prototypes)
    if key == "escape" then
        if gMode == "prototype1" or gMode == "prototype2" or gMode == "infosystem" then
            ReturnToLauncher()
            return
        elseif gMode == "launcher" then
            love.event.quit()
            return
        end
    end

    if gMode == "main" then
        -- forward to focused modal (for name input)
        if gStateStack then
            for i = #gStateStack.mStates, 1, -1 do
                local state = gStateStack.mStates[i]
                if state.keypressed then
                    state:keypressed(key)
                    break
                end
            end
        end
    elseif gMode == "infosystem" then
        if gInfoSystem and gInfoSystem.keypressed then
            gInfoSystem:keypressed(key)
        end
    end

    -- Toggle fullscreen with F11 or Alt+Enter
    if key == "f11" or (key == "return" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"))) then
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
    end
end

function love.textinput(t)
    if gMode == "main" then
        if gStateStack then
            for i = #gStateStack.mStates, 1, -1 do
                local state = gStateStack.mStates[i]
                if state.textinput then
                    state:textinput(t)
                    break
                end
            end
        end
    elseif gMode == "infosystem" then
        if gInfoSystem and gInfoSystem.textinput then
            gInfoSystem:textinput(t)
        end
    end
end