--
-- Building - represents a building in the town
--

require("code/BuildingTypes")

Building = {}
Building.__index = Building

function Building:Create(params)
    -- Get building type definition
    local buildingType = params.buildingType or BuildingTypes.FAMILY_HOME

    -- Deep copy properties
    local properties = {}
    if buildingType.properties then
        for k, v in pairs(buildingType.properties) do
            if type(v) == "table" then
                properties[k] = {}
                for k2, v2 in pairs(v) do
                    properties[k][k2] = v2
                end
            else
                properties[k] = v
            end
        end
    end

    local this = {
        mBuildingType = buildingType,
        mTypeId = buildingType.id,
        mName = buildingType.name,
        mCategory = buildingType.category,
        mX = params.x or 0,
        mY = params.y or 0,
        mWidth = params.width or buildingType.baseWidth,
        mHeight = params.height or buildingType.baseHeight,
        mColor = params.color or buildingType.color,
        mTextColor = {1, 1, 1},
        mLabel = params.label or buildingType.label,
        mPlaced = params.placed or false,
        mProperties = properties,
        mWorkers = {},  -- Array of worker IDs assigned to this building
        mAutoAssignWorkers = true,
        -- Production system
        mProductionTimer = 0,  -- Time elapsed since last production
        mFirstProduction = true,  -- Flag for first production cycle
        mPlacementTime = 0,  -- Time when building was placed
        mProducedGrain = nil,  -- For farms: which grain is produced (wheat, barley, etc.)
        -- Bakery production
        mBakery = {
            wheatPerBread = 5,
            wheatReserved = 0,
            breadQueued = 0,
            breadProduced = 0,
            intervalSec = 120,  -- 2 minutes per bread
            timer = 0,
            active = false
        },
        mProductionNotifications = {}  -- Visual notifications for production
    }

    setmetatable(this, self)
    return this
end

function Building:SetPosition(x, y)
    self.mX = x
    self.mY = y
end

function Building:GetPosition()
    return self.mX, self.mY
end

function Building:GetBounds()
    return self.mX, self.mY, self.mWidth, self.mHeight
end

function Building:SetPlaced(placed)
    self.mPlaced = placed
    if placed then
        self.mPlacementTime = love.timer.getTime()
        self.mProductionTimer = 0
        self.mFirstProduction = true
    end
end

function Building:IsPlaced()
    return self.mPlaced
end

function Building:CheckCollision(other)
    local x1, y1, w1, h1 = self:GetBounds()
    local x2, y2, w2, h2 = other:GetBounds()

    -- AABB collision detection
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

function Building:GetProperty(key)
    return self.mProperties[key]
end

function Building:SetProperty(key, value)
    self.mProperties[key] = value
end

function Building:GetAllProperties()
    return self.mProperties
end

function Building:Update(dt)
    -- Only produce if building is placed
    if not self.mPlaced then
        return
    end

    -- Handle production based on building type
    if self.mTypeId == "farm" then
        self:UpdateFarmProduction(dt)
    elseif self.mTypeId == "bakery" then
        self:UpdateBakeryProduction(dt)
    end

    -- Update production notifications
    for i = #self.mProductionNotifications, 1, -1 do
        local notif = self.mProductionNotifications[i]
        notif.timer = notif.timer - dt
        notif.y = notif.y - 30 * dt  -- Float upwards

        if notif.timer <= 0 then
            table.remove(self.mProductionNotifications, i)
        end
    end
end

function Building:BeginBakeryProduction(breadUnits)
    -- breadUnits is how many bread outputs to produce; assumes wheat already reserved in inventory
    if breadUnits and breadUnits > 0 then
        self.mBakery.breadQueued = self.mBakery.breadQueued + breadUnits
        self.mBakery.active = true
    end
end

function Building:CancelBakeryProduction()
    -- Return reserved wheat if any remained unused
    local unusedBread = self.mBakery.breadQueued
    if unusedBread and unusedBread > 0 and self.mBakery.wheatReserved >= unusedBread * self.mBakery.wheatPerBread then
        if gTown and gTown.mInventory then
            gTown.mInventory:Add("wheat", unusedBread * self.mBakery.wheatPerBread)
        end
    end
    self.mBakery.wheatReserved = 0
    self.mBakery.breadQueued = 0
    self.mBakery.timer = 0
    self.mBakery.active = false
end

function Building:ReserveWheatForBakery(breadUnits)
    local needed = (breadUnits or 0) * self.mBakery.wheatPerBread
    if needed <= 0 then return false end
    if gTown and gTown.mInventory and gTown.mInventory:Has("wheat", needed) then
        gTown.mInventory:Remove("wheat", needed)
        self.mBakery.wheatReserved = self.mBakery.wheatReserved + needed
        return true
    end
    return false
end

function Building:UpdateBakeryProduction(dt)
    if not self.mPlaced then return end
    if not self.mBakery.active or self.mBakery.breadQueued <= 0 then return end

    self.mBakery.timer = self.mBakery.timer + dt
    if self.mBakery.timer >= self.mBakery.intervalSec then
        self.mBakery.timer = self.mBakery.timer - self.mBakery.intervalSec
        -- consume wheat for one bread if still reserved
        if self.mBakery.wheatReserved >= self.mBakery.wheatPerBread then
            self.mBakery.wheatReserved = self.mBakery.wheatReserved - self.mBakery.wheatPerBread
            self.mBakery.breadQueued = self.mBakery.breadQueued - 1
            self.mBakery.breadProduced = self.mBakery.breadProduced + 1
            if gTown and gTown.mInventory then
                gTown.mInventory:Add("bread", 1)
            end
            self:PlayProductionSound()
            self:AddProductionNotification("+1 bread")
        else
            -- no more wheat; stop production and notify
            self:AddProductionNotification("No wheat")
            self.mBakery.active = false
            self.mBakery.breadQueued = 0
        end
    end

    if self.mBakery.breadQueued <= 0 then
        self.mBakery.active = false
    end
end

function Building:UpdateFarmProduction(dt)
    -- Farm production logic:
    -- First production: after 1 minute (60 seconds)
    -- Subsequent production: every 5 minutes (300 seconds)
    -- Produces: 1 unit of selected grain

    -- Don't produce if no grain has been selected yet
    if not self.mProducedGrain then
        return
    end

    self.mProductionTimer = self.mProductionTimer + dt

    local productionInterval = self.mFirstProduction and 60 or 300  -- 60s for first, 300s for subsequent

    if self.mProductionTimer >= productionInterval then
        -- Produce 1 unit of selected grain
        if gTown and gTown.mInventory then
            gTown.mInventory:Add(self.mProducedGrain, 1)
            print("Farm produced 1 " .. self.mProducedGrain .. "! (Total time: " .. math.floor(self.mProductionTimer) .. "s)")
        end

        -- Play production sound
        self:PlayProductionSound()

        -- Add visual notification
        self:AddProductionNotification("+1")

        -- Reset timer and mark first production as done
        self.mProductionTimer = self.mProductionTimer - productionInterval
        self.mFirstProduction = false
    end
end

function Building:PlayProductionSound()
    -- Create a simple beep sound programmatically
    local sampleRate = 44100
    local frequency = 440  -- A4 note
    local duration = 0.2
    local samples = math.floor(sampleRate * duration)

    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        local value = math.sin(2 * math.pi * frequency * t) * 0.3
        soundData:setSample(i, value)
    end

    local source = love.audio.newSource(soundData)
    source:play()
end

function Building:AddProductionNotification(text)
    -- Add floating notification above the building
    table.insert(self.mProductionNotifications, {
        text = text,
        x = self.mX + self.mWidth / 2,
        y = self.mY - 10,
        timer = 1.5,  -- Display for 1.5 seconds
        alpha = 1.0
    })
end

function Building:GetProductionInfo()
    -- Return production information for farms
    if self.mTypeId == "farm" then
        if not self.mProducedGrain then
            return "No grain selected"
        end

        local productionInterval = self.mFirstProduction and 60 or 300
        local timeRemaining = productionInterval - self.mProductionTimer
        local minutes = math.floor(timeRemaining / 60)
        local seconds = math.floor(timeRemaining % 60)

        local grainName = self.mProducedGrain:gsub("_", " ")
        grainName = grainName:sub(1,1):upper() .. grainName:sub(2)

        return string.format("Produces: %s\nNext in: %dm %ds\n%s production",
            grainName,
            minutes,
            seconds,
            self.mFirstProduction and "First" or "Regular")
    elseif self.mTypeId == "bakery" then
        local queued = self.mBakery.breadQueued or 0
        if queued <= 0 then
            return "No active order"
        end
        local timeRemaining = self.mBakery.intervalSec - (self.mBakery.timer or 0)
        local minutes = math.floor(timeRemaining / 60)
        local seconds = math.floor(timeRemaining % 60)
        return string.format("Produces: Bread\nQueued: %d\nNext in: %dm %ds", queued, minutes, seconds)
    end

    return nil
end

function Building:IsMouseOver(mx, my)
    -- Check if mouse is over this building (in world coordinates)
    return mx >= self.mX and mx <= self.mX + self.mWidth and
           my >= self.mY and my <= self.mY + self.mHeight
end

function Building:Render(canPlace)
    -- If canPlace is false, show red tinge
    if canPlace == false then
        love.graphics.setColor(0.8, 0.2, 0.2, 0.7) -- Red with transparency
    else
        love.graphics.setColor(self.mColor[1], self.mColor[2], self.mColor[3])
    end

    -- Draw the building box
    love.graphics.rectangle("fill", self.mX, self.mY, self.mWidth, self.mHeight)

    -- Draw border
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.mX, self.mY, self.mWidth, self.mHeight)

    -- Draw label in center
    love.graphics.setColor(self.mTextColor[1], self.mTextColor[2], self.mTextColor[3])
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(self.mLabel)
    local textHeight = font:getHeight()
    love.graphics.print(
        self.mLabel,
        self.mX + self.mWidth / 2 - textWidth / 2,
        self.mY + self.mHeight / 2 - textHeight / 2
    )

    -- Draw production notifications
    for _, notif in ipairs(self.mProductionNotifications) do
        local alpha = notif.timer / 1.5  -- Fade out over time
        love.graphics.setColor(0.2, 1, 0.2, alpha)  -- Green with fading alpha
        local notifFont = love.graphics.getFont()
        local notifTextWidth = notifFont:getWidth(notif.text)
        love.graphics.print(notif.text, notif.x - notifTextWidth / 2, notif.y)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end
