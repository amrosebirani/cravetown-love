--
-- LandRegistryPanel.lua
-- Side panel showing land ownership registry with owner details
--
-- ┌──────────────────────────────────────┐
-- │ LAND REGISTRY                    [X] │
-- ├──────────────────────────────────────┤
-- │ Town Statistics                      │
-- │ ┌──────────────────────────────────┐ │
-- │ │ Total Plots:  768                │ │
-- │ │ Town-owned:   512 (67%)          │ │
-- │ │ Citizen-owned: 256 (33%)         │ │
-- │ │ For Sale:     48                 │ │
-- │ │ Total Value:  76,800 gold        │ │
-- │ └──────────────────────────────────┘ │
-- ├──────────────────────────────────────┤
-- │ Filter: [All ▾] Search: [________]  │
-- ├──────────────────────────────────────┤
-- │ LANDOWNERS                    ▾ Plots│
-- ├──────────────────────────────────────┤
-- │ ┌──────────────────────────────────┐ │
-- │ │ ★ Town of Millbrook              │ │
-- │ │   512 plots | 51,200g value      │ │
-- │ │   [View Plots] [Sell Plot]       │ │
-- │ └──────────────────────────────────┘ │
-- │ ┌──────────────────────────────────┐ │
-- │ │ ◆ Heinrich Mueller (Elite)       │ │
-- │ │   12 plots | 1,800g value        │ │
-- │ │   Rent income: 45g/cycle         │ │
-- │ │   [View Plots] [Transfer]        │ │
-- │ └──────────────────────────────────┘ │
-- │ ┌──────────────────────────────────┐ │
-- │ │ ◆ Maria Schmidt (Upper)          │ │
-- │ │   6 plots | 720g value           │ │
-- │ │   Rent income: 20g/cycle         │ │
-- │ │   [View Plots] [Transfer]        │ │
-- │ └──────────────────────────────────┘ │
-- │                                      │
-- │ ─────── Scroll for more ───────     │
-- │                                      │
-- └──────────────────────────────────────┘
--
-- FEATURES:
--   - Summary statistics at top
--   - Sortable list of all landowners
--   - Filter by owner type (Town/Citizens)
--   - Search by owner name
--   - Drill-down to view specific plots
--   - Quick actions: sell, transfer ownership
--

local LandRegistryPanel = {}
LandRegistryPanel.__index = LandRegistryPanel

function LandRegistryPanel:Create(world, onClose)
    local panel = setmetatable({}, LandRegistryPanel)

    panel.world = world
    panel.onClose = onClose
    panel.visible = false

    -- Panel positioning
    panel.width = 350
    panel.height = 500
    panel.x = 20  -- Left side of screen
    panel.y = 100

    -- UI State
    panel.scrollOffset = 0
    panel.maxScroll = 0
    panel.filterType = "all"  -- "all", "town", "citizens"
    panel.searchText = ""
    panel.sortBy = "plots"  -- "plots", "value", "name"
    panel.sortAsc = false

    -- Cached data
    panel.landowners = {}
    panel.statistics = {
        totalPlots = 0,
        townOwned = 0,
        citizenOwned = 0,
        forSale = 0,
        totalValue = 0
    }

    -- Selected owner for actions
    panel.selectedOwner = nil
    panel.hoverOwner = nil

    -- Fonts
    panel.fonts = {
        title = love.graphics.newFont(16),
        header = love.graphics.newFont(14),
        normal = love.graphics.newFont(12),
        small = love.graphics.newFont(10),
        tiny = love.graphics.newFont(9)
    }

    -- Colors
    panel.colors = {
        background = {0.1, 0.1, 0.12, 0.95},
        headerBg = {0.15, 0.15, 0.18},
        cardBg = {0.12, 0.14, 0.16},
        cardHover = {0.18, 0.20, 0.24},
        cardSelected = {0.2, 0.25, 0.3},
        border = {0.3, 0.35, 0.4},
        text = {1, 1, 1},
        textDim = {0.7, 0.7, 0.7},
        textMuted = {0.5, 0.5, 0.5},
        accent = {0.4, 0.7, 1.0},
        gold = {0.98, 0.85, 0.37},
        success = {0.4, 0.8, 0.4},
        warning = {1.0, 0.7, 0.3},
        town = {0.29, 0.56, 0.85},
        citizen = {0.32, 0.77, 0.10},
        button = {0.25, 0.28, 0.32},
        buttonHover = {0.35, 0.38, 0.42},
    }

    return panel
end

function LandRegistryPanel:Show()
    self.visible = true
    self:RefreshData()
end

function LandRegistryPanel:Hide()
    self.visible = false
    if self.onClose then self.onClose() end
end

function LandRegistryPanel:Toggle()
    if self.visible then
        self:Hide()
    else
        self:Show()
    end
end

function LandRegistryPanel:IsVisible()
    return self.visible
end

-- Helper to check if an owner ID represents the town
local function isTownOwner(ownerId)
    return ownerId == nil or ownerId == "TOWN" or ownerId == "town" or ownerId == 0
end

function LandRegistryPanel:RefreshData()
    local landSystem = self.world.landSystem
    if not landSystem then return end

    -- Reset statistics
    self.statistics = {
        totalPlots = 0,
        townOwned = 0,
        citizenOwned = 0,
        forSale = 0,
        totalValue = 0
    }

    -- Build landowner index
    local ownerData = {}  -- ownerId -> {plots=[], totalValue=0}

    for plotId, plot in pairs(landSystem.plots or {}) do
        self.statistics.totalPlots = self.statistics.totalPlots + 1

        if plot.isBlocked then
            -- Don't count blocked plots
        else
            local price = plot.purchasePrice or 100
            self.statistics.totalValue = self.statistics.totalValue + price

            local ownerId = plot.ownerId
            local isTown = isTownOwner(ownerId)

            if isTown then
                self.statistics.townOwned = self.statistics.townOwned + 1
                ownerId = "TOWN"  -- Normalize to single town ID
            else
                self.statistics.citizenOwned = self.statistics.citizenOwned + 1
            end

            if plot.forSale then
                self.statistics.forSale = self.statistics.forSale + 1
            end

            -- Track per-owner (skip town from landowners list - shown in stats)
            if not isTown then
                if not ownerData[ownerId] then
                    ownerData[ownerId] = {
                        ownerId = ownerId,
                        plots = {},
                        totalValue = 0,
                        rentIncome = 0
                    }
                end
                table.insert(ownerData[ownerId].plots, plot)
                ownerData[ownerId].totalValue = ownerData[ownerId].totalValue + price
            end
        end
    end

    -- Convert to array and add owner info (citizens only, town shown in stats)
    self.landowners = {}
    for ownerId, data in pairs(ownerData) do
        local owner = {
            id = ownerId,
            plotCount = #data.plots,
            totalValue = data.totalValue,
            rentIncome = data.rentIncome,
            plots = data.plots
        }

        -- Get citizen data (citizens are stored in an array, not a dictionary)
        local citizen = nil
        -- First try citizensById if available
        if self.world.citizensById and self.world.citizensById[ownerId] then
            citizen = self.world.citizensById[ownerId]
        else
            -- Otherwise search the citizens array
            for _, c in ipairs(self.world.citizens or {}) do
                if c.id == ownerId then
                    citizen = c
                    break
                end
            end
        end

        if citizen then
            owner.name = citizen.name or ("Citizen #" .. ownerId)
            owner.class = citizen.emergentClass or citizen.class
        else
            owner.name = "Citizen #" .. ownerId
            owner.class = nil
        end
        owner.type = "citizen"

        -- Calculate rent income from buildings on their land
        -- (Simplified - would need building system integration)
        owner.rentIncome = math.floor(owner.plotCount * 3)  -- Placeholder

        table.insert(self.landowners, owner)
    end

    -- Apply sorting
    self:SortLandowners()
end

function LandRegistryPanel:SortLandowners()
    local sortKey = self.sortBy
    local ascending = self.sortAsc

    table.sort(self.landowners, function(a, b)
        local valA, valB
        if sortKey == "plots" then
            valA, valB = a.plotCount, b.plotCount
        elseif sortKey == "value" then
            valA, valB = a.totalValue, b.totalValue
        elseif sortKey == "name" then
            valA, valB = a.name:lower(), b.name:lower()
        else
            valA, valB = a.plotCount, b.plotCount
        end

        if ascending then
            return valA < valB
        else
            return valA > valB
        end
    end)
end

function LandRegistryPanel:GetFilteredLandowners()
    local result = {}
    local searchLower = self.searchText:lower()

    for _, owner in ipairs(self.landowners) do
        local matchesSearch = searchLower == "" or
                             owner.name:lower():find(searchLower, 1, true)

        if matchesSearch then
            table.insert(result, owner)
        end
    end

    return result
end

function LandRegistryPanel:Update(dt)
    -- Could add animations here
end

function LandRegistryPanel:Render()
    if not self.visible then return end

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

    -- Statistics section
    local statsY = y + 45
    self:RenderStatistics(x + 10, statsY, w - 20)

    -- Filter/search bar
    local filterY = statsY + 95
    self:RenderFilterBar(x + 10, filterY, w - 20)

    -- Landowners list
    local listY = filterY + 35
    local listH = h - (listY - y) - 15
    self:RenderLandownersList(x + 10, listY, w - 20, listH)

    love.graphics.setColor(1, 1, 1, 1)
end

function LandRegistryPanel:RenderHeader(x, y, w)
    -- Header background
    love.graphics.setColor(self.colors.headerBg)
    love.graphics.rectangle("fill", x, y, w, 40, 6, 6)
    love.graphics.rectangle("fill", x, y + 30, w, 10)  -- Square bottom corners

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("LAND REGISTRY", x + 15, y + 10)

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

function LandRegistryPanel:RenderStatistics(x, y, w)
    -- Stats box background
    love.graphics.setColor(self.colors.cardBg)
    love.graphics.rectangle("fill", x, y, w, 85, 4, 4)

    -- Stats title
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Town Statistics", x + 8, y + 5)

    -- Stats content
    local statY = y + 22
    local col1X = x + 10
    local col2X = x + w/2 + 10

    love.graphics.setFont(self.fonts.normal)

    -- Row 1
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Total Plots:", col1X, statY)
    love.graphics.print(tostring(self.statistics.totalPlots), col1X + 85, statY)

    love.graphics.setColor(self.colors.town)
    love.graphics.print("Town-owned:", col2X, statY)
    local townPct = self.statistics.totalPlots > 0 and
                   math.floor(self.statistics.townOwned / self.statistics.totalPlots * 100) or 0
    love.graphics.print(string.format("%d (%d%%)", self.statistics.townOwned, townPct), col2X + 85, statY)

    -- Row 2
    statY = statY + 18
    love.graphics.setColor(self.colors.citizen)
    love.graphics.print("Citizen-owned:", col1X, statY)
    local citPct = self.statistics.totalPlots > 0 and
                  math.floor(self.statistics.citizenOwned / self.statistics.totalPlots * 100) or 0
    love.graphics.print(string.format("%d (%d%%)", self.statistics.citizenOwned, citPct), col1X + 95, statY)

    love.graphics.setColor(self.colors.warning)
    love.graphics.print("For Sale:", col2X, statY)
    love.graphics.print(tostring(self.statistics.forSale), col2X + 85, statY)

    -- Row 3
    statY = statY + 18
    love.graphics.setColor(self.colors.gold)
    love.graphics.print("Total Value:", col1X, statY)
    love.graphics.print(string.format("%s gold", self:FormatNumber(self.statistics.totalValue)), col1X + 85, statY)
end

function LandRegistryPanel:RenderFilterBar(x, y, w)
    -- Sort label
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Sort by:", x, y + 4)

    -- Sort button
    local sortBtnX = x + 50
    love.graphics.setColor(self.colors.button)
    love.graphics.rectangle("fill", sortBtnX, y, 80, 22, 3, 3)
    love.graphics.setColor(self.colors.text)

    local sortText = self.sortBy == "plots" and "Plots" or
                    self.sortBy == "value" and "Value" or "Name"
    local arrow = self.sortAsc and "↑" or "↓"
    love.graphics.print(sortText .. " " .. arrow, sortBtnX + 8, y + 4)
    self.sortBtn = {x = sortBtnX, y = y, w = 80, h = 22}

    -- Refresh button
    local refreshX = x + w - 25
    love.graphics.setColor(self.colors.button)
    love.graphics.rectangle("fill", refreshX, y, 24, 22, 3, 3)
    love.graphics.setColor(self.colors.accent)
    love.graphics.print("↻", refreshX + 6, y + 3)
    self.refreshBtn = {x = refreshX, y = y, w = 24, h = 22}
end

function LandRegistryPanel:RenderLandownersList(x, y, w, h)
    -- List header
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("CITIZEN LANDOWNERS", x, y)

    -- Clip region for scrolling
    local listY = y + 18
    local listH = h - 18
    love.graphics.setScissor(x, listY, w, listH)

    local filteredOwners = self:GetFilteredLandowners()
    local cardH = 65
    local spacing = 8

    self.ownerCards = {}

    for i, owner in ipairs(filteredOwners) do
        local cardY = listY + (i - 1) * (cardH + spacing) - self.scrollOffset

        -- Skip if off-screen
        if cardY + cardH < listY or cardY > y + h then
            goto continue
        end

        local isHovered = self.hoverOwner == owner.id
        local isSelected = self.selectedOwner == owner.id

        -- Card background
        if isSelected then
            love.graphics.setColor(self.colors.cardSelected)
        elseif isHovered then
            love.graphics.setColor(self.colors.cardHover)
        else
            love.graphics.setColor(self.colors.cardBg)
        end
        love.graphics.rectangle("fill", x, cardY, w, cardH, 4, 4)

        -- Owner icon (citizen)
        love.graphics.setColor(self.colors.citizen)
        love.graphics.setFont(self.fonts.header)
        love.graphics.print("◆", x + 8, cardY + 6)

        -- Owner name and class
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.text)
        local nameText = owner.name
        if owner.class then
            nameText = nameText .. " (" .. owner.class .. ")"
        end
        love.graphics.print(nameText, x + 25, cardY + 6)

        -- Plot count and value
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(string.format("%d plots | %s value",
            owner.plotCount, self:FormatNumber(owner.totalValue) .. "g"), x + 25, cardY + 25)

        -- Rent income
        if owner.rentIncome > 0 then
            love.graphics.setColor(self.colors.gold)
            love.graphics.print(string.format("Rent income: %dg/cycle", owner.rentIncome), x + 25, cardY + 40)
        end

        -- Store card bounds
        self.ownerCards[i] = {x = x, y = cardY, w = w, h = cardH, owner = owner}

        ::continue::
    end

    -- Calculate max scroll
    local totalHeight = #filteredOwners * (cardH + spacing)
    self.maxScroll = math.max(0, totalHeight - listH)

    love.graphics.setScissor()

    -- Scroll indicator
    if self.maxScroll > 0 then
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("─── Scroll for more ───", x + w/2 - 50, y + h - 12)
    end

    -- Store list bounds for scroll detection
    self.listArea = {x = x, y = listY, w = w, h = listH}
end

function LandRegistryPanel:FormatNumber(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(n)
    end
end

function LandRegistryPanel:HandleClick(screenX, screenY, button)
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

    -- Sort button
    if self.sortBtn then
        local btn = self.sortBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            -- Cycle through sort options or toggle direction
            if self.sortBy == "plots" then
                self.sortBy = "value"
            elseif self.sortBy == "value" then
                self.sortBy = "name"
            else
                self.sortBy = "plots"
            end
            self:SortLandowners()
            return true
        end
    end

    -- Refresh button
    if self.refreshBtn then
        local btn = self.refreshBtn
        if screenX >= btn.x and screenX < btn.x + btn.w and
           screenY >= btn.y and screenY < btn.y + btn.h then
            self:RefreshData()
            return true
        end
    end

    -- Owner cards
    if self.ownerCards then
        for _, card in ipairs(self.ownerCards) do
            if card and screenX >= card.x and screenX < card.x + card.w and
               screenY >= card.y and screenY < card.y + card.h then
                self.selectedOwner = card.owner.id
                -- Could trigger drill-down view here
                return true
            end
        end
    end

    return true  -- Consume click within panel
end

function LandRegistryPanel:HandleMouseMove(screenX, screenY)
    if not self.visible then return end

    self.hoverOwner = nil

    -- Update hover state for owner cards
    if self.ownerCards then
        for _, card in ipairs(self.ownerCards) do
            if card and screenX >= card.x and screenX < card.x + card.w and
               screenY >= card.y and screenY < card.y + card.h then
                self.hoverOwner = card.owner.id
                break
            end
        end
    end
end

function LandRegistryPanel:HandleMouseWheel(screenX, screenY, dx, dy)
    if not self.visible then return false end

    -- Check if within list area
    if self.listArea then
        local la = self.listArea
        if screenX >= la.x and screenX < la.x + la.w and
           screenY >= la.y and screenY < la.y + la.h then
            self.scrollOffset = math.max(0, math.min(self.maxScroll, self.scrollOffset - dy * 30))
            return true
        end
    end

    return false
end

function LandRegistryPanel:HandleKeyPress(key)
    if not self.visible then return false end

    if key == "escape" then
        self:Hide()
        return true
    end

    return false
end

return LandRegistryPanel
