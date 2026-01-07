--
-- CharacterMovement.lua
-- Character movement state machine and pathfinding logic
-- CRAVE-7: Movement State Tracking
--

CharacterMovement = {}

-- =============================================================================
-- MOVEMENT STATES
-- =============================================================================

CharacterMovement.States = {
    IDLE = "IDLE",               -- Standing still, no destination
    WALKING = "WALKING",         -- Moving toward target
    WORKING = "WORKING",         -- At workplace, performing job
    RESTING = "RESTING",         -- At home, resting
    CONSUMING = "CONSUMING",     -- Consuming goods
    WANDERING = "WANDERING"      -- Random exploration movement
}

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Initialize movement data for a citizen
function CharacterMovement.InitializeCitizen(citizen)
    -- Position (already set by AlphaWorld, preserve if exists)
    citizen.x = citizen.x or 100
    citizen.y = citizen.y or 100

    -- Target position
    citizen.targetX = citizen.targetX or citizen.x
    citizen.targetY = citizen.targetY or citizen.y

    -- Movement state
    citizen.movementState = citizen.movementState or CharacterMovement.States.IDLE

    -- Movement speed (units per second)
    citizen.speed = citizen.speed or 50

    -- Facing direction (radians, 0 = right, π/2 = down)
    citizen.facing = citizen.facing or 0

    -- Target building (if moving to a building)
    citizen.targetBuilding = citizen.targetBuilding or nil

    -- Arrival threshold (how close counts as "arrived")
    citizen.arrivalThreshold = citizen.arrivalThreshold or 5
end

-- =============================================================================
-- DESTINATION SETTING
-- =============================================================================

-- Set a destination for the citizen to walk to
-- @param citizen - the citizen object
-- @param x - target x coordinate
-- @param y - target y coordinate
-- @param buildingId - optional building ID if destination is a building
function CharacterMovement.SetDestination(citizen, x, y, buildingId)
    if not citizen then return false end

    citizen.targetX = x
    citizen.targetY = y
    citizen.targetBuilding = buildingId

    -- Calculate distance to determine if we should walk
    local dx = x - citizen.x
    local dy = y - citizen.y
    local distance = math.sqrt(dx * dx + dy * dy)

    -- Only transition to WALKING if destination is far enough
    if distance > citizen.arrivalThreshold then
        citizen.movementState = CharacterMovement.States.WALKING

        -- Update facing direction
        citizen.facing = math.atan2(dy, dx)
    else
        -- Already at destination
        citizen.movementState = CharacterMovement.States.IDLE
    end

    return true
end

-- =============================================================================
-- BUILDING ENTRANCE CALCULATION
-- =============================================================================

-- Get the entrance point for a building (where citizens should walk to)
-- @param building - the building object
-- @return x, y - entrance coordinates
function CharacterMovement.GetBuildingEntrancePoint(building)
    if not building then return 0, 0 end

    -- Default building dimensions (can be overridden by building type)
    local width = 60
    local height = 60

    -- Use building type dimensions if available
    if building.type then
        width = building.type.width or width
        height = building.type.height or height
    end

    -- Entrance is at the center-bottom of the building
    local entranceX = building.x + width / 2
    local entranceY = building.y + height

    return entranceX, entranceY
end

-- Set citizen destination to a building's entrance
-- @param citizen - the citizen object
-- @param building - the building to walk to
function CharacterMovement.SetDestinationToBuilding(citizen, building)
    if not citizen or not building then return false end

    local entranceX, entranceY = CharacterMovement.GetBuildingEntrancePoint(building)
    return CharacterMovement.SetDestination(citizen, entranceX, entranceY, building.id)
end

-- =============================================================================
-- MOVEMENT UPDATE
-- =============================================================================

-- Update citizen movement (linear interpolation toward target)
-- @param citizen - the citizen object
-- @param dt - delta time in seconds
-- @param world - optional world object for collision detection
function CharacterMovement.UpdateMovement(citizen, dt, world)
    if not citizen then return end

    -- Only update movement if in WALKING or WANDERING state
    if citizen.movementState ~= CharacterMovement.States.WALKING and
       citizen.movementState ~= CharacterMovement.States.WANDERING then
        return
    end

    -- Calculate direction to target
    local dx = citizen.targetX - citizen.x
    local dy = citizen.targetY - citizen.y
    local distance = math.sqrt(dx * dx + dy * dy)

    -- Check if arrived
    if distance <= citizen.arrivalThreshold then
        CharacterMovement.OnArrival(citizen)
        return
    end

    -- Normalize direction and apply speed
    local moveSpeed = citizen.speed * dt
    local moveX = (dx / distance) * moveSpeed
    local moveY = (dy / distance) * moveSpeed

    -- Calculate new position
    local newX = citizen.x + moveX
    local newY = citizen.y + moveY

    -- Collision detection (if world is provided)
    local blocked = false
    if world then
        blocked = CharacterMovement.CheckCollision(world, newX, newY, citizen)
    end

    -- Update position if not blocked
    if not blocked then
        citizen.x = newX
        citizen.y = newY

        -- Update facing direction
        citizen.facing = math.atan2(dy, dx)
    else
        -- If blocked, try to find alternate path or stop
        CharacterMovement.OnBlocked(citizen, world)
    end
end

-- =============================================================================
-- STATE TRANSITIONS
-- =============================================================================

-- Handle arrival at destination
function CharacterMovement.OnArrival(citizen)
    -- Snap to exact target position
    citizen.x = citizen.targetX
    citizen.y = citizen.targetY

    -- Determine new state based on context
    if citizen.targetBuilding then
        -- Arrived at building - check what type
        if citizen.workplace and citizen.workplace.id == citizen.targetBuilding then
            citizen.movementState = CharacterMovement.States.WORKING
        else
            -- Default to IDLE when arriving at other buildings
            citizen.movementState = CharacterMovement.States.IDLE
        end
        citizen.targetBuilding = nil
    elseif citizen.movementState == CharacterMovement.States.WANDERING then
        -- Finished wandering, go idle
        citizen.movementState = CharacterMovement.States.IDLE
    else
        -- Default to IDLE
        citizen.movementState = CharacterMovement.States.IDLE
    end
end

-- Handle being blocked by obstacles
function CharacterMovement.OnBlocked(citizen, world)
    -- For now, simply stop and go idle
    -- TODO: Implement pathfinding around obstacles
    citizen.movementState = CharacterMovement.States.IDLE
    citizen.targetX = citizen.x
    citizen.targetY = citizen.y
end

-- =============================================================================
-- COLLISION DETECTION
-- =============================================================================

-- Check if a position collides with water, trees, or buildings
-- @param world - the game world object
-- @param x, y - position to check
-- @param citizen - the citizen (for context)
-- @return true if blocked, false if clear
function CharacterMovement.CheckCollision(world, x, y, citizen)
    if not world then return false end

    -- Check water collision (river)
    if world.river then
        local riverX = x - world.worldWidth * 0.5
        local riverY = y - world.worldHeight * 0.5
        if world.river:IsPointNear(riverX, riverY, 20) then
            return true
        end
    end

    -- Check forest collision
    if world.forest then
        if world.forest:CheckRectCollision(x - 10, y - 10, 20, 20) then
            return true
        end
    end

    -- Check mountain collision
    if world.mountains then
        if world.mountains:CheckRectCollision(x - 10, y - 10, 20, 20) then
            return true
        end
    end

    -- Check world boundaries
    if x < 0 or y < 0 or x > world.worldWidth or y > world.worldHeight then
        return true
    end

    return false
end

-- =============================================================================
-- WANDERING BEHAVIOR
-- =============================================================================

-- Initiate random wandering for a citizen
-- @param citizen - the citizen object
-- @param world - the world object (for bounds and collision)
function CharacterMovement.StartWandering(citizen, world)
    if not citizen or not world then return false end

    -- Try to find a valid random destination
    local attempts = 0
    local maxAttempts = 10
    local validTarget = false
    local newX, newY

    while not validTarget and attempts < maxAttempts do
        -- Generate random position within wandering area
        newX = math.random(100, math.min(700, world.worldWidth - 100))
        newY = math.random(100, math.min(500, world.worldHeight - 100))

        -- Check if position is valid
        if not CharacterMovement.CheckCollision(world, newX, newY, citizen) then
            validTarget = true
        end

        attempts = attempts + 1
    end

    if validTarget then
        citizen.movementState = CharacterMovement.States.WANDERING
        citizen.targetX = newX
        citizen.targetY = newY
        citizen.targetBuilding = nil

        -- Update facing
        local dx = newX - citizen.x
        local dy = newY - citizen.y
        citizen.facing = math.atan2(dy, dx)

        return true
    end

    return false
end

-- =============================================================================
-- STATE QUERIES
-- =============================================================================

-- Check if citizen is currently moving
function CharacterMovement.IsMoving(citizen)
    return citizen.movementState == CharacterMovement.States.WALKING or
           citizen.movementState == CharacterMovement.States.WANDERING
end

-- Check if citizen is idle
function CharacterMovement.IsIdle(citizen)
    return citizen.movementState == CharacterMovement.States.IDLE
end

-- Check if citizen is at work
function CharacterMovement.IsWorking(citizen)
    return citizen.movementState == CharacterMovement.States.WORKING
end

-- Get current movement state as string
function CharacterMovement.GetStateName(citizen)
    return citizen.movementState or CharacterMovement.States.IDLE
end

-- =============================================================================
-- DEBUG HELPERS
-- =============================================================================

-- Get debug info about citizen movement
function CharacterMovement.GetDebugInfo(citizen)
    if not citizen then return "No citizen" end

    local dx = citizen.targetX - citizen.x
    local dy = citizen.targetY - citizen.y
    local distanceToTarget = math.sqrt(dx * dx + dy * dy)

    return string.format(
        "State: %s | Pos: (%.0f, %.0f) | Target: (%.0f, %.0f) | Dist: %.1f | Speed: %.0f",
        citizen.movementState or "UNKNOWN",
        citizen.x or 0,
        citizen.y or 0,
        citizen.targetX or 0,
        citizen.targetY or 0,
        distanceToTarget,
        citizen.speed or 0
    )
end

return CharacterMovement
