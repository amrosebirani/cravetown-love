--
-- PerlinNoise - Procedural noise generation for natural resource distribution
-- Implements 2D Perlin noise with octave noise (fBm) and hotspot generation
--

PerlinNoise = {}
PerlinNoise.__index = PerlinNoise

-- Permutation table (will be shuffled based on seed)
local p = {}

-- Gradient vectors for 2D
local grad2 = {
    {1, 0}, {-1, 0}, {0, 1}, {0, -1},
    {1, 1}, {-1, 1}, {1, -1}, {-1, -1}
}

-- Normalize gradient vectors
for i, g in ipairs(grad2) do
    local len = math.sqrt(g[1] * g[1] + g[2] * g[2])
    grad2[i] = {g[1] / len, g[2] / len}
end

--
-- Create a new PerlinNoise generator with a specific seed
--
function PerlinNoise:Create(seed)
    local this = {
        seed = seed or os.time(),
        permutation = {}
    }

    setmetatable(this, self)

    -- Initialize and shuffle permutation table
    this:initPermutation()

    return this
end

--
-- Initialize permutation table with seed-based shuffle
--
function PerlinNoise:initPermutation()
    -- Initialize with values 0-255
    for i = 0, 255 do
        self.permutation[i] = i
    end

    -- Seed the random generator
    math.randomseed(self.seed)

    -- Fisher-Yates shuffle
    for i = 255, 1, -1 do
        local j = math.random(0, i)
        self.permutation[i], self.permutation[j] = self.permutation[j], self.permutation[i]
    end

    -- Duplicate for overflow handling
    for i = 0, 255 do
        self.permutation[i + 256] = self.permutation[i]
    end
end

--
-- Fade function (smoothstep) for interpolation
-- 6t^5 - 15t^4 + 10t^3
--
local function fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

--
-- Linear interpolation
--
local function lerp(a, b, t)
    return a + t * (b - a)
end

--
-- Dot product of gradient and distance vector
--
local function gradDot(hash, x, y)
    local g = grad2[(hash % 8) + 1]
    return g[1] * x + g[2] * y
end

--
-- 2D Perlin noise function
-- Returns value in range [-1, 1]
--
function PerlinNoise:noise2D(x, y)
    -- Find unit grid cell containing point
    local X = math.floor(x) % 256
    local Y = math.floor(y) % 256

    -- Relative x,y in cell
    x = x - math.floor(x)
    y = y - math.floor(y)

    -- Compute fade curves
    local u = fade(x)
    local v = fade(y)

    -- Hash coordinates of the 4 corners
    local A = self.permutation[X] + Y
    local B = self.permutation[X + 1] + Y

    local AA = self.permutation[A % 512]
    local AB = self.permutation[(A + 1) % 512]
    local BA = self.permutation[B % 512]
    local BB = self.permutation[(B + 1) % 512]

    -- Calculate gradients and dot products
    local gradAA = gradDot(AA, x, y)
    local gradBA = gradDot(BA, x - 1, y)
    local gradAB = gradDot(AB, x, y - 1)
    local gradBB = gradDot(BB, x - 1, y - 1)

    -- Interpolate
    local lerpX1 = lerp(gradAA, gradBA, u)
    local lerpX2 = lerp(gradAB, gradBB, u)

    return lerp(lerpX1, lerpX2, v)
end

--
-- Fractional Brownian Motion (octave noise)
-- Combines multiple octaves of Perlin noise for more natural-looking results
-- Returns value normalized to [0, 1]
--
-- @param x, y - Coordinates
-- @param octaves - Number of noise layers (default 4)
-- @param persistence - Amplitude falloff per octave (default 0.5)
-- @param frequency - Starting frequency (default 1.0)
-- @param lacunarity - Frequency multiplier per octave (default 2.0)
--
function PerlinNoise:fbm(x, y, octaves, persistence, frequency, lacunarity)
    octaves = octaves or 4
    persistence = persistence or 0.5
    frequency = frequency or 1.0
    lacunarity = lacunarity or 2.0

    local total = 0
    local amplitude = 1
    local maxValue = 0

    for i = 1, octaves do
        total = total + self:noise2D(x * frequency, y * frequency) * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * lacunarity
    end

    -- Normalize to [0, 1]
    return (total / maxValue + 1) / 2
end

--
-- Generate random hotspots within bounds
--
-- @param countMin, countMax - Range of hotspot count
-- @param bounds - {minX, minY, maxX, maxY}
-- @param radiusMin, radiusMax - Range of hotspot radii
-- @param intensityMin, intensityMax - Range of hotspot intensities
--
function PerlinNoise:generateHotspots(countMin, countMax, bounds, radiusMin, radiusMax, intensityMin, intensityMax)
    local count = math.random(countMin, countMax)
    local hotspots = {}

    for i = 1, count do
        local hotspot = {
            x = math.random(bounds.minX + radiusMax, bounds.maxX - radiusMax),
            y = math.random(bounds.minY + radiusMax, bounds.maxY - radiusMax),
            radius = math.random(radiusMin, radiusMax),
            intensity = intensityMin + math.random() * (intensityMax - intensityMin)
        }
        table.insert(hotspots, hotspot)
    end

    return hotspots
end

--
-- Calculate hotspot value at a point using Gaussian falloff
-- Returns value in [0, 1]
--
-- @param x, y - Coordinates
-- @param hotspots - Array of hotspot definitions
--
function PerlinNoise:hotspotValue(x, y, hotspots)
    local maxValue = 0

    for _, hotspot in ipairs(hotspots) do
        local dx = x - hotspot.x
        local dy = y - hotspot.y
        local distSq = dx * dx + dy * dy
        local radiusSq = hotspot.radius * hotspot.radius

        if distSq < radiusSq then
            -- Gaussian falloff: intensity * exp(-distance^2 / (2 * sigma^2))
            -- Using radius/2 as sigma for smooth falloff
            local sigma = hotspot.radius / 2
            local sigmaSq = sigma * sigma
            local value = hotspot.intensity * math.exp(-distSq / (2 * sigmaSq))
            maxValue = math.max(maxValue, value)
        end
    end

    return maxValue
end

--
-- Combined Perlin + Hotspot value (hybrid distribution)
-- Returns value in [0, 1]
--
-- @param x, y - World coordinates
-- @param hotspots - Array of hotspot definitions
-- @param perlinWeight - Weight for Perlin noise (0-1)
-- @param hotspotWeight - Weight for hotspots (0-1)
-- @param frequency - Perlin frequency
-- @param octaves - Perlin octaves
--
function PerlinNoise:hybridValue(x, y, hotspots, perlinWeight, hotspotWeight, frequency, octaves)
    local perlinValue = self:fbm(x * frequency, y * frequency, octaves, 0.5, 1.0, 2.0)
    local hotspotValue = self:hotspotValue(x, y, hotspots)

    -- Combine values: Perlin provides base coverage, hotspots boost it
    -- Use max-blend to ensure coverage across the whole map
    local baseValue = perlinValue * perlinWeight
    local boostValue = hotspotValue * hotspotWeight

    -- Blend: base + boost, but use max for areas within hotspots for more intensity
    local combined = baseValue + boostValue * (1 + perlinValue * 0.5)

    -- Clamp to [0, 1]
    return math.max(0, math.min(1, combined))
end

--
-- Generate a cluster deposit value at a point
-- Used for discrete resources (ores, oil, etc.)
--
-- @param x, y - Coordinates
-- @param deposits - Array of deposit definitions {x, y, radius, richness}
-- @param falloffExponent - How quickly value falls off from center (default 2)
-- @param noiseVariation - How much noise to add (0-1, default 0.1)
--
function PerlinNoise:clusterValue(x, y, deposits, falloffExponent, noiseVariation)
    falloffExponent = falloffExponent or 2
    noiseVariation = noiseVariation or 0.1

    local maxValue = 0

    for _, deposit in ipairs(deposits) do
        local dx = x - deposit.x
        local dy = y - deposit.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < deposit.radius then
            -- Falloff from center: richness * (1 - (dist/radius)^exponent)
            local normalizedDist = dist / deposit.radius
            local falloff = 1 - math.pow(normalizedDist, falloffExponent)
            local value = deposit.richness * falloff

            -- Add noise variation
            if noiseVariation > 0 then
                local noise = self:noise2D(x * 0.1, y * 0.1)  -- Low frequency noise
                value = value * (1 + noise * noiseVariation)
            end

            maxValue = math.max(maxValue, value)
        end
    end

    return math.max(0, math.min(1, maxValue))
end

--
-- Generate random deposit locations for cluster distribution
--
-- @param countMin, countMax - Range of deposit count
-- @param bounds - {minX, minY, maxX, maxY}
-- @param radiusMin, radiusMax - Range of deposit radii
-- @param richnessMin, richnessMax - Range of center richness values
-- @param collisionRules - Optional collision checking rules
-- @param existingDeposits - Optional existing deposits to avoid
-- @param river - Optional river reference for collision checking
--
function PerlinNoise:generateDeposits(countMin, countMax, bounds, radiusMin, radiusMax,
                                       richnessMin, richnessMax, collisionRules, existingDeposits, river)
    local count = math.random(countMin, countMax)
    local deposits = {}
    collisionRules = collisionRules or {}
    existingDeposits = existingDeposits or {}

    local riverDistance = collisionRules.riverDistance or 100
    local sameTypeDistance = collisionRules.sameTypeDistance or 150
    local boundaryBuffer = collisionRules.boundaryBuffer or 50

    for i = 1, count do
        local attempts = 0
        local maxAttempts = 50
        local deposit = nil

        while attempts < maxAttempts do
            local candidateX = math.random(bounds.minX + boundaryBuffer, bounds.maxX - boundaryBuffer)
            local candidateY = math.random(bounds.minY + boundaryBuffer, bounds.maxY - boundaryBuffer)
            local candidateRadius = math.random(radiusMin, radiusMax)

            local valid = true

            -- Check river collision using actual river geometry
            if river and riverDistance > 0 then
                -- Use River's IsPointNear method if available
                if river.IsPointNear then
                    if river:IsPointNear(candidateX, candidateY, riverDistance) then
                        valid = false
                    end
                else
                    -- Fallback: simple check assuming river near X=0
                    if math.abs(candidateX) < riverDistance then
                        valid = false
                    end
                end
            end

            -- Check collision with existing deposits of same type
            if valid then
                for _, existing in ipairs(deposits) do
                    local dx = candidateX - existing.x
                    local dy = candidateY - existing.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < sameTypeDistance then
                        valid = false
                        break
                    end
                end
            end

            -- Check collision with other resource deposits
            if valid and existingDeposits then
                for _, existing in ipairs(existingDeposits) do
                    local dx = candidateX - existing.x
                    local dy = candidateY - existing.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    local minDist = (candidateRadius + (existing.radius or 50)) * 0.5
                    if dist < minDist then
                        valid = false
                        break
                    end
                end
            end

            if valid then
                deposit = {
                    x = candidateX,
                    y = candidateY,
                    radius = candidateRadius,
                    richness = richnessMin + math.random() * (richnessMax - richnessMin)
                }
                break
            end

            attempts = attempts + 1
        end

        if deposit then
            table.insert(deposits, deposit)
        end
    end

    return deposits
end

--
-- Utility: Apply river influence boost to a value
--
-- @param value - Current value (0-1)
-- @param x, y - Coordinates
-- @param riverRange - Distance from river to apply boost
-- @param boost - Amount to boost (0-1)
-- @param river - Optional river object for accurate distance calculation
--
function PerlinNoise:applyRiverInfluence(value, x, y, riverRange, boost, river)
    local distFromRiver = riverRange + 1  -- Default: outside range

    if river and river.GetDistanceToRiver then
        -- Use efficient distance calculation
        distFromRiver = river:GetDistanceToRiver(x, y)
    else
        -- Fallback: assume river is centered around X=0
        distFromRiver = math.abs(x)
    end

    if distFromRiver < riverRange then
        -- Linear falloff from river
        local influence = 1 - (math.max(0, distFromRiver) / riverRange)
        value = value + boost * influence
    end

    return math.max(0, math.min(1, value))
end

return PerlinNoise
