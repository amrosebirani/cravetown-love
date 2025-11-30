-- ConsumptionPrototype.lua
-- Consumption prototype with proper 3-panel layout following design document

ConsumptionPrototype = {}
ConsumptionPrototype.__index = ConsumptionPrototype

-- Import subsystems (Phase 5 - V2 systems)
local CharacterV2 = require("code.consumption.CharacterV2")
local AllocationEngineV2 = require("code.consumption.AllocationEngineV2")
local CommodityCache = require("code.consumption.CommodityCache")
local TownConsequences = require("code.consumption.TownConsequences")
local DataLoader = require("code.DataLoader")

function ConsumptionPrototype:Create()
    local prototype = setmetatable({}, ConsumptionPrototype)

    -- Load data files
    prototype:LoadData()

    -- Initialize Phase 5 V2 subsystems
    CharacterV2.Init(
        prototype.consumptionMechanics,
        prototype.fulfillmentVectors,
        prototype.characterTraits,
        prototype.characterClasses,
        prototype.dimensionDefinitions,
        prototype.commodityFatigueRates,
        prototype.enablementRules
    )
    CommodityCache.Init(prototype.fulfillmentVectors, prototype.dimensionDefinitions, prototype.substitutionRules, CharacterV2)
    AllocationEngineV2.Init(prototype.consumptionMechanics, prototype.fulfillmentVectors, prototype.substitutionRules, CharacterV2, CommodityCache)
    TownConsequences.Init(prototype.consumptionMechanics)

    -- Simulation state
    prototype.cycleNumber = 0
    prototype.cycleTime = 0
    prototype.cycleDuration = 60  -- 60 seconds per cycle
    prototype.isPaused = true  -- Start paused
    prototype.simulationSpeed = 1.0  -- 1x, 2x, 5x, 10x
    prototype.characters = {}  -- Start empty, user adds manually
    prototype.townInventory = {}
    prototype.allocationHistory = {}

    -- UI state
    prototype.currentView = "grid"  -- grid/heatmap/log
    prototype.selectedCharacter = nil
    prototype.showCharacterCreator = false
    prototype.showResourceInjector = false
    prototype.showInventoryModal = false
    prototype.inventoryScrollOffset = 0
    prototype.inventoryCategoryScrollOffset = 0
    prototype.selectedInventoryCategory = nil  -- nil = "All"

    -- Heatmap modal state
    prototype.showHeatmapModal = false
    prototype.heatmapType = nil  -- "base_cravings", "current_cravings", "satisfaction"
    prototype.heatmapLevel = "coarse"  -- "coarse" or "fine"
    prototype.heatmapScrollOffset = 0
    prototype.heatmapScrollMax = 0

    -- Character detail modal state
    prototype.showCharacterDetailModal = false
    prototype.detailCharacter = nil  -- The character being viewed in detail
    prototype.detailScrollOffset = 0
    prototype.detailScrollMax = 0

    -- Character creator state
    prototype.creatorName = ""
    prototype.creatorClass = "Middle"
    prototype.creatorTraits = {}
    prototype.creatorAge = 30
    prototype.creatorVocation = nil  -- nil = random
    prototype.creatorVocationScrollOffset = 0

    -- Resource injector state (new design with categories and rates)
    -- Note: prototype.commodities is set by LoadData()
    prototype.injectionRates = {}  -- {commodityId: rate per minute}
    prototype.injectionAccumulator = 0  -- Time accumulator for injection
    prototype.selectedInjectorCategory = nil  -- nil = "All"
    prototype.injectorCategoryScrollOffset = 0
    prototype.injectorCommodityScrollOffset = 0

    -- Panel dimensions
    prototype.leftPanelWidth = 250
    prototype.rightPanelWidth = 350
    prototype.topBarHeight = 60

    -- Statistics
    prototype.stats = {
        totalCycles = 0,
        totalAllocations = 0,
        totalEmigrations = 0,
        totalRiots = 0,
        averageSatisfaction = 0,
        productivityMultiplier = 1.0
    }

    -- Event log
    prototype.eventLog = {}  -- Array of {time, type, message, details}
    prototype.eventLogScrollOffset = 0
    prototype.maxEventLogEntries = 100  -- Keep last 100 events

    -- Initialize with empty inventory (user will inject)
    prototype:InitializeInventory()

    print("ConsumptionPrototype initialized (empty, ready for manual character creation)")

    return prototype
end

function ConsumptionPrototype:LoadData()
    self.consumptionMechanics = DataLoader.loadJSON("data/" .. DataLoader.activeVersion .. "/consumption_mechanics.json")
    self.fulfillmentVectors = DataLoader.loadJSON("data/" .. DataLoader.activeVersion .. "/craving_system/fulfillment_vectors.json")
    self.substitutionRules = DataLoader.loadJSON("data/" .. DataLoader.activeVersion .. "/substitution_rules.json")
    self.dimensionDefinitions = DataLoader.loadJSON("data/" .. DataLoader.activeVersion .. "/craving_system/dimension_definitions.json")
    self.characterTraits = DataLoader.loadJSON("data/" .. DataLoader.activeVersion .. "/craving_system/character_traits.json")

    -- Phase 5 data files
    self.characterClasses = DataLoader.loadJSON("data/" .. DataLoader.activeVersion .. "/craving_system/character_classes.json")
    self.commodityFatigueRates = DataLoader.loadJSON("data/" .. DataLoader.activeVersion .. "/craving_system/commodity_fatigue_rates.json")
    self.enablementRules = DataLoader.loadJSON("data/" .. DataLoader.activeVersion .. "/craving_system/enablement_rules.json")

    -- Load commodities for resource injector
    local success, result = pcall(DataLoader.loadCommodities)
    if success then
        self.commodities = result
        print("Loaded " .. #result .. " commodities for resource injector")
        if #result > 0 then
            print("First commodity: " .. result[1].id .. " - " .. result[1].name)
        end
    else
        print("ERROR: Failed to load commodities: " .. tostring(result))
        self.commodities = {}
    end
    print("self.commodities count after load: " .. #self.commodities)

    -- Load worker types for vocation selector
    local wtSuccess, wtResult = pcall(DataLoader.loadWorkerTypes)
    if wtSuccess then
        self.workerTypes = wtResult
        print("Loaded " .. #self.workerTypes .. " worker types for vocation selector")
        if #self.workerTypes > 0 then
            print("  First worker type: " .. (self.workerTypes[1].name or "nil"))
        else
            print("  WARNING: workerTypes array is empty!")
        end
    else
        print("ERROR: Failed to load worker types: " .. tostring(wtResult))
        self.workerTypes = {}
    end

    print("Consumption data loaded successfully (Phase 5)")
end

function ConsumptionPrototype:InitializeInventory()
    -- Start with empty inventory - user must inject resources
    self.townInventory = {}
    print("Town inventory initialized (empty)")
end

function ConsumptionPrototype:Update(dt)
    if not self.isPaused then
        local adjustedDt = dt * self.simulationSpeed

        -- Update cycle timer
        self.cycleTime = self.cycleTime + adjustedDt

        -- Auto-inject commodities based on injection rates (every minute)
        self.injectionAccumulator = self.injectionAccumulator + adjustedDt
        if self.injectionAccumulator >= 60.0 then
            self.injectionAccumulator = self.injectionAccumulator - 60.0
            -- Inject commodities based on rates
            for commodityId, rate in pairs(self.injectionRates) do
                if rate > 0 then
                    self.townInventory[commodityId] = (self.townInventory[commodityId] or 0) + rate
                end
            end
        end

        -- Update current cravings continuously (CharacterV2)
        for _, character in ipairs(self.characters) do
            if not character.hasEmigrated then
                character:UpdateCurrentCravings(adjustedDt)
            end
        end

        -- Run allocation cycle
        if self.cycleTime >= self.cycleDuration then
            self:RunAllocationCycle()
            self.cycleTime = self.cycleTime - self.cycleDuration
            self.cycleNumber = self.cycleNumber + 1

            -- Update satisfaction after allocation (decay based on unfulfilled cravings)
            for _, character in ipairs(self.characters) do
                if not character.hasEmigrated then
                    character:UpdateSatisfaction(self.cycleNumber)
                end
            end
        end

        -- Phase 5: Update productivity based on satisfaction
        for _, character in ipairs(self.characters) do
            if not character.hasEmigrated then
                character:UpdateProductivity()
            end
        end

        -- Phase 5: Check for protests
        for _, character in ipairs(self.characters) do
            if not character.hasEmigrated then
                local startedProtesting = character:CheckProtest()
                if startedProtesting then
                    print(character.name .. " has started protesting!")
                end
            end
        end

        -- Phase 5: Check for emigrations
        for _, character in ipairs(self.characters) do
            if not character.hasEmigrated then
                local emigrated = character:CheckEmigration(self.cycleNumber)
                if emigrated then
                    self.stats.totalEmigrations = self.stats.totalEmigrations + 1
                    print(character.name .. " has emigrated!")
                end
            end
        end

        -- Phase 5: Check town-level consequences
        local inUnrest, unrestPenalty = TownConsequences.CheckCivilUnrest(self.characters)
        if inUnrest then
            print("⚠️  CIVIL UNREST: Town productivity reduced by " .. (unrestPenalty * 100) .. "%")
        end

        local riotTriggered, riotDamage = TownConsequences.CheckRiot(self.characters, self.cycleNumber)
        if riotTriggered then
            print("🔥 RIOT! Damaging town inventory...")
            local damagedCommodities = TownConsequences.ApplyRiotDamage(self.townInventory, riotDamage)
            self.stats.totalRiots = self.stats.totalRiots + 1
            self:LogEvent("riot", "RIOT! Town inventory damaged", {
                damage = riotDamage
            })
        end

        local massEmigration, emigrantCount = TownConsequences.CheckMassEmigration(self.characters, self.cycleNumber)
        if massEmigration then
            print("📉 MASS EMIGRATION: " .. emigrantCount .. " characters emigrated this cycle")
            self:LogEvent("emigration", emigrantCount .. " citizens left the town", {
                count = emigrantCount
            })
        end

        -- Update statistics
        self:UpdateStatistics()
    end
end

function ConsumptionPrototype:RunAllocationCycle()
    if #self.characters == 0 then
        return
    end

    print("\n=== Cycle " .. self.cycleNumber .. " - Allocation Phase ===")

    -- Use AllocationEngineV2 for Phase 5
    local allocationLog = AllocationEngineV2.AllocateCycle(self.characters, self.townInventory, self.cycleNumber)
    table.insert(self.allocationHistory, allocationLog)

    -- Keep only last 20 cycles in history
    if #self.allocationHistory > 20 then
        table.remove(self.allocationHistory, 1)
    end

    print("Allocation complete: " ..
          allocationLog.stats.granted .. " granted, " ..
          allocationLog.stats.substituted .. " substituted, " ..
          allocationLog.stats.failed .. " failed")

    self.stats.totalCycles = self.stats.totalCycles + 1
    self.stats.totalAllocations = self.stats.totalAllocations + allocationLog.stats.totalAttempts

    -- Log allocation cycle summary
    self:LogEvent("allocation", "Cycle " .. self.cycleNumber .. ": " ..
        allocationLog.stats.granted .. " granted, " ..
        allocationLog.stats.substituted .. " substituted, " ..
        allocationLog.stats.failed .. " failed", {
        granted = allocationLog.stats.granted,
        substituted = allocationLog.stats.substituted,
        failed = allocationLog.stats.failed
    })

    -- Log notable individual events (failures, substitutions)
    if allocationLog.allocations then
        for _, alloc in ipairs(allocationLog.allocations) do
            if alloc.result == "failed" then
                self:LogEvent("failure", alloc.characterName .. " couldn't get " .. (alloc.commodity or "resources"), {
                    character = alloc.characterName,
                    commodity = alloc.commodity
                })
            elseif alloc.result == "substituted" then
                self:LogEvent("substitution", alloc.characterName .. ": " ..
                    (alloc.substitute or "?") .. " for " .. (alloc.commodity or "?"), {
                    character = alloc.characterName,
                    wanted = alloc.commodity,
                    got = alloc.substitute
                })
            end
        end
    end
end

function ConsumptionPrototype:UpdateStatistics()
    -- Phase 5: Use TownConsequences to calculate comprehensive statistics
    local townStats = TownConsequences.CalculateTownStats(self.characters)

    -- Update stats object with Phase 5 metrics
    self.stats.averageSatisfaction = townStats.averageSatisfaction
    self.stats.productivityMultiplier = townStats.averageProductivity
    self.stats.totalPopulation = townStats.totalPopulation
    self.stats.activePopulation = townStats.activePopulation
    self.stats.protestingCount = townStats.protestingCount
    self.stats.emigratedCount = townStats.emigratedCount
    self.stats.dissatisfiedCount = townStats.dissatisfiedCount
    self.stats.stressedCount = townStats.stressedCount
    self.stats.byClass = townStats.byClass
end

function ConsumptionPrototype:AddCharacter(class, traits, vocation)
    -- Use CharacterV2 for Phase 5
    local char = CharacterV2:New(class, nil)

    -- Auto-generate biographical info
    char.name = CharacterV2.GenerateRandomName()
    char.age = math.random(18, 65)
    char.vocation = vocation or CharacterV2.GetRandomVocation()

    -- Set the user-selected traits and RECALCULATE baseCravings with correct traits
    char.traits = traits or {}
    char.baseCravings = CharacterV2.GenerateBaseCravings(char.class, char.traits)

    -- Debug: print some base cravings to verify
    print(string.format("Recalculated baseCravings for %s - [0-4]: %.2f, %.2f, %.2f, %.2f, %.2f",
        char.name,
        char.baseCravings[0] or 0, char.baseCravings[1] or 0, char.baseCravings[2] or 0,
        char.baseCravings[3] or 0, char.baseCravings[4] or 0))

    -- Position in grid (calculate based on current count)
    local count = #self.characters
    local col = count % 8
    local row = math.floor(count / 8)
    char.position.x = self.leftPanelWidth + 20 + col * 120
    char.position.y = self.topBarHeight + 20 + row * 100

    table.insert(self.characters, char)
    local traitStr = #char.traits > 0 and table.concat(char.traits, ", ") or "none"
    print("Added character: " .. char.name .. " (" .. class .. ") with traits: " .. traitStr)

    -- Log event
    self:LogEvent("character", char.name .. " joined the town", {
        class = class,
        vocation = char.vocation,
        traits = char.traits
    })
end

function ConsumptionPrototype:InjectResource(commodity, amount)
    self.townInventory[commodity] = (self.townInventory[commodity] or 0) + amount
    print("Injected +" .. amount .. " " .. commodity .. " (total: " .. self.townInventory[commodity] .. ")")

    -- Log event
    self:LogEvent("injection", "+" .. amount .. " " .. commodity .. " injected", {
        commodity = commodity,
        amount = amount,
        newTotal = self.townInventory[commodity]
    })
end

function ConsumptionPrototype:Render()
    love.graphics.clear(0.12, 0.12, 0.15)

    -- Clear buttons at start of each frame (rebuild during render)
    self.buttons = {}

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Top bar
    self:RenderTopBar()

    -- Left panel (controls)
    self:RenderLeftPanel()

    -- Right panel (inventory & info)
    self:RenderRightPanel()

    -- Center panel (character grid)
    self:RenderCenterPanel()

    -- Modals (on top of everything)
    if self.showCharacterCreator then
        self:RenderCharacterCreator()
    end

    if self.showResourceInjector then
        self:RenderResourceInjector()
    end

    if self.showInventoryModal then
        self:RenderInventoryModal()
    end

    if self.showHeatmapModal then
        self:RenderHeatmapModal()
    end

    if self.showCharacterDetailModal then
        self:RenderCharacterDetailModal()
    end

    -- Help text
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("ESC: Exit | TAB: Change View", 10, screenH - 25)
end

function ConsumptionPrototype:RenderTopBar()
    local screenW = love.graphics.getWidth()

    -- Background
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", 0, 0, screenW, self.topBarHeight)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CONSUMPTION PROTOTYPE", 20, 15, 0, 1.5, 1.5)

    -- Cycle info
    love.graphics.print(string.format("Cycle: %d | Time: %.1fs/%.0fs | Speed: %.1fx",
        self.cycleNumber, self.cycleTime, self.cycleDuration, self.simulationSpeed), 20, 40, 0, 0.9, 0.9)

    -- Stats
    local statsX = screenW - 400
    love.graphics.print(string.format("Population: %d | Avg Sat: %.1f%% | Productivity: %.0f%%",
        self:GetActiveCharacterCount(),
        self.stats.averageSatisfaction,
        self.stats.productivityMultiplier * 100
    ), statsX, 25, 0, 0.9, 0.9)

    -- Pause indicator
    if self.isPaused then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print("⏸ PAUSED", screenW - 120, 15, 0, 1.2, 1.2)
    end
end

function ConsumptionPrototype:RenderLeftPanel()
    local x = 0
    local y = self.topBarHeight
    local w = self.leftPanelWidth
    local h = love.graphics.getHeight() - self.topBarHeight

    -- Background
    love.graphics.setColor(0.10, 0.10, 0.13)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Border
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.setLineWidth(1)
    love.graphics.line(w, y, w, y + h)

    local buttonY = y + 20

    -- Header
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("CONTROLS", x + 20, buttonY, 0, 1.2, 1.2)
    buttonY = buttonY + 35

    -- Pause/Resume button
    local pauseText = self.isPaused and "▶ Resume" or "⏸ Pause"
    self:RenderButton(pauseText, x + 20, buttonY, 210, 35, function()
        self.isPaused = not self.isPaused
    end)
    buttonY = buttonY + 45

    -- Speed controls
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Speed:", x + 20, buttonY, 0, 0.9, 0.9)
    buttonY = buttonY + 25

    local speeds = {1.0, 2.0, 5.0, 10.0}
    local speedLabels = {"1x", "2x", "5x", "10x"}
    for i, speed in ipairs(speeds) do
        local bx = x + 20 + (i - 1) * 52
        local isActive = self.simulationSpeed == speed
        self:RenderButton(speedLabels[i], bx, buttonY, 48, 30, function()
            self.simulationSpeed = speed
        end, isActive)
    end
    buttonY = buttonY + 40

    -- Separator
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.line(x + 20, buttonY, x + w - 20, buttonY)
    buttonY = buttonY + 20

    -- Add Character button
    self:RenderButton("+ Add Character", x + 20, buttonY, 210, 40, function()
        self.showCharacterCreator = true
    end, false, {0.2, 0.6, 0.9})
    buttonY = buttonY + 50

    -- Inject Resources button
    self:RenderButton("💉 Inject Resources", x + 20, buttonY, 210, 40, function()
        self.showResourceInjector = true
    end, false, {0.3, 0.7, 0.4})
    buttonY = buttonY + 50

    -- Info
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Characters: " .. #self.characters, x + 20, buttonY + 10, 0, 0.8, 0.8)
    love.graphics.print("Emigrated: " .. self.stats.totalEmigrations, x + 20, buttonY + 30, 0, 0.8, 0.8)
end

function ConsumptionPrototype:RenderRightPanel()
    local screenW = love.graphics.getWidth()
    local x = screenW - self.rightPanelWidth
    local y = self.topBarHeight
    local w = self.rightPanelWidth
    local h = love.graphics.getHeight() - self.topBarHeight

    -- Background
    love.graphics.setColor(0.10, 0.10, 0.13)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Border
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.setLineWidth(1)
    love.graphics.line(x, y, x, y + h)

    local contentY = y + 20

    -- Inventory Section
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("INVENTORY", x + 20, contentY, 0, 1.2, 1.2)
    contentY = contentY + 35

    -- Count items in inventory
    local itemCount = 0
    local totalQuantity = 0
    for commodity, quantity in pairs(self.townInventory) do
        if quantity > 0 then
            itemCount = itemCount + 1
            totalQuantity = totalQuantity + quantity
        end
    end

    -- Summary text
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(itemCount .. " types, " .. totalQuantity .. " total items", x + 20, contentY, 0, 0.85, 0.85)
    contentY = contentY + 30

    -- View Inventory button
    self:RenderButton("📦 View Inventory", x + 20, contentY, w - 40, 35, function()
        self.showInventoryModal = true
    end, false, {0.3, 0.5, 0.7})
    contentY = contentY + 50

    -- Separator
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.line(x + 20, contentY, x + w - 20, contentY)
    contentY = contentY + 20

    -- Selected Character Section
    if self.selectedCharacter then
        self:RenderSelectedCharacterInfo(x + 20, contentY, w - 40)
    else
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("SELECTED CHARACTER", x + 20, contentY, 0, 1.1, 1.1)
        contentY = contentY + 30
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("(click a character to select)", x + 30, contentY, 0, 0.8, 0.8)
    end
end

function ConsumptionPrototype:RenderSelectedCharacterInfo(x, y, width)
    local char = self.selectedCharacter

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print(char.name, x, y, 0, 1.1, 1.1)
    y = y + 25

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(char.class .. " | Age " .. char.age, x, y, 0, 0.85, 0.85)
    y = y + 20

    -- Vocation
    love.graphics.setColor(0.6, 0.8, 0.6)
    love.graphics.print("Vocation: " .. (char.vocation or "Unknown"), x, y, 0, 0.8, 0.8)
    y = y + 20

    -- Traits
    if char.traits and #char.traits > 0 then
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("Traits: " .. table.concat(char.traits, ", "), x, y, 0, 0.75, 0.75)
        y = y + 20
    end

    y = y + 10

    -- Satisfaction bars (coarse)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Satisfaction:", x, y, 0, 0.9, 0.9)
    y = y + 20

    local cravingNames = {
        "Biological", "Safety", "Touch", "Psych",
        "Status", "Social", "Exotic",
        "Shiny", "Vice"
    }
    local cravingKeys = {
        "biological", "safety", "touch", "psychological",
        "social_status", "social_connection", "exotic_goods",
        "shiny_objects", "vice"
    }

    for i, key in ipairs(cravingKeys) do
        local value = char.satisfaction[key] or 0

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(cravingNames[i], x, y, 0, 0.7, 0.7)

        -- Draw bar background
        local barX = x + 60
        local barW = width - 100
        local barH = 10
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, y + 2, barW, barH, 2, 2)

        -- Calculate center point (0 is at 25% of the bar, since range is -100 to 300)
        -- -100 = 0%, 0 = 25%, 100 = 50%, 300 = 100%
        local centerX = barX + barW * 0.25
        local normalized = (value + 100) / 400  -- 0 to 1

        -- Draw zero line marker
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("fill", centerX - 1, y + 1, 2, barH + 2)

        -- Draw bar fill from center
        if value < 0 then
            -- Negative: red bar extending left from center
            local negWidth = (math.abs(value) / 100) * barW * 0.25
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.rectangle("fill", centerX - negWidth, y + 2, negWidth, barH, 2, 2)
        else
            -- Positive: green bar extending right from center
            -- 0-100 uses 25% of bar, 100-300 uses remaining 75%
            local posWidth
            if value <= 100 then
                posWidth = (value / 100) * barW * 0.25
            else
                posWidth = barW * 0.25 + ((value - 100) / 200) * barW * 0.5
            end
            local r, g, b = self:GetSatisfactionColor(value)
            love.graphics.setColor(r, g, b)
            love.graphics.rectangle("fill", centerX, y + 2, math.min(posWidth, barW * 0.75), barH, 2, 2)
        end

        -- Value text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%.0f", value), x + width - 35, y, 0, 0.7, 0.7)

        y = y + 16
    end

    y = y + 15

    -- Visualization buttons
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("View Vectors:", x, y, 0, 0.9, 0.9)
    y = y + 25

    local btnW = (width - 10) / 2
    local btnH = 28

    -- Row 1: Base Cravings
    self:RenderButton("Base (Coarse)", x, y, btnW, btnH, function()
        self.heatmapType = "base_cravings"
        self.heatmapLevel = "coarse"
        self.showHeatmapModal = true
    end, false, {0.4, 0.5, 0.6})

    self:RenderButton("Base (Fine)", x + btnW + 10, y, btnW, btnH, function()
        self.heatmapType = "base_cravings"
        self.heatmapLevel = "fine"
        self.showHeatmapModal = true
    end, false, {0.4, 0.5, 0.6})
    y = y + btnH + 5

    -- Row 2: Current Cravings
    self:RenderButton("Current (Coarse)", x, y, btnW, btnH, function()
        self.heatmapType = "current_cravings"
        self.heatmapLevel = "coarse"
        self.showHeatmapModal = true
    end, false, {0.5, 0.6, 0.4})

    self:RenderButton("Current (Fine)", x + btnW + 10, y, btnW, btnH, function()
        self.heatmapType = "current_cravings"
        self.heatmapLevel = "fine"
        self.showHeatmapModal = true
    end, false, {0.5, 0.6, 0.4})
    y = y + btnH + 5

    -- Row 3: Satisfaction
    self:RenderButton("Satisfaction (Coarse)", x, y, btnW, btnH, function()
        self.heatmapType = "satisfaction"
        self.heatmapLevel = "coarse"
        self.showHeatmapModal = true
    end, false, {0.6, 0.5, 0.4})

    self:RenderButton("Satisfaction (Fine)", x + btnW + 10, y, btnW, btnH, function()
        self.heatmapType = "satisfaction"
        self.heatmapLevel = "fine"
        self.showHeatmapModal = true
    end, false, {0.6, 0.5, 0.4})
    y = y + btnH + 15

    -- Full Details button
    self:RenderButton("View Full Details", x, y, width, btnH, function()
        self.detailCharacter = self.selectedCharacter
        self.detailScrollOffset = 0
        self.showCharacterDetailModal = true
    end, false, {0.3, 0.6, 0.8})
end

function ConsumptionPrototype:RenderCenterPanel()
    local x = self.leftPanelWidth
    local y = self.topBarHeight
    local w = love.graphics.getWidth() - self.leftPanelWidth - self.rightPanelWidth
    local h = love.graphics.getHeight() - self.topBarHeight

    -- Split: Character grid (top 60%) and Event log (bottom 40%)
    local gridH = math.floor(h * 0.6)
    local logH = h - gridH

    -- Character grid area
    love.graphics.setColor(0.09, 0.09, 0.12)
    love.graphics.rectangle("fill", x, y, w, gridH)

    if #self.characters == 0 then
        -- Empty state message
        love.graphics.setColor(0.5, 0.5, 0.5)
        local msg = "No characters yet. Click 'Add Character' to begin."
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(msg)
        love.graphics.print(msg, x + (w - textWidth) / 2, y + gridH / 2 - 10)
    else
        -- Render character cards
        for _, character in ipairs(self.characters) do
            if not character.hasEmigrated then
                self:RenderCharacterCard(character)
            end
        end
    end

    -- Separator line
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.setLineWidth(1)
    love.graphics.line(x, y + gridH, x + w, y + gridH)

    -- Event log area
    self:RenderEventLog(x, y + gridH, w, logH)
end

function ConsumptionPrototype:RenderEventLog(x, y, w, h)
    -- Background
    love.graphics.setColor(0.07, 0.07, 0.10)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Header
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("EVENT LOG", x + 10, y + 8, 0, 0.9, 0.9)

    -- Cycle indicator
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print(string.format("Cycle %d", self.cycleNumber), x + w - 80, y + 8, 0, 0.8, 0.8)

    local contentY = y + 30
    local contentH = h - 40
    local lineHeight = 16
    local maxVisibleLines = math.floor(contentH / lineHeight)

    -- Scissor for scrolling
    love.graphics.setScissor(x + 5, contentY, w - 20, contentH)

    if #self.eventLog == 0 then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print("No events yet. Start the simulation to see activity.", x + 10, contentY + 10, 0, 0.75, 0.75)
    else
        -- Calculate total content height and scroll
        local totalLines = #self.eventLog
        self.eventLogScrollMax = math.max(0, (totalLines * lineHeight) - contentH)
        self.eventLogScrollOffset = math.max(0, math.min(self.eventLogScrollOffset, self.eventLogScrollMax))

        -- Render events (newest first)
        local startLine = math.floor(self.eventLogScrollOffset / lineHeight)
        local yOffset = -(self.eventLogScrollOffset % lineHeight)

        for i = 1, maxVisibleLines + 2 do
            local eventIndex = #self.eventLog - startLine - i + 1
            if eventIndex >= 1 and eventIndex <= #self.eventLog then
                local event = self.eventLog[eventIndex]
                local lineY = contentY + yOffset + (i - 1) * lineHeight

                -- Event type color
                local color = self:GetEventColor(event.type)
                love.graphics.setColor(color[1], color[2], color[3], 0.9)

                -- Time prefix
                local timeStr = string.format("[%d] ", event.cycle or 0)
                love.graphics.print(timeStr, x + 10, lineY, 0, 0.7, 0.7)

                -- Event type icon
                local icon = self:GetEventIcon(event.type)
                love.graphics.print(icon, x + 45, lineY, 0, 0.7, 0.7)

                -- Message
                love.graphics.setColor(0.85, 0.85, 0.85)
                love.graphics.print(event.message, x + 60, lineY, 0, 0.7, 0.7)
            end
        end
    end

    love.graphics.setScissor()

    -- Scrollbar
    if (self.eventLogScrollMax or 0) > 0 then
        local scrollbarH = contentH * (contentH / (#self.eventLog * lineHeight))
        scrollbarH = math.max(20, scrollbarH)
        local scrollbarY = contentY + (self.eventLogScrollOffset / self.eventLogScrollMax) * (contentH - scrollbarH)
        love.graphics.setColor(0.4, 0.4, 0.4, 0.8)
        love.graphics.rectangle("fill", x + w - 12, scrollbarY, 6, scrollbarH, 3, 3)
    end
end

-- =============================================================================
-- Character Detail Modal (6 sections)
-- =============================================================================
function ConsumptionPrototype:RenderCharacterDetailModal()
    if not self.detailCharacter then
        self.showCharacterDetailModal = false
        return
    end

    local char = self.detailCharacter
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local w = 900
    local h = 650
    local x = (screenW - w) / 2
    local y = (screenH - h) / 2

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CHARACTER DETAILS: " .. char.name, x + 20, y + 15, 0, 1.2, 1.2)

    -- Close button
    self:RenderButton("X", x + w - 40, y + 10, 30, 30, function()
        self.showCharacterDetailModal = false
        self.detailCharacter = nil
    end, false, {0.6, 0.3, 0.3})

    -- Content area with scroll
    local contentX = x + 20
    local contentY = y + 55
    local contentW = w - 40
    local contentH = h - 70
    local padding = 15

    -- Set up scissor for scrollable content
    love.graphics.setScissor(contentX, contentY, contentW, contentH)

    local scrollY = contentY - self.detailScrollOffset
    local sectionH = 0

    -- ==========================================================================
    -- SECTION 1: Identity & Enablements
    -- ==========================================================================
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.print("IDENTITY & ENABLEMENTS", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 22

    -- Identity info
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Name: " .. char.name, contentX, scrollY, 0, 0.8, 0.8)
    love.graphics.print("Class: " .. (char.class or "Unknown"), contentX + 200, scrollY, 0, 0.8, 0.8)
    love.graphics.print("Age: " .. (char.age or "?"), contentX + 350, scrollY, 0, 0.8, 0.8)
    scrollY = scrollY + 18

    love.graphics.print("Vocation: " .. (char.vocation or "Unknown"), contentX, scrollY, 0, 0.8, 0.8)
    scrollY = scrollY + 18

    -- Traits
    local traitStr = char.traits and #char.traits > 0 and table.concat(char.traits, ", ") or "None"
    love.graphics.print("Traits: " .. traitStr, contentX, scrollY, 0, 0.8, 0.8)
    scrollY = scrollY + 18

    -- Enablements (what they can access)
    love.graphics.setColor(0.6, 0.7, 0.6)
    local enablements = char.enablements or {}
    local enableStr = "Enablements: "
    if next(enablements) then
        local enabled = {}
        for cat, val in pairs(enablements) do
            if val then table.insert(enabled, cat) end
        end
        enableStr = enableStr .. (#enabled > 0 and table.concat(enabled, ", ") or "None")
    else
        enableStr = enableStr .. "Standard access"
    end
    love.graphics.print(enableStr, contentX, scrollY, 0, 0.75, 0.75)
    scrollY = scrollY + 25

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
    scrollY = scrollY + padding

    -- ==========================================================================
    -- SECTION 2: Satisfaction Bars (9 coarse dimensions)
    -- ==========================================================================
    love.graphics.setColor(0.4, 0.8, 0.6)
    love.graphics.print("SATISFACTION (9 Dimensions)", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 22

    local cravingNames = {"Biological", "Safety", "Touch", "Psychological", "Social Status", "Social Connection", "Exotic Goods", "Shiny Objects", "Vice"}
    local cravingKeys = {"biological", "safety", "touch", "psychological", "social_status", "social_connection", "exotic_goods", "shiny_objects", "vice"}

    local barW = (contentW - 20) / 2 - 80
    local barH = 12

    for i, key in ipairs(cravingKeys) do
        local value = char.satisfaction and char.satisfaction[key] or 0
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local bx = contentX + col * (contentW / 2)
        local by = scrollY + row * 22

        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print(cravingNames[i], bx, by, 0, 0.7, 0.7)

        -- Bar background
        local barX = bx + 90
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, by + 2, barW, barH, 2, 2)

        -- Center line (0 at 25%)
        local centerX = barX + barW * 0.25
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("fill", centerX - 1, by + 1, 2, barH + 2)

        -- Bar fill
        if value < 0 then
            local negWidth = math.min((math.abs(value) / 100) * barW * 0.25, barW * 0.25)
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.rectangle("fill", centerX - negWidth, by + 2, negWidth, barH, 2, 2)
        else
            local posWidth = math.min(value <= 100 and (value / 100) * barW * 0.25 or barW * 0.25 + ((value - 100) / 200) * barW * 0.5, barW * 0.75)
            local r, g, b = self:GetSatisfactionColor(value)
            love.graphics.setColor(r, g, b)
            love.graphics.rectangle("fill", centerX, by + 2, posWidth, barH, 2, 2)
        end

        -- Value
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%.0f", value), barX + barW + 5, by, 0, 0.7, 0.7)
    end
    scrollY = scrollY + math.ceil(#cravingKeys / 2) * 22 + 10

    -- Average satisfaction
    local avgSat = char:GetAverageSatisfaction()
    love.graphics.setColor(0.8, 0.8, 0.4)
    love.graphics.print(string.format("Average Satisfaction: %.1f", avgSat), contentX, scrollY, 0, 0.8, 0.8)
    scrollY = scrollY + 25

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
    scrollY = scrollY + padding

    -- ==========================================================================
    -- SECTION 3: Current Cravings (Top 10)
    -- ==========================================================================
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.print("TOP CURRENT CRAVINGS", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 22

    -- Get top 10 cravings
    local cravingsList = {}
    if char.currentCravings then
        for i = 0, 48 do
            local craving = char.currentCravings[i] or 0
            if craving > 0.1 then
                local fineName = CharacterV2.fineNames and CharacterV2.fineNames[i] or ("dim_" .. i)
                table.insert(cravingsList, {index = i, name = fineName, value = craving})
            end
        end
    end
    table.sort(cravingsList, function(a, b) return a.value > b.value end)

    if #cravingsList == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No significant cravings", contentX, scrollY, 0, 0.75, 0.75)
        scrollY = scrollY + 18
    else
        for i = 1, math.min(10, #cravingsList) do
            local craving = cravingsList[i]
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            local cx = contentX + col * (contentW / 2)
            local cy = scrollY + row * 18

            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(i .. ". " .. craving.name, cx, cy, 0, 0.7, 0.7)
            love.graphics.setColor(0.9, 0.7, 0.4)
            love.graphics.print(string.format("%.1f", craving.value), cx + 180, cy, 0, 0.7, 0.7)
        end
        scrollY = scrollY + math.ceil(math.min(10, #cravingsList) / 2) * 18 + 10
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
    scrollY = scrollY + padding

    -- ==========================================================================
    -- SECTION 4: Commodity Fatigue
    -- ==========================================================================
    love.graphics.setColor(0.6, 0.4, 0.8)
    love.graphics.print("COMMODITY FATIGUE", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 22

    local fatigueList = {}
    if char.commodityMultipliers then
        for commodity, mult in pairs(char.commodityMultipliers) do
            if mult < 0.95 then  -- Only show fatigued commodities
                table.insert(fatigueList, {commodity = commodity, multiplier = mult})
            end
        end
    end
    table.sort(fatigueList, function(a, b) return a.multiplier < b.multiplier end)

    if #fatigueList == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No commodity fatigue", contentX, scrollY, 0, 0.75, 0.75)
        scrollY = scrollY + 18
    else
        for i = 1, math.min(8, #fatigueList) do
            local fatigue = fatigueList[i]
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            local fx = contentX + col * (contentW / 2)
            local fy = scrollY + row * 18

            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(fatigue.commodity, fx, fy, 0, 0.7, 0.7)
            love.graphics.setColor(0.8, 0.5, 0.8)
            love.graphics.print(string.format("%.0f%%", fatigue.multiplier * 100), fx + 180, fy, 0, 0.7, 0.7)
        end
        scrollY = scrollY + math.ceil(math.min(8, #fatigueList) / 2) * 18 + 10
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
    scrollY = scrollY + padding

    -- ==========================================================================
    -- SECTION 5: Consumption History (Last 10)
    -- ==========================================================================
    love.graphics.setColor(0.4, 0.7, 0.7)
    love.graphics.print("RECENT CONSUMPTION HISTORY", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 22

    local history = char.consumptionHistory or {}
    if #history == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No consumption history yet", contentX, scrollY, 0, 0.75, 0.75)
        scrollY = scrollY + 18
    else
        local startIdx = math.max(1, #history - 9)
        for i = #history, startIdx, -1 do
            local entry = history[i]
            love.graphics.setColor(0.7, 0.7, 0.7)
            local entryText = string.format("Cycle %d: %s (x%d)",
                entry.cycle or 0,
                entry.commodity or "unknown",
                entry.quantity or 1)
            love.graphics.print(entryText, contentX, scrollY, 0, 0.7, 0.7)
            scrollY = scrollY + 16
        end
    end
    scrollY = scrollY + 5

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
    scrollY = scrollY + padding

    -- ==========================================================================
    -- SECTION 6: Status & Risks
    -- ==========================================================================
    love.graphics.setColor(0.8, 0.4, 0.4)
    love.graphics.print("STATUS & RISKS", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 22

    -- Status flags
    local statusX = contentX
    love.graphics.setColor(0.7, 0.7, 0.7)

    -- Protesting
    if char.isProtesting then
        love.graphics.setColor(0.9, 0.6, 0.2)
        love.graphics.print("PROTESTING", statusX, scrollY, 0, 0.8, 0.8)
        statusX = statusX + 120
    end

    -- Emigrated
    if char.hasEmigrated then
        love.graphics.setColor(0.9, 0.3, 0.3)
        love.graphics.print("EMIGRATED", statusX, scrollY, 0, 0.8, 0.8)
        statusX = statusX + 120
    end

    -- Stressed
    local avgSatisfaction = char:GetAverageSatisfaction()
    if avgSatisfaction < 0 then
        love.graphics.setColor(0.9, 0.4, 0.4)
        love.graphics.print("STRESSED", statusX, scrollY, 0, 0.8, 0.8)
        statusX = statusX + 100
    elseif avgSatisfaction < 30 then
        love.graphics.setColor(0.8, 0.6, 0.3)
        love.graphics.print("DISSATISFIED", statusX, scrollY, 0, 0.8, 0.8)
        statusX = statusX + 120
    else
        love.graphics.setColor(0.4, 0.8, 0.4)
        love.graphics.print("CONTENT", statusX, scrollY, 0, 0.8, 0.8)
        statusX = statusX + 100
    end
    scrollY = scrollY + 22

    -- Productivity
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(string.format("Productivity: %.0f%%", (char.productivity or 1) * 100), contentX, scrollY, 0, 0.8, 0.8)

    -- Allocation Priority
    love.graphics.print(string.format("Allocation Priority: %.1f", char.allocationPriority or 0), contentX + 200, scrollY, 0, 0.8, 0.8)
    scrollY = scrollY + 22

    -- Risk indicators
    love.graphics.setColor(0.6, 0.6, 0.6)
    local emigrationRisk = "Low"
    if avgSatisfaction < -50 then
        emigrationRisk = "CRITICAL"
        love.graphics.setColor(1, 0.2, 0.2)
    elseif avgSatisfaction < 0 then
        emigrationRisk = "High"
        love.graphics.setColor(0.9, 0.5, 0.2)
    elseif avgSatisfaction < 30 then
        emigrationRisk = "Medium"
        love.graphics.setColor(0.8, 0.8, 0.3)
    end
    love.graphics.print("Emigration Risk: " .. emigrationRisk, contentX, scrollY, 0, 0.8, 0.8)
    scrollY = scrollY + 25

    -- Calculate total content height for scrolling
    local totalHeight = scrollY - (contentY - self.detailScrollOffset)
    self.detailScrollMax = math.max(0, totalHeight - contentH)

    love.graphics.setScissor()

    -- Scrollbar
    if self.detailScrollMax > 0 then
        local scrollbarH = contentH * (contentH / totalHeight)
        scrollbarH = math.max(30, scrollbarH)
        local scrollbarY = contentY + (self.detailScrollOffset / self.detailScrollMax) * (contentH - scrollbarH)
        love.graphics.setColor(0.4, 0.4, 0.5, 0.8)
        love.graphics.rectangle("fill", x + w - 15, scrollbarY, 8, scrollbarH, 4, 4)
    end
end

function ConsumptionPrototype:GetEventColor(eventType)
    local colors = {
        allocation = {0.3, 0.8, 0.4},      -- Green: successful allocation cycle
        failure = {0.9, 0.3, 0.3},         -- Red: failed allocation
        substitution = {0.9, 0.7, 0.3},    -- Yellow-orange: substitution
        emigration = {0.9, 0.6, 0.2},      -- Orange: character left
        riot = {1.0, 0.2, 0.2},            -- Bright red: riot
        protest = {0.9, 0.7, 0.2},         -- Yellow: protest
        injection = {0.4, 0.6, 0.9},       -- Blue: resource injection
        character = {0.6, 0.8, 0.6},       -- Light green: character added
        cycle = {0.5, 0.5, 0.6},           -- Gray: cycle start/end
        info = {0.6, 0.6, 0.7},            -- Light gray: info
    }
    return colors[eventType] or {0.6, 0.6, 0.6}
end

function ConsumptionPrototype:GetEventIcon(eventType)
    local icons = {
        allocation = "✓",
        failure = "✗",
        substitution = "~",
        emigration = "→",
        riot = "!",
        protest = "⚠",
        injection = "+",
        character = "★",
        cycle = "○",
        info = "•",
    }
    return icons[eventType] or "•"
end

function ConsumptionPrototype:LogEvent(eventType, message, details)
    local event = {
        cycle = self.cycleNumber,
        time = self.cycleTime,
        type = eventType,
        message = message,
        details = details or {}
    }
    table.insert(self.eventLog, event)

    -- Keep only last N events
    while #self.eventLog > self.maxEventLogEntries do
        table.remove(self.eventLog, 1)
    end
end

function ConsumptionPrototype:RenderCharacterCard(character)
    local x = character.position.x
    local y = character.position.y
    local w = 110
    local h = 90

    -- Card background
    local avgSat = character:GetAverageSatisfaction()
    local r, g, b = self:GetSatisfactionColor(avgSat)
    love.graphics.setColor(r * 0.25, g * 0.25, b * 0.25)
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)

    -- Border (class-based)
    local borderColor = self:GetClassColor(character.class)
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3])
    love.graphics.setLineWidth(self.selectedCharacter == character and 3 or 2)
    love.graphics.rectangle("line", x, y, w, h, 5, 5)

    -- Name
    love.graphics.setColor(1, 1, 1)
    local nameFont = love.graphics.getFont()
    local nameWidth = nameFont:getWidth(character.name)
    local scale = math.min(1, (w - 10) / nameWidth * 0.7)
    love.graphics.print(character.name, x + 5, y + 5, 0, scale, scale)

    -- Class
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3])
    love.graphics.print(character.class, x + 5, y + 20, 0, 0.6, 0.6)

    -- Average satisfaction
    love.graphics.setColor(r, g, b)
    love.graphics.print(string.format("%.0f%%", avgSat), x + 5, y + 35, 0, 1.0, 1.0)

    -- Status indicators
    if character.status == "variety_seeking" then
        love.graphics.setColor(1, 0.8, 0.3)
        love.graphics.print("🔁", x + 5, y + 52, 0, 0.7, 0.7)
    end

    -- Critical cravings
    local criticalCount = character:GetCriticalCravingCount()
    if criticalCount > 0 then
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.print("!" .. criticalCount, x + w - 25, y + 5, 0, 0.9, 0.9)
    end

    -- Priority
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("P:" .. math.floor(character.allocationPriority), x + 5, y + h - 18, 0, 0.55, 0.55)
end

function ConsumptionPrototype:RenderCharacterCreator()
    local w = 550
    local h = 560
    local x = (love.graphics.getWidth() - w) / 2
    local y = (love.graphics.getHeight() - h) / 2

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Modal background
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Border
    love.graphics.setColor(0.4, 0.4, 0.45)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CREATE CHARACTER", x + 20, y + 20, 0, 1.3, 1.3)

    local formY = y + 60

    -- Class selection
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Class:", x + 20, formY, 0, 0.9, 0.9)
    local classes = {"Elite", "Upper", "Middle", "Lower"}
    for i, class in ipairs(classes) do
        local bx = x + 120 + (i - 1) * 100
        local isSelected = self.creatorClass == class
        self:RenderButton(class, bx, formY - 5, 95, 30, function()
            self.creatorClass = class
        end, isSelected)
    end
    formY = formY + 50

    -- Vocation selection (using worker types)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Vocation:", x + 20, formY, 0, 0.9, 0.9)

    local workerTypes = self.workerTypes or {}
    local vocListX = x + 120
    local vocListY = formY - 5
    local vocListW = w - 140
    local vocListH = 100  -- Taller to show more worker types

    -- Vocation list background
    love.graphics.setColor(0.12, 0.12, 0.14)
    love.graphics.rectangle("fill", vocListX, vocListY, vocListW, vocListH, 5, 5)

    -- Scissor for scrolling
    love.graphics.setScissor(vocListX, vocListY, vocListW, vocListH)

    local vocBtnW = 100
    local vocBtnH = 28
    local vocCols = 4
    local vocScrollOffset = self.creatorVocationScrollOffset or 0
    local vocTotalHeight = 0

    -- Add "Random" option first, then all worker types
    local allVocations = {{id = "random", name = "Random"}}
    for _, wt in ipairs(workerTypes) do
        table.insert(allVocations, {id = wt.id, name = wt.name})
    end

    for i, voc in ipairs(allVocations) do
        local col = (i - 1) % vocCols
        local row = math.floor((i - 1) / vocCols)
        local bx = vocListX + 5 + col * (vocBtnW + 3)
        local by = vocListY + 5 + row * (vocBtnH + 4) - vocScrollOffset

        -- Only render AND register buttons that are visible
        if by + vocBtnH >= vocListY and by <= vocListY + vocListH then
            local isSelected = (voc.id == "random" and self.creatorVocation == nil) or
                              (self.creatorVocation == voc.name)

            if isSelected then
                love.graphics.setColor(0.3, 0.5, 0.7)
            else
                love.graphics.setColor(0.22, 0.22, 0.25)
            end
            love.graphics.rectangle("fill", bx, by, vocBtnW, vocBtnH, 3, 3)

            love.graphics.setColor(1, 1, 1)
            local displayName = voc.name:sub(1, 11)
            love.graphics.print(displayName, bx + 5, by + 6, 0, 0.7, 0.7)

            -- Store button ONLY if visible
            local vocName = voc.name
            local vocId = voc.id
            table.insert(self.buttons, {
                x = bx, y = by, w = vocBtnW, h = vocBtnH,
                onClick = function()
                    if vocId == "random" then
                        self.creatorVocation = nil
                    else
                        self.creatorVocation = vocName
                    end
                end
            })
        end

        vocTotalHeight = math.max(vocTotalHeight, (row + 1) * (vocBtnH + 4))
    end

    love.graphics.setScissor()

    -- Vocation scrollbar
    self.creatorVocationScrollMax = math.max(0, vocTotalHeight - vocListH + 10)
    if self.creatorVocationScrollMax > 0 then
        local scrollbarH = vocListH * (vocListH / vocTotalHeight)
        local scrollbarY = vocListY + (vocScrollOffset / self.creatorVocationScrollMax) * (vocListH - scrollbarH)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", vocListX + vocListW - 6, scrollbarY, 4, scrollbarH, 2, 2)
    end

    formY = formY + vocListH + 15

    -- Traits section (using character_traits.json for full fine-grained multipliers)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Traits:", x + 20, formY, 0, 0.9, 0.9)
    formY = formY + 30

    local availableTraits = self.characterTraits and self.characterTraits.traits or {}
    for i, trait in ipairs(availableTraits) do
        local row = math.floor((i - 1) / 2)
        local col = (i - 1) % 2
        local bx = x + 20 + col * 260
        local by = formY + row * 35

        local isSelected = false
        for _, selectedTrait in ipairs(self.creatorTraits) do
            if selectedTrait == trait.id then
                isSelected = true
                break
            end
        end

        self:RenderButton(trait.name, bx, by, 250, 30, function()
            if isSelected then
                -- Remove trait
                for j, t in ipairs(self.creatorTraits) do
                    if t == trait.id then
                        table.remove(self.creatorTraits, j)
                        break
                    end
                end
            else
                -- Add trait (no limit)
                table.insert(self.creatorTraits, trait.id)
            end
        end, isSelected)
    end

    formY = formY + math.ceil(#availableTraits / 2) * 35 + 20

    -- Buttons
    self:RenderButton("Cancel", x + w - 230, y + h - 50, 100, 35, function()
        self.showCharacterCreator = false
        self:ResetCharacterCreator()
    end, false, {0.6, 0.3, 0.3})

    self:RenderButton("Create", x + w - 120, y + h - 50, 100, 35, function()
        -- Name and biographical info will be auto-generated
        self:AddCharacter(self.creatorClass, self.creatorTraits, self.creatorVocation)
        self.showCharacterCreator = false
        self:ResetCharacterCreator()
    end, false, {0.3, 0.7, 0.4})
end

function ConsumptionPrototype:RenderResourceInjector()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local w = 700
    local h = 500
    local x = (screenW - w) / 2
    local y = (screenH - h) / 2

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Border
    love.graphics.setColor(0.4, 0.7, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("RESOURCE INJECTION RATES", x + 20, y + 15, 0, 1.2, 1.2)

    -- Subtitle
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Set rate per minute for each commodity", x + 20, y + 40, 0, 0.8, 0.8)

    -- Build category list from commodities
    local categories = {{id = "all", name = "All"}, {id = "nonzero", name = "With Rate"}}
    local categorySet = {}
    local commodities = self.commodities or {}
    for _, c in ipairs(commodities) do
        if c.category and not categorySet[c.category] then
            categorySet[c.category] = true
            table.insert(categories, {id = c.category, name = c.category:gsub("^%l", string.upper)})
        end
    end

    -- LEFT SIDE: Category filter
    local catX = x + 10
    local catY = y + 60
    local catW = 130
    local catH = h - 120

    love.graphics.setColor(0.12, 0.12, 0.14)
    love.graphics.rectangle("fill", catX, catY, catW, catH, 5, 5)

    -- Enable scissor for category scrolling
    love.graphics.setScissor(catX, catY, catW, catH)

    -- Category buttons
    local btnY = catY + 5 - self.injectorCategoryScrollOffset
    local catTotalHeight = 0
    for _, category in ipairs(categories) do
        -- Only render if visible
        if btnY + 28 >= catY and btnY <= catY + catH then
            local isSelected = (self.selectedInjectorCategory == category.id) or
                              (self.selectedInjectorCategory == nil and category.id == "all")

            if isSelected then
                love.graphics.setColor(0.3, 0.5, 0.7)
            else
                love.graphics.setColor(0.22, 0.22, 0.25)
            end
            love.graphics.rectangle("fill", catX + 5, btnY, catW - 10, 28, 3, 3)

            love.graphics.setColor(1, 1, 1)
            love.graphics.print(category.name, catX + 12, btnY + 6, 0, 0.85, 0.85)
        end

        -- Store button for click handling (always, for scroll handling)
        local catId = category.id
        table.insert(self.buttons, {
            x = catX + 5, y = btnY, w = catW - 10, h = 28,
            onClick = function()
                if catId == "all" then
                    self.selectedInjectorCategory = nil
                else
                    self.selectedInjectorCategory = catId
                end
                self.injectorCommodityScrollOffset = 0
            end
        })

        btnY = btnY + 32
        catTotalHeight = catTotalHeight + 32
    end

    love.graphics.setScissor()

    -- Category scrollbar if needed
    self.injectorCategoryScrollMax = math.max(0, catTotalHeight - catH)
    if self.injectorCategoryScrollMax > 0 then
        local scrollbarH = catH * (catH / catTotalHeight)
        local scrollbarY = catY + (self.injectorCategoryScrollOffset / self.injectorCategoryScrollMax) * (catH - scrollbarH)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", catX + catW - 8, scrollbarY, 6, scrollbarH, 3, 3)
    end

    -- RIGHT SIDE: Commodity list with rate controls
    local listX = x + catW + 20
    local listY = y + 60
    local listW = w - catW - 40
    local listH = h - 120

    love.graphics.setColor(0.12, 0.12, 0.14)
    love.graphics.rectangle("fill", listX, listY, listW, listH, 5, 5)

    -- Filter commodities by selected category
    local filteredCommodities = {}
    for _, c in ipairs(commodities) do
        local include = false
        if self.selectedInjectorCategory == nil then
            include = true
        elseif self.selectedInjectorCategory == "nonzero" then
            include = (self.injectionRates[c.id] or 0) > 0
        else
            include = c.category == self.selectedInjectorCategory
        end
        if include then
            table.insert(filteredCommodities, c)
        end
    end

    -- Enable scissor for scrolling
    love.graphics.setScissor(listX, listY, listW, listH)

    -- Render commodities
    local itemH = 45
    local itemY = listY + 5 - self.injectorCommodityScrollOffset
    local totalContentHeight = 0

    for _, c in ipairs(filteredCommodities) do
        if itemY + itemH >= listY and itemY <= listY + listH then
            local rate = self.injectionRates[c.id] or 0
            local currentStock = self.townInventory[c.id] or 0

            -- Item background
            if rate > 0 then
                love.graphics.setColor(0.25, 0.35, 0.25)
            else
                love.graphics.setColor(0.2, 0.2, 0.22)
            end
            love.graphics.rectangle("fill", listX + 5, itemY, listW - 10, itemH - 3, 4, 4)

            -- Commodity name
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(c.name, listX + 15, itemY + 5, 0, 0.9, 0.9)

            -- Category and stock
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(c.category .. " | Stock: " .. currentStock, listX + 15, itemY + 24, 0, 0.7, 0.7)

            -- Rate display
            love.graphics.setColor(1, 1, 1)
            local rateText = tostring(rate) .. "/min"
            love.graphics.print(rateText, listX + listW - 150, itemY + 12, 0, 0.9, 0.9)

            -- - button
            local btnSize = 28
            local minusX = listX + listW - 80
            local minusY = itemY + 8
            love.graphics.setColor(0.5, 0.3, 0.3)
            love.graphics.rectangle("fill", minusX, minusY, btnSize, btnSize, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("-", minusX + 10, minusY + 4, 0, 1.0, 1.0)

            local commodityId = c.id
            table.insert(self.buttons, {
                x = minusX, y = minusY, w = btnSize, h = btnSize,
                onClick = function()
                    self.injectionRates[commodityId] = math.max(0, (self.injectionRates[commodityId] or 0) - 1)
                end
            })

            -- + button
            local plusX = listX + listW - 45
            love.graphics.setColor(0.3, 0.5, 0.3)
            love.graphics.rectangle("fill", plusX, minusY, btnSize, btnSize, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("+", plusX + 9, minusY + 4, 0, 1.0, 1.0)

            table.insert(self.buttons, {
                x = plusX, y = minusY, w = btnSize, h = btnSize,
                onClick = function()
                    self.injectionRates[commodityId] = (self.injectionRates[commodityId] or 0) + 1
                end
            })
        end

        itemY = itemY + itemH
        totalContentHeight = totalContentHeight + itemH
    end

    love.graphics.setScissor()

    -- Scrollbar if needed
    local maxScroll = math.max(0, totalContentHeight - listH)
    if maxScroll > 0 then
        local scrollbarH = listH * (listH / totalContentHeight)
        local scrollbarY = listY + (self.injectorCommodityScrollOffset / maxScroll) * (listH - scrollbarH)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", listX + listW - 8, scrollbarY, 6, scrollbarH, 3, 3)
    end

    -- Store max scroll for mouse wheel handling
    self.injectorCommodityScrollMax = maxScroll

    -- Summary at bottom
    local totalRate = 0
    for _, rate in pairs(self.injectionRates) do
        totalRate = totalRate + rate
    end
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Total injection rate: " .. totalRate .. " items/minute | Showing: " .. #filteredCommodities .. "/" .. #commodities .. " commodities", x + 20, y + h - 45, 0, 0.9, 0.9)

    -- Close button
    self:RenderButton("Close", x + w - 100, y + h - 50, 80, 35, function()
        self.showResourceInjector = false
    end)
end

function ConsumptionPrototype:RenderInventoryModal()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local w = 700
    local h = 500
    local x = (screenW - w) / 2
    local y = (screenH - h) / 2

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Border
    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("TOWN INVENTORY", x + 20, y + 15, 0, 1.2, 1.2)

    -- Subtitle
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Current stock of all commodities", x + 20, y + 40, 0, 0.8, 0.8)

    -- Build category list from commodities
    local categories = {{id = "all", name = "All"}, {id = "instock", name = "In Stock"}}
    local categorySet = {}
    local commodities = self.commodities or {}
    for _, c in ipairs(commodities) do
        if c.category and not categorySet[c.category] then
            categorySet[c.category] = true
            table.insert(categories, {id = c.category, name = c.category:gsub("^%l", string.upper)})
        end
    end

    -- LEFT SIDE: Category filter
    local catX = x + 10
    local catY = y + 60
    local catW = 130
    local catH = h - 120

    love.graphics.setColor(0.12, 0.12, 0.14)
    love.graphics.rectangle("fill", catX, catY, catW, catH, 5, 5)

    -- Enable scissor for category scrolling
    love.graphics.setScissor(catX, catY, catW, catH)

    -- Category buttons with scrolling
    local catScrollOffset = self.inventoryCategoryScrollOffset or 0
    local btnY = catY + 5 - catScrollOffset
    local catTotalHeight = 0
    for _, category in ipairs(categories) do
        if btnY + 28 >= catY and btnY <= catY + catH then
            local isSelected = (self.selectedInventoryCategory == category.id) or
                              (self.selectedInventoryCategory == nil and category.id == "all")

            if isSelected then
                love.graphics.setColor(0.3, 0.5, 0.7)
            else
                love.graphics.setColor(0.22, 0.22, 0.25)
            end
            love.graphics.rectangle("fill", catX + 5, btnY, catW - 10, 28, 3, 3)

            love.graphics.setColor(1, 1, 1)
            love.graphics.print(category.name, catX + 12, btnY + 6, 0, 0.85, 0.85)
        end

        -- Store button for click handling
        local catId = category.id
        table.insert(self.buttons, {
            x = catX + 5, y = btnY, w = catW - 10, h = 28,
            onClick = function()
                if catId == "all" then
                    self.selectedInventoryCategory = nil
                else
                    self.selectedInventoryCategory = catId
                end
                self.inventoryScrollOffset = 0
            end
        })

        btnY = btnY + 32
        catTotalHeight = catTotalHeight + 32
    end

    love.graphics.setScissor()

    -- Category scrollbar if needed
    self.inventoryCategoryScrollMax = math.max(0, catTotalHeight - catH)
    if self.inventoryCategoryScrollMax > 0 then
        local scrollbarH = catH * (catH / catTotalHeight)
        local scrollbarY = catY + (catScrollOffset / self.inventoryCategoryScrollMax) * (catH - scrollbarH)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", catX + catW - 8, scrollbarY, 6, scrollbarH, 3, 3)
    end

    -- RIGHT SIDE: Commodity list with quantities
    local listX = x + catW + 20
    local listY = y + 60
    local listW = w - catW - 40
    local listH = h - 120

    love.graphics.setColor(0.12, 0.12, 0.14)
    love.graphics.rectangle("fill", listX, listY, listW, listH, 5, 5)

    -- Filter commodities by selected category
    local filteredCommodities = {}
    for _, c in ipairs(commodities) do
        local include = false
        local quantity = self.townInventory[c.id] or 0
        if self.selectedInventoryCategory == nil then
            include = true
        elseif self.selectedInventoryCategory == "instock" then
            include = quantity > 0
        else
            include = c.category == self.selectedInventoryCategory
        end
        if include then
            table.insert(filteredCommodities, {commodity = c, quantity = quantity})
        end
    end

    -- Enable scissor for scrolling
    love.graphics.setScissor(listX, listY, listW, listH)

    -- Render commodities
    local itemH = 40
    local itemY = listY + 5 - self.inventoryScrollOffset
    local totalContentHeight = 0

    for _, item in ipairs(filteredCommodities) do
        local c = item.commodity
        local quantity = item.quantity

        if itemY + itemH >= listY and itemY <= listY + listH then
            -- Item background
            if quantity > 0 then
                love.graphics.setColor(0.2, 0.3, 0.25)
            else
                love.graphics.setColor(0.18, 0.18, 0.2)
            end
            love.graphics.rectangle("fill", listX + 5, itemY, listW - 10, itemH - 3, 4, 4)

            -- Commodity name
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(c.name, listX + 15, itemY + 5, 0, 0.9, 0.9)

            -- Category
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(c.category, listX + 15, itemY + 22, 0, 0.7, 0.7)

            -- Quantity display
            if quantity > 0 then
                love.graphics.setColor(0.4, 0.9, 0.4)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
            end
            love.graphics.print(tostring(quantity), listX + listW - 80, itemY + 10, 0, 1.1, 1.1)
        end

        itemY = itemY + itemH
        totalContentHeight = totalContentHeight + itemH
    end

    love.graphics.setScissor()

    -- Scrollbar if needed
    local maxScroll = math.max(0, totalContentHeight - listH)
    if maxScroll > 0 then
        local scrollbarH = listH * (listH / totalContentHeight)
        local scrollbarY = listY + (self.inventoryScrollOffset / maxScroll) * (listH - scrollbarH)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", listX + listW - 8, scrollbarY, 6, scrollbarH, 3, 3)
    end

    -- Store max scroll for mouse wheel handling
    self.inventoryScrollMax = maxScroll

    -- Summary at bottom
    local totalItems = 0
    local totalTypes = 0
    for _, quantity in pairs(self.townInventory) do
        if quantity > 0 then
            totalTypes = totalTypes + 1
            totalItems = totalItems + quantity
        end
    end
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Total: " .. totalItems .. " items across " .. totalTypes .. " types | Showing: " .. #filteredCommodities .. " commodities", x + 20, y + h - 45, 0, 0.9, 0.9)

    -- Close button
    self:RenderButton("Close", x + w - 100, y + h - 50, 80, 35, function()
        self.showInventoryModal = false
    end)
end

function ConsumptionPrototype:RenderHeatmapModal()
    if not self.selectedCharacter then
        self.showHeatmapModal = false
        return
    end

    local char = self.selectedCharacter
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local w = 800
    local h = 550
    local x = (screenW - w) / 2
    local y = (screenH - h) / 2

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Border color based on type
    local borderColors = {
        base_cravings = {0.4, 0.5, 0.6},
        current_cravings = {0.5, 0.6, 0.4},
        satisfaction = {0.6, 0.5, 0.4}
    }
    local borderColor = borderColors[self.heatmapType] or {0.4, 0.4, 0.45}
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3])
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    -- Title
    local titles = {
        base_cravings = "BASE CRAVINGS",
        current_cravings = "CURRENT CRAVINGS",
        satisfaction = "SATISFACTION"
    }
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(titles[self.heatmapType] or "VECTOR", x + 20, y + 15, 0, 1.2, 1.2)

    -- Subtitle with level
    love.graphics.setColor(0.7, 0.7, 0.7)
    local levelText = self.heatmapLevel == "coarse" and "Coarse Level (9 dimensions)" or "Fine Level (49 dimensions)"
    love.graphics.print(char.name .. " - " .. levelText, x + 20, y + 40, 0, 0.9, 0.9)

    -- Level toggle buttons
    self:RenderButton("Coarse", x + w - 180, y + 15, 80, 28, function()
        self.heatmapLevel = "coarse"
    end, self.heatmapLevel == "coarse")

    self:RenderButton("Fine", x + w - 90, y + 15, 70, 28, function()
        self.heatmapLevel = "fine"
        self.heatmapScrollOffset = 0  -- Reset scroll when switching to fine
    end, self.heatmapLevel == "fine")

    -- Get vector data
    local vector = {}
    local labels = {}
    local maxValue = 100

    -- Build fine-to-coarse mapping from dimension definitions
    local fineDimensions = self.dimensionDefinitions and self.dimensionDefinitions.fineDimensions or {}
    local fineToCoarse = {}  -- fineIndex -> coarseKey
    for _, dim in ipairs(fineDimensions) do
        fineToCoarse[dim.index] = dim.parentCoarse
    end

    if self.heatmapLevel == "coarse" then
        -- Coarse level (9 dimensions)
        local coarseKeys = {"biological", "safety", "touch", "psychological", "social_status", "social_connection", "exotic_goods", "shiny_objects", "vice"}
        local coarseNames = {"Biological", "Safety", "Touch", "Psychological", "Social Status", "Social Connection", "Exotic Goods", "Shiny Objects", "Vice"}

        if self.heatmapType == "base_cravings" then
            -- Aggregate fine base cravings into coarse dimensions
            local coarseSums = {}
            local coarseCounts = {}
            for _, key in ipairs(coarseKeys) do
                coarseSums[key] = 0
                coarseCounts[key] = 0
            end

            if char.baseCravings then
                for fineIndex = 0, 48 do
                    local coarseKey = fineToCoarse[fineIndex]
                    if coarseKey and coarseSums[coarseKey] then
                        coarseSums[coarseKey] = coarseSums[coarseKey] + (char.baseCravings[fineIndex] or 0)
                        coarseCounts[coarseKey] = coarseCounts[coarseKey] + 1
                    end
                end
            end

            for i, key in ipairs(coarseKeys) do
                -- Average the fine values for each coarse dimension
                local count = coarseCounts[key] or 1
                vector[i] = count > 0 and (coarseSums[key] / count) or 0
                labels[i] = coarseNames[i]
            end
            maxValue = 5  -- base cravings are typically 0-5 range
        elseif self.heatmapType == "current_cravings" then
            -- Aggregate fine current cravings into coarse dimensions
            local coarseSums = {}
            local coarseCounts = {}
            for _, key in ipairs(coarseKeys) do
                coarseSums[key] = 0
                coarseCounts[key] = 0
            end

            if char.currentCravings then
                for fineIndex = 0, 48 do
                    local coarseKey = fineToCoarse[fineIndex]
                    if coarseKey and coarseSums[coarseKey] then
                        coarseSums[coarseKey] = coarseSums[coarseKey] + (char.currentCravings[fineIndex] or 0)
                        coarseCounts[coarseKey] = coarseCounts[coarseKey] + 1
                    end
                end
            end

            for i, key in ipairs(coarseKeys) do
                -- Sum the fine values for each coarse dimension
                vector[i] = coarseSums[key] or 0
                labels[i] = coarseNames[i]
            end
            maxValue = 50  -- accumulated cravings can get high
        else -- satisfaction
            for i, key in ipairs(coarseKeys) do
                vector[i] = char.satisfaction and char.satisfaction[key] or 0
                labels[i] = coarseNames[i]
            end
            maxValue = 100
        end

        -- Render coarse heatmap as grid
        local gridX = x + 30
        local gridY = y + 70
        local cellW = (w - 60) / 3
        local cellH = 50

        for i, label in ipairs(labels) do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local cx = gridX + col * cellW
            local cy = gridY + row * (cellH + 10)

            local value = vector[i] or 0

            -- For satisfaction, normalize with 0 as center
            local normalized
            if self.heatmapType == "satisfaction" then
                -- Range: -100 to 300, with 0 as neutral point
                -- Map: -100 -> 0, 0 -> 0.25, 100 -> 0.5, 300 -> 1.0
                normalized = (value + 100) / 400
            else
                normalized = value / maxValue
            end

            -- Cell background with color intensity
            local r, g, b = self:GetHeatmapColor(normalized, self.heatmapType)
            love.graphics.setColor(r, g, b, 0.8)
            love.graphics.rectangle("fill", cx, cy, cellW - 10, cellH, 5, 5)

            -- Border
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", cx, cy, cellW - 10, cellH, 5, 5)

            -- Label
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(label, cx + 8, cy + 8, 0, 0.85, 0.85)

            -- Value
            love.graphics.setColor(1, 1, 1)
            local valueStr = self.heatmapType == "satisfaction" and string.format("%.0f", value) or string.format("%.1f", value)
            love.graphics.print(valueStr, cx + 8, cy + 28, 0, 1.0, 1.0)
        end
    else
        -- Fine level (49 dimensions)
        -- Note: fineDimensions already defined above for fineToCoarse mapping

        -- Group by parent coarse
        local groups = {}
        for _, dim in ipairs(fineDimensions) do
            local parent = dim.parentCoarse or "unknown"
            if not groups[parent] then
                groups[parent] = {}
            end

            local value = 0
            local fineIndex = dim.index  -- 0-indexed
            if self.heatmapType == "base_cravings" then
                value = char.baseCravings and char.baseCravings[fineIndex] or 0
                maxValue = 5  -- base cravings are typically 0-5 range
            elseif self.heatmapType == "current_cravings" then
                value = char.currentCravings and char.currentCravings[fineIndex] or 0
                maxValue = 20  -- accumulated cravings can get higher
            else -- satisfaction - use parent coarse value since fine doesn't exist
                value = char.satisfaction and char.satisfaction[parent] or 0
                maxValue = 100
            end

            table.insert(groups[parent], {
                name = dim.name or dim.id,
                value = value,
                index = fineIndex
            })
        end

        -- Render fine heatmap grouped by coarse dimension
        local gridX = x + 20
        local gridY = y + 70
        local scrollAreaH = h - 130
        local groupOrder = {"biological", "safety", "touch", "psychological", "social_status", "social_connection", "exotic_goods", "shiny_objects", "vice"}
        local groupNames = {
            biological = "Biological",
            safety = "Safety",
            touch = "Touch",
            psychological = "Psychological",
            social_status = "Social Status",
            social_connection = "Social Connection",
            exotic_goods = "Exotic Goods",
            shiny_objects = "Shiny Objects",
            vice = "Vice"
        }

        local cellSize = 40
        local cellsPerRow = math.floor((w - 60) / cellSize)

        -- Calculate total content height first
        local totalContentHeight = 0
        for _, groupKey in ipairs(groupOrder) do
            local items = groups[groupKey] or {}
            if #items > 0 then
                totalContentHeight = totalContentHeight + 20  -- Group header
                local numRows = math.ceil(#items / cellsPerRow)
                totalContentHeight = totalContentHeight + numRows * cellSize + 10
            end
        end

        -- Update scroll max
        self.heatmapScrollMax = math.max(0, totalContentHeight - scrollAreaH)
        self.heatmapScrollOffset = math.max(0, math.min(self.heatmapScrollOffset, self.heatmapScrollMax))

        local currentY = gridY - self.heatmapScrollOffset

        -- Enable scissor for scrolling
        love.graphics.setScissor(x + 10, gridY, w - 20, scrollAreaH)

        for _, groupKey in ipairs(groupOrder) do
            local items = groups[groupKey] or {}
            if #items > 0 then
                -- Group header
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print(groupNames[groupKey] or groupKey, gridX, currentY, 0, 0.8, 0.8)
                currentY = currentY + 20

                -- Render cells
                for j, item in ipairs(items) do
                    local col = (j - 1) % cellsPerRow
                    local row = math.floor((j - 1) / cellsPerRow)
                    local cx = gridX + col * cellSize
                    local cy = currentY + row * cellSize

                    -- For satisfaction, normalize with 0 as center
                    local normalized
                    if self.heatmapType == "satisfaction" then
                        -- Range: -100 to 300, with 0 as neutral point
                        -- Map: -100 -> 0, 0 -> 0.25, 100 -> 0.5, 300 -> 1.0
                        normalized = (item.value + 100) / 400
                    else
                        normalized = item.value / maxValue
                    end

                    -- Cell background
                    local r, g, b = self:GetHeatmapColor(normalized, self.heatmapType)
                    love.graphics.setColor(r, g, b, 0.9)
                    love.graphics.rectangle("fill", cx, cy, cellSize - 3, cellSize - 3, 3, 3)

                    -- Value
                    love.graphics.setColor(1, 1, 1)
                    local valueStr = self.heatmapType == "satisfaction" and string.format("%.0f", item.value) or string.format("%.1f", item.value)
                    love.graphics.print(valueStr, cx + 3, cy + 3, 0, 0.6, 0.6)

                    -- Short name (first 5 chars)
                    local shortName = item.name:sub(1, 5)
                    love.graphics.print(shortName, cx + 3, cy + 18, 0, 0.5, 0.5)
                end

                local numRows = math.ceil(#items / cellsPerRow)
                currentY = currentY + numRows * cellSize + 10
            end
        end

        love.graphics.setScissor()

        -- Scrollbar for fine level
        if self.heatmapScrollMax > 0 then
            local scrollbarH = scrollAreaH * (scrollAreaH / totalContentHeight)
            local scrollbarY = gridY + (self.heatmapScrollOffset / self.heatmapScrollMax) * (scrollAreaH - scrollbarH)
            love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
            love.graphics.rectangle("fill", x + w - 18, scrollbarY, 6, scrollbarH, 3, 3)
        end
    end

    -- Legend
    local legendY = y + h - 70
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Legend:", x + 20, legendY, 0, 0.85, 0.85)

    local legendX = x + 80
    if self.heatmapType == "satisfaction" then
        -- Special legend for satisfaction: -100, 0, 100, 200, 300
        local legendValues = {-100, 0, 100, 200, 300}
        for i, val in ipairs(legendValues) do
            local normalized = (val + 100) / 400
            local r, g, b = self:GetHeatmapColor(normalized, self.heatmapType)
            love.graphics.setColor(r, g, b)
            love.graphics.rectangle("fill", legendX + (i-1) * 45, legendY, 40, 20, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(tostring(val), legendX + (i-1) * 45 + 8, legendY + 3, 0, 0.6, 0.6)
        end
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Negative", x + 80, legendY + 22, 0, 0.6, 0.6)
        love.graphics.print("Positive", x + 260, legendY + 22, 0, 0.6, 0.6)
    else
        for i = 0, 4 do
            local normalized = i / 4
            local r, g, b = self:GetHeatmapColor(normalized, self.heatmapType)
            love.graphics.setColor(r, g, b)
            love.graphics.rectangle("fill", legendX + i * 40, legendY, 35, 20, 3, 3)
        end
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Low", x + 80, legendY + 22, 0, 0.7, 0.7)
        love.graphics.print("High", x + 270, legendY + 22, 0, 0.7, 0.7)
    end

    -- Close button
    self:RenderButton("Close", x + w - 100, y + h - 50, 80, 35, function()
        self.showHeatmapModal = false
    end)
end

function ConsumptionPrototype:GetHeatmapColor(normalized, heatmapType)
    normalized = math.max(0, math.min(1, normalized))

    if heatmapType == "base_cravings" then
        -- Blue scheme
        return 0.2 + 0.3 * normalized, 0.3 + 0.4 * normalized, 0.5 + 0.5 * normalized
    elseif heatmapType == "current_cravings" then
        -- Green scheme
        return 0.2 + 0.3 * normalized, 0.4 + 0.5 * normalized, 0.2 + 0.3 * normalized
    else
        -- Satisfaction: Red-Yellow-Green with 0.25 as neutral (0 value)
        -- normalized: 0 = -100, 0.25 = 0, 0.5 = 100, 1.0 = 300
        if normalized < 0.25 then
            -- Deep red to lighter red (very negative to neutral)
            local t = normalized / 0.25  -- 0 to 1
            return 0.6 + 0.2 * t, 0.1 + 0.3 * t, 0.1 + 0.2 * t
        elseif normalized < 0.5 then
            -- Yellow/neutral to light green (0 to 100)
            local t = (normalized - 0.25) / 0.25  -- 0 to 1
            return 0.8 - 0.3 * t, 0.4 + 0.4 * t, 0.3
        else
            -- Light green to bright green (100 to 300)
            local t = (normalized - 0.5) / 0.5  -- 0 to 1
            return 0.5 - 0.3 * t, 0.8 + 0.2 * t, 0.3 + 0.4 * t
        end
    end
end

function ConsumptionPrototype:RenderButton(text, x, y, w, h, onClick, isActive, customColor)
    local mx, my = love.mouse.getPosition()
    local isHovered = mx >= x and mx <= x + w and my >= y and my <= y + h

    -- Button color
    if customColor then
        if isActive then
            love.graphics.setColor(customColor[1] * 1.2, customColor[2] * 1.2, customColor[3] * 1.2)
        elseif isHovered then
            love.graphics.setColor(customColor[1] * 0.9, customColor[2] * 0.9, customColor[3] * 0.9)
        else
            love.graphics.setColor(customColor[1] * 0.7, customColor[2] * 0.7, customColor[3] * 0.7)
        end
    else
        if isActive then
            love.graphics.setColor(0.4, 0.7, 0.9)
        elseif isHovered then
            love.graphics.setColor(0.25, 0.25, 0.30)
        else
            love.graphics.setColor(0.20, 0.20, 0.25)
        end
    end

    love.graphics.rectangle("fill", x, y, w, h, 3, 3)

    -- Border
    if isActive then
        love.graphics.setColor(0.6, 0.9, 1.0)
    else
        love.graphics.setColor(0.4, 0.4, 0.45)
    end
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 3, 3)

    -- Text
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local scale = math.min(1, (w - 10) / textWidth * 0.85)
    love.graphics.print(text, x + (w - textWidth * scale) / 2, y + (h - font:getHeight() * scale) / 2, 0, scale, scale)

    -- Store click handler
    if not self.buttons then
        self.buttons = {}
    end
    table.insert(self.buttons, {x = x, y = y, w = w, h = h, onClick = onClick})
end

function ConsumptionPrototype:ResetCharacterCreator()
    self.creatorName = ""
    self.creatorClass = "Middle"
    self.creatorTraits = {}
    self.creatorAge = 30
    self.creatorVocation = nil
    self.creatorVocationScrollOffset = 0
end

function ConsumptionPrototype:GetSatisfactionColor(satisfaction)
    -- Handle full range: -100 to 300
    if satisfaction >= 150 then
        -- Very high (150-300): bright green
        return 0.2, 1, 0.4
    elseif satisfaction >= 80 then
        -- High (80-150): green
        return 0.3, 0.9, 0.3
    elseif satisfaction >= 40 then
        -- Good (40-80): yellow-green
        return 0.6, 0.85, 0.3
    elseif satisfaction >= 0 then
        -- Neutral (0-40): yellow
        return 0.9, 0.8, 0.2
    elseif satisfaction >= -50 then
        -- Low (-50 to 0): orange
        return 1, 0.5, 0.2
    else
        -- Critical (-100 to -50): red
        return 0.9, 0.2, 0.2
    end
end

function ConsumptionPrototype:GetClassColor(class)
    if class == "Elite" then
        return {0.9, 0.7, 0.2}
    elseif class == "Upper" then
        return {0.5, 0.7, 1}
    elseif class == "Middle" then
        return {0.6, 0.9, 0.6}
    else
        return {0.7, 0.7, 0.7}
    end
end

function ConsumptionPrototype:GetActiveCharacterCount()
    local count = 0
    for _, character in ipairs(self.characters) do
        if not character.hasEmigrated then
            count = count + 1
        end
    end
    return count
end

function ConsumptionPrototype:KeyPressed(key)
    if key == "escape" then
        if self.showCharacterCreator then
            self.showCharacterCreator = false
            self:ResetCharacterCreator()
        elseif self.showResourceInjector then
            self.showResourceInjector = false
        elseif self.showInventoryModal then
            self.showInventoryModal = false
        elseif self.showHeatmapModal then
            self.showHeatmapModal = false
        elseif self.showCharacterDetailModal then
            self.showCharacterDetailModal = false
            self.detailCharacter = nil
        else
            gMode = "launcher"
        end
    elseif key == "space" then
        self.isPaused = not self.isPaused
    elseif key == "tab" then
        local views = {"grid", "heatmap", "log"}
        local currentIndex = 1
        for i, view in ipairs(views) do
            if view == self.currentView then
                currentIndex = i
                break
            end
        end
        self.currentView = views[(currentIndex % #views) + 1]
    elseif self.showCharacterCreator then
        -- Handle text input for name
        if key == "backspace" then
            self.creatorName = self.creatorName:sub(1, -2)
        elseif key == "return" then
            if self.creatorName ~= "" then
                self:AddCharacter(self.creatorName, self.creatorClass, self.creatorTraits, self.creatorAge)
                self.showCharacterCreator = false
                self:ResetCharacterCreator()
            end
        end
    end
end

function ConsumptionPrototype:TextInput(t)
    if self.showCharacterCreator then
        if #self.creatorName < 20 then
            self.creatorName = self.creatorName .. t
        end
    end
end

function ConsumptionPrototype:OnMouseWheel(dx, dy)
    local mx, my = love.mouse.getPosition()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local modalW, modalH = 700, 500
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2
    local catX = modalX + 10
    local catW = 130
    local catY = modalY + 60
    local catH = modalH - 120
    local scrollAmount = dy * 30

    -- Handle scrolling in resource injector
    if self.showResourceInjector then
        -- Check if mouse is over category list or commodity list
        if mx >= catX and mx <= catX + catW and my >= catY and my <= catY + catH then
            -- Scroll categories
            self.injectorCategoryScrollOffset = self.injectorCategoryScrollOffset - scrollAmount
            self.injectorCategoryScrollOffset = math.max(0, math.min(self.injectorCategoryScrollOffset, self.injectorCategoryScrollMax or 0))
        else
            -- Scroll commodities
            self.injectorCommodityScrollOffset = self.injectorCommodityScrollOffset - scrollAmount
            self.injectorCommodityScrollOffset = math.max(0, math.min(self.injectorCommodityScrollOffset, self.injectorCommodityScrollMax or 0))
        end
    elseif self.showInventoryModal then
        -- Check if mouse is over category list or commodity list
        if mx >= catX and mx <= catX + catW and my >= catY and my <= catY + catH then
            -- Scroll categories
            self.inventoryCategoryScrollOffset = (self.inventoryCategoryScrollOffset or 0) - scrollAmount
            self.inventoryCategoryScrollOffset = math.max(0, math.min(self.inventoryCategoryScrollOffset, self.inventoryCategoryScrollMax or 0))
        else
            -- Scroll inventory list
            self.inventoryScrollOffset = (self.inventoryScrollOffset or 0) - scrollAmount
            self.inventoryScrollOffset = math.max(0, math.min(self.inventoryScrollOffset, self.inventoryScrollMax or 0))
        end
    elseif self.showHeatmapModal and self.heatmapLevel == "fine" then
        -- Scroll fine level heatmap
        self.heatmapScrollOffset = (self.heatmapScrollOffset or 0) - scrollAmount
        self.heatmapScrollOffset = math.max(0, math.min(self.heatmapScrollOffset, self.heatmapScrollMax or 0))
    elseif self.showCharacterCreator then
        -- Scroll vocation list
        self.creatorVocationScrollOffset = (self.creatorVocationScrollOffset or 0) - scrollAmount
        self.creatorVocationScrollOffset = math.max(0, math.min(self.creatorVocationScrollOffset, self.creatorVocationScrollMax or 0))
    elseif self.showCharacterDetailModal then
        -- Scroll character detail modal
        self.detailScrollOffset = (self.detailScrollOffset or 0) - scrollAmount
        self.detailScrollOffset = math.max(0, math.min(self.detailScrollOffset, self.detailScrollMax or 0))
    else
        -- Check if mouse is over event log area
        local centerX = self.leftPanelWidth
        local centerW = screenW - self.leftPanelWidth - self.rightPanelWidth
        local centerY = self.topBarHeight
        local centerH = screenH - self.topBarHeight
        local gridH = math.floor(centerH * 0.6)
        local logY = centerY + gridH
        local logH = centerH - gridH

        if mx >= centerX and mx <= centerX + centerW and
           my >= logY and my <= logY + logH then
            -- Scroll event log
            self.eventLogScrollOffset = (self.eventLogScrollOffset or 0) - scrollAmount
            self.eventLogScrollOffset = math.max(0, math.min(self.eventLogScrollOffset, self.eventLogScrollMax or 0))
        end
    end
end

function ConsumptionPrototype:MousePressed(x, y, button)
    -- Nothing needed here - buttons are cleared at start of Render
end

function ConsumptionPrototype:MouseReleased(x, y, button)
    if button == 1 and self.buttons then
        -- Check button clicks in REVERSE order (last added first)
        -- This ensures modal buttons (added last) are checked before background buttons
        for i = #self.buttons, 1, -1 do
            local btn = self.buttons[i]
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                btn.onClick()
                self.buttons = {}
                return
            end
        end

        -- If any modal is open and click didn't hit a button, block the click
        if self.showCharacterCreator or self.showResourceInjector or
           self.showInventoryModal or self.showHeatmapModal or self.showCharacterDetailModal then
            -- Click was on modal backdrop, ignore it
            return
        end

        -- Check character card clicks (only if not in modal)
        for _, character in ipairs(self.characters) do
            if not character.hasEmigrated then
                local cx, cy, cw, ch = character.position.x, character.position.y, 110, 90
                if x >= cx and x <= cx + cw and y >= cy and y <= cy + ch then
                    self.selectedCharacter = character
                    return
                end
            end
        end
    end
end

return ConsumptionPrototype
