--
-- StatsDrawer - right-side drawer showing building statistics by category
--

StatsDrawer = {}
StatsDrawer.__index = StatsDrawer

function StatsDrawer:Create()
    local this = {
        mIsStatsDrawer = true,  -- Flag to identify this state
        mWidth = 400,
        mPadding = 15,
        mScrollOffset = 0,
        mMaxScroll = 0
    }

    setmetatable(this, self)
    return this
end

function StatsDrawer:Enter()
end

function StatsDrawer:Exit()
end

function StatsDrawer:HandleInput()
    return true  -- Continue processing input
end

function StatsDrawer:Update(dt)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local drawerX = screenW - self.mWidth
    local topBarHeight = 50
    local mx, my = love.mouse.getPosition()

    -- Handle close button
    if gMouseReleased and gMouseReleased.button == 1 then
        local closeX = screenW - 35
        local closeY = topBarHeight + 10
        if mx >= closeX and mx <= closeX + 25 and
           my >= closeY and my <= closeY + 25 then
            gStateStack:Pop()
            return false
        end
    end

    return true -- Continue processing input for states below
end

function StatsDrawer:GetBuildingCategoryCounts()
    -- Count buildings by category and type
    local categoryCounts = {}
    local buildingCounts = {}

    if gTown and gTown.mBuildings then
        for _, building in ipairs(gTown.mBuildings) do
            if building.mBuildingType and building.mBuildingType.category then
                local category = building.mBuildingType.category
                local buildingId = building.mTypeId
                local buildingName = building.mName

                -- Count by category
                categoryCounts[category] = (categoryCounts[category] or 0) + 1

                -- Count by building type
                if not buildingCounts[category] then
                    buildingCounts[category] = {}
                end
                if not buildingCounts[category][buildingId] then
                    buildingCounts[category][buildingId] = {
                        name = buildingName,
                        count = 0
                    }
                end
                buildingCounts[category][buildingId].count = buildingCounts[category][buildingId].count + 1
            end
        end
    end

    return categoryCounts, buildingCounts
end

function StatsDrawer:HandleInput()
    return true  -- Continue processing input
end

function StatsDrawer:Render()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local drawerX = screenW - self.mWidth
    local topBarHeight = 50

    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, drawerX, screenH)

    -- Draw drawer background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.98)
    love.graphics.rectangle("fill", drawerX, topBarHeight, self.mWidth, screenH - topBarHeight)

    -- Draw close button
    local closeX = screenW - 35
    local closeY = topBarHeight + 10
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", closeX, closeY, 25, 25, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("X", closeX + 7, closeY + 4)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    local townName = (gTown and gTown.mName) or "Cravetown"
    love.graphics.print(townName .. " - Statistics", drawerX + self.mPadding, topBarHeight + 15)

    -- Get building counts by category
    local categoryCounts, buildingCounts = self:GetBuildingCategoryCounts()

    -- Define category display names
    local categoryNames = {
        residential = "Residential",
        medical = "Medical",
        production = "Production",
        food_processing = "Food Processing",
        service = "Service",
        education = "Education",
        spiritual = "Spiritual",
        infrastructure = "Infrastructure",
        crafting = "Crafting",
        commerce = "Commerce"
    }

    -- Sort categories alphabetically for consistent display
    local sortedCategories = {}
    for category, _ in pairs(categoryNames) do
        table.insert(sortedCategories, category)
    end
    table.sort(sortedCategories)

    local y = topBarHeight + 50
    local lineHeight = 22

    -- Display total buildings
    love.graphics.setColor(0.8, 0.8, 1)
    local totalBuildings = 0
    for _, count in pairs(categoryCounts) do
        totalBuildings = totalBuildings + count
    end
    love.graphics.print("Total Sites: " .. totalBuildings, drawerX + self.mPadding, y)
    y = y + lineHeight * 2

    -- Display each category
    for _, category in ipairs(sortedCategories) do
        local count = categoryCounts[category] or 0
        local displayName = categoryNames[category] or category

        if count > 0 then
            -- Category name in color
            love.graphics.setColor(0.7, 0.9, 0.7)
            love.graphics.print(displayName .. " (" .. count .. "):", drawerX + self.mPadding, y)
            y = y + lineHeight

            -- Display individual building counts within this category
            if buildingCounts[category] then
                for buildingId, buildingInfo in pairs(buildingCounts[category]) do
                    love.graphics.setColor(0.8, 0.8, 0.8)
                    love.graphics.print("  " .. buildingInfo.name .. ": " .. buildingInfo.count,
                        drawerX + self.mPadding + 10, y)
                    y = y + lineHeight
                end
            end

            y = y + 5  -- Extra spacing between categories
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end
