-- CitizenSeparation.lua
-- Separation force calculations to prevent citizen overlap
-- Uses soft-body collision with weighted distance falloff

local CitizenSeparation = {}

-- Configuration
CitizenSeparation.SEPARATION_RADIUS = 25      -- Distance within which separation applies
CitizenSeparation.SEPARATION_FORCE = 80       -- Strength of push-apart force
CitizenSeparation.MIN_DISTANCE = 5            -- Minimum distance before max force applied

-- Calculate separation force for a citizen based on nearby citizens
-- Returns separationX, separationY (force vector)
function CitizenSeparation.Calculate(citizen, nearbyCitizens)
    local sepX, sepY = 0, 0
    local count = 0

    local radius = CitizenSeparation.SEPARATION_RADIUS
    local radiusSq = radius * radius
    local minDist = CitizenSeparation.MIN_DISTANCE

    for _, other in ipairs(nearbyCitizens) do
        -- Skip self
        if other.id ~= citizen.id then
            local dx = citizen.x - other.x
            local dy = citizen.y - other.y
            local distSq = dx * dx + dy * dy

            -- Only apply force if within separation radius
            if distSq < radiusSq and distSq > 0 then
                local dist = math.sqrt(distSq)

                -- Weight by inverse distance (closer = stronger push)
                -- Clamp minimum distance to avoid extreme forces
                local effectiveDist = math.max(dist, minDist)
                local weight = 1.0 - (effectiveDist / radius)

                -- Add to separation vector
                sepX = sepX + (dx / dist) * weight
                sepY = sepY + (dy / dist) * weight
                count = count + 1
            end
        end
    end

    -- Average and scale by force
    if count > 0 then
        local force = CitizenSeparation.SEPARATION_FORCE
        return (sepX / count) * force, (sepY / count) * force
    end

    return 0, 0
end

-- Calculate separation with avoidance (also considers movement direction)
-- This prevents citizens from walking into each other
function CitizenSeparation.CalculateWithAvoidance(citizen, nearbyCitizens, moveX, moveY)
    local sepX, sepY = 0, 0
    local count = 0

    local radius = CitizenSeparation.SEPARATION_RADIUS
    local radiusSq = radius * radius
    local minDist = CitizenSeparation.MIN_DISTANCE
    local lookahead = 40  -- How far ahead to check for avoidance

    for _, other in ipairs(nearbyCitizens) do
        if other.id ~= citizen.id then
            local dx = citizen.x - other.x
            local dy = citizen.y - other.y
            local distSq = dx * dx + dy * dy

            -- Separation force (push apart)
            if distSq < radiusSq and distSq > 0 then
                local dist = math.sqrt(distSq)
                local effectiveDist = math.max(dist, minDist)
                local weight = 1.0 - (effectiveDist / radius)

                sepX = sepX + (dx / dist) * weight
                sepY = sepY + (dy / dist) * weight
                count = count + 1
            end

            -- Avoidance force (steer away from collision course)
            -- Check if we would collide if continuing on current path
            if moveX ~= 0 or moveY ~= 0 then
                local futureX = citizen.x + moveX * lookahead
                local futureY = citizen.y + moveY * lookahead

                local futureDx = futureX - other.x
                local futureDy = futureY - other.y
                local futureDistSq = futureDx * futureDx + futureDy * futureDy

                -- If we'd be closer in the future, add avoidance
                if futureDistSq < radiusSq and futureDistSq < distSq then
                    local futureDist = math.sqrt(futureDistSq)
                    local weight = 0.5 * (1.0 - (futureDist / radius))

                    sepX = sepX + (futureDx / futureDist) * weight
                    sepY = sepY + (futureDy / futureDist) * weight
                    count = count + 1
                end
            end
        end
    end

    if count > 0 then
        local force = CitizenSeparation.SEPARATION_FORCE
        return (sepX / count) * force, (sepY / count) * force
    end

    return 0, 0
end

-- Check if a position would cause collision with nearby citizens
function CitizenSeparation.WouldCollide(x, y, citizenId, nearbyCitizens)
    local collisionRadius = CitizenSeparation.MIN_DISTANCE * 2
    local collisionRadiusSq = collisionRadius * collisionRadius

    for _, other in ipairs(nearbyCitizens) do
        if other.id ~= citizenId then
            local dx = x - other.x
            local dy = y - other.y
            local distSq = dx * dx + dy * dy

            if distSq < collisionRadiusSq then
                return true
            end
        end
    end

    return false
end

-- Get the closest citizen to a position
function CitizenSeparation.GetClosest(x, y, citizenId, nearbyCitizens)
    local closest = nil
    local closestDistSq = math.huge

    for _, other in ipairs(nearbyCitizens) do
        if other.id ~= citizenId then
            local dx = x - other.x
            local dy = y - other.y
            local distSq = dx * dx + dy * dy

            if distSq < closestDistSq then
                closestDistSq = distSq
                closest = other
            end
        end
    end

    return closest, math.sqrt(closestDistSq)
end

-- Debug: Visualize separation forces
function CitizenSeparation.DebugDraw(citizen, nearbyCitizens)
    local sepX, sepY = CitizenSeparation.Calculate(citizen, nearbyCitizens)

    -- Draw separation force vector
    if sepX ~= 0 or sepY ~= 0 then
        love.graphics.setColor(1, 0, 0, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.line(citizen.x, citizen.y, citizen.x + sepX * 0.5, citizen.y + sepY * 0.5)
    end

    -- Draw separation radius
    love.graphics.setColor(1, 1, 0, 0.2)
    love.graphics.circle("line", citizen.x, citizen.y, CitizenSeparation.SEPARATION_RADIUS)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return CitizenSeparation
