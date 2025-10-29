--
-- NatureDrawer - right-side drawer showing nature status (river, forest, mines)
--

require("code/CommodityTypes")

NatureDrawer = {}
NatureDrawer.__index = NatureDrawer

function NatureDrawer:Create()
    local this = {
        mIsNatureDrawer = true,  -- Flag to identify this state
        mWidth = 400,
        mPadding = 15,
        mScrollOffset = 0,
        mMaxScroll = 0
    }

    setmetatable(this, self)
    return this
end

function NatureDrawer:Enter()
end

function NatureDrawer:Exit()
end

function NatureDrawer:HandleInput()
    return true  -- Continue processing input
end

function NatureDrawer:Update(dt)
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

function NatureDrawer:OnMouseWheel(dx, dy)
    -- Handle scroll
    local screenW = love.graphics.getWidth()
    local drawerX = screenW - self.mWidth
    local mx, my = love.mouse.getPosition()

    if mx >= drawerX then
        self.mScrollOffset = self.mScrollOffset - dy * 30
        self.mScrollOffset = math.max(0, math.min(self.mScrollOffset, self.mMaxScroll))
    end
end

function NatureDrawer:Render()
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
    love.graphics.print(townName .. " - Nature", drawerX + self.mPadding, topBarHeight + 15)

    -- Get nature data from town
    local river = gTown:GetRiver()
    local forest = gTown:GetForest()
    local mines = gTown:GetMines()
    local mountains = gTown:GetMountains()

    local contentY = topBarHeight + 50
    local y = contentY - self.mScrollOffset
    local lineHeight = 25

    -- Set up scissor for scrollable content
    local contentHeight = screenH - contentY
    love.graphics.setScissor(drawerX, contentY, self.mWidth, contentHeight)

    -- River Status
    if river then
        love.graphics.setColor(0.3, 0.5, 0.8)
        love.graphics.print("River", drawerX + self.mPadding, y)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Status: " .. (river.mFlowStatus or "Unknown"), drawerX + self.mPadding, y + lineHeight)
        y = y + lineHeight * 2 + 10
    end

    -- Forest Status
    if forest then
        love.graphics.setColor(0.2, 0.6, 0.3)
        love.graphics.print("Forest", drawerX + self.mPadding, y)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Status: " .. (forest.mDensityStatus or "Unknown"), drawerX + self.mPadding, y + lineHeight)
        love.graphics.print("Trees: " .. (#forest.mTrees or 0), drawerX + self.mPadding, y + lineHeight * 2)
        y = y + lineHeight * 3 + 10
    end

    -- Mountains Status (show before mines so they're always visible)
    if mountains then
        love.graphics.setColor(0.6, 0.4, 0.5)
        love.graphics.print("Mountains", drawerX + self.mPadding, y)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Total Ranges: " .. #mountains.mRanges, drawerX + self.mPadding, y + lineHeight)
        y = y + lineHeight * 2 + 10

        -- List all mountain ranges and their berries
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Mountain Ranges:", drawerX + self.mPadding, y)
        y = y + lineHeight

        for i, range in ipairs(mountains.mRanges) do
            local berryName = CommodityTypes[range.berry:upper()]
            if berryName and berryName.name then
                berryName = berryName.name
            else
                berryName = range.berry or "Unknown"
            end

            -- Show actual inventory count for this berry to keep in-sync with Inventory
            local invCount = 0
            if gTown and gTown.mInventory and range.berry then
                invCount = gTown.mInventory:Get(range.berry) or 0
            end
            local mountainInfo = string.format("%s - %d berries", berryName, invCount)

            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(i .. ". " .. mountainInfo, drawerX + self.mPadding + 10, y)
            y = y + lineHeight
        end

        y = y + 10  -- Extra spacing after mountains
    end

    -- Mines Status
    if mines then
        love.graphics.setColor(0.7, 0.5, 0.3)
        love.graphics.print("Mines", drawerX + self.mPadding, y)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Status: " .. (mines.mAbundanceStatus or "Unknown"), drawerX + self.mPadding, y + lineHeight)
        love.graphics.print("Total Sites: " .. #mines.mSites, drawerX + self.mPadding, y + lineHeight * 2)
        y = y + lineHeight * 3 + 10

        -- List all mines
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Mine List:", drawerX + self.mPadding, y)
        y = y + lineHeight

        -- Sort mines by size: small (3), medium (5), large (10)
        local sortedMines = {}
        for _, mine in ipairs(mines.mSites) do
            table.insert(sortedMines, mine)
        end
        table.sort(sortedMines, function(a, b)
            local sizeOrder = {small = 1, medium = 2, large = 3}
            local orderA = sizeOrder[a.oreSize] or 0
            local orderB = sizeOrder[b.oreSize] or 0
            return orderA < orderB
        end)

        for i, mine in ipairs(sortedMines) do
            local mineInfo = (mine.oreName or "Unknown") .. " - "
            if mine.oreSize == "large" then
                mineInfo = mineInfo .. "Large (10 units)"
            elseif mine.oreSize == "medium" then
                mineInfo = mineInfo .. "Medium (5 units)"
            elseif mine.oreSize == "small" then
                mineInfo = mineInfo .. "Small (3 units)"
            else
                mineInfo = mineInfo .. "Unknown"
            end

            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(i .. ". " .. mineInfo, drawerX + self.mPadding + 10, y)
            y = y + lineHeight
        end
    end

    -- Calculate max scroll based on content height
    local totalContentHeight = y - (contentY - self.mScrollOffset)
    self.mMaxScroll = math.max(0, totalContentHeight - contentHeight + 20)

    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.mMaxScroll > 0 then
        local scrollbarHeight = contentHeight * (contentHeight / (totalContentHeight + 20))
        local scrollbarY = contentY + (self.mScrollOffset / self.mMaxScroll) * (contentHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", screenW - 8, scrollbarY, 6, scrollbarHeight, 3, 3)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

