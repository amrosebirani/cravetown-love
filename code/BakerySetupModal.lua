--
-- BakerySetupModal - configure bakery to fetch wheat and start bread production
--

BakerySetupModal = {}
BakerySetupModal.__index = BakerySetupModal

function BakerySetupModal:Create(building)
    local this = {
        mIsBakerySetupModal = true,
        mBuilding = building,
        mStep = "confirm", -- "confirm", "amount", or alert steps
        mModalWidth = 520,
        mModalHeight = 300,
        mSelectedBreadUnits = 0,
        mMaxBreadUnits = 0,
        mAlertMessage = nil
    }

    setmetatable(this, self)

    -- Guard: ensure there is at least one farm producing wheat
    local function hasWheatFarm()
        if not gTown or not gTown.mBuildings then return false end
        for _, b in ipairs(gTown.mBuildings) do
            if b.mTypeId == "farm" and b.mProducedGrain == "wheat" then
                return true
            end
        end
        return false
    end

    if not hasWheatFarm() then
        this.mStep = "alert_no_farm"
        this.mAlertMessage = "No wheat farm found. Place a farm and select Wheat first."
        return this
    end

    -- Compute max bread units from available wheat (5 wheat per bread)
    local availableWheat = 0
    if gTown and gTown.mInventory then
        availableWheat = gTown.mInventory:Get("wheat") or 0
    end
    this.mMaxBreadUnits = math.floor((availableWheat or 0) / (building.mBakery.wheatPerBread or 5))
    if this.mMaxBreadUnits < 0 then this.mMaxBreadUnits = 0 end

    return this
end

function BakerySetupModal:Enter() end
function BakerySetupModal:Exit() end

function BakerySetupModal:HandleInput()
    return true
end

function BakerySetupModal:Update(dt)
    local mx, my = love.mouse.getPosition()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    if gMouseReleased and gMouseReleased.button == 1 then
        local x = gMouseReleased.x
        local y = gMouseReleased.y

        if self.mStep == "alert_no_farm" or self.mStep == "alert_no_wheat" then
            -- Single OK button anywhere on panel closes
            gStateStack:Pop()
            return false
        elseif self.mStep == "confirm" then
            -- Yes button
            local yesX, yesY, yesW, yesH = modalX + 80, modalY + 200, 140, 40
            if x >= yesX and x <= yesX + yesW and y >= yesY and y <= yesY + yesH then
                -- If no wheat available, alert
                if self.mMaxBreadUnits <= 0 then
                    self.mStep = "alert_no_wheat"
                    self.mAlertMessage = "No wheat available in inventory."
                else
                    self.mStep = "amount"
                end
                return false
            end

            -- Cancel button
            local cancelX, cancelY, cancelW, cancelH = modalX + 300, modalY + 200, 140, 40
            if x >= cancelX and x <= cancelX + cancelW and y >= cancelY and y <= cancelY + cancelH then
                gStateStack:Pop()
                return false
            end
        else
            -- Amount step controls
            local minus5 = {x = modalX + 40, y = modalY + 170, w = 50, h = 40}
            local minus1 = {x = modalX + 100, y = modalY + 170, w = 50, h = 40}
            local plus1  = {x = modalX + 370, y = modalY + 170, w = 50, h = 40}
            local plus5  = {x = modalX + 430, y = modalY + 170, w = 50, h = 40}
            local start  = {x = modalX + 180, y = modalY + 230, w = 160, h = 40}
            local back   = {x = modalX + 20, y = modalY + 20, w = 80, h = 30}

            local function inside(btn) return x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h end

            if inside(back) then
                self.mStep = "confirm"
                return false
            end

            if inside(minus5) then
                self.mSelectedBreadUnits = math.max(0, self.mSelectedBreadUnits - 5)
                return false
            end
            if inside(minus1) then
                self.mSelectedBreadUnits = math.max(0, self.mSelectedBreadUnits - 1)
                return false
            end
            if inside(plus1) then
                self.mSelectedBreadUnits = math.min(self.mMaxBreadUnits, self.mSelectedBreadUnits + 1)
                return false
            end
            if inside(plus5) then
                self.mSelectedBreadUnits = math.min(self.mMaxBreadUnits, self.mSelectedBreadUnits + 5)
                return false
            end
            if inside(start) then
                if self.mBuilding and self.mSelectedBreadUnits > 0 then
                    -- Reserve wheat and begin production
                    if self.mBuilding:ReserveWheatForBakery(self.mSelectedBreadUnits) then
                        self.mBuilding:BeginBakeryProduction(self.mSelectedBreadUnits)
                        gStateStack:Pop()
                    else
                        -- Not enough wheat; do nothing or show feedback
                    end
                end
                return false
            end
        end
    end

    return true
end

function BakerySetupModal:Render()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel
    love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", modalX, modalY, self.mModalWidth, self.mModalHeight, 10, 10)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, self.mModalWidth, self.mModalHeight, 10, 10)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1)
    local title = "Bakery Setup"
    love.graphics.print(title, modalX + 20, modalY + 15)

    if self.mStep == "alert_no_farm" or self.mStep == "alert_no_wheat" then
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(self.mAlertMessage or "Alert", modalX + 20, modalY + 80)

        local function drawBtn(x, y, w, h, label, color)
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", x, y, w, h, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(label, x + 10, y + 10)
        end
        drawBtn(modalX + (self.mModalWidth - 120) / 2, modalY + 200, 120, 40, "OK", {0.3, 0.3, 0.3})
    elseif self.mStep == "confirm" then
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print("Get wheat from farmer?", modalX + 20, modalY + 60)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Recipe: 5 wheat -> 1 bread", modalX + 20, modalY + 90)

        local availableWheat = 0
        if gTown and gTown.mInventory then
            availableWheat = gTown.mInventory:Get("wheat") or 0
        end
        love.graphics.print("Available wheat: " .. tostring(availableWheat), modalX + 20, modalY + 120)

        -- Buttons
        local function drawBtn(x, y, w, h, label, color)
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", x, y, w, h, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(label, x + 10, y + 10)
        end

        drawBtn(modalX + 80, modalY + 200, 140, 40, "Yes", {0.3, 0.6, 0.3})
        drawBtn(modalX + 300, modalY + 200, 140, 40, "Cancel", {0.6, 0.3, 0.3})
    else
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print("Select bread units to produce", modalX + 20, modalY + 60)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Max: " .. tostring(self.mMaxBreadUnits) .. " (5 wheat each)", modalX + 20, modalY + 90)

        local function drawBtn(x, y, w, h, label)
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", x, y, w, h, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(label, x + 10, y + 10)
        end

        -- Back
        drawBtn(modalX + 20, modalY + 20, 80, 30, "Back")

        -- Amount controls
        drawBtn(modalX + 40, modalY + 170, 50, 40, "-5")
        drawBtn(modalX + 100, modalY + 170, 50, 40, "-1")
        drawBtn(modalX + 370, modalY + 170, 50, 40, "+1")
        drawBtn(modalX + 430, modalY + 170, 50, 40, "+5")

        -- Current selection
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Bread units: " .. tostring(self.mSelectedBreadUnits), modalX + 210, modalY + 140)

        -- Start button (disabled if 0)
        if self.mSelectedBreadUnits > 0 then
            love.graphics.setColor(0.3, 0.6, 0.3)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end
        love.graphics.rectangle("fill", modalX + 180, modalY + 230, 160, 40, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Start Production", modalX + 190, modalY + 240)
    end

    love.graphics.setColor(1, 1, 1)
end

return BakerySetupModal


