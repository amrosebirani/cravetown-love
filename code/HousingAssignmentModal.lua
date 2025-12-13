--
-- HousingAssignmentModal.lua
-- Modal for assigning citizens to housing buildings
--
-- ┌─────────────────────────────────────────────────────────────────────────────────┐
-- │ ASSIGN HOUSING                                                             [X] │
-- ├─────────────────────────────────────────────────────────────────────────────────┤
-- │ Filter: [All ▾]  Class: [Any ▾]  Status: [Homeless ▾]   [___Search___]         │
-- ├───────────────────────────────────────┬─────────────────────────────────────────┤
-- │ CITIZENS (23 homeless)                │ HOUSING BUILDINGS (12 available)       │
-- ├───────────────────────────────────────┼─────────────────────────────────────────┤
-- │                                       │                                         │
-- │ ☑ Hans Mueller (Middle)               │ ┌─────────────────────────────────────┐ │
-- │   Baker | Homeless                    │ │ ★★★ Townhouse #3            ▾       │ │
-- │   Prefers: Good quality               │ │ Owner: Town                         │ │
-- │                                       │ │ Capacity: 6/8 (75%)                 │ │
-- │ ☑ Maria Schmidt (Lower)               │ │ Quality: Good (0.7)                 │ │
-- │   Farmer | Homeless                   │ │ Rent: 15g/cycle                     │ │
-- │   Prefers: Basic quality              │ │ Suitable for: Middle, Lower         │ │
-- │                                       │ └─────────────────────────────────────┘ │
-- │ ☐ Karl Weber (Upper)                  │                                         │
-- │   Merchant | Current: Cottage         │ │ ┌─────────────────────────────────────┐ │
-- │   Wants upgrade                       │ │ ★★ Lodge #1                   ▾       │ │
-- │                                       │ │ Owner: Town                         │ │
-- │ ☐ Anna Fischer (Elite)                │ │ Capacity: 8/12 (67%)                │ │
-- │   Noble | Current: Manor              │ │ Quality: Basic (0.3)                │ │
-- │   Satisfied                           │ │ Rent: 5g/cycle                      │ │
-- │                                       │ │ Suitable for: Lower                 │ │
-- │                                       │ └─────────────────────────────────────┘ │
-- │                                       │                                         │
-- │ ─── Scroll for more ───               │ ─── Scroll for more ───                │
-- │                                       │                                         │
-- ├───────────────────────────────────────┴─────────────────────────────────────────┤
-- │ Selected: 2 citizens → Townhouse #3                                            │
-- │ Fit: ✓ Hans (Good match)  ✓ Maria (Acceptable)                                 │
-- │                                                   [CANCEL]    [ASSIGN]          │
-- └─────────────────────────────────────────────────────────────────────────────────┘
--
-- FEATURES:
--   - Left panel: Citizens list (filterable by class, status)
--   - Multi-select citizens for batch assignment
--   - Right panel: Available housing buildings
--   - Fit indicators showing suitability
--   - Selection summary before confirming
--

local HousingAssignmentModal = {}
HousingAssignmentModal.__index = HousingAssignmentModal

function HousingAssignmentModal:Create(world, onComplete, onCancel)
    local modal = setmetatable({}, HousingAssignmentModal)

    modal.world = world
    modal.onComplete = onComplete
    modal.onCancel = onCancel

    -- Selection state
    modal.selectedCitizens = {}  -- {citizenId = true}
    modal.selectedBuilding = nil

    -- Filter state
    modal.filterClass = "any"     -- "any", "elite", "upper", "middle", "lower"
    modal.filterStatus = "homeless"  -- "any", "homeless", "housed", "relocating"
    modal.searchText = ""

    -- Scroll state
    modal.citizenScroll = 0
    modal.citizenMaxScroll = 0
    modal.buildingScroll = 0
    modal.buildingMaxScroll = 0

    -- Hover state
    modal.hoverCitizen = nil
    modal.hoverBuilding = nil

    -- Cached data
    modal.citizens = {}
    modal.buildings = {}
    modal:RefreshData()

    -- Fonts
    modal.fonts = {
        title = love.graphics.newFont(18),
        header = love.graphics.newFont(14),
        normal = love.graphics.newFont(12),
        small = love.graphics.newFont(10),
        tiny = love.graphics.newFont(9)
    }

    -- Colors
    modal.colors = {
        background = {0.1, 0.1, 0.12, 0.98},
        headerBg = {0.15, 0.15, 0.18},
        cardBg = {0.12, 0.14, 0.16},
        cardHover = {0.18, 0.20, 0.24},
        cardSelected = {0.2, 0.3, 0.25},
        border = {0.4, 0.5, 0.6},
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
        star = {0.98, 0.85, 0.37},
        checkbox = {0.4, 0.7, 1.0},
        elite = {0.45, 0.18, 0.82},
        upper = {0.10, 0.56, 1.0},
        middle = {0.32, 0.77, 0.10},
        lower = {0.55, 0.55, 0.55},
    }

    return modal
end

function HousingAssignmentModal:RefreshData()
    local housingSystem = self.world.housingSystem
    local worldCitizens = self.world.citizens or {}

    -- Gather citizens
    self.citizens = {}
    for _, citizen in ipairs(worldCitizens) do
        local charId = citizen.id
        local class = (citizen.emergentClass or citizen.class or "middle"):lower()

        -- Check housing assignments - first check housingSystem, then citizen.housingId as fallback
        local housingId = nil
        if housingSystem and housingSystem.housingAssignments then
            housingId = housingSystem.housingAssignments[charId]
        end
        if not housingId then
            housingId = citizen.housingId
        end

        local hasHousing = housingId ~= nil
        local wantsRelocation = citizen.wantsRelocation or false

        local status = "housed"
        if not hasHousing then
            status = "homeless"
        elseif wantsRelocation then
            status = "relocating"
        end

        table.insert(self.citizens, {
            id = charId,
            name = citizen.name or ("Citizen #" .. charId),
            class = class,
            vocation = citizen.vocation or citizen.workerType or "Worker",
            status = status,
            currentHousing = housingId,
            housingQualityPref = citizen.housingQualityPref or 0.5,
            canAffordRent = citizen.canAffordRent ~= false
        })
    end

    -- Sort by status (homeless first) then name
    table.sort(self.citizens, function(a, b)
        if a.status ~= b.status then
            local statusOrder = {homeless = 1, relocating = 2, housed = 3}
            return (statusOrder[a.status] or 4) < (statusOrder[b.status] or 4)
        end
        return a.name < b.name
    end)

    -- Gather housing buildings from buildingOccupancy
    self.buildings = {}
    if housingSystem then
        for buildingId, buildingData in pairs(housingSystem.buildingOccupancy or {}) do
            local capacity = buildingData.capacity or 4
            local occupants = buildingData.occupants or {}
            local occupancy = #occupants
            local available = capacity - occupancy

            -- Get building name from world.buildings if available
            local buildingName = nil
            local buildingTypeId = buildingData.typeId or "lodge"
            if self.world.buildings then
                local building = self.world.buildings[buildingId]
                if building then
                    buildingName = building.name
                    buildingTypeId = building.typeId or buildingTypeId
                end
            end
            buildingName = buildingName or (buildingTypeId:sub(1,1):upper() .. buildingTypeId:sub(2) .. " #" .. buildingId)

            -- Get housing config
            local housingConfig = buildingData.housingConfig or {}
            local quality = housingConfig.quality or 0.5
            local rentRate = housingConfig.rentRate or 10
            local targetClasses = housingConfig.targetClasses or {"lower", "middle"}
            local ownerId = buildingData.ownerId or "town"

            -- Include all buildings, but only allow selection of ones with space
            table.insert(self.buildings, {
                id = buildingId,
                typeId = buildingTypeId,
                name = buildingName,
                owner = ownerId == "town" and "Town" or ("Citizen #" .. ownerId),
                capacity = capacity,
                occupancy = occupancy,
                available = available,
                quality = quality,
                qualityTier = self:GetQualityTier(quality),
                rentRate = rentRate,
                targetClasses = targetClasses,
                stars = self:GetStars(quality),
                isFull = available <= 0
            })
        end
    end

    -- Sort by quality descending
    table.sort(self.buildings, function(a, b) return a.quality > b.quality end)
end

function HousingAssignmentModal:GetQualityTier(quality)
    if quality >= 0.9 then return "Masterwork"
    elseif quality >= 0.75 then return "Luxury"
    elseif quality >= 0.55 then return "Good"
    elseif quality >= 0.4 then return "Basic"
    else return "Poor"
    end
end

function HousingAssignmentModal:GetStars(quality)
    if quality >= 0.9 then return 5
    elseif quality >= 0.7 then return 4
    elseif quality >= 0.5 then return 3
    elseif quality >= 0.35 then return 2
    else return 1
    end
end

function HousingAssignmentModal:GetFilteredCitizens()
    local result = {}
    local searchLower = self.searchText:lower()

    for _, citizen in ipairs(self.citizens) do
        local matchesClass = self.filterClass == "any" or citizen.class == self.filterClass
        local matchesStatus = self.filterStatus == "any" or citizen.status == self.filterStatus
        local matchesSearch = searchLower == "" or citizen.name:lower():find(searchLower, 1, true)

        if matchesClass and matchesStatus and matchesSearch then
            table.insert(result, citizen)
        end
    end

    return result
end

function HousingAssignmentModal:IsCitizenSelected(citizenId)
    return self.selectedCitizens[citizenId] == true
end

function HousingAssignmentModal:ToggleCitizen(citizenId)
    if self.selectedCitizens[citizenId] then
        self.selectedCitizens[citizenId] = nil
    else
        self.selectedCitizens[citizenId] = true
    end
end

function HousingAssignmentModal:GetSelectedCount()
    local count = 0
    for _ in pairs(self.selectedCitizens) do
        count = count + 1
    end
    return count
end

function HousingAssignmentModal:CheckFit(citizen, building)
    if not building then return "none", "No building selected" end

    -- Check capacity
    local selectedCount = self:GetSelectedCount()
    if selectedCount > building.available then
        return "error", "Not enough space"
    end

    -- Check class compatibility
    local classMatch = false
    for _, targetClass in ipairs(building.targetClasses or {}) do
        if targetClass:lower() == citizen.class:lower() then
            classMatch = true
            break
        end
    end

    -- Check quality preference
    local qualityDiff = building.quality - citizen.housingQualityPref
    local qualityMatch = qualityDiff >= -0.2  -- Allow slightly below preference

    if classMatch and qualityMatch and qualityDiff >= 0 then
        return "good", "Good match"
    elseif classMatch or qualityMatch then
        return "acceptable", "Acceptable"
    else
        return "poor", "Poor fit"
    end
end

function HousingAssignmentModal:Show(building)
    -- Refresh data when modal is shown
    self:RefreshData()

    -- Reset selection state
    self.selectedCitizens = {}
    self.citizenScroll = 0
    self.buildingScroll = 0

    -- If a specific building was passed, select it
    if building then
        self.selectedBuilding = building.id or building
    else
        self.selectedBuilding = nil
    end
end

function HousingAssignmentModal:Hide()
    -- Reset state when hidden
    self.selectedCitizens = {}
    self.selectedBuilding = nil
    self.hoverCitizen = nil
    self.hoverBuilding = nil
end

function HousingAssignmentModal:Update(dt)
    -- Could add animations
end

function HousingAssignmentModal:Render()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal dimensions
    local modalW = 900
    local modalH = 600
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    -- Modal background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 8, 8)

    -- Modal border
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Header
    self:RenderHeader(modalX, modalY, modalW)

    -- Filter bar
    self:RenderFilterBar(modalX + 15, modalY + 50, modalW - 30)

    -- Split content area
    local contentY = modalY + 85
    local contentH = modalH - 170

    -- Left panel - Citizens
    local leftW = (modalW - 40) / 2
    self:RenderCitizensPanel(modalX + 15, contentY, leftW, contentH)

    -- Right panel - Buildings
    local rightX = modalX + leftW + 25
    self:RenderBuildingsPanel(rightX, contentY, leftW, contentH)

    -- Bottom bar with selection summary and actions
    self:RenderBottomBar(modalX, modalY + modalH - 80, modalW)

    love.graphics.setColor(1, 1, 1, 1)
end

function HousingAssignmentModal:RenderHeader(x, y, w)
    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("ASSIGN HOUSING", x + 20, y + 15)

    -- Close button
    local closeX = x + w - 40
    local closeY = y + 12
    love.graphics.setColor(self.colors.danger)
    love.graphics.setFont(self.fonts.header)
    love.graphics.print("X", closeX + 8, closeY + 2)
    self.closeBtn = {x = closeX, y = closeY, w = 30, h = 30}

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 15, y + 45, x + w - 15, y + 45)
end

function HousingAssignmentModal:RenderFilterBar(x, y, w)
    love.graphics.setFont(self.fonts.small)

    -- Class filter
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Class:", x, y + 4)

    local classBtnX = x + 40
    love.graphics.setColor(self.colors.button)
    love.graphics.rectangle("fill", classBtnX, y, 80, 22, 3, 3)
    love.graphics.setColor(self.colors.text)
    local classText = self.filterClass == "any" and "Any" or
                     self.filterClass:sub(1,1):upper() .. self.filterClass:sub(2)
    love.graphics.print(classText .. " ▾", classBtnX + 8, y + 4)
    self.classFilterBtn = {x = classBtnX, y = y, w = 80, h = 22}

    -- Status filter
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Status:", x + 140, y + 4)

    local statusBtnX = x + 185
    love.graphics.setColor(self.colors.button)
    love.graphics.rectangle("fill", statusBtnX, y, 90, 22, 3, 3)
    love.graphics.setColor(self.colors.text)
    local statusText = self.filterStatus == "any" and "Any" or
                      self.filterStatus:sub(1,1):upper() .. self.filterStatus:sub(2)
    love.graphics.print(statusText .. " ▾", statusBtnX + 8, y + 4)
    self.statusFilterBtn = {x = statusBtnX, y = y, w = 90, h = 22}

    -- Refresh button
    local refreshX = x + w - 30
    love.graphics.setColor(self.colors.button)
    love.graphics.rectangle("fill", refreshX, y, 28, 22, 3, 3)
    love.graphics.setColor(self.colors.accent)
    love.graphics.print("↻", refreshX + 8, y + 3)
    self.refreshBtn = {x = refreshX, y = y, w = 28, h = 22}
end

function HousingAssignmentModal:RenderCitizensPanel(x, y, w, h)
    -- Panel header
    local filteredCitizens = self:GetFilteredCitizens()
    local homelessCount = 0
    for _, c in ipairs(filteredCitizens) do
        if c.status == "homeless" then homelessCount = homelessCount + 1 end
    end

    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("CITIZENS (" .. homelessCount .. " homeless)", x, y)

    -- List area
    local listY = y + 22
    local listH = h - 22
    love.graphics.setScissor(x, listY, w, listH)

    local cardH = 55
    local spacing = 5
    self.citizenCards = {}

    for i, citizen in ipairs(filteredCitizens) do
        local cardY = listY + (i - 1) * (cardH + spacing) - self.citizenScroll

        -- Skip if off-screen
        if cardY + cardH < listY or cardY > y + h then goto continue end

        local isSelected = self:IsCitizenSelected(citizen.id)
        local isHovered = self.hoverCitizen == citizen.id

        -- Card background
        if isSelected then
            love.graphics.setColor(self.colors.cardSelected)
        elseif isHovered then
            love.graphics.setColor(self.colors.cardHover)
        else
            love.graphics.setColor(self.colors.cardBg)
        end
        love.graphics.rectangle("fill", x, cardY, w, cardH, 4, 4)

        -- Checkbox
        love.graphics.setColor(self.colors.border)
        love.graphics.rectangle("line", x + 8, cardY + 8, 16, 16, 2, 2)
        if isSelected then
            love.graphics.setColor(self.colors.checkbox)
            love.graphics.rectangle("fill", x + 10, cardY + 10, 12, 12, 1, 1)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.small)
            love.graphics.print("✓", x + 11, cardY + 9)
        end

        -- Name and class
        love.graphics.setFont(self.fonts.normal)
        local classColor = self.colors[citizen.class] or self.colors.text
        love.graphics.setColor(classColor)
        local classLabel = citizen.class:sub(1,1):upper() .. citizen.class:sub(2)
        love.graphics.print(citizen.name .. " (" .. classLabel .. ")", x + 30, cardY + 6)

        -- Vocation and status
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textDim)
        local statusColor = citizen.status == "homeless" and self.colors.danger or
                           citizen.status == "relocating" and self.colors.warning or
                           self.colors.success
        love.graphics.print(citizen.vocation .. " | ", x + 30, cardY + 24)
        love.graphics.setColor(statusColor)
        local statusText = citizen.status == "homeless" and "Homeless" or
                          citizen.status == "relocating" and "Wants relocation" or
                          "Housed"
        love.graphics.print(statusText, x + 90, cardY + 24)

        -- Housing preference
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("Prefers: " .. self:GetQualityTier(citizen.housingQualityPref) .. " quality", x + 30, cardY + 40)

        self.citizenCards[i] = {x = x, y = cardY, w = w, h = cardH, citizen = citizen}
        ::continue::
    end

    -- Max scroll
    self.citizenMaxScroll = math.max(0, #filteredCitizens * (cardH + spacing) - listH)

    love.graphics.setScissor()

    -- Scroll hint
    if self.citizenMaxScroll > 0 then
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("─── Scroll ───", x + w/2 - 35, y + h - 10)
    end

    self.citizenListArea = {x = x, y = listY, w = w, h = listH}
end

function HousingAssignmentModal:RenderBuildingsPanel(x, y, w, h)
    -- Count available buildings (with space)
    local availableCount = 0
    for _, b in ipairs(self.buildings) do
        if not b.isFull then availableCount = availableCount + 1 end
    end

    -- Panel header
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("HOUSING BUILDINGS (" .. availableCount .. "/" .. #self.buildings .. " with space)", x, y)

    -- List area
    local listY = y + 22
    local listH = h - 22
    love.graphics.setScissor(x, listY, w, listH)

    local cardH = 90
    local spacing = 8
    self.buildingCards = {}

    for i, building in ipairs(self.buildings) do
        local cardY = listY + (i - 1) * (cardH + spacing) - self.buildingScroll

        -- Skip if off-screen
        if cardY + cardH < listY or cardY > y + h then goto continue end

        local isSelected = self.selectedBuilding == building.id
        local isHovered = self.hoverBuilding == building.id
        local isFull = building.isFull

        -- Card background - grey out full buildings
        if isFull then
            love.graphics.setColor(0.15, 0.15, 0.17, 0.7)
        elseif isSelected then
            love.graphics.setColor(self.colors.cardSelected)
        elseif isHovered then
            love.graphics.setColor(self.colors.cardHover)
        else
            love.graphics.setColor(self.colors.cardBg)
        end
        love.graphics.rectangle("fill", x, cardY, w, cardH, 4, 4)

        -- Selection indicator
        if isSelected and not isFull then
            love.graphics.setColor(self.colors.success)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, cardY, w, cardH, 4, 4)
            love.graphics.setLineWidth(1)
        end

        -- Full indicator border for full buildings
        if isFull then
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", x, cardY, w, cardH, 4, 4)
        end

        -- Stars and name - dimmed for full buildings
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(isFull and {0.5, 0.45, 0.2} or self.colors.star)
        local starStr = string.rep("★", building.stars)
        love.graphics.print(starStr, x + 8, cardY + 6)

        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(isFull and self.colors.textMuted or self.colors.text)
        love.graphics.print(building.name, x + 8 + building.stars * 12, cardY + 5)

        -- "FULL" badge for full buildings
        if isFull then
            love.graphics.setFont(self.fonts.tiny)
            love.graphics.setColor(0.7, 0.3, 0.3)
            love.graphics.print("[FULL]", x + w - 40, cardY + 8)
        end

        -- Owner
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(isFull and self.colors.textMuted or self.colors.textDim)
        love.graphics.print("Owner: " .. building.owner, x + 8, cardY + 24)

        -- Capacity bar
        local barX = x + 8
        local barY = cardY + 42
        local barW = w - 16
        local barH = 12
        local fillPct = building.capacity > 0 and (building.occupancy / building.capacity) or 0

        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 2, 2)
        if isFull then
            love.graphics.setColor(0.7, 0.3, 0.3)
        else
            love.graphics.setColor(fillPct > 0.8 and self.colors.warning or self.colors.success)
        end
        love.graphics.rectangle("fill", barX, barY, barW * fillPct, barH, 2, 2)

        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(1, 1, 1, isFull and 0.6 or 1)
        local capText = string.format("%d/%d (%d%% full)", building.occupancy, building.capacity, math.floor(fillPct * 100))
        love.graphics.print(capText, barX + 4, barY + 1)

        -- Quality and rent
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(isFull and self.colors.textMuted or self.colors.textDim)
        love.graphics.print("Quality: " .. building.qualityTier .. string.format(" (%.1f)", building.quality), x + 8, cardY + 58)

        love.graphics.setColor(isFull and {0.5, 0.45, 0.2} or self.colors.gold)
        love.graphics.print("Rent: " .. building.rentRate .. "g/cycle", x + 180, cardY + 58)

        -- Suitable classes
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textMuted)
        local suitableStr = "Suitable for: " .. table.concat(building.targetClasses, ", ")
        love.graphics.print(suitableStr, x + 8, cardY + 74)

        -- Only add to clickable cards if not full
        self.buildingCards[i] = {x = x, y = cardY, w = w, h = cardH, building = building, isFull = isFull}
        ::continue::
    end

    -- Max scroll
    self.buildingMaxScroll = math.max(0, #self.buildings * (cardH + spacing) - listH)

    love.graphics.setScissor()

    -- Scroll hint
    if self.buildingMaxScroll > 0 then
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("─── Scroll ───", x + w/2 - 35, y + h - 10)
    end

    self.buildingListArea = {x = x, y = listY, w = w, h = listH}
end

function HousingAssignmentModal:RenderBottomBar(x, y, w)
    -- Background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", x, y, w, 80)

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 15, y, x + w - 15, y)

    local selectedCount = self:GetSelectedCount()
    local building = nil
    for _, b in ipairs(self.buildings) do
        if b.id == self.selectedBuilding then
            building = b
            break
        end
    end

    -- Selection summary
    local summaryY = y + 10
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)

    if selectedCount > 0 and building then
        love.graphics.print(string.format("Selected: %d citizens → %s", selectedCount, building.name), x + 20, summaryY)

        -- Fit indicators
        summaryY = summaryY + 20
        love.graphics.setFont(self.fonts.small)
        love.graphics.print("Fit: ", x + 20, summaryY)

        local fitX = x + 50
        for citizenId, _ in pairs(self.selectedCitizens) do
            local citizen = nil
            for _, c in ipairs(self.citizens) do
                if c.id == citizenId then citizen = c break end
            end
            if citizen then
                local fitLevel, fitText = self:CheckFit(citizen, building)
                local fitColor = fitLevel == "good" and self.colors.success or
                                fitLevel == "acceptable" and self.colors.warning or
                                self.colors.danger
                local symbol = fitLevel == "good" and "✓" or fitLevel == "acceptable" and "~" or "✗"

                love.graphics.setColor(fitColor)
                love.graphics.print(symbol .. " " .. citizen.name:sub(1, 10), fitX, summaryY)
                fitX = fitX + 100
                if fitX > x + w - 250 then break end
            end
        end
    elseif selectedCount > 0 then
        love.graphics.print(string.format("Selected: %d citizens (select a building)", selectedCount), x + 20, summaryY)
    else
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Select citizens and a housing building", x + 20, summaryY)
    end

    -- Action buttons
    local btnW = 100
    local btnH = 35
    local btnY = y + 25

    -- Cancel button
    local cancelX = x + w - btnW * 2 - 30
    love.graphics.setColor(self.colors.danger[1], self.colors.danger[2], self.colors.danger[3], 0.8)
    love.graphics.rectangle("fill", cancelX, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(self.colors.text)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.print("CANCEL", cancelX + 25, btnY + 9)
    self.cancelBtn = {x = cancelX, y = btnY, w = btnW, h = btnH}

    -- Assign button
    local assignX = x + w - btnW - 15
    local canAssign = selectedCount > 0 and building and selectedCount <= building.available
    if canAssign then
        love.graphics.setColor(self.colors.success[1], self.colors.success[2], self.colors.success[3], 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end
    love.graphics.rectangle("fill", assignX, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(1, 1, 1, canAssign and 1 or 0.5)
    love.graphics.print("ASSIGN", assignX + 25, btnY + 9)
    self.assignBtn = {x = assignX, y = btnY, w = btnW, h = btnH, enabled = canAssign}
end

function HousingAssignmentModal:HandleClick(screenX, screenY, button)
    -- Close button
    if self.closeBtn then
        local btn = self.closeBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            if self.onCancel then self.onCancel() end
            return true
        end
    end

    -- Filter buttons
    if self.classFilterBtn then
        local btn = self.classFilterBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            local classes = {"any", "elite", "upper", "middle", "lower"}
            for i, c in ipairs(classes) do
                if c == self.filterClass then
                    self.filterClass = classes[(i % #classes) + 1]
                    break
                end
            end
            return true
        end
    end

    if self.statusFilterBtn then
        local btn = self.statusFilterBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            local statuses = {"homeless", "relocating", "housed", "any"}
            for i, s in ipairs(statuses) do
                if s == self.filterStatus then
                    self.filterStatus = statuses[(i % #statuses) + 1]
                    break
                end
            end
            return true
        end
    end

    if self.refreshBtn then
        local btn = self.refreshBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            self:RefreshData()
            return true
        end
    end

    -- Citizen cards
    if self.citizenCards then
        for _, card in ipairs(self.citizenCards) do
            if card and screenX >= card.x and screenX < card.x + card.w and
               screenY >= card.y and screenY < card.y + card.h then
                self:ToggleCitizen(card.citizen.id)
                return true
            end
        end
    end

    -- Building cards
    if self.buildingCards then
        for _, card in ipairs(self.buildingCards) do
            if card and screenX >= card.x and screenX < card.x + card.w and
               screenY >= card.y and screenY < card.y + card.h then
                -- Only allow selecting buildings that have space
                if not card.isFull then
                    self.selectedBuilding = card.building.id
                end
                return true
            end
        end
    end

    -- Cancel button
    if self.cancelBtn then
        local btn = self.cancelBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            if self.onCancel then self.onCancel() end
            return true
        end
    end

    -- Assign button
    if self.assignBtn and self.assignBtn.enabled then
        local btn = self.assignBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            if self.onComplete then
                local citizenIds = {}
                for id, _ in pairs(self.selectedCitizens) do
                    table.insert(citizenIds, id)
                end
                self.onComplete(citizenIds, self.selectedBuilding)
            end
            return true
        end
    end

    return true  -- Consume click
end

function HousingAssignmentModal:HandleMouseMove(screenX, screenY)
    self.hoverCitizen = nil
    self.hoverBuilding = nil

    -- Citizen cards hover
    if self.citizenCards then
        for _, card in ipairs(self.citizenCards) do
            if card and screenX >= card.x and screenX < card.x + card.w and
               screenY >= card.y and screenY < card.y + card.h then
                self.hoverCitizen = card.citizen.id
                break
            end
        end
    end

    -- Building cards hover
    if self.buildingCards then
        for _, card in ipairs(self.buildingCards) do
            if card and screenX >= card.x and screenX < card.x + card.w and
               screenY >= card.y and screenY < card.y + card.h then
                self.hoverBuilding = card.building.id
                break
            end
        end
    end
end

function HousingAssignmentModal:HandleMouseWheel(screenX, screenY, dx, dy)
    -- Citizen list scroll
    if self.citizenListArea then
        local la = self.citizenListArea
        if screenX >= la.x and screenX < la.x + la.w and
           screenY >= la.y and screenY < la.y + la.h then
            self.citizenScroll = math.max(0, math.min(self.citizenMaxScroll, self.citizenScroll - dy * 30))
            return true
        end
    end

    -- Building list scroll
    if self.buildingListArea then
        local la = self.buildingListArea
        if screenX >= la.x and screenX < la.x + la.w and
           screenY >= la.y and screenY < la.y + la.h then
            self.buildingScroll = math.max(0, math.min(self.buildingMaxScroll, self.buildingScroll - dy * 30))
            return true
        end
    end

    return false
end

function HousingAssignmentModal:HandleKeyPress(key)
    if key == "escape" then
        if self.onCancel then self.onCancel() end
        return true
    end
    return false
end

return HousingAssignmentModal
