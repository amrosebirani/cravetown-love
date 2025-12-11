--
-- HousingOverviewPanel.lua
-- Side panel showing housing capacity, occupancy, and rent income overview
--
-- ┌──────────────────────────────────────┐
-- │ HOUSING OVERVIEW                 [X] │
-- ├──────────────────────────────────────┤
-- │ Capacity Summary                     │
-- │ ┌──────────────────────────────────┐ │
-- │ │ Total Capacity:  156 residents   │ │
-- │ │ Current Pop:     98 (63%)        │ │
-- │ │ Vacant Slots:    58              │ │
-- │ │ Housing Units:   12 buildings    │ │
-- │ └──────────────────────────────────┘ │
-- ├──────────────────────────────────────┤
-- │ Rent Income        Total: 245g/cycle │
-- │ ┌──────────────────────────────────┐ │
-- │ │ Town-owned:      180g/cycle      │ │
-- │ │ Private:          65g/cycle      │ │
-- │ │ Unpaid/Arrears:   12g            │ │
-- │ └──────────────────────────────────┘ │
-- ├──────────────────────────────────────┤
-- │ Quality Tiers      Cap    Occ   %    │
-- │ ┌──────────────────────────────────┐ │
-- │ │ ★★★★★ Estate       12    10  83%  │ │
-- │ │ ★★★★  Manor        20    18  90%  │ │
-- │ │ ★★★   Townhouse    24    22  92%  │ │
-- │ │ ★★    House        40    30  75%  │ │
-- │ │ ★     Lodge        60    18  30%  │ │
-- │ └──────────────────────────────────┘ │
-- ├──────────────────────────────────────┤
-- │ By Class           Housed  Homeless  │
-- │ ┌──────────────────────────────────┐ │
-- │ │ Elite:             8        0     │ │
-- │ │ Upper:            22        2     │ │
-- │ │ Middle:           45        5     │ │
-- │ │ Lower:            23       12     │ │
-- │ └──────────────────────────────────┘ │
-- ├──────────────────────────────────────┤
-- │ Relocation Queue: 8 requests         │
-- │ [View Queue]    [Assign Housing]     │
-- └──────────────────────────────────────┘
--
-- FEATURES:
--   - Capacity/occupancy summary
--   - Rent income breakdown (town vs private)
--   - Quality tier capacity utilization
--   - Class-based housing status
--   - Relocation queue count
--   - Quick actions for housing management
--

local HousingOverviewPanel = {}
HousingOverviewPanel.__index = HousingOverviewPanel

function HousingOverviewPanel:Create(world, onAssignClick, onQueueClick)
    local panel = setmetatable({}, HousingOverviewPanel)

    panel.world = world
    panel.onAssignClick = onAssignClick
    panel.onQueueClick = onQueueClick
    panel.visible = false

    -- Panel positioning (right side)
    panel.width = 320
    panel.height = 520
    panel.x = love.graphics.getWidth() - panel.width - 20
    panel.y = 100

    -- Cached data
    panel.statistics = {
        totalCapacity = 0,
        currentPop = 0,
        vacantSlots = 0,
        buildingCount = 0,
        totalRent = 0,
        townRent = 0,
        privateRent = 0,
        unpaidRent = 0,
        relocationQueue = 0
    }

    panel.qualityTiers = {}  -- {name, stars, capacity, occupancy}
    panel.classBased = {}     -- {class, housed, homeless}

    -- Fonts
    panel.fonts = {
        title = love.graphics.newFont(16),
        header = love.graphics.newFont(13),
        normal = love.graphics.newFont(11),
        small = love.graphics.newFont(10),
        tiny = love.graphics.newFont(9)
    }

    -- Colors
    panel.colors = {
        background = {0.1, 0.1, 0.12, 0.95},
        headerBg = {0.15, 0.15, 0.18},
        sectionBg = {0.12, 0.14, 0.16},
        border = {0.3, 0.35, 0.4},
        text = {1, 1, 1},
        textDim = {0.7, 0.7, 0.7},
        textMuted = {0.5, 0.5, 0.5},
        gold = {0.98, 0.85, 0.37},
        success = {0.4, 0.8, 0.4},
        warning = {1.0, 0.7, 0.3},
        danger = {0.9, 0.4, 0.4},
        accent = {0.4, 0.7, 1.0},
        button = {0.25, 0.28, 0.32},
        buttonHover = {0.35, 0.38, 0.42},
        elite = {0.45, 0.18, 0.82},
        upper = {0.10, 0.56, 1.0},
        middle = {0.32, 0.77, 0.10},
        lower = {0.55, 0.55, 0.55},
        star = {0.98, 0.85, 0.37},
    }

    return panel
end

function HousingOverviewPanel:Show()
    self.visible = true
    self:RefreshData()
end

function HousingOverviewPanel:Hide()
    self.visible = false
end

function HousingOverviewPanel:Toggle()
    if self.visible then
        self:Hide()
    else
        self:Show()
    end
end

function HousingOverviewPanel:IsVisible()
    return self.visible
end

function HousingOverviewPanel:RefreshData()
    local housingSystem = self.world.housingSystem
    local characters = self.world.characters or {}

    -- Reset statistics
    self.statistics = {
        totalCapacity = 0,
        currentPop = 0,
        vacantSlots = 0,
        buildingCount = 0,
        totalRent = 0,
        townRent = 0,
        privateRent = 0,
        unpaidRent = 0,
        relocationQueue = 0
    }

    -- Quality tier tracking
    local tierData = {
        estate = {name = "Estate", stars = 5, capacity = 0, occupancy = 0, quality = 1.0},
        manor = {name = "Manor", stars = 4, capacity = 0, occupancy = 0, quality = 0.85},
        townhouse = {name = "Townhouse", stars = 3, capacity = 0, occupancy = 0, quality = 0.7},
        house = {name = "House", stars = 3, capacity = 0, occupancy = 0, quality = 0.6},
        apartment = {name = "Apartment", stars = 2, capacity = 0, occupancy = 0, quality = 0.55},
        cottage = {name = "Cottage", stars = 2, capacity = 0, occupancy = 0, quality = 0.5},
        tenement = {name = "Tenement", stars = 1, capacity = 0, occupancy = 0, quality = 0.4},
        lodge = {name = "Lodge", stars = 1, capacity = 0, occupancy = 0, quality = 0.3},
    }

    -- Class-based tracking
    local classData = {
        elite = {class = "Elite", housed = 0, homeless = 0},
        upper = {class = "Upper", housed = 0, homeless = 0},
        middle = {class = "Middle", housed = 0, homeless = 0},
        lower = {class = "Lower", housed = 0, homeless = 0},
    }

    -- Process housing buildings
    if housingSystem then
        for buildingId, building in pairs(housingSystem.housingBuildings or {}) do
            self.statistics.buildingCount = self.statistics.buildingCount + 1

            local capacity = building.capacity or 4
            local occupancy = building.currentOccupancy or 0
            local rentRate = building.rentRate or 10

            self.statistics.totalCapacity = self.statistics.totalCapacity + capacity
            self.statistics.currentPop = self.statistics.currentPop + occupancy

            -- Calculate rent
            local rent = occupancy * rentRate
            self.statistics.totalRent = self.statistics.totalRent + rent

            if building.ownerId == "town" or building.ownerId == 0 or not building.ownerId then
                self.statistics.townRent = self.statistics.townRent + rent
            else
                self.statistics.privateRent = self.statistics.privateRent + rent
            end

            -- Update tier data based on building type
            local typeId = building.typeId or "lodge"
            local tierKey = typeId:lower():gsub("_", ""):gsub(" ", "")

            -- Map common building type IDs to tier keys
            if typeId:find("estate") then tierKey = "estate"
            elseif typeId:find("manor") then tierKey = "manor"
            elseif typeId:find("townhouse") then tierKey = "townhouse"
            elseif typeId:find("house") then tierKey = "house"
            elseif typeId:find("apartment") then tierKey = "apartment"
            elseif typeId:find("cottage") then tierKey = "cottage"
            elseif typeId:find("tenement") then tierKey = "tenement"
            elseif typeId:find("lodge") then tierKey = "lodge"
            end

            if tierData[tierKey] then
                tierData[tierKey].capacity = tierData[tierKey].capacity + capacity
                tierData[tierKey].occupancy = tierData[tierKey].occupancy + occupancy
            end
        end

        -- Relocation queue
        self.statistics.relocationQueue = housingSystem.relocationQueue and #housingSystem.relocationQueue or 0
    end

    -- Calculate vacant slots
    self.statistics.vacantSlots = self.statistics.totalCapacity - self.statistics.currentPop

    -- Process characters for class-based stats
    for charId, char in pairs(characters) do
        local class = (char.emergentClass or char.class or "middle"):lower()
        local hasHousing = char.housingId ~= nil

        if classData[class] then
            if hasHousing then
                classData[class].housed = classData[class].housed + 1
            else
                classData[class].homeless = classData[class].homeless + 1
            end
        else
            -- Default to lower class if unknown
            if hasHousing then
                classData.lower.housed = classData.lower.housed + 1
            else
                classData.lower.homeless = classData.lower.homeless + 1
            end
        end
    end

    -- Convert tier data to sorted array (by quality descending)
    self.qualityTiers = {}
    for _, tier in pairs(tierData) do
        if tier.capacity > 0 then
            table.insert(self.qualityTiers, tier)
        end
    end
    table.sort(self.qualityTiers, function(a, b) return a.quality > b.quality end)

    -- Convert class data to array
    self.classBased = {
        classData.elite,
        classData.upper,
        classData.middle,
        classData.lower
    }
end

function HousingOverviewPanel:Update(dt)
    -- Could add animations
end

function HousingOverviewPanel:Render()
    if not self.visible then return end

    -- Update position if screen size changed
    self.x = love.graphics.getWidth() - self.width - 20

    local x, y = self.x, self.y
    local w, h = self.width, self.height

    -- Panel background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", x, y, w, h, 6, 6)

    -- Panel border
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 6, 6)
    love.graphics.setLineWidth(1)

    -- Header
    self:RenderHeader(x, y, w)

    local contentY = y + 45

    -- Capacity Summary
    contentY = self:RenderCapacitySummary(x + 10, contentY, w - 20)

    -- Rent Income
    contentY = self:RenderRentSummary(x + 10, contentY + 10, w - 20)

    -- Quality Tiers
    contentY = self:RenderQualityTiers(x + 10, contentY + 10, w - 20)

    -- By Class
    contentY = self:RenderClassBased(x + 10, contentY + 10, w - 20)

    -- Action buttons
    self:RenderActions(x + 10, contentY + 10, w - 20)

    love.graphics.setColor(1, 1, 1, 1)
end

function HousingOverviewPanel:RenderHeader(x, y, w)
    -- Header background
    love.graphics.setColor(self.colors.headerBg)
    love.graphics.rectangle("fill", x, y, w, 40, 6, 6)
    love.graphics.rectangle("fill", x, y + 30, w, 10)

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("HOUSING OVERVIEW", x + 15, y + 10)

    -- Close button
    local closeX = x + w - 35
    local closeY = y + 8
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.rectangle("fill", closeX, closeY, 24, 24, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.header)
    love.graphics.print("X", closeX + 7, closeY + 3)

    self.closeBtn = {x = closeX, y = closeY, w = 24, h = 24}
end

function HousingOverviewPanel:RenderCapacitySummary(x, y, w)
    -- Section label
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Capacity Summary", x, y)

    -- Box
    local boxY = y + 16
    local boxH = 65
    love.graphics.setColor(self.colors.sectionBg)
    love.graphics.rectangle("fill", x, boxY, w, boxH, 4, 4)

    -- Content
    local innerY = boxY + 8
    love.graphics.setFont(self.fonts.normal)

    -- Row 1
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Total Capacity:", x + 8, innerY)
    love.graphics.print(self.statistics.totalCapacity .. " residents", x + 130, innerY)

    -- Row 2
    innerY = innerY + 16
    local occupancyPct = self.statistics.totalCapacity > 0 and
                        math.floor(self.statistics.currentPop / self.statistics.totalCapacity * 100) or 0
    local occColor = occupancyPct > 90 and self.colors.warning or self.colors.success
    love.graphics.setColor(occColor)
    love.graphics.print("Current Pop:", x + 8, innerY)
    love.graphics.print(string.format("%d (%d%%)", self.statistics.currentPop, occupancyPct), x + 130, innerY)

    -- Row 3
    innerY = innerY + 16
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Vacant Slots:", x + 8, innerY)
    love.graphics.print(tostring(self.statistics.vacantSlots), x + 130, innerY)

    love.graphics.print("Buildings:", x + 180, innerY)
    love.graphics.print(tostring(self.statistics.buildingCount), x + 250, innerY)

    return boxY + boxH
end

function HousingOverviewPanel:RenderRentSummary(x, y, w)
    -- Section label with total
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Rent Income", x, y)

    love.graphics.setColor(self.colors.gold)
    love.graphics.print("Total: " .. self.statistics.totalRent .. "g/cycle", x + w - 110, y)

    -- Box
    local boxY = y + 16
    local boxH = 48
    love.graphics.setColor(self.colors.sectionBg)
    love.graphics.rectangle("fill", x, boxY, w, boxH, 4, 4)

    -- Content
    local innerY = boxY + 8
    love.graphics.setFont(self.fonts.normal)

    -- Town rent
    love.graphics.setColor(self.colors.accent)
    love.graphics.print("Town-owned:", x + 8, innerY)
    love.graphics.print(self.statistics.townRent .. "g/cycle", x + 130, innerY)

    -- Private rent
    innerY = innerY + 16
    love.graphics.setColor(self.colors.success)
    love.graphics.print("Private:", x + 8, innerY)
    love.graphics.print(self.statistics.privateRent .. "g/cycle", x + 130, innerY)

    -- Unpaid (if any)
    if self.statistics.unpaidRent > 0 then
        love.graphics.setColor(self.colors.danger)
        love.graphics.print("Arrears:", x + 180, innerY)
        love.graphics.print(self.statistics.unpaidRent .. "g", x + 240, innerY)
    end

    return boxY + boxH
end

function HousingOverviewPanel:RenderQualityTiers(x, y, w)
    -- Section label
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Quality Tiers", x, y)
    love.graphics.print("Cap   Occ    %", x + w - 85, y)

    -- Box
    local boxY = y + 16
    local tierCount = math.min(#self.qualityTiers, 5)
    local boxH = math.max(48, tierCount * 16 + 12)
    love.graphics.setColor(self.colors.sectionBg)
    love.graphics.rectangle("fill", x, boxY, w, boxH, 4, 4)

    -- Content
    love.graphics.setFont(self.fonts.normal)
    local innerY = boxY + 6

    for i, tier in ipairs(self.qualityTiers) do
        if i > 5 then break end

        -- Stars
        love.graphics.setColor(self.colors.star)
        local starStr = string.rep("★", tier.stars) .. string.rep("☆", 5 - tier.stars)
        love.graphics.print(starStr, x + 8, innerY)

        -- Name
        love.graphics.setColor(self.colors.text)
        love.graphics.print(tier.name, x + 70, innerY)

        -- Capacity
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(string.format("%3d", tier.capacity), x + w - 85, innerY)

        -- Occupancy
        love.graphics.print(string.format("%3d", tier.occupancy), x + w - 55, innerY)

        -- Percentage
        local pct = tier.capacity > 0 and math.floor(tier.occupancy / tier.capacity * 100) or 0
        local pctColor = pct > 90 and self.colors.warning or (pct > 50 and self.colors.success or self.colors.textDim)
        love.graphics.setColor(pctColor)
        love.graphics.print(string.format("%3d%%", pct), x + w - 30, innerY)

        innerY = innerY + 16
    end

    if #self.qualityTiers == 0 then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No housing buildings", x + 8, innerY)
    end

    return boxY + boxH
end

function HousingOverviewPanel:RenderClassBased(x, y, w)
    -- Section label
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("By Class", x, y)
    love.graphics.print("Housed  Homeless", x + w - 105, y)

    -- Box
    local boxY = y + 16
    local boxH = 72
    love.graphics.setColor(self.colors.sectionBg)
    love.graphics.rectangle("fill", x, boxY, w, boxH, 4, 4)

    -- Content
    love.graphics.setFont(self.fonts.normal)
    local innerY = boxY + 6

    local classColors = {
        elite = self.colors.elite,
        upper = self.colors.upper,
        middle = self.colors.middle,
        lower = self.colors.lower
    }

    for _, data in ipairs(self.classBased) do
        local classKey = data.class:lower()

        -- Class label with color
        love.graphics.setColor(classColors[classKey] or self.colors.text)
        love.graphics.print(data.class .. ":", x + 8, innerY)

        -- Housed count
        love.graphics.setColor(self.colors.success)
        love.graphics.print(string.format("%4d", data.housed), x + w - 100, innerY)

        -- Homeless count
        if data.homeless > 0 then
            love.graphics.setColor(self.colors.danger)
        else
            love.graphics.setColor(self.colors.textDim)
        end
        love.graphics.print(string.format("%4d", data.homeless), x + w - 50, innerY)

        innerY = innerY + 16
    end

    return boxY + boxH
end

function HousingOverviewPanel:RenderActions(x, y, w)
    -- Relocation queue info
    love.graphics.setFont(self.fonts.normal)
    if self.statistics.relocationQueue > 0 then
        love.graphics.setColor(self.colors.warning)
        love.graphics.print("Relocation Queue: " .. self.statistics.relocationQueue .. " requests", x, y)
    else
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Relocation Queue: empty", x, y)
    end

    -- Buttons
    local btnY = y + 22
    local btnW = (w - 10) / 2
    local btnH = 28

    -- View Queue button
    love.graphics.setColor(self.colors.button)
    love.graphics.rectangle("fill", x, btnY, btnW, btnH, 4, 4)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("View Queue", x + 20, btnY + 7)
    self.viewQueueBtn = {x = x, y = btnY, w = btnW, h = btnH}

    -- Assign Housing button
    local assignX = x + btnW + 10
    love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.8)
    love.graphics.rectangle("fill", assignX, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Assign Housing", assignX + 12, btnY + 7)
    self.assignBtn = {x = assignX, y = btnY, w = btnW, h = btnH}
end

function HousingOverviewPanel:HandleClick(screenX, screenY, button)
    if not self.visible then return false end

    -- Check if click is within panel bounds
    if screenX < self.x or screenX > self.x + self.width or
       screenY < self.y or screenY > self.y + self.height then
        return false
    end

    -- Close button
    if self.closeBtn then
        local btn = self.closeBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            self:Hide()
            return true
        end
    end

    -- View Queue button
    if self.viewQueueBtn then
        local btn = self.viewQueueBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            if self.onQueueClick then self.onQueueClick() end
            return true
        end
    end

    -- Assign Housing button
    if self.assignBtn then
        local btn = self.assignBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            if self.onAssignClick then self.onAssignClick() end
            return true
        end
    end

    return true  -- Consume click within panel
end

function HousingOverviewPanel:HandleKeyPress(key)
    if not self.visible then return false end

    if key == "escape" then
        self:Hide()
        return true
    end

    return false
end

return HousingOverviewPanel
