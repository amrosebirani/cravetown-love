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
        prototype.dimensionDefinitions,
        prototype.characterClasses,
        prototype.commodityFatigueRates,
        prototype.enablementRules
    )
    CommodityCache.Init(prototype.dimensionDefinitions, prototype.fulfillmentVectors)
    AllocationEngineV2.Init(prototype.consumptionMechanics, prototype.fulfillmentVectors, prototype.substitutionRules)
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

    -- Character creator state
    prototype.creatorName = ""
    prototype.creatorClass = "Middle"
    prototype.creatorTraits = {}
    prototype.creatorAge = 30

    -- Resource injector state
    prototype.injectorCommodity = "wheat"
    prototype.injectorAmount = 10

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
        end

        local massEmigration, emigrantCount = TownConsequences.CheckMassEmigration(self.characters, self.cycleNumber)
        if massEmigration then
            print("📉 MASS EMIGRATION: " .. emigrantCount .. " characters emigrated this cycle")
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

function ConsumptionPrototype:AddCharacter(class, traits)
    -- Use CharacterV2 for Phase 5
    local char = CharacterV2:New(class, nil)
    -- Auto-generate biographical info
    char.name = CharacterV2.GenerateRandomName()
    char.age = math.random(18, 65)
    char.vocation = CharacterV2.GetRandomVocation()
    char.traits = traits

    -- Position in grid (calculate based on current count)
    local count = #self.characters
    local col = count % 8
    local row = math.floor(count / 8)
    char.position.x = self.leftPanelWidth + 20 + col * 120
    char.position.y = self.topBarHeight + 20 + row * 100

    table.insert(self.characters, char)
    print("Added character: " .. char.name .. " (" .. class .. ") with traits: " .. table.concat(traits, ", "))
end

function ConsumptionPrototype:InjectResource(commodity, amount)
    self.townInventory[commodity] = (self.townInventory[commodity] or 0) + amount
    print("Injected +" .. amount .. " " .. commodity .. " (total: " .. self.townInventory[commodity] .. ")")
end

function ConsumptionPrototype:Render()
    love.graphics.clear(0.12, 0.12, 0.15)

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
    contentY = contentY + 30

    -- List all commodities in inventory
    local hasInventory = false
    for commodity, quantity in pairs(self.townInventory) do
        if quantity > 0 then
            hasInventory = true
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(commodity .. ":", x + 30, contentY, 0, 0.85, 0.85)
            love.graphics.print(quantity, x + w - 60, contentY, 0, 0.85, 0.85)
            contentY = contentY + 20
        end
    end

    if not hasInventory then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("(empty - inject resources)", x + 30, contentY, 0, 0.8, 0.8)
        contentY = contentY + 25
    end

    contentY = contentY + 20

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
    y = y + 25

    -- Traits
    if #char.traits > 0 then
        love.graphics.print("Traits: " .. table.concat(char.traits, ", "), x, y, 0, 0.75, 0.75)
        y = y + 20
    end

    y = y + 10

    -- Cravings
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Cravings:", x, y, 0, 0.9, 0.9)
    y = y + 20

    local cravingNames = {
        "Biological", "Safety", "Touch", "Psychological",
        "Social Status", "Social Connection", "Exotic Goods",
        "Shiny Objects", "Vice"
    }
    local cravingKeys = {
        "biological", "safety", "touch", "psychological",
        "social_status", "social_connection", "exotic_goods",
        "shiny_objects", "vice"
    }

    for i, key in ipairs(cravingKeys) do
        local value = char.satisfaction[key] or 0
        local r, g, b = self:GetSatisfactionColor(value)

        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(cravingNames[i] .. ":", x, y, 0, 0.75, 0.75)

        love.graphics.setColor(r, g, b)
        love.graphics.print(string.format("%.0f%%", value), x + width - 50, y, 0, 0.75, 0.75)

        y = y + 18
    end
end

function ConsumptionPrototype:RenderCenterPanel()
    local x = self.leftPanelWidth
    local y = self.topBarHeight
    local w = love.graphics.getWidth() - self.leftPanelWidth - self.rightPanelWidth
    local h = love.graphics.getHeight() - self.topBarHeight

    -- Background
    love.graphics.setColor(0.09, 0.09, 0.12)
    love.graphics.rectangle("fill", x, y, w, h)

    if #self.characters == 0 then
        -- Empty state message
        love.graphics.setColor(0.5, 0.5, 0.5)
        local msg = "No characters yet. Click 'Add Character' to begin."
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(msg)
        love.graphics.print(msg, x + (w - textWidth) / 2, y + h / 2 - 10)
    else
        -- Render character cards
        for _, character in ipairs(self.characters) do
            if not character.hasEmigrated then
                self:RenderCharacterCard(character)
            end
        end
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
    local w = 500
    local h = 450
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
        local bx = x + 120 + (i - 1) * 90
        local isSelected = self.creatorClass == class
        self:RenderButton(class, bx, formY - 5, 85, 30, function()
            self.creatorClass = class
        end, isSelected)
    end
    formY = formY + 50

    -- Traits section
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Traits:", x + 20, formY, 0, 0.9, 0.9)
    formY = formY + 30

    local availableTraits = self.consumptionMechanics.characterGeneration.traits.available
    for i, trait in ipairs(availableTraits) do
        local row = math.floor((i - 1) / 2)
        local col = (i - 1) % 2
        local bx = x + 20 + col * 230
        local by = formY + row * 35

        local isSelected = false
        for _, selectedTrait in ipairs(self.creatorTraits) do
            if selectedTrait == trait.id then
                isSelected = true
                break
            end
        end

        self:RenderButton(trait.name, bx, by, 220, 30, function()
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
        self:AddCharacter(self.creatorClass, self.creatorTraits)
        self.showCharacterCreator = false
        self:ResetCharacterCreator()
    end, false, {0.3, 0.7, 0.4})
end

function ConsumptionPrototype:RenderResourceInjector()
    local w = 450
    local h = 400
    local x = (love.graphics.getWidth() - w) / 2
    local y = (love.graphics.getHeight() - h) / 2

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Modal background
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Border
    love.graphics.setColor(0.4, 0.7, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("INJECT RESOURCES", x + 20, y + 20, 0, 1.3, 1.3)

    local formY = y + 70

    -- Quick inject buttons
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Quick Inject (10 units):", x + 20, formY, 0, 0.9, 0.9)
    formY = formY + 30

    local quickCommodities = {"wheat", "bread", "meat", "cloth", "books", "wine", "beer", "furniture"}
    for i, commodity in ipairs(quickCommodities) do
        local row = math.floor((i - 1) / 3)
        local col = (i - 1) % 3
        local bx = x + 20 + col * 135
        local by = formY + row * 40

        self:RenderButton(commodity, bx, by, 130, 35, function()
            self:InjectResource(commodity, 10)
        end, false, {0.3, 0.6, 0.8})
    end

    formY = formY + math.ceil(#quickCommodities / 3) * 40 + 30

    -- Custom injection
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Custom Amount:", x + 20, formY, 0, 0.9, 0.9)
    formY = formY + 25

    -- Amount input
    love.graphics.print("Quantity:", x + 30, formY, 0, 0.85, 0.85)
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", x + 120, formY - 5, 100, 30, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tostring(self.injectorAmount), x + 130, formY, 0, 0.85, 0.85)

    -- Buttons for amount
    self:RenderButton("-", x + 230, formY - 5, 30, 30, function()
        self.injectorAmount = math.max(1, self.injectorAmount - 10)
    end)
    self:RenderButton("+", x + 265, formY - 5, 30, 30, function()
        self.injectorAmount = self.injectorAmount + 10
    end)

    formY = formY + 40

    -- Inject button
    self:RenderButton("Inject " .. self.injectorAmount .. " of selected commodity", x + 30, formY, 390, 40, function()
        -- Use first quick commodity for now
        self:InjectResource("wheat", self.injectorAmount)
    end, false, {0.3, 0.7, 0.4})

    -- Close button
    self:RenderButton("Close", x + w - 120, y + h - 50, 100, 35, function()
        self.showResourceInjector = false
    end)
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
end

function ConsumptionPrototype:GetSatisfactionColor(satisfaction)
    if satisfaction >= 80 then
        return 0.2, 1, 0.3
    elseif satisfaction >= 60 then
        return 0.5, 0.9, 0.3
    elseif satisfaction >= 40 then
        return 1, 0.8, 0.2
    elseif satisfaction >= 20 then
        return 1, 0.5, 0.2
    else
        return 1, 0.2, 0.2
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

function ConsumptionPrototype:MousePressed(x, y, button)
    if button == 1 then
        -- Reset buttons table
        self.buttons = {}
    end
end

function ConsumptionPrototype:MouseReleased(x, y, button)
    if button == 1 and self.buttons then
        -- Check button clicks
        for _, btn in ipairs(self.buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                btn.onClick()
                self.buttons = {}
                return
            end
        end

        -- Check character card clicks (only if not in modal)
        if not self.showCharacterCreator and not self.showResourceInjector then
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
end

return ConsumptionPrototype
