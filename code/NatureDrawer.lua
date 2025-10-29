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
    love.graphics.print("Nature Status", drawerX + self.mPadding, topBarHeight + 15)

    -- Get nature data from town
    local river = gTown:GetRiver()
    local forest = gTown:GetForest()
    local mines = gTown:GetMines()

    local y = topBarHeight + 50
    local lineHeight = 25

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
        
        for i, mine in ipairs(mines.mSites) do
            if y < screenH - 50 then  -- Don't draw off screen
                local mineInfo = (mine.oreName or "Unknown") .. " - "
                if mine.size <= 35 then
                    mineInfo = mineInfo .. "Small"
                elseif mine.size <= 40 then
                    mineInfo = mineInfo .. "Medium"
                else
                    mineInfo = mineInfo .. "Large"
                end
                
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.print(i .. ". " .. mineInfo, drawerX + self.mPadding + 10, y)
                y = y + lineHeight
            end
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

