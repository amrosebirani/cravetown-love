--
-- WorldZones.lua
-- Simple zone-based world layout to separate natural resources from building areas
--
-- Zone Types:
--   - BUILDING_AREA: Where all buildings can be placed (no natural obstacles)
--   - FOREST: Forest regions with trees
--   - RIVER: River course
--   - MOUNTAIN: Mountain regions
--

local WorldZones = {}
WorldZones.__index = WorldZones

-- Zone type constants
WorldZones.ZONE_BUILDING = "building"
WorldZones.ZONE_FOREST = "forest"
WorldZones.ZONE_RIVER = "river"
WorldZones.ZONE_MOUNTAIN = "mountain"

function WorldZones:Create(worldWidth, worldHeight, locationConfig)
    local zones = setmetatable({}, WorldZones)

    zones.worldWidth = worldWidth
    zones.worldHeight = worldHeight
    zones.locationConfig = locationConfig or {}

    -- Zone definitions
    zones.buildingArea = nil      -- Single rect: {x, y, width, height}
    zones.forestZones = {}        -- Array of rects
    zones.riverZone = nil         -- Single rect for river corridor
    zones.mountainZones = {}      -- Array of rects

    -- Generate zone layout based on location
    zones:GenerateLayout()

    return zones
end

function WorldZones:GenerateLayout()
    local w, h = self.worldWidth, self.worldHeight
    local config = self.locationConfig

    -- Determine river position (if any)
    local riverPosition = config.riverPosition or "east"  -- "east", "west", "center", "none"
    local riverWidth = config.riverWidth or 200

    -- Determine mountain position (if any)
    local mountainPosition = config.mountainPosition or "none"  -- "north", "south", "east", "west", "none"
    local mountainDepth = config.mountainDepth or 300

    -- Determine forest coverage
    local forestCoverage = config.forestCoverage or 0.25  -- 25% of non-building area

    -- Step 1: Place river zone (if enabled)
    if riverPosition ~= "none" then
        self.riverZone = self:CreateRiverZone(riverPosition, riverWidth)
    end

    -- Step 2: Place mountain zone (if enabled)
    if mountainPosition ~= "none" then
        table.insert(self.mountainZones, self:CreateMountainZone(mountainPosition, mountainDepth))
    end

    -- Step 3: Determine building area (avoiding river and mountains)
    self.buildingArea = self:CreateBuildingArea()

    -- Step 4: Place forest zones in remaining space
    self:CreateForestZones(forestCoverage)

    self:LogZones()
end

function WorldZones:CreateRiverZone(position, width)
    local w, h = self.worldWidth, self.worldHeight
    local buffer = 50  -- Buffer from edge

    if position == "east" then
        return {
            x = w - width - buffer,
            y = 0,
            width = width + buffer,
            height = h
        }
    elseif position == "west" then
        return {
            x = 0,
            y = 0,
            width = width + buffer,
            height = h
        }
    elseif position == "center" then
        return {
            x = (w - width) / 2,
            y = 0,
            width = width,
            height = h
        }
    elseif position == "north" then
        return {
            x = 0,
            y = 0,
            width = w,
            height = width + buffer
        }
    elseif position == "south" then
        return {
            x = 0,
            y = h - width - buffer,
            width = w,
            height = width + buffer
        }
    end

    return nil
end

function WorldZones:CreateMountainZone(position, depth)
    local w, h = self.worldWidth, self.worldHeight

    if position == "north" then
        return {
            x = 0,
            y = 0,
            width = w,
            height = depth
        }
    elseif position == "south" then
        return {
            x = 0,
            y = h - depth,
            width = w,
            height = depth
        }
    elseif position == "east" then
        -- Avoid overlap with river if on same side
        local startX = w - depth
        if self.riverZone and self.riverZone.x < w * 0.7 then
            -- River is not on east, safe to place mountains
        else
            startX = w - depth - (self.riverZone and self.riverZone.width or 0) - 50
        end
        return {
            x = math.max(0, startX),
            y = 0,
            width = depth,
            height = h
        }
    elseif position == "west" then
        local startX = 0
        if self.riverZone and self.riverZone.x > w * 0.3 then
            -- River is not on west, safe to place mountains at edge
        else
            startX = (self.riverZone and self.riverZone.width or 0) + 50
        end
        return {
            x = startX,
            y = 0,
            width = depth,
            height = h
        }
    end

    return nil
end

function WorldZones:CreateBuildingArea()
    local w, h = self.worldWidth, self.worldHeight
    local padding = 100  -- Padding from world edges and obstacles

    -- Start with full world
    local minX, minY = padding, padding
    local maxX, maxY = w - padding, h - padding

    -- Shrink away from river
    if self.riverZone then
        local rz = self.riverZone
        if rz.x < w / 2 then
            -- River on left/west
            minX = math.max(minX, rz.x + rz.width + padding)
        else
            -- River on right/east
            maxX = math.min(maxX, rz.x - padding)
        end

        -- Handle horizontal rivers
        if rz.width > rz.height then
            if rz.y < h / 2 then
                minY = math.max(minY, rz.y + rz.height + padding)
            else
                maxY = math.min(maxY, rz.y - padding)
            end
        end
    end

    -- Shrink away from mountains
    for _, mz in ipairs(self.mountainZones) do
        if mz.width > mz.height then
            -- Horizontal mountain range
            if mz.y < h / 2 then
                minY = math.max(minY, mz.y + mz.height + padding)
            else
                maxY = math.min(maxY, mz.y - padding)
            end
        else
            -- Vertical mountain range
            if mz.x < w / 2 then
                minX = math.max(minX, mz.x + mz.width + padding)
            else
                maxX = math.min(maxX, mz.x - padding)
            end
        end
    end

    -- Ensure minimum building area size
    local minBuildingSize = 800
    if maxX - minX < minBuildingSize then
        local center = (minX + maxX) / 2
        minX = center - minBuildingSize / 2
        maxX = center + minBuildingSize / 2
    end
    if maxY - minY < minBuildingSize then
        local center = (minY + maxY) / 2
        minY = center - minBuildingSize / 2
        maxY = center + minBuildingSize / 2
    end

    return {
        x = minX,
        y = minY,
        width = maxX - minX,
        height = maxY - minY
    }
end

function WorldZones:CreateForestZones(coverage)
    local w, h = self.worldWidth, self.worldHeight
    local ba = self.buildingArea

    -- Calculate how much area should be forest
    local totalArea = w * h
    local buildingAreaSize = ba.width * ba.height
    local riverArea = self.riverZone and (self.riverZone.width * self.riverZone.height) or 0
    local mountainArea = 0
    for _, mz in ipairs(self.mountainZones) do
        mountainArea = mountainArea + mz.width * mz.height
    end

    local availableArea = totalArea - buildingAreaSize - riverArea - mountainArea
    local targetForestArea = availableArea * coverage

    -- Create forest regions in corners/edges away from building area
    local forestLocations = self:FindForestLocations()

    local currentForestArea = 0
    for _, loc in ipairs(forestLocations) do
        if currentForestArea >= targetForestArea then break end

        -- Create forest zone at this location
        local forestZone = self:CreateForestZoneAt(loc)
        if forestZone and forestZone.width > 100 and forestZone.height > 100 then
            table.insert(self.forestZones, forestZone)
            currentForestArea = currentForestArea + forestZone.width * forestZone.height
        end
    end
end

function WorldZones:FindForestLocations()
    -- Return potential forest locations as corner/edge identifiers
    -- Prioritize corners away from building area
    local ba = self.buildingArea
    local w, h = self.worldWidth, self.worldHeight
    local locations = {}

    -- Check each corner
    local corners = {
        {id = "nw", x = 0, y = 0},
        {id = "ne", x = w, y = 0},
        {id = "sw", x = 0, y = h},
        {id = "se", x = w, y = h}
    }

    -- Sort by distance from building area center
    local baCenter = {x = ba.x + ba.width/2, y = ba.y + ba.height/2}
    table.sort(corners, function(a, b)
        local distA = math.sqrt((a.x - baCenter.x)^2 + (a.y - baCenter.y)^2)
        local distB = math.sqrt((b.x - baCenter.x)^2 + (b.y - baCenter.y)^2)
        return distA > distB  -- Farthest first
    end)

    for _, corner in ipairs(corners) do
        table.insert(locations, corner.id)
    end

    return locations
end

function WorldZones:CreateForestZoneAt(locationId)
    local w, h = self.worldWidth, self.worldHeight
    local ba = self.buildingArea
    local padding = 50

    local zone = nil

    if locationId == "nw" then
        -- Northwest corner - from (0,0) to building area
        zone = {
            x = padding,
            y = padding,
            width = math.max(100, ba.x - padding * 2),
            height = math.max(100, ba.y + ba.height/2 - padding)
        }
    elseif locationId == "ne" then
        -- Northeast corner
        local startX = ba.x + ba.width + padding
        zone = {
            x = startX,
            y = padding,
            width = math.max(100, w - startX - padding),
            height = math.max(100, ba.y + ba.height/2 - padding)
        }
    elseif locationId == "sw" then
        -- Southwest corner
        zone = {
            x = padding,
            y = ba.y + ba.height/2 + padding,
            width = math.max(100, ba.x - padding * 2),
            height = math.max(100, h - ba.y - ba.height/2 - padding * 2)
        }
    elseif locationId == "se" then
        -- Southeast corner
        local startX = ba.x + ba.width + padding
        local startY = ba.y + ba.height/2 + padding
        zone = {
            x = startX,
            y = startY,
            width = math.max(100, w - startX - padding),
            height = math.max(100, h - startY - padding)
        }
    end

    -- Ensure zone doesn't overlap with river or mountains
    if zone then
        zone = self:ClipZoneToAvoidObstacles(zone)
    end

    return zone
end

function WorldZones:ClipZoneToAvoidObstacles(zone)
    if not zone then return nil end

    -- Clip against river
    if self.riverZone then
        zone = self:ClipRect(zone, self.riverZone)
    end

    -- Clip against mountains
    for _, mz in ipairs(self.mountainZones) do
        zone = self:ClipRect(zone, mz)
        if not zone then break end
    end

    return zone
end

function WorldZones:ClipRect(rect, obstacle)
    if not rect then return nil end

    -- Check if they overlap
    if rect.x + rect.width <= obstacle.x or
       rect.x >= obstacle.x + obstacle.width or
       rect.y + rect.height <= obstacle.y or
       rect.y >= obstacle.y + obstacle.height then
        return rect  -- No overlap
    end

    -- They overlap - shrink rect to avoid obstacle
    -- Simple approach: shrink from the side with most overlap
    local overlapLeft = math.max(0, obstacle.x + obstacle.width - rect.x)
    local overlapRight = math.max(0, rect.x + rect.width - obstacle.x)
    local overlapTop = math.max(0, obstacle.y + obstacle.height - rect.y)
    local overlapBottom = math.max(0, rect.y + rect.height - obstacle.y)

    local minOverlap = math.min(overlapLeft, overlapRight, overlapTop, overlapBottom)

    if minOverlap == overlapLeft then
        rect.x = obstacle.x + obstacle.width
        rect.width = rect.width - overlapLeft
    elseif minOverlap == overlapRight then
        rect.width = obstacle.x - rect.x
    elseif minOverlap == overlapTop then
        rect.y = obstacle.y + obstacle.height
        rect.height = rect.height - overlapTop
    else
        rect.height = obstacle.y - rect.y
    end

    if rect.width <= 0 or rect.height <= 0 then
        return nil
    end

    return rect
end

function WorldZones:LogZones()
    print("[WorldZones] Generated zone layout:")
    print(string.format("  World size: %dx%d", self.worldWidth, self.worldHeight))

    if self.buildingArea then
        local ba = self.buildingArea
        print(string.format("  Building area: (%d,%d) %dx%d", ba.x, ba.y, ba.width, ba.height))
    end

    if self.riverZone then
        local rz = self.riverZone
        print(string.format("  River zone: (%d,%d) %dx%d", rz.x, rz.y, rz.width, rz.height))
    end

    for i, mz in ipairs(self.mountainZones) do
        print(string.format("  Mountain zone %d: (%d,%d) %dx%d", i, mz.x, mz.y, mz.width, mz.height))
    end

    for i, fz in ipairs(self.forestZones) do
        print(string.format("  Forest zone %d: (%d,%d) %dx%d", i, fz.x, fz.y, fz.width, fz.height))
    end
end

-- Query methods

function WorldZones:IsInBuildingArea(x, y, width, height)
    width = width or 0
    height = height or 0

    local ba = self.buildingArea
    if not ba then return true end  -- No building area defined, allow anywhere

    return x >= ba.x and
           y >= ba.y and
           x + width <= ba.x + ba.width and
           y + height <= ba.y + ba.height
end

function WorldZones:GetBuildingArea()
    return self.buildingArea
end

function WorldZones:GetForestZones()
    return self.forestZones
end

function WorldZones:GetRiverZone()
    return self.riverZone
end

function WorldZones:GetMountainZones()
    return self.mountainZones
end

function WorldZones:GetRandomPositionInBuildingArea(width, height)
    local ba = self.buildingArea
    if not ba then return nil, nil end

    width = width or 60
    height = height or 60

    local maxX = ba.x + ba.width - width
    local maxY = ba.y + ba.height - height

    if maxX <= ba.x or maxY <= ba.y then
        return ba.x, ba.y  -- Building area too small
    end

    local x = math.random(ba.x, maxX)
    local y = math.random(ba.y, maxY)

    return x, y
end

-- Get zone type at a specific point
function WorldZones:GetZoneAt(x, y)
    -- Check river first (highest priority)
    if self.riverZone and self:PointInRect(x, y, self.riverZone) then
        return WorldZones.ZONE_RIVER
    end

    -- Check mountains
    for _, mz in ipairs(self.mountainZones) do
        if self:PointInRect(x, y, mz) then
            return WorldZones.ZONE_MOUNTAIN
        end
    end

    -- Check forests
    for _, fz in ipairs(self.forestZones) do
        if self:PointInRect(x, y, fz) then
            return WorldZones.ZONE_FOREST
        end
    end

    -- Check building area
    if self.buildingArea and self:PointInRect(x, y, self.buildingArea) then
        return WorldZones.ZONE_BUILDING
    end

    return nil  -- Wilderness/undefined
end

function WorldZones:PointInRect(x, y, rect)
    return x >= rect.x and x < rect.x + rect.width and
           y >= rect.y and y < rect.y + rect.height
end

return WorldZones
