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
    prototype.expandedDimensions = {}  -- Track which coarse dimensions are expanded to show fine
    prototype.detailEditMode = false  -- Edit mode toggle for character detail modal

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

    -- Character grid scroll state
    prototype.characterGridScrollOffset = 0
    prototype.characterGridScrollMax = 0

    -- Analytics modal state (Phase 9)
    prototype.showAnalyticsModal = false
    prototype.analyticsTab = "heatmap"  -- "heatmap", "breakdown", "trends"
    prototype.analyticsHeatmapDimension = "all"  -- "all" or specific dimension key
    prototype.analyticsScrollOffset = 0
    prototype.analyticsScrollMax = 0

    -- Historical data for trends (Phase 9)
    prototype.historyMaxCycles = 20  -- Track last 20 cycles
    prototype.satisfactionHistory = {}  -- Array of {cycle, avgSatisfaction, byClass}
    prototype.populationHistory = {}  -- Array of {cycle, total, byClass, immigrated, emigrated, died}
    prototype.inventoryHistory = {}  -- Array of {cycle, commodities}

    -- Commodity consumption history for trends chart
    prototype.commodityConsumptionHistory = {}  -- {commodityId: [{cycle, quantity}]}
    prototype.consumptionHistoryMaxCycles = 50  -- Track last 50 cycles
    prototype.selectedTrendCommodity = nil  -- Currently selected commodity for trend chart

    -- Allocation Policy state (Phase 10)
    prototype.showAllocationPolicyModal = false
    prototype.allocationPolicyScrollOffset = 0
    prototype.allocationPolicyScrollMax = 0

    -- Policy settings (runtime overrides of consumption_mechanics)
    prototype.allocationPolicy = {
        -- Priority mode: "need_based" (default), "equality", "class_based"
        priorityMode = "need_based",

        -- Fairness mode: spreads resources more evenly when enabled
        fairnessEnabled = false,

        -- Class priority weights (multipliers)
        classPriorities = {
            Elite = 10,
            Upper = 7,
            Middle = 4,
            Working = 2,
            Poor = 1
        },

        -- Class consumption budgets (items per cycle per character)
        consumptionBudgets = {
            Elite = 10,
            Upper = 7,
            Middle = 5,
            Working = 3,
            Poor = 2
        },

        -- Dimension priority weights
        dimensionPriorities = {
            biological = 1.0,
            safety = 0.9,
            touch = 0.7,
            social_connection = 0.6,
            psychological = 0.5,
            social_status = 0.3,
            exotic_goods = 0.2,
            shiny_objects = 0.2,
            vice = 0.1
        },

        -- Substitution aggressiveness (0.0 = never substitute, 1.0 = always prefer fresh)
        substitutionAggressiveness = 0.5,

        -- Reserve threshold (0.0 - 1.0): keep this % of inventory in reserve
        reserveThreshold = 0.0,

        -- Presets for quick switching
        activePreset = nil  -- nil = custom
    }

    -- Predefined policy presets
    prototype.policyPresets = {
        {
            name = "Egalitarian",
            description = "Equal distribution, fairness enabled",
            settings = {
                priorityMode = "equality",
                fairnessEnabled = true,
                classPriorities = {Elite = 1, Upper = 1, Middle = 1, Working = 1, Poor = 1},
                consumptionBudgets = {Elite = 5, Upper = 5, Middle = 5, Working = 5, Poor = 5},
                reserveThreshold = 0.1
            }
        },
        {
            name = "Hierarchical",
            description = "Class-based priority, elites first",
            settings = {
                priorityMode = "class_based",
                fairnessEnabled = false,
                classPriorities = {Elite = 20, Upper = 10, Middle = 5, Working = 2, Poor = 1},
                consumptionBudgets = {Elite = 15, Upper = 10, Middle = 5, Working = 2, Poor = 1},
                reserveThreshold = 0.0
            }
        },
        {
            name = "Survival Focus",
            description = "Biological needs prioritized, high reserve",
            settings = {
                priorityMode = "need_based",
                fairnessEnabled = true,
                dimensionPriorities = {
                    biological = 1.0, safety = 1.0, touch = 0.3,
                    social_connection = 0.2, psychological = 0.2,
                    social_status = 0.1, exotic_goods = 0.0,
                    shiny_objects = 0.0, vice = 0.0
                },
                consumptionBudgets = {Elite = 3, Upper = 3, Middle = 3, Working = 3, Poor = 3},
                reserveThreshold = 0.2
            }
        },
        {
            name = "Balanced",
            description = "Default balanced settings",
            settings = {
                priorityMode = "need_based",
                fairnessEnabled = false,
                classPriorities = {Elite = 10, Upper = 7, Middle = 4, Working = 2, Poor = 1},
                consumptionBudgets = {Elite = 10, Upper = 7, Middle = 5, Working = 3, Poor = 2},
                dimensionPriorities = {
                    biological = 1.0, safety = 0.9, touch = 0.7,
                    social_connection = 0.6, psychological = 0.5,
                    social_status = 0.3, exotic_goods = 0.2,
                    shiny_objects = 0.2, vice = 0.1
                },
                substitutionAggressiveness = 0.5,
                reserveThreshold = 0.0
            }
        }
    }

    -- Testing Tools state (Phase 11)
    prototype.showTestingToolsModal = false
    prototype.testingToolsScrollOffset = 0
    prototype.testingToolsScrollMax = 0
    prototype.selectedScenario = nil

    -- Simulation control multipliers
    prototype.satisfactionDecayMultiplier = 1.0
    prototype.cravingGrowthMultiplier = 1.0

    -- Save/Load state (Phase 12)
    prototype.saveSlots = {nil, nil, nil, nil, nil}  -- 5 save slots
    prototype.saveSlotNames = {"Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5"}
    prototype.autoSaveEnabled = true
    prototype.autoSaveInterval = 5  -- Auto-save every N cycles
    prototype.lastAutoSaveCycle = 0
    prototype.showSaveLoadModal = false
    prototype.showHelpOverlay = false
    prototype.saveLoadScrollOffset = 0
    prototype.saveLoadScrollMax = 0
    prototype.saveDirectory = "saves"
    prototype.lastSaveMessage = nil
    prototype.lastSaveMessageTime = 0

    -- Scenario Templates for meaningful test populations
    prototype.scenarioTemplates = {
        {
            id = "balanced_town",
            name = "Balanced Town",
            description = "Diverse community with equal class representation",
            population = {min = 20, max = 30},
            classDistribution = {Elite = 0.15, Upper = 0.20, Middle = 0.30, Working = 0.25, Poor = 0.10},
            ageDistribution = {min = 18, max = 65, mean = 35},
            traitTendencies = {},  -- Random traits
            vocationFocus = nil,   -- All vocations
            satisfactionRange = {min = 40, max = 70},
            startingInventory = {bread = 50, milk = 50, potato = 30, meat = 20, simple_clothes = 20},
            injectionRates = {bread = 10, milk = 10, potato = 5}
        },
        {
            id = "wealthy_district",
            name = "Wealthy District",
            description = "Affluent area with high expectations and luxury demands",
            population = {min = 15, max = 25},
            classDistribution = {Elite = 0.40, Upper = 0.35, Middle = 0.20, Working = 0.05, Poor = 0.00},
            ageDistribution = {min = 25, max = 70, mean = 45},
            traitTendencies = {"ambitious", "materialistic"},
            vocationFocus = {"Merchant", "Lawyer", "Doctor", "Scholar"},
            satisfactionRange = {min = 50, max = 80},
            startingInventory = {bread = 30, wine = 40, perfume = 20, silk = 15, jewelry = 10, painting = 10},
            injectionRates = {bread = 5, wine = 8, perfume = 3}
        },
        {
            id = "working_class",
            name = "Working Class Town",
            description = "Industrial area focused on production and basic needs",
            population = {min = 30, max = 50},
            classDistribution = {Elite = 0.02, Upper = 0.08, Middle = 0.25, Working = 0.45, Poor = 0.20},
            ageDistribution = {min = 16, max = 55, mean = 30},
            traitTendencies = {"frugal"},
            vocationFocus = {"Farmer", "Blacksmith", "Carpenter", "Mason", "Miner", "Laborer"},
            satisfactionRange = {min = 30, max = 55},
            startingInventory = {bread = 80, milk = 80, potato = 50, beer = 30, hammer = 20},
            injectionRates = {bread = 15, milk = 15, potato = 8, beer = 5}
        },
        {
            id = "frontier_settlement",
            name = "Frontier Settlement",
            description = "Small pioneer community, survival-focused with scarce resources",
            population = {min = 8, max = 15},
            classDistribution = {Elite = 0.00, Upper = 0.10, Middle = 0.30, Working = 0.40, Poor = 0.20},
            ageDistribution = {min = 20, max = 50, mean = 32},
            traitTendencies = {"frugal", "anxious"},
            vocationFocus = {"Farmer", "Hunter", "Carpenter", "Blacksmith"},
            satisfactionRange = {min = 25, max = 50},
            startingInventory = {bread = 20, milk = 30, meat = 15, axe = 10},
            injectionRates = {bread = 3, milk = 5, meat = 2}
        },
        {
            id = "prosperous_era",
            name = "Prosperous Era",
            description = "Golden age - abundant resources, high satisfaction",
            population = {min = 25, max = 40},
            classDistribution = {Elite = 0.15, Upper = 0.25, Middle = 0.35, Working = 0.20, Poor = 0.05},
            ageDistribution = {min = 18, max = 65, mean = 38},
            traitTendencies = {"social", "hedonist"},
            vocationFocus = nil,
            satisfactionRange = {min = 65, max = 90},
            startingInventory = {bread = 100, milk = 100, meat = 60, wine = 50, potato = 80, cheese = 40, silk = 30},
            injectionRates = {bread = 20, milk = 20, meat = 10, wine = 8, potato = 15}
        },
        {
            id = "crisis_mode",
            name = "Crisis Mode",
            description = "Famine conditions - scarce resources, desperate population",
            population = {min = 20, max = 35},
            classDistribution = {Elite = 0.05, Upper = 0.10, Middle = 0.25, Working = 0.35, Poor = 0.25},
            ageDistribution = {min = 18, max = 60, mean = 35},
            traitTendencies = {"anxious"},
            vocationFocus = nil,
            satisfactionRange = {min = 10, max = 35},
            startingInventory = {bread = 10, milk = 15},
            injectionRates = {bread = 2, milk = 3}
        },
        {
            id = "class_divide",
            name = "Class Divide",
            description = "Extreme inequality - very rich and very poor, no middle class",
            population = {min = 25, max = 35},
            classDistribution = {Elite = 0.25, Upper = 0.10, Middle = 0.05, Working = 0.20, Poor = 0.40},
            ageDistribution = {min = 18, max = 70, mean = 40},
            traitTendencies = {},
            vocationFocus = nil,
            satisfactionRange = {min = 20, max = 80},  -- Wide range based on class
            satisfactionByClass = {Elite = {70, 90}, Upper = {55, 75}, Middle = {40, 55}, Working = {20, 40}, Poor = {10, 30}},
            startingInventory = {bread = 40, milk = 40, wine = 30, jewelry = 15, silk = 20},
            injectionRates = {bread = 8, milk = 8, wine = 5}
        },
        {
            id = "farming_village",
            name = "Farming Village",
            description = "Agricultural community with seasonal rhythms",
            population = {min = 20, max = 30},
            classDistribution = {Elite = 0.05, Upper = 0.10, Middle = 0.35, Working = 0.40, Poor = 0.10},
            ageDistribution = {min = 16, max = 70, mean = 38},
            traitTendencies = {"frugal"},
            vocationFocus = {"Farmer", "Miller", "Baker", "Cooper", "Brewer"},
            satisfactionRange = {min = 35, max = 60},
            startingInventory = {bread = 80, milk = 60, potato = 100, meat = 40, beer = 50, cheese = 30},
            injectionRates = {bread = 12, potato = 20, meat = 5, beer = 8}
        },
        {
            id = "trading_hub",
            name = "Trading Hub",
            description = "Cosmopolitan market town with exotic goods and diverse population",
            population = {min = 30, max = 45},
            classDistribution = {Elite = 0.12, Upper = 0.25, Middle = 0.35, Working = 0.20, Poor = 0.08},
            ageDistribution = {min = 20, max = 60, mean = 35},
            traitTendencies = {"ambitious", "social"},
            vocationFocus = {"Merchant", "Innkeeper", "Tailor", "Jeweler", "Clerk"},
            satisfactionRange = {min = 40, max = 70},
            startingInventory = {bread = 50, perfume = 40, silk = 30, jewelry = 25, wine = 40, honey = 30},
            injectionRates = {bread = 10, perfume = 8, silk = 5, wine = 6}
        },
        {
            id = "aging_population",
            name = "Aging Population",
            description = "Elderly community with different needs and lower energy",
            population = {min = 15, max = 25},
            classDistribution = {Elite = 0.15, Upper = 0.25, Middle = 0.35, Working = 0.20, Poor = 0.05},
            ageDistribution = {min = 50, max = 85, mean = 65},
            traitTendencies = {"frugal", "bookish"},
            vocationFocus = {"Scholar", "Priest", "Doctor", "Teacher"},
            satisfactionRange = {min = 45, max = 70},
            startingInventory = {bread = 40, medicine = 30, book = 25, honey = 20, chair = 15},
            injectionRates = {bread = 8, medicine = 5, honey = 4}
        },
        {
            id = "young_colony",
            name = "Young Colony",
            description = "New settlement of young pioneers with high growth potential",
            population = {min = 12, max = 20},
            classDistribution = {Elite = 0.00, Upper = 0.05, Middle = 0.40, Working = 0.45, Poor = 0.10},
            ageDistribution = {min = 18, max = 35, mean = 25},
            traitTendencies = {"ambitious", "social"},
            vocationFocus = {"Farmer", "Carpenter", "Blacksmith", "Hunter", "Mason"},
            satisfactionRange = {min = 40, max = 65},
            startingInventory = {bread = 30, milk = 40, axe = 25, meat = 20, beer = 15},
            injectionRates = {bread = 6, milk = 8, axe = 2, meat = 4}
        },
        {
            id = "religious_commune",
            name = "Religious Commune",
            description = "Spiritual community with simple living and strong social bonds",
            population = {min = 15, max = 25},
            classDistribution = {Elite = 0.05, Upper = 0.10, Middle = 0.50, Working = 0.30, Poor = 0.05},
            ageDistribution = {min = 20, max = 70, mean = 40},
            traitTendencies = {"ascetic", "bookish"},
            vocationFocus = {"Priest", "Farmer", "Baker", "Scholar", "Teacher"},
            satisfactionRange = {min = 50, max = 75},
            startingInventory = {bread = 60, milk = 60, book = 40, candle = 30, potato = 50},
            injectionRates = {bread = 12, milk = 12, potato = 10, book = 2}
        }
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
            -- Phase Durables: Update and apply active effects from durables/permanents
            for _, character in ipairs(self.characters) do
                if not character.hasEmigrated then
                    -- 1. Update effects (decay effectiveness, remove expired)
                    local expiredEffects = character:UpdateActiveEffects(self.cycleNumber)
                    if expiredEffects and #expiredEffects > 0 then
                        for _, effect in ipairs(expiredEffects) do
                            self:LogEvent("durable_expired", character.name .. "'s " .. effect.commodityId .. " has worn out", {
                                character = character.name,
                                commodity = effect.commodityId,
                                category = effect.category
                            })
                        end
                    end
                    -- 2. Apply passive satisfaction from active effects
                    character:ApplyActiveEffectsSatisfaction(self.cycleNumber)
                end
            end

            self:RunAllocationCycle()
            self.cycleTime = self.cycleTime - self.cycleDuration
            self.cycleNumber = self.cycleNumber + 1

            -- Check for auto-save
            self:CheckAutoSave()

            -- Update satisfaction after allocation (decay based on unfulfilled cravings)
            for _, character in ipairs(self.characters) do
                if not character.hasEmigrated then
                    character:UpdateSatisfaction(self.cycleNumber)
                end
            end

            -- Record historical data for analytics (Phase 9)
            self:RecordHistoricalData()
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

    -- Apply allocation policy settings
    local policy = self.allocationPolicy

    -- Create working inventory with reserve threshold applied
    local workingInventory = {}
    local reserveThreshold = policy.reserveThreshold or 0
    for commodity, quantity in pairs(self.townInventory) do
        -- Only allocate (1 - reserveThreshold) of inventory
        local allocatable = math.floor(quantity * (1 - reserveThreshold))
        if allocatable > 0 then
            workingInventory[commodity] = allocatable
        end
    end

    -- Determine allocation mode from policy
    local allocationMode = policy.fairnessEnabled and "fairness" or "standard"

    print(string.format("  Policy: mode=%s, fairness=%s, reserve=%.0f%%",
        policy.priorityMode, tostring(policy.fairnessEnabled), reserveThreshold * 100))

    -- Use AllocationEngineV2 with policy settings
    local allocationLog = AllocationEngineV2.AllocateCycle(
        self.characters,
        workingInventory,
        self.cycleNumber,
        allocationMode,
        policy  -- Pass full policy for advanced priority calculation
    )

    -- Apply the changes from workingInventory back to townInventory
    -- (only subtract what was actually consumed)
    for commodity, originalQty in pairs(self.townInventory) do
        local workingQty = workingInventory[commodity]
        if workingQty then
            local consumed = math.floor(originalQty * (1 - reserveThreshold)) - workingQty
            if consumed > 0 then
                self.townInventory[commodity] = originalQty - consumed
            end
        end
    end

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
    -- Also track commodity consumption for trends
    local cycleConsumption = {}  -- {commodityId: quantity}
    if allocationLog.allocations then
        for _, alloc in ipairs(allocationLog.allocations) do
            if alloc.status == "failed" then
                self:LogEvent("failure", alloc.characterName .. " couldn't get " .. (alloc.requestedCommodity or "resources"), {
                    character = alloc.characterName,
                    commodity = alloc.requestedCommodity
                })
            elseif alloc.status == "substituted" then
                -- Check if this is a durable acquisition
                if alloc.allocationType == "acquired" then
                    self:LogEvent("durable_acquired", alloc.characterName .. " acquired " .. (alloc.allocatedCommodity or "item") .. " (durable, substituted)", {
                        character = alloc.characterName,
                        commodity = alloc.allocatedCommodity,
                        wanted = alloc.requestedCommodity,
                        allocationType = alloc.allocationType
                    })
                else
                    self:LogEvent("substitution", alloc.characterName .. ": " ..
                        (alloc.allocatedCommodity or "?") .. " for " .. (alloc.requestedCommodity or "?"), {
                        character = alloc.characterName,
                        wanted = alloc.requestedCommodity,
                        got = alloc.allocatedCommodity
                    })
                end
                -- Track substituted commodity
                local commodity = alloc.allocatedCommodity
                if commodity then
                    cycleConsumption[commodity] = (cycleConsumption[commodity] or 0) + 1
                end
            elseif alloc.status == "granted" then
                -- Track granted commodity
                local commodity = alloc.allocatedCommodity
                if commodity then
                    cycleConsumption[commodity] = (cycleConsumption[commodity] or 0) + 1
                end
                -- Log durable acquisitions as notable events
                if alloc.allocationType == "acquired" then
                    self:LogEvent("durable_acquired", alloc.characterName .. " acquired " .. (alloc.allocatedCommodity or "item") .. " (durable)", {
                        character = alloc.characterName,
                        commodity = alloc.allocatedCommodity,
                        allocationType = alloc.allocationType
                    })
                end
            end
        end
    end

    -- Store consumption history for trends
    for commodity, quantity in pairs(cycleConsumption) do
        if not self.commodityConsumptionHistory[commodity] then
            self.commodityConsumptionHistory[commodity] = {}
        end
        table.insert(self.commodityConsumptionHistory[commodity], {
            cycle = self.cycleNumber,
            quantity = quantity
        })
        -- Trim to max cycles
        while #self.commodityConsumptionHistory[commodity] > self.consumptionHistoryMaxCycles do
            table.remove(self.commodityConsumptionHistory[commodity], 1)
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

    -- Position in grid (calculate based on current count and available width)
    local count = #self.characters
    local centerW = love.graphics.getWidth() - self.leftPanelWidth - self.rightPanelWidth
    local cardSpacing = 120  -- 110 card width + 10 gap
    local maxCols = math.max(1, math.floor((centerW - 40) / cardSpacing))  -- 40 = 20 margin each side
    local col = count % maxCols
    local row = math.floor(count / maxCols)
    char.position.x = self.leftPanelWidth + 20 + col * cardSpacing
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

    if self.showAnalyticsModal then
        self:RenderAnalyticsModal()
    end

    if self.showAllocationPolicyModal then
        self:RenderAllocationPolicyModal()
    end

    if self.showTestingToolsModal then
        self:RenderTestingToolsModal()
    end

    if self.showSaveLoadModal then
        self:RenderSaveLoadModal()
    end

    if self.showHelpOverlay then
        self:RenderHelpOverlay()
    end

    -- Show save message toast if recent
    if self.lastSaveMessage and (love.timer.getTime() - self.lastSaveMessageTime) < 3 then
        local msgW = 300
        local msgH = 40
        local msgX = (screenW - msgW) / 2
        local msgY = screenH - 80

        love.graphics.setColor(0.15, 0.3, 0.15, 0.9)
        love.graphics.rectangle("fill", msgX, msgY, msgW, msgH, 5, 5)
        love.graphics.setColor(0.3, 0.8, 0.4)
        love.graphics.rectangle("line", msgX, msgY, msgW, msgH, 5, 5)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf(self.lastSaveMessage, msgX, msgY + 12, msgW, "center")
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

    -- Analytics button (Phase 9)
    self:RenderButton("📊 Analytics", x + 20, buttonY, 210, 40, function()
        self.showAnalyticsModal = true
    end, false, {0.6, 0.4, 0.7})
    buttonY = buttonY + 50

    -- Allocation Policy button (Phase 10)
    self:RenderButton("⚖️ Allocation Policy", x + 20, buttonY, 210, 40, function()
        self.showAllocationPolicyModal = true
    end, false, {0.7, 0.5, 0.3})
    buttonY = buttonY + 50

    -- Testing Tools button (Phase 11)
    self:RenderButton("🧪 Testing Tools", x + 20, buttonY, 210, 40, function()
        self.showTestingToolsModal = true
    end, false, {0.5, 0.7, 0.6})
    buttonY = buttonY + 50

    -- Save/Load button (Phase 12)
    self:RenderButton("💾 Save/Load", x + 20, buttonY, 210, 40, function()
        self.showSaveLoadModal = true
    end, false, {0.4, 0.5, 0.7})
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

    -- Update character positions for current window size
    self:UpdateCharacterPositions()

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
        -- Calculate total content height for scrolling
        local cardSpacing = 120
        local cardHeight = 100
        local maxCols = math.max(1, math.floor((w - 40) / cardSpacing))
        local visibleCharCount = 0
        for _, char in ipairs(self.characters) do
            if not char.hasEmigrated then
                visibleCharCount = visibleCharCount + 1
            end
        end
        local totalRows = math.ceil(visibleCharCount / maxCols)
        local totalContentH = totalRows * cardHeight + 20  -- 20 for padding

        -- Update scroll limits
        self.characterGridScrollMax = math.max(0, totalContentH - gridH)
        self.characterGridScrollOffset = math.max(0, math.min(self.characterGridScrollOffset, self.characterGridScrollMax))

        -- Scissor for clipping
        love.graphics.setScissor(x, y, w, gridH)

        -- Render character cards with scroll offset
        for _, character in ipairs(self.characters) do
            if not character.hasEmigrated then
                -- Offset y position by scroll
                local cardY = character.position.y - self.characterGridScrollOffset
                -- Only render if visible
                if cardY + cardHeight > y and cardY < y + gridH then
                    self:RenderCharacterCardAt(character, character.position.x, cardY)
                end
            end
        end

        love.graphics.setScissor()

        -- Scrollbar for character grid
        if self.characterGridScrollMax > 0 then
            local scrollbarH = gridH * (gridH / totalContentH)
            scrollbarH = math.max(30, scrollbarH)
            local scrollbarY = y + (self.characterGridScrollOffset / self.characterGridScrollMax) * (gridH - scrollbarH)
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.rectangle("fill", x + w - 12, y, 8, gridH)
            love.graphics.setColor(0.5, 0.5, 0.55)
            love.graphics.rectangle("fill", x + w - 12, scrollbarY, 8, scrollbarH, 4, 4)
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
    local h = 750  -- Increased for Possessions section
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

    -- Edit Mode toggle button
    local editBtnColor = self.detailEditMode and {0.8, 0.5, 0.2} or {0.3, 0.5, 0.3}
    local editBtnText = self.detailEditMode and "Exit Edit" or "Edit Mode"
    self:RenderButton(editBtnText, x + w - 160, y + 12, 70, 26, function()
        self.detailEditMode = not self.detailEditMode
    end, false, editBtnColor)

    -- Close button
    self:RenderButton("X", x + w - 40, y + 10, 30, 30, function()
        self.showCharacterDetailModal = false
        self.detailCharacter = nil
        self.detailEditMode = false
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
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Traits:", contentX, scrollY, 0, 0.8, 0.8)

    if self.detailEditMode then
        -- Edit mode: Show each trait with X button to remove, and + button to add
        local traitX = contentX + 50
        local availableTraits = self.characterTraits and self.characterTraits.traits or {}

        -- Show current traits with remove buttons
        if char.traits and #char.traits > 0 then
            for idx, traitId in ipairs(char.traits) do
                -- Find trait name
                local traitName = traitId
                for _, t in ipairs(availableTraits) do
                    if t.id == traitId then
                        traitName = t.name
                        break
                    end
                end

                love.graphics.setColor(0.6, 0.75, 0.8)
                love.graphics.print(traitName, traitX, scrollY, 0, 0.7, 0.7)

                -- Remove button
                local textW = love.graphics.getFont():getWidth(traitName) * 0.7
                self:RenderButton("x", traitX + textW + 5, scrollY - 1, 14, 14, function()
                    -- Remove trait and recalculate base cravings
                    table.remove(char.traits, idx)
                    char.baseCravings = CharacterV2.GenerateBaseCravings(char.class, char.traits)
                end, false, {0.6, 0.3, 0.3})

                traitX = traitX + textW + 25
            end
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("None", traitX, scrollY, 0, 0.7, 0.7)
            traitX = traitX + 35
        end
        scrollY = scrollY + 18

        -- Add trait dropdown (show traits not already on character)
        love.graphics.setColor(0.5, 0.6, 0.5)
        love.graphics.print("Add Trait:", contentX, scrollY, 0, 0.7, 0.7)
        local addX = contentX + 65
        local addedCount = 0
        for _, traitData in ipairs(availableTraits) do
            -- Check if character already has this trait
            local hasTrait = false
            if char.traits then
                for _, existingTrait in ipairs(char.traits) do
                    if existingTrait == traitData.id then
                        hasTrait = true
                        break
                    end
                end
            end

            if not hasTrait and addedCount < 6 then  -- Show max 6 buttons per row
                self:RenderButton("+" .. traitData.name, addX, scrollY - 2, 75, 16, function()
                    if not char.traits then char.traits = {} end
                    table.insert(char.traits, traitData.id)
                    char.baseCravings = CharacterV2.GenerateBaseCravings(char.class, char.traits)
                end, false, {0.3, 0.5, 0.3})
                addX = addX + 80
                addedCount = addedCount + 1
            end
        end
        scrollY = scrollY + 20
    else
        -- View mode: Just show trait list
        local traitStr = char.traits and #char.traits > 0 and table.concat(char.traits, ", ") or "None"
        love.graphics.print(" " .. traitStr, contentX + 40, scrollY, 0, 0.8, 0.8)
        scrollY = scrollY + 18
    end

    -- Enablements (what they can access)
    love.graphics.setColor(0.6, 0.7, 0.6)
    love.graphics.print("Enablements:", contentX, scrollY, 0, 0.75, 0.75)

    if self.detailEditMode then
        -- Edit mode: Show toggle buttons for each enablement rule
        local enablementRules = self.enablementRules and self.enablementRules.rules or {}
        scrollY = scrollY + 16

        local enableX = contentX + 10
        local enableCount = 0
        for _, rule in ipairs(enablementRules) do
            local isApplied = char.appliedEnablements and char.appliedEnablements[rule.id] ~= nil

            local btnColor = isApplied and {0.3, 0.6, 0.3} or {0.4, 0.4, 0.4}
            local btnText = (isApplied and "✓ " or "○ ") .. (rule.name or rule.id)

            self:RenderButton(btnText, enableX, scrollY, 130, 16, function()
                if not char.appliedEnablements then char.appliedEnablements = {} end

                if isApplied then
                    -- Remove enablement and reverse its effect on base cravings
                    if rule.effect and rule.effect.cravingModifier and rule.effect.cravingModifier.fine then
                        for i = 0, 48 do
                            local modifier = rule.effect.cravingModifier.fine[i + 1] or 0
                            if modifier ~= 0 then
                                char.baseCravings[i] = math.max(0, char.baseCravings[i] - modifier)
                            end
                        end
                    end
                    char.appliedEnablements[rule.id] = nil
                else
                    -- Apply enablement effect to base cravings
                    if rule.effect and rule.effect.cravingModifier and rule.effect.cravingModifier.fine then
                        for i = 0, 48 do
                            local modifier = rule.effect.cravingModifier.fine[i + 1] or 0
                            if modifier ~= 0 then
                                char.baseCravings[i] = char.baseCravings[i] + modifier
                            end
                        end
                    end
                    char.appliedEnablements[rule.id] = self.cycleNumber
                end
            end, false, btnColor)

            enableX = enableX + 135
            enableCount = enableCount + 1

            if enableCount % 6 == 0 then
                enableX = contentX + 10
                scrollY = scrollY + 20
            end
        end
        if enableCount % 6 ~= 0 then
            scrollY = scrollY + 20
        end
        scrollY = scrollY + 5
    else
        -- View mode: Just show applied enablements
        local enablements = char.appliedEnablements or {}
        local enableStr = ""
        if next(enablements) then
            local enabled = {}
            local enablementRules = self.enablementRules and self.enablementRules.rules or {}
            for ruleId, _ in pairs(enablements) do
                -- Find rule name
                local ruleName = ruleId
                for _, rule in ipairs(enablementRules) do
                    if rule.id == ruleId then
                        ruleName = rule.name or rule.id
                        break
                    end
                end
                table.insert(enabled, ruleName)
            end
            enableStr = #enabled > 0 and table.concat(enabled, ", ") or "None"
        else
            enableStr = "Standard access"
        end
        love.graphics.print(" " .. enableStr, contentX + 78, scrollY, 0, 0.75, 0.75)
        scrollY = scrollY + 18
    end
    scrollY = scrollY + 7

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
    scrollY = scrollY + padding

    -- ==========================================================================
    -- SECTION 2: Satisfaction Bars (9 coarse dimensions with expand/collapse)
    -- ==========================================================================
    love.graphics.setColor(0.4, 0.8, 0.6)
    love.graphics.print("SATISFACTION (9 Dimensions)", contentX, scrollY, 0, 0.9, 0.9)

    -- Expand All / Collapse All buttons
    if not self.expandedDimensions then self.expandedDimensions = {} end
    local allExpanded = true
    local anyExpanded = false
    for i = 0, 8 do
        if self.expandedDimensions[i] then anyExpanded = true else allExpanded = false end
    end

    self:RenderButton(allExpanded and "Collapse All" or "Expand All", contentX + contentW - 80, scrollY - 2, 75, 18, function()
        if allExpanded then
            self.expandedDimensions = {}
        else
            for i = 0, 8 do self.expandedDimensions[i] = true end
        end
    end, false, {0.3, 0.4, 0.5})

    scrollY = scrollY + 22

    local cravingNames = {"Biological", "Safety", "Touch", "Psychological", "Social Status", "Social Connection", "Exotic Goods", "Shiny Objects", "Vice"}
    local cravingKeys = {"biological", "safety", "touch", "psychological", "social_status", "social_connection", "exotic_goods", "shiny_objects", "vice"}

    local barW = contentW - 200
    local barH = 8

    for i, key in ipairs(cravingKeys) do
        local coarseIdx = i - 1  -- 0-indexed
        local satValue = char.satisfaction and char.satisfaction[key] or 0
        local isExpanded = self.expandedDimensions[coarseIdx]

        -- Calculate coarse-level aggregated cravings
        local coarseCurrentCraving = 0
        local coarseBaseCraving = 0
        local fineCount = 0
        local fineRange = CharacterV2.coarseToFineMap and CharacterV2.coarseToFineMap[coarseIdx]
        if fineRange then
            for fineIdx = fineRange.start, fineRange.finish do
                coarseCurrentCraving = coarseCurrentCraving + (char.currentCravings and char.currentCravings[fineIdx] or 0)
                coarseBaseCraving = coarseBaseCraving + (char.baseCravings and char.baseCravings[fineIdx] or 0)
                fineCount = fineCount + 1
            end
        end

        -- Expand/collapse arrow (clickable)
        local arrow = isExpanded and "v" or ">"
        self:RenderButton(arrow, contentX, scrollY - 2, 16, 16, function()
            self.expandedDimensions[coarseIdx] = not self.expandedDimensions[coarseIdx]
        end, false, {0.25, 0.35, 0.45})

        -- Coarse dimension name (header)
        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.print(cravingNames[i], contentX + 20, scrollY, 0, 0.85, 0.85)
        scrollY = scrollY + 18

        -- Row 1: Satisfaction bar
        local labelX = contentX + 30
        local barX = contentX + 110
        local editBarW = self.detailEditMode and (barW - 70) or barW  -- Reduce bar width in edit mode
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Satisfaction", labelX, scrollY, 0, 0.65, 0.65)

        -- Satisfaction bar background
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, scrollY + 1, editBarW, barH, 2, 2)

        -- Center line (0 at 25%)
        local centerX = barX + editBarW * 0.25
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("fill", centerX - 1, scrollY, 2, barH + 2)

        -- Satisfaction bar fill
        if satValue < 0 then
            local negWidth = math.min((math.abs(satValue) / 100) * editBarW * 0.25, editBarW * 0.25)
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.rectangle("fill", centerX - negWidth, scrollY + 1, negWidth, barH, 2, 2)
        else
            local posWidth = math.min(satValue <= 100 and (satValue / 100) * editBarW * 0.25 or editBarW * 0.25 + ((satValue - 100) / 200) * editBarW * 0.5, editBarW * 0.75)
            local r, g, b = self:GetSatisfactionColor(satValue)
            love.graphics.setColor(r, g, b)
            love.graphics.rectangle("fill", centerX, scrollY + 1, posWidth, barH, 2, 2)
        end

        -- Value display
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%.0f", satValue), barX + editBarW + 5, scrollY, 0, 0.65, 0.65)

        -- Edit mode: +/- buttons for satisfaction (after the value)
        if self.detailEditMode then
            local btnX = barX + editBarW + 35
            self:RenderButton("-10", btnX, scrollY - 2, 28, 14, function()
                char.satisfaction[key] = math.max(-100, (char.satisfaction[key] or 0) - 10)
            end, false, {0.6, 0.3, 0.3})
            self:RenderButton("+10", btnX + 32, scrollY - 2, 28, 14, function()
                char.satisfaction[key] = math.min(300, (char.satisfaction[key] or 0) + 10)
            end, false, {0.3, 0.6, 0.3})
        end
        scrollY = scrollY + 14

        -- Row 2: Current Craving bar
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Craving", labelX, scrollY, 0, 0.65, 0.65)

        -- Craving bar background
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, scrollY + 1, editBarW, barH, 2, 2)

        local maxCoarseCraving = math.max(coarseBaseCraving * 50, 50)
        local cravingFill = math.min(coarseCurrentCraving / maxCoarseCraving, 1.0) * editBarW
        if cravingFill > 0 then
            local intensity = coarseCurrentCraving / maxCoarseCraving
            love.graphics.setColor(0.9 * intensity + 0.3, 0.7 * (1 - intensity) + 0.2, 0.2)
            love.graphics.rectangle("fill", barX, scrollY + 1, cravingFill, barH, 2, 2)
        end

        -- Value display with base value
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%.0f", coarseCurrentCraving), barX + editBarW + 5, scrollY, 0, 0.65, 0.65)
        love.graphics.setColor(0.45, 0.55, 0.65)
        love.graphics.print(string.format("(B:%.1f)", coarseBaseCraving), barX + editBarW + 30, scrollY, 0, 0.55, 0.55)

        -- Edit mode: Reset craving button for this dimension (after the value)
        if self.detailEditMode and fineRange then
            local btnX = barX + editBarW + 75
            self:RenderButton("Reset", btnX, scrollY - 2, 38, 14, function()
                for fineIdx = fineRange.start, fineRange.finish do
                    char.currentCravings[fineIdx] = 0
                end
            end, false, {0.5, 0.4, 0.3})
        end
        scrollY = scrollY + 16

        -- Show fine dimensions if expanded
        if isExpanded and fineRange then
            love.graphics.setColor(0.4, 0.4, 0.45)
            love.graphics.print("  Fine Dimensions:", contentX + 25, scrollY, 0, 0.7, 0.7)
            scrollY = scrollY + 16

            local fineBarW = 180
            local fineBarH = 6

            for fineIdx = fineRange.start, fineRange.finish do
                local fineName = CharacterV2.fineNames and CharacterV2.fineNames[fineIdx] or ("fine_" .. fineIdx)
                local fineValue = char.currentCravings and char.currentCravings[fineIdx] or 0
                local baseCraving = char.baseCravings and char.baseCravings[fineIdx] or 0

                -- Shorten fine dimension name (remove prefix)
                local shortName = fineName:gsub("^%w+_", "")

                -- Fine dimension name
                love.graphics.setColor(0.55, 0.55, 0.55)
                love.graphics.print("    " .. shortName, contentX + 30, scrollY, 0, 0.65, 0.65)

                -- Fine bar background
                local fineBarX = contentX + contentW - fineBarW - 90
                love.graphics.setColor(0.18, 0.18, 0.22)
                love.graphics.rectangle("fill", fineBarX, scrollY + 1, fineBarW, fineBarH, 2, 2)

                -- Fine bar fill
                local maxCraving = math.max(baseCraving * 50, 50)
                local fillWidth = math.min(fineValue / maxCraving, 1.0) * fineBarW
                if fillWidth > 0 then
                    local intensity = fineValue / maxCraving
                    love.graphics.setColor(0.3 + intensity * 0.6, 0.7 - intensity * 0.4, 0.3)
                    love.graphics.rectangle("fill", fineBarX, scrollY + 1, fillWidth, fineBarH, 2, 2)
                end

                -- Values
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.print(string.format("B:%.1f C:%.0f", baseCraving, fineValue), fineBarX + fineBarW + 6, scrollY, 0, 0.6, 0.6)

                scrollY = scrollY + 14
            end
            scrollY = scrollY + 4
        end

        -- Separator between coarse dimensions
        scrollY = scrollY + 4
        love.graphics.setColor(0.25, 0.25, 0.28)
        love.graphics.line(contentX + 20, scrollY, contentX + contentW - 20, scrollY)
        scrollY = scrollY + 8
    end

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
    -- SECTION 4: Commodity Fatigue (Top 10 Most Consumed)
    -- ==========================================================================
    love.graphics.setColor(0.6, 0.4, 0.8)
    love.graphics.print("COMMODITY FATIGUE (Top 10 Most Consumed)", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 25

    -- Build fatigue list from all consumed commodities (not just fatigued)
    local fatigueList = {}
    if char.commodityMultipliers then
        for commodity, data in pairs(char.commodityMultipliers) do
            table.insert(fatigueList, {
                commodity = commodity,
                multiplier = data.multiplier or 1.0,
                consecutiveCount = data.consecutiveCount or 0,
                lastConsumed = data.lastConsumed or 0
            })
        end
    end
    -- Sort by consecutive count (most consumed first)
    table.sort(fatigueList, function(a, b) return a.consecutiveCount > b.consecutiveCount end)

    if #fatigueList == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No consumption data yet", contentX, scrollY, 0, 0.75, 0.75)
        scrollY = scrollY + 20
    else
        local maxToShow = math.min(10, #fatigueList)
        for i = 1, maxToShow do
            local fatigue = fatigueList[i]
            local itemY = scrollY

            -- Commodity name
            love.graphics.setColor(0.85, 0.85, 0.85)
            love.graphics.print(fatigue.commodity .. ":", contentX, itemY, 0, 0.8, 0.8)

            -- Effectiveness bar background
            local barX = contentX + 120
            local barW = 80
            local barH = 14
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", barX, itemY + 2, barW, barH)

            -- Effectiveness bar fill
            local effectiveness = fatigue.multiplier
            local fillW = effectiveness * barW
            if effectiveness >= 0.8 then
                love.graphics.setColor(0.3, 0.7, 0.3)  -- Green (fresh)
            elseif effectiveness >= 0.5 then
                love.graphics.setColor(0.7, 0.7, 0.3)  -- Yellow (tired)
            else
                love.graphics.setColor(0.8, 0.3, 0.3)  -- Red (very tired)
            end
            love.graphics.rectangle("fill", barX, itemY + 2, fillW, barH)

            -- Effectiveness percentage and status
            local statusText
            if effectiveness >= 0.95 then
                statusText = "fresh"
                love.graphics.setColor(0.4, 0.8, 0.4)
            elseif effectiveness >= 0.7 then
                statusText = "tired"
                love.graphics.setColor(0.8, 0.8, 0.4)
            else
                statusText = "VERY TIRED"
                love.graphics.setColor(0.9, 0.4, 0.4)
            end
            love.graphics.print(string.format("%.0f%% effective (%s)", effectiveness * 100, statusText), barX + barW + 10, itemY, 0, 0.75, 0.75)

            -- Second line: Consumed count and last cycle
            scrollY = scrollY + 18
            love.graphics.setColor(0.5, 0.5, 0.55)
            love.graphics.print(string.format("Consumed: %dx consecutive, Last: Cycle %d",
                fatigue.consecutiveCount, fatigue.lastConsumed), contentX + 20, scrollY, 0, 0.7, 0.7)

            -- Reset Fatigue / Max Fatigue buttons (in edit mode)
            if self.editModeEnabled then
                local btnY = scrollY - 2
                self:RenderButton("Reset", contentX + 280, btnY, 50, 18, function()
                    if char.commodityMultipliers[fatigue.commodity] then
                        char.commodityMultipliers[fatigue.commodity].multiplier = 1.0
                        char.commodityMultipliers[fatigue.commodity].consecutiveCount = 0
                    end
                end, false, {0.3, 0.5, 0.3})

                self:RenderButton("Max", contentX + 335, btnY, 40, 18, function()
                    if char.commodityMultipliers[fatigue.commodity] then
                        char.commodityMultipliers[fatigue.commodity].multiplier = 0.1
                        char.commodityMultipliers[fatigue.commodity].consecutiveCount = 20
                    end
                end, false, {0.5, 0.3, 0.3})
            end

            scrollY = scrollY + 22
        end

        -- Show remaining count if any
        if #fatigueList > maxToShow then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print(string.format("... (%d more commodities)", #fatigueList - maxToShow), contentX, scrollY, 0, 0.7, 0.7)
            scrollY = scrollY + 18
        end
    end

    -- Reset All Fatigue button (in edit mode)
    if self.editModeEnabled and #fatigueList > 0 then
        self:RenderButton("Reset All Fatigue", contentX, scrollY, 120, 22, function()
            char.commodityMultipliers = {}
        end, false, {0.4, 0.5, 0.4})
        scrollY = scrollY + 28
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
    scrollY = scrollY + padding

    -- ==========================================================================
    -- SECTION 5: Consumption History (Last 10 Cycles)
    -- ==========================================================================
    love.graphics.setColor(0.4, 0.7, 0.7)
    love.graphics.print("CONSUMPTION HISTORY (Last 10 Cycles)", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 25

    local history = char.consumptionHistory or {}
    if #history == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No consumption history yet", contentX, scrollY, 0, 0.75, 0.75)
        scrollY = scrollY + 20
    else
        local maxToShow = math.min(10, #history)
        for i = 1, maxToShow do
            local entry = history[i]
            local itemY = scrollY

            -- Cycle number and status
            local effectiveness = entry.fatigueMultiplier or 1.0
            local effectivenessStr = string.format("%.0f%% effective", effectiveness * 100)

            -- Status indicator and commodity
            if entry.commodity then
                local isAcquired = entry.allocationType == "acquired"
                if isAcquired then
                    love.graphics.setColor(0.6, 0.5, 0.9)  -- Purple for acquired
                    love.graphics.print("+", contentX, itemY, 0, 0.8, 0.8)
                else
                    love.graphics.setColor(0.4, 0.8, 0.4)  -- Green for consumed
                    love.graphics.print("*", contentX, itemY, 0, 0.8, 0.8)
                end

                -- Color based on effectiveness
                if effectiveness >= 0.8 then
                    love.graphics.setColor(0.7, 0.9, 0.7)
                elseif effectiveness >= 0.5 then
                    love.graphics.setColor(0.9, 0.9, 0.6)
                else
                    love.graphics.setColor(0.9, 0.6, 0.6)
                end
                local actionText = isAcquired and "Acquired" or "Consumed"
                love.graphics.print(string.format("Cycle %d: %s %s (%s)",
                    entry.cycle or 0, actionText, entry.commodity, effectivenessStr), contentX + 15, itemY, 0, 0.75, 0.75)
            else
                love.graphics.setColor(0.8, 0.4, 0.4)
                love.graphics.print("x", contentX, itemY, 0, 0.8, 0.8)
                love.graphics.print(string.format("Cycle %d: FAILED (no allocation)", entry.cycle or 0), contentX + 15, itemY, 0, 0.75, 0.75)
            end

            -- Second line: Fine dimension breakdown (look up fulfillment vector)
            scrollY = scrollY + 16
            if entry.commodity and self.fulfillmentVectors and self.fulfillmentVectors.commodities then
                local commodityData = self.fulfillmentVectors.commodities[entry.commodity]
                if commodityData and commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine then
                    local fineVector = commodityData.fulfillmentVector.fine
                    local dimStr = ""
                    local count = 0
                    for dimName, points in pairs(fineVector) do
                        if points > 0 and count < 3 then
                            local gain = points * effectiveness * (entry.quantity or 1)
                            if dimStr ~= "" then dimStr = dimStr .. ", " end
                            dimStr = dimStr .. string.format("%s +%.1f", dimName, gain)
                            count = count + 1
                        end
                    end
                    if dimStr ~= "" then
                        love.graphics.setColor(0.5, 0.6, 0.6)
                        love.graphics.print("  -> " .. dimStr, contentX + 10, scrollY, 0, 0.65, 0.65)
                        scrollY = scrollY + 14
                    end
                end
            end

            scrollY = scrollY + 6
        end

        -- Show remaining count
        if #history > maxToShow then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print(string.format("... (scrollable to %d)", #history), contentX, scrollY, 0, 0.7, 0.7)
            scrollY = scrollY + 18
        end

        -- Clear History button (in edit mode)
        if self.editModeEnabled then
            self:RenderButton("Clear History", contentX, scrollY, 100, 22, function()
                char.consumptionHistory = {}
            end, false, {0.5, 0.4, 0.4})
            scrollY = scrollY + 28
        end
    end
    scrollY = scrollY + 5

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
    scrollY = scrollY + padding

    -- ==========================================================================
    -- SECTION 6: Possessions (Durables & Permanents)
    -- ==========================================================================
    love.graphics.setColor(0.7, 0.5, 0.8)
    love.graphics.print("POSSESSIONS (Durables & Permanents)", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 22

    local activeEffects = char.activeEffects or {}
    if #activeEffects == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No possessions", contentX, scrollY, 0, 0.75, 0.75)
        scrollY = scrollY + 20
    else
        for i, effect in ipairs(activeEffects) do
            local itemY = scrollY

            -- Commodity name and durability badge
            local durabilityColor = {0.7, 0.7, 0.7}
            local durabilityBadge = ""
            if effect.durability == "permanent" then
                durabilityColor = {0.4, 0.8, 0.9}
                durabilityBadge = " [PERMANENT]"
            elseif effect.durability == "durable" then
                durabilityColor = {0.8, 0.7, 0.4}
                durabilityBadge = ""
            end

            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print(effect.commodityId, contentX, itemY, 0, 0.85, 0.85)
            love.graphics.setColor(durabilityColor[1], durabilityColor[2], durabilityColor[3])
            local nameW = love.graphics.getFont():getWidth(effect.commodityId) * 0.85
            love.graphics.print(durabilityBadge, contentX + nameW + 5, itemY, 0, 0.7, 0.7)

            -- Category
            love.graphics.setColor(0.5, 0.6, 0.6)
            love.graphics.print("(" .. (effect.category or "unknown") .. ")", contentX + nameW + 80, itemY, 0, 0.7, 0.7)
            scrollY = scrollY + 16

            -- Effectiveness bar
            local effectiveness = effect.currentEffectiveness or 1.0
            local effBarX = contentX + 20
            local effBarW = 150
            local effBarH = 10

            love.graphics.setColor(0.55, 0.55, 0.55)
            love.graphics.print("Effectiveness:", effBarX, scrollY, 0, 0.7, 0.7)

            local barStartX = effBarX + 80
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", barStartX, scrollY + 1, effBarW, effBarH, 2, 2)

            local effFillW = effectiveness * effBarW
            if effectiveness >= 0.8 then
                love.graphics.setColor(0.3, 0.7, 0.3)
            elseif effectiveness >= 0.5 then
                love.graphics.setColor(0.7, 0.7, 0.3)
            else
                love.graphics.setColor(0.7, 0.4, 0.3)
            end
            love.graphics.rectangle("fill", barStartX, scrollY + 1, effFillW, effBarH, 2, 2)

            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(string.format("%.0f%%", effectiveness * 100), barStartX + effBarW + 8, scrollY, 0, 0.7, 0.7)
            scrollY = scrollY + 14

            -- Remaining cycles (for durables only)
            if effect.durability == "durable" and effect.remainingCycles then
                local remaining = effect.remainingCycles
                local total = effect.durationCycles or remaining
                local cycleBarX = contentX + 20
                local cycleBarW = 150

                love.graphics.setColor(0.55, 0.55, 0.55)
                love.graphics.print("Remaining:", cycleBarX, scrollY, 0, 0.7, 0.7)

                local cycleBarStartX = cycleBarX + 80
                love.graphics.setColor(0.2, 0.2, 0.25)
                love.graphics.rectangle("fill", cycleBarStartX, scrollY + 1, cycleBarW, effBarH, 2, 2)

                local cycleFillW = (remaining / total) * cycleBarW
                local cycleRatio = remaining / total
                if cycleRatio >= 0.5 then
                    love.graphics.setColor(0.3, 0.6, 0.7)
                elseif cycleRatio >= 0.2 then
                    love.graphics.setColor(0.7, 0.6, 0.3)
                else
                    love.graphics.setColor(0.7, 0.4, 0.3)
                end
                love.graphics.rectangle("fill", cycleBarStartX, scrollY + 1, cycleFillW, effBarH, 2, 2)

                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print(string.format("%d/%d cycles", remaining, total), cycleBarStartX + cycleBarW + 8, scrollY, 0, 0.7, 0.7)
                scrollY = scrollY + 14
            end

            -- Edit mode: Remove possession button
            if self.detailEditMode then
                self:RenderButton("Remove", contentX + contentW - 60, itemY, 55, 16, function()
                    table.remove(char.activeEffects, i)
                end, false, {0.6, 0.3, 0.3})
            end

            scrollY = scrollY + 8
        end
    end

    -- Edit mode: Add possession dropdown
    if self.detailEditMode then
        scrollY = scrollY + 5
        love.graphics.setColor(0.5, 0.6, 0.5)
        love.graphics.print("Add Possession:", contentX, scrollY, 0, 0.75, 0.75)
        scrollY = scrollY + 18

        -- Show available durables/permanents from fulfillment vectors
        local addX = contentX
        local addedCount = 0
        if self.fulfillmentVectors and self.fulfillmentVectors.commodities then
            for commodityId, commodityData in pairs(self.fulfillmentVectors.commodities) do
                local durability = commodityData.durability
                if durability == "durable" or durability == "permanent" then
                    -- Check if character can acquire this
                    if char:CanAcquireDurable(commodityId) then
                        if addedCount < 8 then  -- Max 8 buttons
                            self:RenderButton("+" .. commodityId, addX, scrollY, 90, 16, function()
                                char:AddActiveEffect(commodityId, self.cycleNumber)
                            end, false, {0.3, 0.5, 0.4})
                            addX = addX + 95
                            addedCount = addedCount + 1

                            if addedCount % 4 == 0 then
                                addX = contentX
                                scrollY = scrollY + 20
                            end
                        end
                    end
                end
            end
        end
        if addedCount == 0 then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("No available durables to add", addX, scrollY, 0, 0.7, 0.7)
        end
        scrollY = scrollY + 25
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
    scrollY = scrollY + padding

    -- ==========================================================================
    -- SECTION 7: Status & Risks
    -- ==========================================================================
    love.graphics.setColor(0.8, 0.4, 0.4)
    love.graphics.print("STATUS & RISKS", contentX, scrollY, 0, 0.9, 0.9)
    scrollY = scrollY + 22

    -- Status flags with edit controls
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Protesting:", contentX, scrollY, 0, 0.75, 0.75)
    if char.isProtesting then
        love.graphics.setColor(0.9, 0.6, 0.2)
        love.graphics.print("YES", contentX + 70, scrollY, 0, 0.75, 0.75)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No", contentX + 70, scrollY, 0, 0.75, 0.75)
    end
    if self.detailEditMode then
        self:RenderButton("Toggle", contentX + 100, scrollY - 2, 45, 14, function()
            char.isProtesting = not char.isProtesting
        end, false, {0.5, 0.4, 0.3})
    end

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Emigrated:", contentX + 170, scrollY, 0, 0.75, 0.75)
    if char.hasEmigrated then
        love.graphics.setColor(0.9, 0.3, 0.3)
        love.graphics.print("YES", contentX + 235, scrollY, 0, 0.75, 0.75)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No", contentX + 235, scrollY, 0, 0.75, 0.75)
    end
    if self.detailEditMode then
        self:RenderButton("Toggle", contentX + 265, scrollY - 2, 45, 14, function()
            char.hasEmigrated = not char.hasEmigrated
        end, false, {0.5, 0.4, 0.3})
    end
    scrollY = scrollY + 20

    -- Stressed status (read-only, derived from satisfaction)
    local avgSatisfaction = char:GetAverageSatisfaction()
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Status:", contentX, scrollY, 0, 0.75, 0.75)
    if avgSatisfaction < 0 then
        love.graphics.setColor(0.9, 0.4, 0.4)
        love.graphics.print("STRESSED", contentX + 50, scrollY, 0, 0.75, 0.75)
    elseif avgSatisfaction < 30 then
        love.graphics.setColor(0.8, 0.6, 0.3)
        love.graphics.print("DISSATISFIED", contentX + 50, scrollY, 0, 0.75, 0.75)
    else
        love.graphics.setColor(0.4, 0.8, 0.4)
        love.graphics.print("CONTENT", contentX + 50, scrollY, 0, 0.75, 0.75)
    end
    scrollY = scrollY + 20

    -- Productivity & Priority
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(string.format("Productivity: %.0f%%", (char.productivity or 1) * 100), contentX, scrollY, 0, 0.75, 0.75)
    love.graphics.print(string.format("Priority: %.1f", char.allocationPriority or 0), contentX + 150, scrollY, 0, 0.75, 0.75)
    scrollY = scrollY + 20

    -- Risk indicators
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Emigration Risk:", contentX, scrollY, 0, 0.75, 0.75)
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
    else
        love.graphics.setColor(0.4, 0.7, 0.4)
    end
    love.graphics.print(emigrationRisk, contentX + 105, scrollY, 0, 0.75, 0.75)
    scrollY = scrollY + 25

    -- Edit mode: Action buttons
    if self.detailEditMode then
        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.line(contentX, scrollY, contentX + contentW, scrollY)
        scrollY = scrollY + 10

        love.graphics.setColor(0.7, 0.5, 0.3)
        love.graphics.print("EDIT ACTIONS", contentX, scrollY, 0, 0.85, 0.85)
        scrollY = scrollY + 20

        -- Row 1: Reset buttons
        self:RenderButton("Reset All Cravings", contentX, scrollY, 120, 22, function()
            for i = 0, 48 do
                char.currentCravings[i] = 0
            end
        end, false, {0.5, 0.4, 0.3})

        self:RenderButton("Reset Fatigue", contentX + 130, scrollY, 100, 22, function()
            char.commodityMultipliers = {}
        end, false, {0.5, 0.4, 0.3})

        self:RenderButton("Clear History", contentX + 240, scrollY, 95, 22, function()
            char.consumptionHistory = {}
        end, false, {0.5, 0.4, 0.3})
        scrollY = scrollY + 28

        -- Row 2: Satisfaction presets
        self:RenderButton("Set Sat. 100", contentX, scrollY, 85, 22, function()
            for key, _ in pairs(char.satisfaction) do
                char.satisfaction[key] = 100
            end
        end, false, {0.3, 0.6, 0.3})

        self:RenderButton("Set Sat. 0", contentX + 95, scrollY, 75, 22, function()
            for key, _ in pairs(char.satisfaction) do
                char.satisfaction[key] = 0
            end
        end, false, {0.5, 0.5, 0.3})

        self:RenderButton("Set Sat. -50", contentX + 180, scrollY, 85, 22, function()
            for key, _ in pairs(char.satisfaction) do
                char.satisfaction[key] = -50
            end
        end, false, {0.6, 0.3, 0.3})

        self:RenderButton("Randomize Sat.", contentX + 275, scrollY, 100, 22, function()
            for key, _ in pairs(char.satisfaction) do
                char.satisfaction[key] = math.random(-50, 150)
            end
        end, false, {0.4, 0.4, 0.6})
        scrollY = scrollY + 30
    end

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

-- =============================================================================
-- Analytics Modal (Phase 9)
-- =============================================================================
function ConsumptionPrototype:RenderAnalyticsModal()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local w = math.min(1000, screenW - 100)
    local h = math.min(700, screenH - 100)
    local x = (screenW - w) / 2
    local y = (screenH - h) / 2

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0.5, 0.4, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("TOWN ANALYTICS", x + 20, y + 15, 0, 1.3, 1.3)

    -- Close button
    self:RenderButton("X", x + w - 40, y + 10, 30, 30, function()
        self.showAnalyticsModal = false
    end, false, {0.6, 0.3, 0.3})

    -- Tab buttons
    local tabY = y + 50
    local tabW = 140
    local tabH = 32
    local tabX = x + 20

    local tabs = {
        {id = "heatmap", label = "HEATMAP"},
        {id = "breakdown", label = "CLASS BREAKDOWN"},
        {id = "trends", label = "TRENDS"}
    }

    for _, tab in ipairs(tabs) do
        local isActive = self.analyticsTab == tab.id
        local color = isActive and {0.5, 0.4, 0.7} or {0.25, 0.25, 0.3}
        self:RenderButton(tab.label, tabX, tabY, tabW, tabH, function()
            self.analyticsTab = tab.id
            self.analyticsScrollOffset = 0
        end, isActive, color)
        tabX = tabX + tabW + 10
    end

    -- Content area
    local contentX = x + 20
    local contentY = tabY + tabH + 20
    local contentW = w - 40
    local contentH = h - (contentY - y) - 20

    -- Render active tab content
    if self.analyticsTab == "heatmap" then
        self:RenderAnalyticsHeatmap(contentX, contentY, contentW, contentH)
    elseif self.analyticsTab == "breakdown" then
        self:RenderAnalyticsBreakdown(contentX, contentY, contentW, contentH)
    elseif self.analyticsTab == "trends" then
        self:RenderAnalyticsTrends(contentX, contentY, contentW, contentH)
    end
end

-- =============================================================================
-- Analytics Tab 1: Heatmap
-- =============================================================================
function ConsumptionPrototype:RenderAnalyticsHeatmap(x, y, w, h)
    -- Initialize heatmap view mode if not set
    if not self.heatmapViewMode then
        self.heatmapViewMode = "table"  -- "grid" or "table"
    end

    -- View mode toggle buttons
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("View:", x, y, 0, 0.85, 0.85)

    self:RenderButton("Grid", x + 45, y - 3, 50, 22, function()
        self.heatmapViewMode = "grid"
    end, self.heatmapViewMode == "grid", self.heatmapViewMode == "grid" and {0.5, 0.6, 0.4} or {0.3, 0.3, 0.35})

    self:RenderButton("Table", x + 100, y - 3, 50, 22, function()
        self.heatmapViewMode = "table"
    end, self.heatmapViewMode == "table", self.heatmapViewMode == "table" and {0.5, 0.6, 0.4} or {0.3, 0.3, 0.35})

    if #self.characters == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No characters to display. Add some characters first.", x, y + 50)
        return
    end

    if self.heatmapViewMode == "table" then
        self:RenderHeatmapTableView(x, y + 30, w, h - 60)
    else
        self:RenderHeatmapGridView(x, y + 30, w, h - 60)
    end

    -- Legend
    local legendY = y + h - 25
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Legend:", x, legendY, 0, 0.75, 0.75)

    local legendItems = {
        {label = ">100 (Happy)", color = {0.2, 0.8, 0.3}},
        {label = "50-100", color = {0.5, 0.8, 0.3}},
        {label = "0-50", color = {0.9, 0.8, 0.2}},
        {label = "<0 (Unhappy)", color = {0.9, 0.3, 0.2}}
    }
    local legendX = x + 55
    for _, item in ipairs(legendItems) do
        love.graphics.setColor(item.color)
        love.graphics.circle("fill", legendX + 6, legendY + 8, 6)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(item.label, legendX + 18, legendY, 0, 0.7, 0.7)
        legendX = legendX + 110
    end
end

-- Table-style heatmap: rows=characters, cols=9 coarse dimensions
function ConsumptionPrototype:RenderHeatmapTableView(x, y, w, h)
    local dimensions = {
        {id = "biological", label = "Bio"},
        {id = "safety", label = "Saf"},
        {id = "touch", label = "Tou"},
        {id = "psychological", label = "Psy"},
        {id = "social_status", label = "Sta"},
        {id = "social_connection", label = "Con"},
        {id = "exotic_goods", label = "Exo"},
        {id = "shiny_objects", label = "Shi"},
        {id = "vice", label = "Vic"}
    }

    local nameColW = 80
    local dimColW = math.floor((w - nameColW - 20) / #dimensions)
    local rowH = 24
    local circleR = 8

    -- Header row
    local headerY = y
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("fill", x, headerY, w, rowH)

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Name", x + 5, headerY + 5, 0, 0.75, 0.75)

    for i, dim in ipairs(dimensions) do
        local colX = x + nameColW + (i - 1) * dimColW
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(dim.label, colX + (dimColW - 25) / 2, headerY + 5, 0, 0.75, 0.75)
    end

    -- Scrollable content area
    local contentY = y + rowH + 2
    local contentH = h - rowH - 5

    love.graphics.setScissor(x, contentY, w, contentH)

    -- Count visible characters
    local visibleChars = {}
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            table.insert(visibleChars, char)
        end
    end

    -- Render character rows
    for i, char in ipairs(visibleChars) do
        local rowY = contentY + (i - 1) * rowH - self.analyticsScrollOffset

        -- Skip if outside visible area
        if rowY + rowH < contentY or rowY > contentY + contentH then
            goto continue
        end

        -- Row background (alternating)
        if i % 2 == 0 then
            love.graphics.setColor(0.15, 0.15, 0.18)
        else
            love.graphics.setColor(0.12, 0.12, 0.15)
        end
        love.graphics.rectangle("fill", x, rowY, w, rowH)

        -- Character name
        local classColor = self:GetClassColor(char.class)
        love.graphics.setColor(classColor[1], classColor[2], classColor[3])
        local shortName = string.sub(char.name or "?", 1, 10)
        love.graphics.print(shortName, x + 5, rowY + 5, 0, 0.7, 0.7)

        -- Dimension circles
        for j, dim in ipairs(dimensions) do
            local colX = x + nameColW + (j - 1) * dimColW
            local circleX = colX + dimColW / 2
            local circleY = rowY + rowH / 2

            local satValue = char.satisfaction[dim.id] or 0
            local r, g, b = self:GetSatisfactionColor(satValue)

            -- Draw circle
            love.graphics.setColor(r, g, b, 0.9)
            love.graphics.circle("fill", circleX, circleY, circleR)

            -- Border
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", circleX, circleY, circleR)
        end

        -- Make row clickable
        local charRef = char
        table.insert(self.buttons, {
            x = x, y = rowY, w = nameColW, h = rowH,
            onClick = function()
                self.detailCharacter = charRef
                self.showCharacterDetailModal = true
                self.detailScrollOffset = 0
            end
        })

        ::continue::
    end

    love.graphics.setScissor()

    -- Calculate scroll max
    local totalH = #visibleChars * rowH
    self.analyticsScrollMax = math.max(0, totalH - contentH)

    -- Scrollbar
    if self.analyticsScrollMax > 0 then
        local scrollbarH = contentH * (contentH / totalH)
        scrollbarH = math.max(30, scrollbarH)
        local scrollbarY = contentY + (self.analyticsScrollOffset / self.analyticsScrollMax) * (contentH - scrollbarH)
        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.rectangle("fill", x + w - 10, contentY, 6, contentH)
        love.graphics.setColor(0.5, 0.5, 0.55)
        love.graphics.rectangle("fill", x + w - 10, scrollbarY, 6, scrollbarH, 3, 3)
    end

    -- Character count
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print(string.format("(%d characters)", #visibleChars), x, y + h - 5, 0, 0.7, 0.7)
end

-- Original grid-style heatmap
function ConsumptionPrototype:RenderHeatmapGridView(x, y, w, h)
    -- Dimension filter buttons
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Filter:", x, y, 0, 0.8, 0.8)

    local filterX = x + 50
    local dimensions = {
        {id = "all", label = "All"},
        {id = "biological", label = "Bio"},
        {id = "safety", label = "Saf"},
        {id = "touch", label = "Tou"},
        {id = "psychological", label = "Psy"},
        {id = "social_status", label = "Sta"},
        {id = "social_connection", label = "Con"},
        {id = "exotic_goods", label = "Exo"},
        {id = "shiny_objects", label = "Shi"},
        {id = "vice", label = "Vic"}
    }

    for _, dim in ipairs(dimensions) do
        local isActive = self.analyticsHeatmapDimension == dim.id
        local color = isActive and {0.5, 0.6, 0.4} or {0.3, 0.3, 0.35}
        self:RenderButton(dim.label, filterX, y - 3, 45, 18, function()
            self.analyticsHeatmapDimension = dim.id
        end, isActive, color)
        filterX = filterX + 50
    end

    -- Heatmap grid
    local gridY = y + 25
    local gridH = h - 30
    local cellSize = 50
    local cellPadding = 4
    local cols = math.floor(w / (cellSize + cellPadding))

    -- Set up scissor for grid
    love.graphics.setScissor(x, gridY, w, gridH)

    local row = 0
    local col = 0

    for i, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            local cellX = x + col * (cellSize + cellPadding)
            local cellY = gridY + row * (cellSize + cellPadding) - self.analyticsScrollOffset

            -- Calculate satisfaction value for coloring
            local satValue = 0
            if self.analyticsHeatmapDimension == "all" then
                satValue = char:GetAverageSatisfaction()
            else
                satValue = char.satisfaction[self.analyticsHeatmapDimension] or 0
            end

            -- Color based on satisfaction
            local r, g, b = self:GetSatisfactionColor(satValue)
            love.graphics.setColor(r, g, b, 0.8)
            love.graphics.rectangle("fill", cellX, cellY, cellSize, cellSize, 4, 4)

            -- Border
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", cellX, cellY, cellSize, cellSize, 4, 4)

            -- Character info
            love.graphics.setColor(1, 1, 1, 0.95)
            local shortName = string.sub(char.name or "?", 1, 6)
            love.graphics.print(shortName, cellX + 3, cellY + 3, 0, 0.6, 0.6)
            love.graphics.print(string.format("%.0f", satValue), cellX + 3, cellY + 35, 0, 0.7, 0.7)

            -- Make cell clickable
            local charRef = char
            table.insert(self.buttons, {
                x = cellX, y = cellY, w = cellSize, h = cellSize,
                onClick = function()
                    self.detailCharacter = charRef
                    self.showCharacterDetailModal = true
                    self.detailScrollOffset = 0
                end
            })

            col = col + 1
            if col >= cols then
                col = 0
                row = row + 1
            end
        end
    end

    love.graphics.setScissor()

    -- Calculate scroll max
    local visibleCount = 0
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then visibleCount = visibleCount + 1 end
    end
    local totalRows = math.ceil(visibleCount / cols)
    local totalGridH = totalRows * (cellSize + cellPadding)
    self.analyticsScrollMax = math.max(0, totalGridH - gridH)
end

-- =============================================================================
-- Analytics Tab 2: Class Breakdown
-- =============================================================================
function ConsumptionPrototype:RenderAnalyticsBreakdown(x, y, w, h)
    local classes = {"Elite", "Upper", "Middle", "Working", "Poor"}
    local classColors = {
        Elite = {0.9, 0.7, 0.2},
        Upper = {0.6, 0.5, 0.8},
        Middle = {0.3, 0.6, 0.8},
        Working = {0.5, 0.7, 0.4},
        Poor = {0.6, 0.4, 0.3}
    }

    -- Calculate stats per class
    local classStats = {}
    local totalActive = 0
    for _, className in ipairs(classes) do
        classStats[className] = {count = 0, totalSatisfaction = 0, consumption = {}}
    end

    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            totalActive = totalActive + 1
            local className = char.class or "Middle"
            if classStats[className] then
                classStats[className].count = classStats[className].count + 1
                classStats[className].totalSatisfaction = classStats[className].totalSatisfaction + char:GetAverageSatisfaction()
            end
        end
    end

    -- Left side: Population by Class
    local leftW = (w - 40) / 2
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("POPULATION BY CLASS", x, y, 0, 0.9, 0.9)

    local barY = y + 30
    local barH = 20
    local maxBarW = leftW - 80

    for _, className in ipairs(classes) do
        local stats = classStats[className]
        local percentage = totalActive > 0 and (stats.count / totalActive * 100) or 0

        -- Label
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(className, x, barY + 2, 0, 0.8, 0.8)

        -- Bar background
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", x + 60, barY, maxBarW, barH, 3, 3)

        -- Bar fill
        local fillW = (percentage / 100) * maxBarW
        if fillW > 0 then
            love.graphics.setColor(classColors[className])
            love.graphics.rectangle("fill", x + 60, barY, fillW, barH, 3, 3)
        end

        -- Percentage text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%d (%.0f%%)", stats.count, percentage), x + 60 + maxBarW + 10, barY + 2, 0, 0.75, 0.75)

        barY = barY + barH + 8
    end

    -- Right side: Average Satisfaction by Class
    local rightX = x + leftW + 40
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("AVG SATISFACTION BY CLASS", rightX, y, 0, 0.9, 0.9)

    barY = y + 30
    local satMaxBarW = leftW - 80

    for _, className in ipairs(classes) do
        local stats = classStats[className]
        local avgSat = stats.count > 0 and (stats.totalSatisfaction / stats.count) or 0

        -- Label
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(className, rightX, barY + 2, 0, 0.8, 0.8)

        -- Bar background
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", rightX + 60, barY, satMaxBarW, barH, 3, 3)

        -- Bar fill (normalized to 0-100 range for display, clamped)
        local normalizedSat = math.max(0, math.min(100, avgSat)) / 100
        local fillW = normalizedSat * satMaxBarW
        if fillW > 0 then
            local r, g, b = self:GetSatisfactionColor(avgSat)
            love.graphics.setColor(r, g, b)
            love.graphics.rectangle("fill", rightX + 60, barY, fillW, barH, 3, 3)
        end

        -- Value text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%.0f", avgSat), rightX + 60 + satMaxBarW + 10, barY + 2, 0, 0.75, 0.75)

        barY = barY + barH + 8
    end

    -- Bottom: Resource Consumption by Class (Top 5 commodities)
    local bottomY = y + 200
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("RESOURCE CONSUMPTION BY CLASS (from consumption history)", x, bottomY, 0, 0.9, 0.9)

    -- Gather consumption data from character histories
    local commodityByClass = {}
    local totalByCommodity = {}

    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated and char.consumptionHistory then
            local className = char.class or "Middle"
            for _, entry in ipairs(char.consumptionHistory) do
                local commodity = entry.commodity
                if commodity then
                    commodityByClass[commodity] = commodityByClass[commodity] or {}
                    commodityByClass[commodity][className] = (commodityByClass[commodity][className] or 0) + (entry.quantity or 1)
                    totalByCommodity[commodity] = (totalByCommodity[commodity] or 0) + (entry.quantity or 1)
                end
            end
        end
    end

    -- Sort commodities by total consumption
    local sortedCommodities = {}
    for commodity, total in pairs(totalByCommodity) do
        table.insert(sortedCommodities, {id = commodity, total = total})
    end
    table.sort(sortedCommodities, function(a, b) return a.total > b.total end)

    -- Show top 5
    local tableY = bottomY + 25
    local colW = (w - 80) / 6

    -- Header
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.print("Commodity", x, tableY, 0, 0.7, 0.7)
    local headerX = x + 100
    for _, className in ipairs(classes) do
        love.graphics.setColor(classColors[className])
        love.graphics.print(className, headerX, tableY, 0, 0.7, 0.7)
        headerX = headerX + colW
    end
    tableY = tableY + 18

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x, tableY, x + w, tableY)
    tableY = tableY + 5

    -- Data rows (top 5)
    local shown = 0
    for _, commodityData in ipairs(sortedCommodities) do
        if shown >= 5 then break end

        local commodity = commodityData.id
        local total = commodityData.total
        local byClass = commodityByClass[commodity] or {}

        -- Commodity name (truncated)
        love.graphics.setColor(0.7, 0.7, 0.7)
        local shortName = string.sub(commodity, 1, 12)
        love.graphics.print(shortName, x, tableY, 0, 0.7, 0.7)

        -- Percentage per class
        local dataX = x + 100
        for _, className in ipairs(classes) do
            local classAmount = byClass[className] or 0
            local pct = total > 0 and (classAmount / total * 100) or 0
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(string.format("%.0f%%", pct), dataX, tableY, 0, 0.7, 0.7)
            dataX = dataX + colW
        end

        tableY = tableY + 18
        shown = shown + 1
    end

    if shown == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No consumption data yet. Run the simulation to see data.", x, tableY)
    end
end

-- =============================================================================
-- Analytics Tab 3: Trends
-- =============================================================================
function ConsumptionPrototype:RenderAnalyticsTrends(x, y, w, h)
    -- Initialize trends sub-tab if not set
    if not self.trendsSubTab then
        self.trendsSubTab = "satisfaction"  -- "satisfaction" or "consumption"
    end

    -- Sub-tab buttons
    self:RenderButton("Satisfaction", x, y, 100, 24, function()
        self.trendsSubTab = "satisfaction"
    end, self.trendsSubTab == "satisfaction", self.trendsSubTab == "satisfaction" and {0.5, 0.6, 0.4} or {0.3, 0.3, 0.35})

    self:RenderButton("Consumption", x + 110, y, 100, 24, function()
        self.trendsSubTab = "consumption"
    end, self.trendsSubTab == "consumption", self.trendsSubTab == "consumption" and {0.5, 0.6, 0.4} or {0.3, 0.3, 0.35})

    local contentY = y + 35

    if self.trendsSubTab == "satisfaction" then
        self:RenderSatisfactionTrends(x, contentY, w, h - 35)
    else
        self:RenderCommodityConsumptionTrends(x, contentY, w, h - 35)
    end
end

-- Satisfaction trends (original content)
function ConsumptionPrototype:RenderSatisfactionTrends(x, y, w, h)
    -- Satisfaction over time graph
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("SATISFACTION OVER TIME (Last 20 Cycles)", x, y, 0, 0.9, 0.9)

    local graphX = x + 40
    local graphY = y + 25
    local graphW = w - 80
    local graphH = 120

    -- Graph background
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", graphX, graphY, graphW, graphH)
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", graphX, graphY, graphW, graphH)

    -- Y-axis labels
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("100", x, graphY, 0, 0.6, 0.6)
    love.graphics.print("50", x + 5, graphY + graphH / 2 - 5, 0, 0.6, 0.6)
    love.graphics.print("0", x + 10, graphY + graphH - 10, 0, 0.6, 0.6)

    -- Grid lines
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.line(graphX, graphY + graphH / 2, graphX + graphW, graphY + graphH / 2)

    -- Plot satisfaction history
    if #self.satisfactionHistory > 1 then
        love.graphics.setColor(0.3, 0.8, 0.4)
        local points = {}
        for i, entry in ipairs(self.satisfactionHistory) do
            local px = graphX + ((i - 1) / (self.historyMaxCycles - 1)) * graphW
            local normalizedSat = math.max(0, math.min(100, entry.avgSatisfaction)) / 100
            local py = graphY + graphH - (normalizedSat * graphH)
            table.insert(points, px)
            table.insert(points, py)
        end
        if #points >= 4 then
            love.graphics.setLineWidth(2)
            love.graphics.line(points)
            love.graphics.setLineWidth(1)
        end

        -- Draw points
        for i = 1, #points, 2 do
            love.graphics.circle("fill", points[i], points[i + 1], 3)
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Run simulation to see trend data...", graphX + 20, graphY + graphH / 2 - 10, 0, 0.8, 0.8)
    end

    -- Bottom section: Population changes and Inventory levels
    local bottomY = graphY + graphH + 20
    local leftW = (w - 40) / 2

    -- Left: Population Changes
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("POPULATION CHANGES", x, bottomY, 0, 0.85, 0.85)

    local popY = bottomY + 20
    local activeCount = self:GetActiveCharacterCount()

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(string.format("Total Active: %d", activeCount), x, popY, 0, 0.75, 0.75)
    popY = popY + 18

    -- Recent changes
    local recentImmigrated, recentEmigrated, recentDied = 0, 0, 0
    for i = math.max(1, #self.populationHistory - 5), #self.populationHistory do
        local entry = self.populationHistory[i]
        if entry then
            recentImmigrated = recentImmigrated + (entry.immigrated or 0)
            recentEmigrated = recentEmigrated + (entry.emigrated or 0)
            recentDied = recentDied + (entry.died or 0)
        end
    end

    love.graphics.setColor(0.4, 0.8, 0.4)
    love.graphics.print(string.format("Recent Immigrated: +%d", recentImmigrated), x, popY, 0, 0.7, 0.7)
    popY = popY + 16
    love.graphics.setColor(0.9, 0.6, 0.3)
    love.graphics.print(string.format("Recent Emigrated: -%d", recentEmigrated), x, popY, 0, 0.7, 0.7)
    popY = popY + 16
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.print(string.format("Recent Died: -%d", recentDied), x, popY, 0, 0.7, 0.7)

    -- Right: Inventory Levels
    local rightX = x + leftW + 40
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("INVENTORY LEVELS (Top 10)", rightX, bottomY, 0, 0.85, 0.85)

    local sortedInventory = {}
    local commodities = self.commodities or {}
    for _, c in ipairs(commodities) do
        local quantity = self.townInventory[c.id] or 0
        if quantity > 0 then
            table.insert(sortedInventory, {id = c.id, name = c.name, quantity = quantity})
        end
    end
    table.sort(sortedInventory, function(a, b) return a.quantity > b.quantity end)

    local invY = bottomY + 20
    local invBarW = leftW - 100
    local maxQty = sortedInventory[1] and sortedInventory[1].quantity or 100

    for i, item in ipairs(sortedInventory) do
        if i > 8 then break end
        local shortName = string.sub(item.name or item.id, 1, 10)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print(shortName, rightX, invY, 0, 0.65, 0.65)

        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", rightX + 65, invY + 2, invBarW, 10, 2, 2)
        local fillW = (item.quantity / maxQty) * invBarW
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", rightX + 65, invY + 2, fillW, 10, 2, 2)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(tostring(math.floor(item.quantity)), rightX + 70 + invBarW, invY, 0, 0.65, 0.65)
        invY = invY + 16
    end

    if #sortedInventory == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No inventory.", rightX, invY, 0, 0.7, 0.7)
    end
end

-- Commodity Consumption Trends (new)
function ConsumptionPrototype:RenderCommodityConsumptionTrends(x, y, w, h)
    -- Title
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("COMMODITY CONSUMPTION TRENDS (Last 50 Cycles)", x, y, 0, 0.9, 0.9)

    -- Build list of commodities with consumption data
    local commoditiesWithData = {}
    for commodityId, history in pairs(self.commodityConsumptionHistory) do
        if #history > 0 then
            local totalConsumed = 0
            for _, entry in ipairs(history) do
                totalConsumed = totalConsumed + entry.quantity
            end
            table.insert(commoditiesWithData, {
                id = commodityId,
                history = history,
                total = totalConsumed
            })
        end
    end
    table.sort(commoditiesWithData, function(a, b) return a.total > b.total end)

    -- Commodity selector buttons
    local selectorY = y + 25
    local selectorX = x

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Select Commodity:", x, selectorY + 3, 0, 0.75, 0.75)
    selectorX = x + 115

    -- Show top 8 commodities as buttons
    local shownCount = 0
    for _, commodityData in ipairs(commoditiesWithData) do
        if shownCount >= 8 then break end
        local isSelected = self.selectedTrendCommodity == commodityData.id
        local shortName = string.sub(commodityData.id, 1, 8)
        self:RenderButton(shortName, selectorX, selectorY, 70, 20, function()
            self.selectedTrendCommodity = commodityData.id
        end, isSelected, isSelected and {0.5, 0.6, 0.4} or {0.3, 0.3, 0.35})
        selectorX = selectorX + 75
        shownCount = shownCount + 1
    end

    -- Auto-select first commodity if none selected
    if not self.selectedTrendCommodity and #commoditiesWithData > 0 then
        self.selectedTrendCommodity = commoditiesWithData[1].id
    end

    -- Chart area
    local chartY = selectorY + 30
    local chartH = 160
    local chartW = w - 60

    if not self.selectedTrendCommodity or not self.commodityConsumptionHistory[self.selectedTrendCommodity] then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No consumption data yet. Run simulation to see trends.", x + 40, chartY + 60, 0, 0.85, 0.85)
        return
    end

    local history = self.commodityConsumptionHistory[self.selectedTrendCommodity]

    -- Find max value for scaling
    local maxQty = 1
    for _, entry in ipairs(history) do
        if entry.quantity > maxQty then
            maxQty = entry.quantity
        end
    end

    -- Chart background
    local chartX = x + 40
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", chartX, chartY, chartW, chartH)
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", chartX, chartY, chartW, chartH)

    -- Y-axis labels
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print(tostring(maxQty), x, chartY, 0, 0.6, 0.6)
    love.graphics.print(tostring(math.floor(maxQty / 2)), x, chartY + chartH / 2 - 5, 0, 0.6, 0.6)
    love.graphics.print("0", x + 10, chartY + chartH - 10, 0, 0.6, 0.6)

    -- Grid lines
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.line(chartX, chartY + chartH / 2, chartX + chartW, chartY + chartH / 2)

    -- Draw bars
    local barW = math.max(4, math.floor(chartW / self.consumptionHistoryMaxCycles) - 2)
    for i, entry in ipairs(history) do
        local barX = chartX + (i - 1) * (chartW / self.consumptionHistoryMaxCycles)
        local barH = (entry.quantity / maxQty) * chartH
        local barY = chartY + chartH - barH

        love.graphics.setColor(0.5, 0.4, 0.7, 0.9)
        love.graphics.rectangle("fill", barX + 1, barY, barW, barH)
    end

    -- X-axis labels (cycle numbers)
    if #history > 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        local firstCycle = history[1].cycle
        local lastCycle = history[#history].cycle
        love.graphics.print("Cycle " .. firstCycle, chartX, chartY + chartH + 5, 0, 0.6, 0.6)
        love.graphics.print(tostring(lastCycle), chartX + chartW - 30, chartY + chartH + 5, 0, 0.6, 0.6)
    end

    -- Statistics
    local statsY = chartY + chartH + 25
    local totalConsumed = 0
    local peakCycle = 0
    local peakQty = 0
    for _, entry in ipairs(history) do
        totalConsumed = totalConsumed + entry.quantity
        if entry.quantity > peakQty then
            peakQty = entry.quantity
            peakCycle = entry.cycle
        end
    end
    local avgConsumption = #history > 0 and totalConsumed / #history or 0

    -- Trend direction
    local trend = "Stable"
    if #history >= 5 then
        local recentAvg = 0
        local oldAvg = 0
        local midpoint = math.floor(#history / 2)
        for i = 1, midpoint do
            oldAvg = oldAvg + history[i].quantity
        end
        for i = midpoint + 1, #history do
            recentAvg = recentAvg + history[i].quantity
        end
        oldAvg = oldAvg / midpoint
        recentAvg = recentAvg / (#history - midpoint)
        if recentAvg > oldAvg * 1.1 then
            trend = "Increasing"
        elseif recentAvg < oldAvg * 0.9 then
            trend = "Decreasing"
        end
    end

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(string.format("Total Consumed: %d units", totalConsumed), x, statsY, 0, 0.8, 0.8)
    love.graphics.print(string.format("Peak Cycle: %d (%d units)", peakCycle, peakQty), x + 200, statsY, 0, 0.8, 0.8)
    statsY = statsY + 18
    love.graphics.print(string.format("Average: %.1f units/cycle", avgConsumption), x, statsY, 0, 0.8, 0.8)

    -- Trend with color
    if trend == "Increasing" then
        love.graphics.setColor(0.4, 0.8, 0.4)
    elseif trend == "Decreasing" then
        love.graphics.setColor(0.9, 0.5, 0.3)
    else
        love.graphics.setColor(0.7, 0.7, 0.7)
    end
    love.graphics.print("Trend: " .. trend, x + 200, statsY, 0, 0.8, 0.8)
end

-- =============================================================================
-- Export Analytics Data
-- =============================================================================
function ConsumptionPrototype:ExportAnalyticsData()
    print("\n========== ANALYTICS DATA EXPORT ==========")
    print("Cycle: " .. self.cycleNumber)
    print("Active Characters: " .. self:GetActiveCharacterCount())
    print("")

    -- Class breakdown
    print("-- CLASS BREAKDOWN --")
    local classes = {"Elite", "Upper", "Middle", "Working", "Poor"}
    for _, className in ipairs(classes) do
        local count = 0
        local totalSat = 0
        for _, char in ipairs(self.characters) do
            if not char.hasEmigrated and char.class == className then
                count = count + 1
                totalSat = totalSat + char:GetAverageSatisfaction()
            end
        end
        local avgSat = count > 0 and (totalSat / count) or 0
        print(string.format("  %s: %d chars, avg satisfaction: %.1f", className, count, avgSat))
    end
    print("")

    -- Satisfaction history
    print("-- SATISFACTION HISTORY --")
    for _, entry in ipairs(self.satisfactionHistory) do
        print(string.format("  Cycle %d: %.1f avg", entry.cycle, entry.avgSatisfaction))
    end
    print("")

    -- Top inventory
    print("-- TOP INVENTORY --")
    local sortedInv = {}
    for commodity, qty in pairs(self.townInventory) do
        if qty > 0 then table.insert(sortedInv, {id = commodity, qty = qty}) end
    end
    table.sort(sortedInv, function(a, b) return a.qty > b.qty end)
    for i = 1, math.min(10, #sortedInv) do
        print(string.format("  %s: %d", sortedInv[i].id, sortedInv[i].qty))
    end

    print("========== END EXPORT ==========\n")
end

-- =============================================================================
-- Record Historical Data (called each cycle)
-- =============================================================================
function ConsumptionPrototype:RecordHistoricalData()
    -- Calculate average satisfaction
    local totalSat = 0
    local activeCount = 0
    local classSatisfaction = {}
    local classCount = {}

    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            activeCount = activeCount + 1
            local sat = char:GetAverageSatisfaction()
            totalSat = totalSat + sat

            local className = char.class or "Middle"
            classSatisfaction[className] = (classSatisfaction[className] or 0) + sat
            classCount[className] = (classCount[className] or 0) + 1
        end
    end

    local avgSat = activeCount > 0 and (totalSat / activeCount) or 0

    -- Calculate per-class averages
    local byClass = {}
    for className, total in pairs(classSatisfaction) do
        byClass[className] = classCount[className] > 0 and (total / classCount[className]) or 0
    end

    -- Record satisfaction history
    table.insert(self.satisfactionHistory, {
        cycle = self.cycleNumber,
        avgSatisfaction = avgSat,
        byClass = byClass
    })

    -- Trim to max cycles
    while #self.satisfactionHistory > self.historyMaxCycles do
        table.remove(self.satisfactionHistory, 1)
    end

    -- Record population history (immigrated/emigrated tracked via events)
    -- For now, just record current state
    table.insert(self.populationHistory, {
        cycle = self.cycleNumber,
        total = activeCount,
        byClass = classCount,
        immigrated = 0,  -- Would need to track this separately
        emigrated = 0,
        died = 0
    })

    while #self.populationHistory > self.historyMaxCycles do
        table.remove(self.populationHistory, 1)
    end

    -- Record inventory snapshot (top 10)
    local invSnapshot = {}
    local sortedInv = {}
    for commodity, qty in pairs(self.townInventory) do
        if qty > 0 then
            table.insert(sortedInv, {id = commodity, quantity = qty})
        end
    end
    table.sort(sortedInv, function(a, b) return a.quantity > b.quantity end)
    for i = 1, math.min(10, #sortedInv) do
        invSnapshot[sortedInv[i].id] = sortedInv[i].quantity
    end

    table.insert(self.inventoryHistory, {
        cycle = self.cycleNumber,
        commodities = invSnapshot
    })

    while #self.inventoryHistory > self.historyMaxCycles do
        table.remove(self.inventoryHistory, 1)
    end
end

-- =============================================================================
-- Allocation Policy Modal (Phase 10)
-- =============================================================================
function ConsumptionPrototype:RenderAllocationPolicyModal()
    if not self.showAllocationPolicyModal then return end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Modal dimensions
    local modalW = math.min(900, screenW - 100)
    local modalH = math.min(700, screenH - 100)
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 10, 10)

    -- Modal border
    love.graphics.setColor(0.7, 0.5, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 10, 10)

    -- Title
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("ALLOCATION POLICY", modalX + 20, modalY + 15, 0, 1.3, 1.3)

    -- Close button
    self:RenderButton("X", modalX + modalW - 45, modalY + 10, 35, 35, function()
        self.showAllocationPolicyModal = false
    end, false, {0.6, 0.3, 0.3})

    -- Content area with scrolling
    local contentX = modalX + 20
    local contentY = modalY + 60
    local contentW = modalW - 40
    local contentH = modalH - 80

    -- Scissor for scrollable content
    love.graphics.setScissor(contentX, contentY, contentW, contentH)

    local y = contentY - self.allocationPolicyScrollOffset
    local sectionSpacing = 30
    local itemSpacing = 35

    -- =============================================================================
    -- Section 1: Quick Presets
    -- =============================================================================
    love.graphics.setColor(0.8, 0.65, 0.4)
    love.graphics.print("QUICK PRESETS", contentX, y, 0, 1.1, 1.1)
    y = y + 30

    local presetX = contentX
    for _, preset in ipairs(self.policyPresets) do
        local isActive = self.allocationPolicy.activePreset == preset.name
        self:RenderButton(preset.name, presetX, y, 140, 35, function()
            self:ApplyPolicyPreset(preset)
        end, isActive, isActive and {0.4, 0.6, 0.3} or {0.3, 0.35, 0.4})

        -- Description tooltip on same line
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(preset.description, presetX + 150, y + 10, 0, 0.75, 0.75)

        y = y + 45
    end

    y = y + sectionSpacing

    -- =============================================================================
    -- Section 2: Priority Mode
    -- =============================================================================
    love.graphics.setColor(0.8, 0.65, 0.4)
    love.graphics.print("PRIORITY MODE", contentX, y, 0, 1.1, 1.1)
    y = y + 30

    local modes = {
        {id = "need_based", label = "Need-Based", desc = "Prioritize characters with highest cravings"},
        {id = "equality", label = "Equality", desc = "Equal chance regardless of class/need"},
        {id = "class_based", label = "Class-Based", desc = "Prioritize by social class (Elite first)"}
    }

    for _, mode in ipairs(modes) do
        local isActive = self.allocationPolicy.priorityMode == mode.id
        self:RenderButton(mode.label, contentX, y, 140, 30, function()
            self.allocationPolicy.priorityMode = mode.id
            self.allocationPolicy.activePreset = nil
        end, isActive, isActive and {0.3, 0.6, 0.4} or {0.25, 0.28, 0.32})

        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print(mode.desc, contentX + 150, y + 8, 0, 0.8, 0.8)

        y = y + 40
    end

    y = y + sectionSpacing

    -- =============================================================================
    -- Section 3: Fairness Mode Toggle
    -- =============================================================================
    love.graphics.setColor(0.8, 0.65, 0.4)
    love.graphics.print("FAIRNESS MODE", contentX, y, 0, 1.1, 1.1)
    y = y + 30

    local fairnessActive = self.allocationPolicy.fairnessEnabled
    self:RenderButton(fairnessActive and "ENABLED" or "DISABLED", contentX, y, 120, 35, function()
        self.allocationPolicy.fairnessEnabled = not self.allocationPolicy.fairnessEnabled
        self.allocationPolicy.activePreset = nil
    end, fairnessActive, fairnessActive and {0.3, 0.6, 0.4} or {0.5, 0.3, 0.3})

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("When enabled, characters who failed allocation get priority boost next cycle", contentX + 130, y + 10, 0, 0.8, 0.8)

    y = y + itemSpacing + sectionSpacing

    -- =============================================================================
    -- Section 4: Class Priority Weights
    -- =============================================================================
    love.graphics.setColor(0.8, 0.65, 0.4)
    love.graphics.print("CLASS PRIORITY WEIGHTS", contentX, y, 0, 1.1, 1.1)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("(Higher = more priority in allocation)", contentX + 220, y + 3, 0, 0.8, 0.8)
    y = y + 30

    local classes = {"Elite", "Upper", "Middle", "Working", "Poor"}
    for _, className in ipairs(classes) do
        local weight = self.allocationPolicy.classPriorities[className] or 1

        -- Class name
        local classColor = self:GetClassColor(className)
        love.graphics.setColor(classColor[1], classColor[2], classColor[3])
        love.graphics.print(className .. ":", contentX, y + 5, 0, 0.9, 0.9)

        -- Weight value
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(string.format("%d", weight), contentX + 100, y + 5, 0, 0.9, 0.9)

        -- Decrease button
        self:RenderButton("-", contentX + 140, y, 30, 28, function()
            self.allocationPolicy.classPriorities[className] = math.max(0, weight - 1)
            self.allocationPolicy.activePreset = nil
        end, false, {0.5, 0.3, 0.3})

        -- Increase button
        self:RenderButton("+", contentX + 175, y, 30, 28, function()
            self.allocationPolicy.classPriorities[className] = math.min(50, weight + 1)
            self.allocationPolicy.activePreset = nil
        end, false, {0.3, 0.5, 0.3})

        -- Visual bar
        local barX = contentX + 220
        local barW = 200
        local barH = 20
        local maxWeight = 20
        local fillW = math.min(1, weight / maxWeight) * barW

        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", barX, y + 4, barW, barH)
        love.graphics.setColor(classColor[1] * 0.7, classColor[2] * 0.7, classColor[3] * 0.7)
        love.graphics.rectangle("fill", barX, y + 4, fillW, barH)

        y = y + 32
    end

    y = y + sectionSpacing

    -- =============================================================================
    -- Section 5: Class Consumption Budgets
    -- =============================================================================
    love.graphics.setColor(0.8, 0.65, 0.4)
    love.graphics.print("CLASS CONSUMPTION BUDGETS", contentX, y, 0, 1.1, 1.1)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("(Items consumed per cycle per character)", contentX + 260, y + 3, 0, 0.8, 0.8)
    y = y + 30

    for _, className in ipairs(classes) do
        local budget = self.allocationPolicy.consumptionBudgets[className] or 3

        -- Class name
        local classColor = self:GetClassColor(className)
        love.graphics.setColor(classColor[1], classColor[2], classColor[3])
        love.graphics.print(className .. ":", contentX, y + 5, 0, 0.9, 0.9)

        -- Budget value
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(string.format("%d", budget), contentX + 100, y + 5, 0, 0.9, 0.9)

        -- Decrease button
        self:RenderButton("-", contentX + 140, y, 30, 28, function()
            self.allocationPolicy.consumptionBudgets[className] = math.max(1, budget - 1)
            self.allocationPolicy.activePreset = nil
        end, false, {0.5, 0.3, 0.3})

        -- Increase button
        self:RenderButton("+", contentX + 175, y, 30, 28, function()
            self.allocationPolicy.consumptionBudgets[className] = math.min(20, budget + 1)
            self.allocationPolicy.activePreset = nil
        end, false, {0.3, 0.5, 0.3})

        -- Visual bar
        local barX = contentX + 220
        local barW = 200
        local barH = 20
        local maxBudget = 20
        local fillW = math.min(1, budget / maxBudget) * barW

        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", barX, y + 4, barW, barH)
        love.graphics.setColor(classColor[1] * 0.5, classColor[2] * 0.8, classColor[3] * 0.5)
        love.graphics.rectangle("fill", barX, y + 4, fillW, barH)

        y = y + 32
    end

    y = y + sectionSpacing

    -- =============================================================================
    -- Section 6: Dimension Priority Weights
    -- =============================================================================
    love.graphics.setColor(0.8, 0.65, 0.4)
    love.graphics.print("DIMENSION PRIORITY WEIGHTS", contentX, y, 0, 1.1, 1.1)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("(Higher = more important needs)", contentX + 260, y + 3, 0, 0.8, 0.8)
    y = y + 30

    local dimensions = {
        {key = "biological", label = "Biological", color = {0.4, 0.8, 0.4}},
        {key = "safety", label = "Safety", color = {0.4, 0.6, 0.9}},
        {key = "touch", label = "Touch", color = {0.9, 0.6, 0.6}},
        {key = "psychological", label = "Psychological", color = {0.7, 0.5, 0.8}},
        {key = "social_status", label = "Social Status", color = {0.9, 0.8, 0.3}},
        {key = "social_connection", label = "Social Connection", color = {0.9, 0.6, 0.4}},
        {key = "exotic_goods", label = "Exotic Goods", color = {0.5, 0.8, 0.8}},
        {key = "shiny_objects", label = "Shiny Objects", color = {0.8, 0.8, 0.5}},
        {key = "vice", label = "Vice", color = {0.7, 0.4, 0.5}}
    }

    -- Render in 2 columns
    local colWidth = contentW / 2
    local col = 0
    local rowY = y

    for i, dim in ipairs(dimensions) do
        local colX = contentX + (col * colWidth)
        local weight = self.allocationPolicy.dimensionPriorities[dim.key] or 0.5

        -- Dimension label
        love.graphics.setColor(dim.color[1], dim.color[2], dim.color[3])
        love.graphics.print(dim.label .. ":", colX, rowY + 3, 0, 0.85, 0.85)

        -- Weight value
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(string.format("%.1f", weight), colX + 120, rowY + 3, 0, 0.85, 0.85)

        -- Decrease button
        self:RenderButton("-", colX + 160, rowY, 25, 24, function()
            self.allocationPolicy.dimensionPriorities[dim.key] = math.max(0, weight - 0.1)
            self.allocationPolicy.activePreset = nil
        end, false, {0.5, 0.3, 0.3})

        -- Increase button
        self:RenderButton("+", colX + 190, rowY, 25, 24, function()
            self.allocationPolicy.dimensionPriorities[dim.key] = math.min(1.0, weight + 0.1)
            self.allocationPolicy.activePreset = nil
        end, false, {0.3, 0.5, 0.3})

        -- Progress bar
        local barX = colX + 225
        local barW = 150
        local barH = 16
        local fillW = weight * barW

        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", barX, rowY + 4, barW, barH)
        love.graphics.setColor(dim.color[1] * 0.6, dim.color[2] * 0.6, dim.color[3] * 0.6)
        love.graphics.rectangle("fill", barX, rowY + 4, fillW, barH)

        col = col + 1
        if col >= 2 then
            col = 0
            rowY = rowY + 30
        end
    end

    if col ~= 0 then rowY = rowY + 30 end
    y = rowY + sectionSpacing

    -- =============================================================================
    -- Section 6: Substitution Aggressiveness
    -- =============================================================================
    love.graphics.setColor(0.8, 0.65, 0.4)
    love.graphics.print("SUBSTITUTION AGGRESSIVENESS", contentX, y, 0, 1.1, 1.1)
    y = y + 30

    local subAggr = self.allocationPolicy.substitutionAggressiveness

    -- Decrease button
    self:RenderButton("-", contentX, y, 35, 30, function()
        self.allocationPolicy.substitutionAggressiveness = math.max(0, subAggr - 0.1)
        self.allocationPolicy.activePreset = nil
    end, false, {0.5, 0.3, 0.3})

    -- Value display
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print(string.format("%.0f%%", subAggr * 100), contentX + 50, y + 7, 0, 1.0, 1.0)

    -- Increase button
    self:RenderButton("+", contentX + 105, y, 35, 30, function()
        self.allocationPolicy.substitutionAggressiveness = math.min(1.0, subAggr + 0.1)
        self.allocationPolicy.activePreset = nil
    end, false, {0.3, 0.5, 0.3})

    -- Bar
    local barX = contentX + 160
    local barW = 300
    local barH = 22
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", barX, y + 4, barW, barH)
    love.graphics.setColor(0.5, 0.6, 0.7)
    love.graphics.rectangle("fill", barX, y + 4, subAggr * barW, barH)

    -- Labels
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Prefer original", barX, y + 30, 0, 0.7, 0.7)
    love.graphics.print("Prefer fresh substitutes", barX + barW - 120, y + 30, 0, 0.7, 0.7)

    y = y + 60 + sectionSpacing

    -- =============================================================================
    -- Section 7: Reserve Threshold
    -- =============================================================================
    love.graphics.setColor(0.8, 0.65, 0.4)
    love.graphics.print("RESERVE THRESHOLD", contentX, y, 0, 1.1, 1.1)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Keep this % of inventory in reserve (won't allocate)", contentX + 190, y + 3, 0, 0.8, 0.8)
    y = y + 30

    local reserve = self.allocationPolicy.reserveThreshold

    -- Decrease button
    self:RenderButton("-", contentX, y, 35, 30, function()
        self.allocationPolicy.reserveThreshold = math.max(0, reserve - 0.05)
        self.allocationPolicy.activePreset = nil
    end, false, {0.5, 0.3, 0.3})

    -- Value display
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print(string.format("%.0f%%", reserve * 100), contentX + 50, y + 7, 0, 1.0, 1.0)

    -- Increase button
    self:RenderButton("+", contentX + 105, y, 35, 30, function()
        self.allocationPolicy.reserveThreshold = math.min(0.9, reserve + 0.05)
        self.allocationPolicy.activePreset = nil
    end, false, {0.3, 0.5, 0.3})

    -- Bar
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", barX, y + 4, barW, barH)
    love.graphics.setColor(0.6, 0.5, 0.3)
    love.graphics.rectangle("fill", barX, y + 4, reserve * barW, barH)

    y = y + itemSpacing + sectionSpacing

    -- =============================================================================
    -- Section 8: Policy Impact Preview
    -- =============================================================================
    love.graphics.setColor(0.8, 0.65, 0.4)
    love.graphics.print("POLICY IMPACT PREVIEW", contentX, y, 0, 1.1, 1.1)
    y = y + 30

    -- Calculate preview stats
    local preview = self:CalculatePolicyImpactPreview()

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Effective allocatable inventory: " .. string.format("%.0f%%", (1 - reserve) * 100), contentX, y, 0, 0.9, 0.9)
    y = y + 22

    love.graphics.print("Characters by priority order:", contentX, y, 0, 0.9, 0.9)
    y = y + 22

    -- Show top 5 characters by priority
    for i, char in ipairs(preview.topCharacters) do
        local classColor = self:GetClassColor(char.class)
        love.graphics.setColor(classColor[1], classColor[2], classColor[3])
        love.graphics.print(string.format("%d. %s (%s) - Priority: %.0f", i, char.name, char.class, char.priority), contentX + 20, y, 0, 0.8, 0.8)
        y = y + 18
    end

    if #preview.topCharacters == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("(No characters to preview)", contentX + 20, y, 0, 0.8, 0.8)
        y = y + 18
    end

    y = y + 20

    -- Store max scroll
    self.allocationPolicyScrollMax = math.max(0, y - contentY - contentH + self.allocationPolicyScrollOffset + 50)

    -- End scissor
    love.graphics.setScissor()

    -- Scroll indicator
    if self.allocationPolicyScrollMax > 0 then
        local scrollBarH = contentH * (contentH / (contentH + self.allocationPolicyScrollMax))
        local scrollBarY = contentY + (self.allocationPolicyScrollOffset / self.allocationPolicyScrollMax) * (contentH - scrollBarH)

        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.rectangle("fill", modalX + modalW - 15, contentY, 8, contentH)
        love.graphics.setColor(0.5, 0.5, 0.55)
        love.graphics.rectangle("fill", modalX + modalW - 15, scrollBarY, 8, scrollBarH)
    end
end

-- Apply a policy preset
function ConsumptionPrototype:ApplyPolicyPreset(preset)
    local settings = preset.settings

    if settings.priorityMode then
        self.allocationPolicy.priorityMode = settings.priorityMode
    end

    if settings.fairnessEnabled ~= nil then
        self.allocationPolicy.fairnessEnabled = settings.fairnessEnabled
    end

    if settings.classPriorities then
        for class, weight in pairs(settings.classPriorities) do
            self.allocationPolicy.classPriorities[class] = weight
        end
    end

    if settings.consumptionBudgets then
        for class, budget in pairs(settings.consumptionBudgets) do
            self.allocationPolicy.consumptionBudgets[class] = budget
        end
    end

    if settings.dimensionPriorities then
        for dim, weight in pairs(settings.dimensionPriorities) do
            self.allocationPolicy.dimensionPriorities[dim] = weight
        end
    end

    if settings.substitutionAggressiveness then
        self.allocationPolicy.substitutionAggressiveness = settings.substitutionAggressiveness
    end

    if settings.reserveThreshold then
        self.allocationPolicy.reserveThreshold = settings.reserveThreshold
    end

    self.allocationPolicy.activePreset = preset.name
end

-- Calculate policy impact preview
function ConsumptionPrototype:CalculatePolicyImpactPreview()
    local preview = {
        topCharacters = {}
    }

    -- Calculate priority for each character based on current policy
    local chars = {}
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            local priority = self:CalculateCharacterPriorityWithPolicy(char)
            table.insert(chars, {
                name = char.name,
                class = char.class,
                priority = priority
            })
        end
    end

    -- Sort by priority (highest first)
    table.sort(chars, function(a, b) return a.priority > b.priority end)

    -- Take top 5
    for i = 1, math.min(5, #chars) do
        table.insert(preview.topCharacters, chars[i])
    end

    return preview
end

-- Calculate character priority based on current policy settings
function ConsumptionPrototype:CalculateCharacterPriorityWithPolicy(character)
    local policy = self.allocationPolicy
    local priority = 0

    -- Base class weight
    local classWeight = policy.classPriorities[character.class] or 1

    if policy.priorityMode == "equality" then
        -- Everyone gets same base priority
        priority = 100 + math.random(0, 10)  -- Small random factor

    elseif policy.priorityMode == "class_based" then
        -- Pure class-based priority
        priority = classWeight * 100

    else -- need_based (default)
        -- Use dimension priorities to weight cravings
        local coarseCravings = character:AggregateCurrentCravingsToCoarse()
        local weightedCraving = 0

        for dimKey, dimWeight in pairs(policy.dimensionPriorities) do
            local craving = coarseCravings[dimKey] or 0
            weightedCraving = weightedCraving + (craving * dimWeight)
        end

        priority = classWeight * 10 + weightedCraving
    end

    -- Apply fairness penalty if enabled
    if policy.fairnessEnabled then
        priority = priority - (character.fairnessPenalty or 0)
    end

    return priority
end

-- =============================================================================
-- Testing Tools Modal (Phase 11)
-- =============================================================================
function ConsumptionPrototype:RenderTestingToolsModal()
    if not self.showTestingToolsModal then return end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Modal dimensions
    local modalW = math.min(950, screenW - 80)
    local modalH = math.min(750, screenH - 80)
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 10, 10)

    -- Modal border
    love.graphics.setColor(0.5, 0.7, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 10, 10)

    -- Title
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("TESTING TOOLS", modalX + 20, modalY + 15, 0, 1.3, 1.3)

    -- Close button
    self:RenderButton("X", modalX + modalW - 45, modalY + 10, 35, 35, function()
        self.showTestingToolsModal = false
    end, false, {0.6, 0.3, 0.3})

    -- Content area with scrolling
    local contentX = modalX + 20
    local contentY = modalY + 60
    local contentW = modalW - 40
    local contentH = modalH - 80

    -- Scissor for scrollable content
    love.graphics.setScissor(contentX, contentY, contentW, contentH)

    local y = contentY - self.testingToolsScrollOffset
    local sectionSpacing = 25

    -- =============================================================================
    -- Section 1: Scenario Generator
    -- =============================================================================
    love.graphics.setColor(0.5, 0.8, 0.6)
    love.graphics.print("SCENARIO GENERATOR", contentX, y, 0, 1.1, 1.1)
    y = y + 28

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Select a scenario template to generate a population with specific characteristics", contentX, y, 0, 0.8, 0.8)
    y = y + 25

    -- Render scenario buttons in 2 columns
    local colWidth = (contentW - 20) / 2
    local col = 0
    local rowY = y

    for i, scenario in ipairs(self.scenarioTemplates) do
        local colX = contentX + (col * (colWidth + 10))
        local isSelected = self.selectedScenario == scenario.id

        -- Scenario button with name
        self:RenderButton(scenario.name, colX, rowY, colWidth - 10, 30, function()
            self.selectedScenario = scenario.id
        end, isSelected, isSelected and {0.4, 0.6, 0.4} or {0.25, 0.3, 0.35})

        -- Description below button
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(scenario.description, colX + 5, rowY + 32, 0, 0.7, 0.7)

        -- Population info
        love.graphics.setColor(0.4, 0.5, 0.5)
        love.graphics.print(string.format("Pop: %d-%d", scenario.population.min, scenario.population.max), colX + 5, rowY + 46, 0, 0.65, 0.65)

        col = col + 1
        if col >= 2 then
            col = 0
            rowY = rowY + 65
        end
    end

    if col ~= 0 then rowY = rowY + 65 end
    y = rowY + 10

    -- Generate button
    local generateEnabled = self.selectedScenario ~= nil
    self:RenderButton("Generate Scenario", contentX, y, 200, 40, function()
        if self.selectedScenario then
            self:GenerateScenario(self.selectedScenario)
        end
    end, false, generateEnabled and {0.3, 0.7, 0.4} or {0.3, 0.3, 0.3})

    -- Clear & Generate button
    self:RenderButton("Clear & Generate", contentX + 210, y, 200, 40, function()
        if self.selectedScenario then
            self:ClearAllCharacters()
            self:ClearInventory()
            self:GenerateScenario(self.selectedScenario)
        end
    end, false, generateEnabled and {0.7, 0.5, 0.3} or {0.3, 0.3, 0.3})

    -- Current state info
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print(string.format("Current: %d characters, %d items", #self.characters, self:GetTotalInventoryCount()), contentX + 430, y + 12, 0, 0.85, 0.85)

    y = y + 55 + sectionSpacing

    -- =============================================================================
    -- Section 2: Quick Actions
    -- =============================================================================
    love.graphics.setColor(0.5, 0.8, 0.6)
    love.graphics.print("QUICK ACTIONS", contentX, y, 0, 1.1, 1.1)
    y = y + 28

    -- Row 1: Population actions
    local btnW = 145
    local btnH = 32
    local btnSpacing = 10

    self:RenderButton("Add 5 Random", contentX, y, btnW, btnH, function()
        self:AddRandomCharacters(5)
    end, false, {0.3, 0.5, 0.6})

    self:RenderButton("Add 10 Random", contentX + btnW + btnSpacing, y, btnW, btnH, function()
        self:AddRandomCharacters(10)
    end, false, {0.3, 0.5, 0.6})

    self:RenderButton("Add 25 Random", contentX + (btnW + btnSpacing) * 2, y, btnW, btnH, function()
        self:AddRandomCharacters(25)
    end, false, {0.3, 0.5, 0.6})

    self:RenderButton("Clear All Chars", contentX + (btnW + btnSpacing) * 3, y, btnW, btnH, function()
        self:ClearAllCharacters()
    end, false, {0.6, 0.3, 0.3})

    y = y + btnH + btnSpacing

    -- Row 2: Inventory actions
    self:RenderButton("Fill Basic Inv", contentX, y, btnW, btnH, function()
        self:FillBasicInventory()
    end, false, {0.4, 0.6, 0.4})

    self:RenderButton("Fill Luxury Inv", contentX + btnW + btnSpacing, y, btnW, btnH, function()
        self:FillLuxuryInventory()
    end, false, {0.6, 0.5, 0.4})

    self:RenderButton("Double Inv", contentX + (btnW + btnSpacing) * 2, y, btnW, btnH, function()
        self:DoubleInventory()
    end, false, {0.4, 0.5, 0.6})

    self:RenderButton("Clear Inventory", contentX + (btnW + btnSpacing) * 3, y, btnW, btnH, function()
        self:ClearInventory()
    end, false, {0.6, 0.3, 0.3})

    y = y + btnH + btnSpacing

    -- Row 3: Time controls
    self:RenderButton("Skip 5 Cycles", contentX, y, btnW, btnH, function()
        self:SkipCycles(5)
    end, false, {0.5, 0.5, 0.6})

    self:RenderButton("Skip 10 Cycles", contentX + btnW + btnSpacing, y, btnW, btnH, function()
        self:SkipCycles(10)
    end, false, {0.5, 0.5, 0.6})

    self:RenderButton("Skip 25 Cycles", contentX + (btnW + btnSpacing) * 2, y, btnW, btnH, function()
        self:SkipCycles(25)
    end, false, {0.5, 0.5, 0.6})

    self:RenderButton("Reset Cycle #", contentX + (btnW + btnSpacing) * 3, y, btnW, btnH, function()
        self.cycleNumber = 0
        self.cycleTime = 0
    end, false, {0.5, 0.4, 0.5})

    y = y + btnH + sectionSpacing + 10

    -- =============================================================================
    -- Section 3: Force Events
    -- =============================================================================
    love.graphics.setColor(0.5, 0.8, 0.6)
    love.graphics.print("FORCE EVENTS", contentX, y, 0, 1.1, 1.1)
    y = y + 28

    self:RenderButton("Trigger Riot", contentX, y, btnW, btnH, function()
        self:TriggerRiot()
    end, false, {0.8, 0.3, 0.3})

    self:RenderButton("Mass Emigration", contentX + btnW + btnSpacing, y, btnW, btnH, function()
        self:TriggerMassEmigration(5)
    end, false, {0.8, 0.5, 0.3})

    self:RenderButton("Random Protest", contentX + (btnW + btnSpacing) * 2, y, btnW, btnH, function()
        self:TriggerRandomProtest()
    end, false, {0.8, 0.6, 0.3})

    self:RenderButton("Civil Unrest", contentX + (btnW + btnSpacing) * 3, y, btnW, btnH, function()
        self:TriggerCivilUnrest()
    end, false, {0.7, 0.3, 0.4})

    y = y + btnH + sectionSpacing + 10

    -- =============================================================================
    -- Section 4: Character State Manipulation
    -- =============================================================================
    love.graphics.setColor(0.5, 0.8, 0.6)
    love.graphics.print("CHARACTER STATE MANIPULATION", contentX, y, 0, 1.1, 1.1)
    y = y + 28

    self:RenderButton("Randomize Sat", contentX, y, btnW, btnH, function()
        self:RandomizeAllSatisfaction()
    end, false, {0.5, 0.5, 0.7})

    self:RenderButton("Max All Sat", contentX + btnW + btnSpacing, y, btnW, btnH, function()
        self:SetAllSatisfaction(100)
    end, false, {0.3, 0.7, 0.4})

    self:RenderButton("Min All Sat", contentX + (btnW + btnSpacing) * 2, y, btnW, btnH, function()
        self:SetAllSatisfaction(0)
    end, false, {0.7, 0.3, 0.3})

    self:RenderButton("Reset Cravings", contentX + (btnW + btnSpacing) * 3, y, btnW, btnH, function()
        self:ResetAllCravings()
    end, false, {0.5, 0.5, 0.5})

    y = y + btnH + btnSpacing

    self:RenderButton("Reset Fatigue", contentX, y, btnW, btnH, function()
        self:ResetAllFatigue()
    end, false, {0.5, 0.5, 0.5})

    self:RenderButton("Clear Protests", contentX + btnW + btnSpacing, y, btnW, btnH, function()
        self:ClearAllProtests()
    end, false, {0.4, 0.6, 0.5})

    self:RenderButton("Age All +10", contentX + (btnW + btnSpacing) * 2, y, btnW, btnH, function()
        self:AgeAllCharacters(10)
    end, false, {0.5, 0.5, 0.6})

    self:RenderButton("Shuffle Traits", contentX + (btnW + btnSpacing) * 3, y, btnW, btnH, function()
        self:ShuffleAllTraits()
    end, false, {0.6, 0.5, 0.5})

    y = y + btnH + sectionSpacing + 10

    -- =============================================================================
    -- Section 5: Simulation Controls
    -- =============================================================================
    love.graphics.setColor(0.5, 0.8, 0.6)
    love.graphics.print("SIMULATION CONTROLS", contentX, y, 0, 1.1, 1.1)
    y = y + 28

    -- Satisfaction Decay Multiplier
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Satisfaction Decay Rate:", contentX, y + 5, 0, 0.9, 0.9)

    self:RenderButton("-", contentX + 200, y, 30, 28, function()
        self.satisfactionDecayMultiplier = math.max(0.1, self.satisfactionDecayMultiplier - 0.25)
    end, false, {0.5, 0.3, 0.3})

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print(string.format("%.2fx", self.satisfactionDecayMultiplier), contentX + 240, y + 5, 0, 0.9, 0.9)

    self:RenderButton("+", contentX + 295, y, 30, 28, function()
        self.satisfactionDecayMultiplier = math.min(5.0, self.satisfactionDecayMultiplier + 0.25)
    end, false, {0.3, 0.5, 0.3})

    -- Quick presets
    self:RenderButton("0.5x", contentX + 340, y, 45, 28, function()
        self.satisfactionDecayMultiplier = 0.5
    end, self.satisfactionDecayMultiplier == 0.5, {0.3, 0.4, 0.5})

    self:RenderButton("1x", contentX + 390, y, 35, 28, function()
        self.satisfactionDecayMultiplier = 1.0
    end, self.satisfactionDecayMultiplier == 1.0, {0.3, 0.4, 0.5})

    self:RenderButton("2x", contentX + 430, y, 35, 28, function()
        self.satisfactionDecayMultiplier = 2.0
    end, self.satisfactionDecayMultiplier == 2.0, {0.3, 0.4, 0.5})

    self:RenderButton("4x", contentX + 470, y, 35, 28, function()
        self.satisfactionDecayMultiplier = 4.0
    end, self.satisfactionDecayMultiplier == 4.0, {0.3, 0.4, 0.5})

    y = y + 35

    -- Craving Growth Multiplier
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Craving Growth Rate:", contentX, y + 5, 0, 0.9, 0.9)

    self:RenderButton("-", contentX + 200, y, 30, 28, function()
        self.cravingGrowthMultiplier = math.max(0.1, self.cravingGrowthMultiplier - 0.25)
    end, false, {0.5, 0.3, 0.3})

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print(string.format("%.2fx", self.cravingGrowthMultiplier), contentX + 240, y + 5, 0, 0.9, 0.9)

    self:RenderButton("+", contentX + 295, y, 30, 28, function()
        self.cravingGrowthMultiplier = math.min(5.0, self.cravingGrowthMultiplier + 0.25)
    end, false, {0.3, 0.5, 0.3})

    -- Quick presets
    self:RenderButton("0.5x", contentX + 340, y, 45, 28, function()
        self.cravingGrowthMultiplier = 0.5
    end, self.cravingGrowthMultiplier == 0.5, {0.3, 0.4, 0.5})

    self:RenderButton("1x", contentX + 390, y, 35, 28, function()
        self.cravingGrowthMultiplier = 1.0
    end, self.cravingGrowthMultiplier == 1.0, {0.3, 0.4, 0.5})

    self:RenderButton("2x", contentX + 430, y, 35, 28, function()
        self.cravingGrowthMultiplier = 2.0
    end, self.cravingGrowthMultiplier == 2.0, {0.3, 0.4, 0.5})

    self:RenderButton("4x", contentX + 470, y, 35, 28, function()
        self.cravingGrowthMultiplier = 4.0
    end, self.cravingGrowthMultiplier == 4.0, {0.3, 0.4, 0.5})

    y = y + 50

    -- Store max scroll
    self.testingToolsScrollMax = math.max(0, y - contentY - contentH + self.testingToolsScrollOffset + 50)

    -- End scissor
    love.graphics.setScissor()

    -- Scroll indicator
    if self.testingToolsScrollMax > 0 then
        local scrollBarH = contentH * (contentH / (contentH + self.testingToolsScrollMax))
        local scrollBarY = contentY + (self.testingToolsScrollOffset / self.testingToolsScrollMax) * (contentH - scrollBarH)

        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.rectangle("fill", modalX + modalW - 15, contentY, 8, contentH)
        love.graphics.setColor(0.5, 0.5, 0.55)
        love.graphics.rectangle("fill", modalX + modalW - 15, scrollBarY, 8, scrollBarH)
    end
end

-- =============================================================================
-- Scenario Generator Functions
-- =============================================================================

-- Generate a scenario based on template ID
function ConsumptionPrototype:GenerateScenario(scenarioId)
    local scenario = nil
    for _, s in ipairs(self.scenarioTemplates) do
        if s.id == scenarioId then
            scenario = s
            break
        end
    end

    if not scenario then
        print("ERROR: Scenario not found: " .. tostring(scenarioId))
        return
    end

    print("\n=== Generating Scenario: " .. scenario.name .. " ===")

    -- Determine population size
    local popSize = math.random(scenario.population.min, scenario.population.max)
    print("  Population size: " .. popSize)

    -- Generate characters according to class distribution
    local classOrder = {"Elite", "Upper", "Middle", "Working", "Poor"}
    local classTargets = {}
    local totalAssigned = 0

    for _, className in ipairs(classOrder) do
        local pct = scenario.classDistribution[className] or 0
        local count = math.floor(popSize * pct)
        classTargets[className] = count
        totalAssigned = totalAssigned + count
    end

    -- Assign remaining to most common class
    local remaining = popSize - totalAssigned
    if remaining > 0 then
        local maxClass = "Middle"
        local maxPct = 0
        for className, pct in pairs(scenario.classDistribution) do
            if pct > maxPct then
                maxPct = pct
                maxClass = className
            end
        end
        classTargets[maxClass] = classTargets[maxClass] + remaining
    end

    -- Create characters
    for _, className in ipairs(classOrder) do
        local count = classTargets[className]
        for i = 1, count do
            local char = self:CreateScenarioCharacter(scenario, className)
            table.insert(self.characters, char)
        end
    end

    -- Update positions
    self:UpdateCharacterPositions()

    -- Set starting inventory
    if scenario.startingInventory then
        for commodity, amount in pairs(scenario.startingInventory) do
            self.townInventory[commodity] = (self.townInventory[commodity] or 0) + amount
        end
    end

    -- Set injection rates
    if scenario.injectionRates then
        for commodity, rate in pairs(scenario.injectionRates) do
            self.injectionRates[commodity] = rate
        end
    end

    -- Log event
    self:LogEvent("info", "Generated scenario: " .. scenario.name .. " with " .. popSize .. " characters", {
        scenario = scenario.id,
        population = popSize
    })

    print("  Scenario generation complete!")
end

-- Create a single character for a scenario
function ConsumptionPrototype:CreateScenarioCharacter(scenario, class)
    local char = CharacterV2:New(class, nil)

    -- Name
    char.name = CharacterV2.GenerateRandomName()

    -- Age based on scenario distribution
    local ageDist = scenario.ageDistribution
    local age
    if ageDist.mean then
        -- Normal-ish distribution around mean
        local deviation = (ageDist.max - ageDist.min) / 4
        age = ageDist.mean + (math.random() - 0.5) * deviation * 2
        age = math.max(ageDist.min, math.min(ageDist.max, math.floor(age)))
    else
        age = math.random(ageDist.min, ageDist.max)
    end
    char.age = age

    -- Vocation based on scenario focus
    if scenario.vocationFocus and #scenario.vocationFocus > 0 then
        -- 70% chance to pick from focus, 30% random
        if math.random() < 0.7 then
            char.vocation = scenario.vocationFocus[math.random(#scenario.vocationFocus)]
        else
            char.vocation = CharacterV2.GetRandomVocation()
        end
    else
        char.vocation = CharacterV2.GetRandomVocation()
    end

    -- Traits based on tendencies
    local traits = {}
    if scenario.traitTendencies and #scenario.traitTendencies > 0 then
        -- 60% chance to get tendency trait, 40% random
        for _, tendencyTrait in ipairs(scenario.traitTendencies) do
            if math.random() < 0.6 then
                table.insert(traits, tendencyTrait)
            end
        end
        -- Add random traits up to 2 total
        while #traits < 2 do
            local randomTraits = CharacterV2.GetRandomTraits(1, class)
            if randomTraits and #randomTraits > 0 then
                local newTrait = randomTraits[1]
                local alreadyHas = false
                for _, t in ipairs(traits) do
                    if t == newTrait then alreadyHas = true break end
                end
                if not alreadyHas then
                    table.insert(traits, newTrait)
                end
            end
            if #traits >= 2 then break end
        end
    else
        traits = CharacterV2.GetRandomTraits(2, class)
    end
    char.traits = traits

    -- Recalculate base cravings with new traits
    char.baseCravings = CharacterV2.GenerateBaseCravings(class, traits)

    -- Set satisfaction based on scenario or class-specific ranges
    local satMin, satMax
    if scenario.satisfactionByClass and scenario.satisfactionByClass[class] then
        satMin = scenario.satisfactionByClass[class][1]
        satMax = scenario.satisfactionByClass[class][2]
    else
        satMin = scenario.satisfactionRange.min
        satMax = scenario.satisfactionRange.max
    end

    -- Set coarse satisfaction (indices 0-8)
    for i = 0, 8 do
        char.satisfaction[i] = math.random(satMin, satMax)
    end

    return char
end

-- Update character grid positions
function ConsumptionPrototype:UpdateCharacterPositions()
    local centerW = love.graphics.getWidth() - self.leftPanelWidth - self.rightPanelWidth
    local cardSpacing = 120  -- 110 card width + 10 gap
    local maxCols = math.max(1, math.floor((centerW - 40) / cardSpacing))  -- 40 = 20 margin each side
    for i, char in ipairs(self.characters) do
        local idx = i - 1
        local col = idx % maxCols
        local row = math.floor(idx / maxCols)
        char.position.x = self.leftPanelWidth + 20 + col * cardSpacing
        char.position.y = self.topBarHeight + 20 + row * 100
    end
end

-- =============================================================================
-- Testing Tool Action Functions
-- =============================================================================

function ConsumptionPrototype:GetTotalInventoryCount()
    local total = 0
    for _, qty in pairs(self.townInventory) do
        total = total + qty
    end
    return total
end

function ConsumptionPrototype:AddRandomCharacters(count)
    local classes = {"Elite", "Upper", "Middle", "Working", "Poor"}
    for i = 1, count do
        local class = classes[math.random(#classes)]
        self:AddCharacter(class, {}, nil)
    end
    self:UpdateCharacterPositions()
    self:LogEvent("info", "Added " .. count .. " random characters", {count = count})
end

function ConsumptionPrototype:ClearAllCharacters()
    local count = #self.characters
    self.characters = {}
    self.selectedCharacter = nil
    self.detailCharacter = nil
    self:LogEvent("info", "Cleared all " .. count .. " characters", {count = count})
end

function ConsumptionPrototype:ClearInventory()
    local count = self:GetTotalInventoryCount()
    self.townInventory = {}
    self.injectionRates = {}
    self:LogEvent("info", "Cleared inventory (" .. count .. " items)", {count = count})
end

function ConsumptionPrototype:FillBasicInventory()
    local basics = {
        bread = 100, water = 100, vegetables = 80, meat = 50,
        ale = 40, cheese = 30, clothing_everyday = 30, tools = 20
    }
    for commodity, amount in pairs(basics) do
        self.townInventory[commodity] = (self.townInventory[commodity] or 0) + amount
    end
    self:LogEvent("info", "Filled basic inventory", {})
end

function ConsumptionPrototype:FillLuxuryInventory()
    local luxury = {
        wine = 50, exotic_spices = 30, silk_fabric = 25, jewelry = 20,
        art_painting = 15, books = 30, perfume = 20, tea = 25
    }
    for commodity, amount in pairs(luxury) do
        self.townInventory[commodity] = (self.townInventory[commodity] or 0) + amount
    end
    self:LogEvent("info", "Filled luxury inventory", {})
end

function ConsumptionPrototype:DoubleInventory()
    for commodity, amount in pairs(self.townInventory) do
        self.townInventory[commodity] = amount * 2
    end
    self:LogEvent("info", "Doubled all inventory", {})
end

function ConsumptionPrototype:SkipCycles(count)
    for i = 1, count do
        self:RunAllocationCycle()
        self.cycleNumber = self.cycleNumber + 1
        self:RecordHistoricalData()
    end
    self:LogEvent("info", "Skipped " .. count .. " cycles", {cycles = count})
end

function ConsumptionPrototype:TriggerRiot()
    TownConsequences.TriggerRiot(self.characters, self.cycleNumber)
    self:LogEvent("riot", "Riot triggered manually!", {})
end

function ConsumptionPrototype:TriggerMassEmigration(count)
    local emigrated = 0
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated and emigrated < count then
            char.hasEmigrated = true
            emigrated = emigrated + 1
            self.stats.totalEmigrations = self.stats.totalEmigrations + 1
        end
    end
    self:LogEvent("emigration", emigrated .. " characters emigrated (forced)", {count = emigrated})
end

function ConsumptionPrototype:TriggerRandomProtest()
    local available = {}
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated and not char.isProtesting then
            table.insert(available, char)
        end
    end
    if #available > 0 then
        local char = available[math.random(#available)]
        char.isProtesting = true
        self:LogEvent("protest", char.name .. " started protesting (forced)", {character = char.name})
    end
end

function ConsumptionPrototype:TriggerCivilUnrest()
    -- Make 30% of population protest
    local count = math.floor(#self.characters * 0.3)
    local protesting = 0
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated and protesting < count then
            char.isProtesting = true
            protesting = protesting + 1
        end
    end
    self:LogEvent("protest", "Civil unrest! " .. protesting .. " characters protesting", {count = protesting})
end

function ConsumptionPrototype:RandomizeAllSatisfaction()
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            for i = 0, 8 do
                char.satisfaction[i] = math.random(0, 100)
            end
        end
    end
    self:LogEvent("info", "Randomized all satisfaction values", {})
end

function ConsumptionPrototype:SetAllSatisfaction(value)
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            for i = 0, 8 do
                char.satisfaction[i] = value
            end
        end
    end
    self:LogEvent("info", "Set all satisfaction to " .. value, {value = value})
end

function ConsumptionPrototype:ResetAllCravings()
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            for i = 0, 48 do
                char.currentCravings[i] = 0
            end
        end
    end
    self:LogEvent("info", "Reset all cravings to 0", {})
end

function ConsumptionPrototype:ResetAllFatigue()
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            char.commodityFatigue = {}
        end
    end
    self:LogEvent("info", "Reset all commodity fatigue", {})
end

function ConsumptionPrototype:ClearAllProtests()
    local cleared = 0
    for _, char in ipairs(self.characters) do
        if char.isProtesting then
            char.isProtesting = false
            cleared = cleared + 1
        end
    end
    self:LogEvent("info", "Cleared " .. cleared .. " protests", {count = cleared})
end

function ConsumptionPrototype:AgeAllCharacters(years)
    for _, char in ipairs(self.characters) do
        char.age = char.age + years
    end
    self:LogEvent("info", "Aged all characters by " .. years .. " years", {years = years})
end

function ConsumptionPrototype:ShuffleAllTraits()
    for _, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            char.traits = CharacterV2.GetRandomTraits(2, char.class)
            char.baseCravings = CharacterV2.GenerateBaseCravings(char.class, char.traits)
        end
    end
    self:LogEvent("info", "Shuffled all character traits", {})
end

-- =============================================================================
-- Save/Load System (Phase 12)
-- =============================================================================

function ConsumptionPrototype:RenderSaveLoadModal()
    if not self.showSaveLoadModal then return end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Modal dimensions
    local modalW = math.min(700, screenW - 100)
    local modalH = math.min(550, screenH - 100)
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 10, 10)

    -- Modal border
    love.graphics.setColor(0.4, 0.5, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 10, 10)

    -- Title
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("SAVE / LOAD", modalX + 20, modalY + 15, 0, 1.3, 1.3)

    -- Close button
    self:RenderButton("X", modalX + modalW - 45, modalY + 10, 35, 35, function()
        self.showSaveLoadModal = false
    end, false, {0.6, 0.3, 0.3})

    -- Content area
    local contentX = modalX + 20
    local contentY = modalY + 60
    local contentW = modalW - 40

    local y = contentY

    -- =============================================================================
    -- Section 1: Quick Save/Load
    -- =============================================================================
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.print("QUICK SAVE/LOAD", contentX, y, 0, 1.1, 1.1)
    y = y + 28

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Hotkeys: F5 = Quick Save, F9 = Quick Load", contentX, y, 0, 0.8, 0.8)
    y = y + 25

    self:RenderButton("Quick Save (F5)", contentX, y, 150, 35, function()
        self:QuickSave()
    end, false, {0.3, 0.6, 0.4})

    self:RenderButton("Quick Load (F9)", contentX + 160, y, 150, 35, function()
        self:QuickLoad()
    end, false, {0.4, 0.5, 0.6})

    -- Current state info
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print(string.format("Cycle: %d | Chars: %d | Items: %d",
        self.cycleNumber, #self.characters, self:GetTotalInventoryCount()),
        contentX + 330, y + 10, 0, 0.85, 0.85)

    y = y + 55

    -- =============================================================================
    -- Section 2: Save Slots
    -- =============================================================================
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.print("SAVE SLOTS", contentX, y, 0, 1.1, 1.1)
    y = y + 30

    for i = 1, 5 do
        local slotData = self:GetSaveSlotInfo(i)
        local slotY = y

        -- Slot background
        love.graphics.setColor(0.15, 0.15, 0.18)
        love.graphics.rectangle("fill", contentX, slotY, contentW, 60, 5, 5)

        -- Slot border
        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.rectangle("line", contentX, slotY, contentW, 60, 5, 5)

        -- Slot name
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Slot " .. i, contentX + 10, slotY + 8, 0, 1.0, 1.0)

        if slotData then
            -- Show save info
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(string.format("Cycle %d | %d chars | %s",
                slotData.cycleNumber or 0,
                slotData.characterCount or 0,
                slotData.timestamp or "Unknown"),
                contentX + 80, slotY + 10, 0, 0.8, 0.8)

            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print(slotData.scenarioName or "Custom", contentX + 80, slotY + 28, 0, 0.75, 0.75)
        else
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.print("(Empty)", contentX + 80, slotY + 18, 0, 0.85, 0.85)
        end

        -- Save button
        self:RenderButton("Save", contentX + contentW - 190, slotY + 15, 60, 30, function()
            self:SaveToSlot(i)
        end, false, {0.3, 0.6, 0.4})

        -- Load button
        local loadEnabled = slotData ~= nil
        self:RenderButton("Load", contentX + contentW - 125, slotY + 15, 60, 30, function()
            if slotData then
                self:LoadFromSlot(i)
            end
        end, false, loadEnabled and {0.4, 0.5, 0.6} or {0.25, 0.25, 0.25})

        -- Delete button
        self:RenderButton("X", contentX + contentW - 55, slotY + 15, 30, 30, function()
            if slotData then
                self:DeleteSlot(i)
            end
        end, false, slotData and {0.6, 0.3, 0.3} or {0.25, 0.25, 0.25})

        y = y + 68
    end

    y = y + 15

    -- =============================================================================
    -- Section 3: Auto-Save Settings
    -- =============================================================================
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.print("AUTO-SAVE", contentX, y, 0, 1.1, 1.1)
    y = y + 28

    -- Toggle auto-save
    self:RenderButton(self.autoSaveEnabled and "ENABLED" or "DISABLED", contentX, y, 100, 30, function()
        self.autoSaveEnabled = not self.autoSaveEnabled
    end, self.autoSaveEnabled, self.autoSaveEnabled and {0.3, 0.6, 0.4} or {0.5, 0.3, 0.3})

    -- Interval
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Every", contentX + 115, y + 7, 0, 0.9, 0.9)

    self:RenderButton("-", contentX + 160, y, 30, 30, function()
        self.autoSaveInterval = math.max(1, self.autoSaveInterval - 1)
    end, false, {0.5, 0.3, 0.3})

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print(tostring(self.autoSaveInterval), contentX + 200, y + 7, 0, 0.9, 0.9)

    self:RenderButton("+", contentX + 225, y, 30, 30, function()
        self.autoSaveInterval = math.min(50, self.autoSaveInterval + 1)
    end, false, {0.3, 0.5, 0.3})

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("cycles", contentX + 265, y + 7, 0, 0.9, 0.9)

    y = y + 45

    -- =============================================================================
    -- Section 4: Export/Import
    -- =============================================================================
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.print("EXPORT / IMPORT", contentX, y, 0, 1.1, 1.1)
    y = y + 28

    self:RenderButton("Export to Clipboard", contentX, y, 160, 32, function()
        self:ExportToClipboard()
    end, false, {0.5, 0.5, 0.6})

    self:RenderButton("Import from Clipboard", contentX + 170, y, 170, 32, function()
        self:ImportFromClipboard()
    end, false, {0.5, 0.6, 0.5})

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Share saves via clipboard", contentX + 355, y + 8, 0, 0.8, 0.8)
end

-- Create save data structure
function ConsumptionPrototype:CreateSaveData()
    local saveData = {
        version = "1.0",
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        unixTime = os.time(),

        -- Simulation state
        simulation = {
            cycleNumber = self.cycleNumber,
            cycleTime = self.cycleTime,
            cycleDuration = self.cycleDuration,
            isPaused = self.isPaused,
            simulationSpeed = self.simulationSpeed,
            satisfactionDecayMultiplier = self.satisfactionDecayMultiplier,
            cravingGrowthMultiplier = self.cravingGrowthMultiplier
        },

        -- Characters (serialize all 6 layers)
        characters = {},

        -- Town inventory
        townInventory = {},

        -- Injection rates
        injectionRates = {},

        -- Allocation policy
        allocationPolicy = {
            priorityMode = self.allocationPolicy.priorityMode,
            fairnessEnabled = self.allocationPolicy.fairnessEnabled,
            classPriorities = {},
            consumptionBudgets = {},
            dimensionPriorities = {},
            substitutionAggressiveness = self.allocationPolicy.substitutionAggressiveness,
            reserveThreshold = self.allocationPolicy.reserveThreshold
        },

        -- Statistics
        stats = {
            totalCycles = self.stats.totalCycles,
            totalAllocations = self.stats.totalAllocations,
            totalEmigrations = self.stats.totalEmigrations,
            totalRiots = self.stats.totalRiots
        },

        -- Event log (last 50)
        eventLog = {},

        -- Historical data
        satisfactionHistory = self.satisfactionHistory,
        populationHistory = self.populationHistory,

        -- Scenario info
        scenarioName = self.selectedScenario or "Custom"
    }

    -- Serialize characters
    for _, char in ipairs(self.characters) do
        local charData = {
            id = char.id,
            name = char.name,
            age = char.age,
            class = char.class,
            vocation = char.vocation,
            traits = char.traits,
            baseCravings = {},
            currentCravings = {},
            satisfaction = {},
            commodityFatigue = {},
            hasEmigrated = char.hasEmigrated,
            isProtesting = char.isProtesting,
            consecutiveLowSatisfactionCycles = char.consecutiveLowSatisfactionCycles,
            consecutiveFailedAllocations = char.consecutiveFailedAllocations,
            fairnessPenalty = char.fairnessPenalty,
            allocationPriority = char.allocationPriority,
            successCount = char.successCount,
            attemptCount = char.attemptCount
        }

        -- Serialize arrays with numeric keys
        for i = 0, 48 do
            charData.baseCravings[tostring(i)] = char.baseCravings[i]
            charData.currentCravings[tostring(i)] = char.currentCravings[i]
        end
        for i = 0, 8 do
            charData.satisfaction[tostring(i)] = char.satisfaction[i]
        end

        -- Serialize commodity fatigue
        if char.commodityFatigue then
            for commodity, fatigue in pairs(char.commodityFatigue) do
                charData.commodityFatigue[commodity] = fatigue
            end
        end

        -- Serialize active effects (durables/permanents)
        charData.activeEffects = {}
        if char.activeEffects then
            for _, effect in ipairs(char.activeEffects) do
                table.insert(charData.activeEffects, {
                    commodityId = effect.commodityId,
                    category = effect.category,
                    durability = effect.durability,
                    acquiredCycle = effect.acquiredCycle,
                    durationCycles = effect.durationCycles,
                    remainingCycles = effect.remainingCycles,
                    effectDecayRate = effect.effectDecayRate,
                    currentEffectiveness = effect.currentEffectiveness,
                    maxOwned = effect.maxOwned
                    -- Note: fulfillmentVector is not saved - will be rebuilt from commodity data on load
                })
            end
        end

        table.insert(saveData.characters, charData)
    end

    -- Serialize inventory
    for commodity, qty in pairs(self.townInventory) do
        saveData.townInventory[commodity] = qty
    end

    -- Serialize injection rates
    for commodity, rate in pairs(self.injectionRates) do
        saveData.injectionRates[commodity] = rate
    end

    -- Serialize allocation policy tables
    for class, weight in pairs(self.allocationPolicy.classPriorities) do
        saveData.allocationPolicy.classPriorities[class] = weight
    end
    for class, budget in pairs(self.allocationPolicy.consumptionBudgets) do
        saveData.allocationPolicy.consumptionBudgets[class] = budget
    end
    for dim, weight in pairs(self.allocationPolicy.dimensionPriorities) do
        saveData.allocationPolicy.dimensionPriorities[dim] = weight
    end

    -- Serialize event log (last 50)
    local startIdx = math.max(1, #self.eventLog - 49)
    for i = startIdx, #self.eventLog do
        table.insert(saveData.eventLog, self.eventLog[i])
    end

    return saveData
end

-- Encode save data to JSON string
function ConsumptionPrototype:EncodeSaveData(saveData)
    -- Simple JSON encoder for Lua tables
    local function encode(val, indent)
        indent = indent or 0
        local t = type(val)

        if t == "nil" then
            return "null"
        elseif t == "boolean" then
            return val and "true" or "false"
        elseif t == "number" then
            if val ~= val then return "null" end  -- NaN
            if val == math.huge or val == -math.huge then return "null" end
            return tostring(val)
        elseif t == "string" then
            return '"' .. val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
        elseif t == "table" then
            local isArray = #val > 0 or next(val) == nil
            -- Check if it's actually an array
            for k, _ in pairs(val) do
                if type(k) ~= "number" then
                    isArray = false
                    break
                end
            end

            local parts = {}
            if isArray then
                for _, v in ipairs(val) do
                    table.insert(parts, encode(v, indent + 1))
                end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                for k, v in pairs(val) do
                    local key = type(k) == "string" and k or tostring(k)
                    table.insert(parts, '"' .. key .. '":' .. encode(v, indent + 1))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        end
        return "null"
    end

    return encode(saveData)
end

-- Decode JSON string to save data
function ConsumptionPrototype:DecodeSaveData(jsonStr)
    -- Simple JSON decoder
    local pos = 1

    local function skipWhitespace()
        while pos <= #jsonStr do
            local c = jsonStr:sub(pos, pos)
            if c == ' ' or c == '\t' or c == '\n' or c == '\r' then
                pos = pos + 1
            else
                break
            end
        end
    end

    local function parseValue()
        skipWhitespace()
        local c = jsonStr:sub(pos, pos)

        if c == '"' then
            -- String
            pos = pos + 1
            local startPos = pos
            local result = ""
            while pos <= #jsonStr do
                c = jsonStr:sub(pos, pos)
                if c == '"' then
                    pos = pos + 1
                    return result
                elseif c == '\\' then
                    pos = pos + 1
                    local nextC = jsonStr:sub(pos, pos)
                    if nextC == 'n' then result = result .. '\n'
                    elseif nextC == 'r' then result = result .. '\r'
                    elseif nextC == 't' then result = result .. '\t'
                    elseif nextC == '"' then result = result .. '"'
                    elseif nextC == '\\' then result = result .. '\\'
                    else result = result .. nextC
                    end
                    pos = pos + 1
                else
                    result = result .. c
                    pos = pos + 1
                end
            end
            return result
        elseif c == '{' then
            -- Object
            pos = pos + 1
            local obj = {}
            skipWhitespace()
            if jsonStr:sub(pos, pos) == '}' then
                pos = pos + 1
                return obj
            end
            while true do
                skipWhitespace()
                local key = parseValue()
                skipWhitespace()
                pos = pos + 1  -- skip ':'
                local value = parseValue()
                obj[key] = value
                skipWhitespace()
                c = jsonStr:sub(pos, pos)
                if c == '}' then
                    pos = pos + 1
                    return obj
                end
                pos = pos + 1  -- skip ','
            end
        elseif c == '[' then
            -- Array
            pos = pos + 1
            local arr = {}
            skipWhitespace()
            if jsonStr:sub(pos, pos) == ']' then
                pos = pos + 1
                return arr
            end
            while true do
                local value = parseValue()
                table.insert(arr, value)
                skipWhitespace()
                c = jsonStr:sub(pos, pos)
                if c == ']' then
                    pos = pos + 1
                    return arr
                end
                pos = pos + 1  -- skip ','
            end
        elseif jsonStr:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif jsonStr:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif jsonStr:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        else
            -- Number
            local numStr = ""
            while pos <= #jsonStr do
                c = jsonStr:sub(pos, pos)
                if c:match("[%d%.%-eE%+]") then
                    numStr = numStr .. c
                    pos = pos + 1
                else
                    break
                end
            end
            return tonumber(numStr)
        end
    end

    local success, result = pcall(parseValue)
    if success then
        return result
    else
        return nil, "Failed to parse JSON"
    end
end

-- Load save data into prototype
function ConsumptionPrototype:LoadSaveData(saveData)
    if not saveData then
        print("ERROR: No save data to load")
        return false
    end

    -- Clear current state
    self.characters = {}
    self.townInventory = {}
    self.injectionRates = {}
    self.eventLog = {}
    self.selectedCharacter = nil
    self.detailCharacter = nil

    -- Restore simulation state
    if saveData.simulation then
        self.cycleNumber = saveData.simulation.cycleNumber or 0
        self.cycleTime = saveData.simulation.cycleTime or 0
        self.cycleDuration = saveData.simulation.cycleDuration or 60
        self.isPaused = saveData.simulation.isPaused
        if self.isPaused == nil then self.isPaused = true end
        self.simulationSpeed = saveData.simulation.simulationSpeed or 1.0
        self.satisfactionDecayMultiplier = saveData.simulation.satisfactionDecayMultiplier or 1.0
        self.cravingGrowthMultiplier = saveData.simulation.cravingGrowthMultiplier or 1.0
    end

    -- Restore characters
    if saveData.characters then
        for _, charData in ipairs(saveData.characters) do
            local char = CharacterV2:New(charData.class, charData.id)
            char.name = charData.name or "Unknown"
            char.age = charData.age or 30
            char.vocation = charData.vocation or "Unknown"
            char.traits = charData.traits or {}
            char.hasEmigrated = charData.hasEmigrated or false
            char.isProtesting = charData.isProtesting or false
            char.consecutiveLowSatisfactionCycles = charData.consecutiveLowSatisfactionCycles or 0
            char.consecutiveFailedAllocations = charData.consecutiveFailedAllocations or 0
            char.fairnessPenalty = charData.fairnessPenalty or 0
            char.allocationPriority = charData.allocationPriority or 0
            char.successCount = charData.successCount or 0
            char.attemptCount = charData.attemptCount or 0

            -- Restore arrays with numeric keys
            if charData.baseCravings then
                for k, v in pairs(charData.baseCravings) do
                    char.baseCravings[tonumber(k)] = v
                end
            end
            if charData.currentCravings then
                for k, v in pairs(charData.currentCravings) do
                    char.currentCravings[tonumber(k)] = v
                end
            end
            if charData.satisfaction then
                for k, v in pairs(charData.satisfaction) do
                    char.satisfaction[tonumber(k)] = v
                end
            end
            if charData.commodityFatigue then
                char.commodityFatigue = charData.commodityFatigue
            end

            -- Restore active effects (durables/permanents)
            char.activeEffects = {}
            if charData.activeEffects then
                for _, effectData in ipairs(charData.activeEffects) do
                    -- Rebuild fulfillment vector from commodity data
                    local commodityData = self.fulfillmentVectors and self.fulfillmentVectors.commodities and self.fulfillmentVectors.commodities[effectData.commodityId]
                    local fulfillmentVector = nil
                    if commodityData and commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine then
                        fulfillmentVector = commodityData.fulfillmentVector.fine
                    end

                    table.insert(char.activeEffects, {
                        commodityId = effectData.commodityId,
                        category = effectData.category,
                        durability = effectData.durability,
                        acquiredCycle = effectData.acquiredCycle,
                        durationCycles = effectData.durationCycles,
                        remainingCycles = effectData.remainingCycles,
                        effectDecayRate = effectData.effectDecayRate,
                        currentEffectiveness = effectData.currentEffectiveness,
                        maxOwned = effectData.maxOwned,
                        fulfillmentVector = fulfillmentVector
                    })
                end
            end

            table.insert(self.characters, char)
        end
    end

    -- Update character positions
    self:UpdateCharacterPositions()

    -- Restore inventory
    if saveData.townInventory then
        for commodity, qty in pairs(saveData.townInventory) do
            self.townInventory[commodity] = qty
        end
    end

    -- Restore injection rates
    if saveData.injectionRates then
        for commodity, rate in pairs(saveData.injectionRates) do
            self.injectionRates[commodity] = rate
        end
    end

    -- Restore allocation policy
    if saveData.allocationPolicy then
        self.allocationPolicy.priorityMode = saveData.allocationPolicy.priorityMode or "need_based"
        self.allocationPolicy.fairnessEnabled = saveData.allocationPolicy.fairnessEnabled or false
        self.allocationPolicy.substitutionAggressiveness = saveData.allocationPolicy.substitutionAggressiveness or 0.5
        self.allocationPolicy.reserveThreshold = saveData.allocationPolicy.reserveThreshold or 0.0

        if saveData.allocationPolicy.classPriorities then
            for class, weight in pairs(saveData.allocationPolicy.classPriorities) do
                self.allocationPolicy.classPriorities[class] = weight
            end
        end
        if saveData.allocationPolicy.consumptionBudgets then
            for class, budget in pairs(saveData.allocationPolicy.consumptionBudgets) do
                self.allocationPolicy.consumptionBudgets[class] = budget
            end
        end
        if saveData.allocationPolicy.dimensionPriorities then
            for dim, weight in pairs(saveData.allocationPolicy.dimensionPriorities) do
                self.allocationPolicy.dimensionPriorities[dim] = weight
            end
        end
    end

    -- Restore stats
    if saveData.stats then
        self.stats.totalCycles = saveData.stats.totalCycles or 0
        self.stats.totalAllocations = saveData.stats.totalAllocations or 0
        self.stats.totalEmigrations = saveData.stats.totalEmigrations or 0
        self.stats.totalRiots = saveData.stats.totalRiots or 0
    end

    -- Restore event log
    if saveData.eventLog then
        self.eventLog = saveData.eventLog
    end

    -- Restore history
    if saveData.satisfactionHistory then
        self.satisfactionHistory = saveData.satisfactionHistory
    end
    if saveData.populationHistory then
        self.populationHistory = saveData.populationHistory
    end

    -- Restore scenario name
    self.selectedScenario = saveData.scenarioName

    return true
end

-- Save to a slot
function ConsumptionPrototype:SaveToSlot(slotNum)
    local saveData = self:CreateSaveData()
    local jsonStr = self:EncodeSaveData(saveData)

    -- Ensure save directory exists
    local info = love.filesystem.getInfo(self.saveDirectory)
    if not info then
        love.filesystem.createDirectory(self.saveDirectory)
    end

    -- Write to file
    local filename = self.saveDirectory .. "/slot" .. slotNum .. ".json"
    local success, err = love.filesystem.write(filename, jsonStr)

    if success then
        self.lastSaveMessage = "Saved to Slot " .. slotNum
        self.lastSaveMessageTime = love.timer.getTime()
        self:LogEvent("info", "Game saved to Slot " .. slotNum, {slot = slotNum})
        print("Saved to " .. filename)
    else
        self.lastSaveMessage = "Save failed: " .. tostring(err)
        self.lastSaveMessageTime = love.timer.getTime()
        print("ERROR saving: " .. tostring(err))
    end
end

-- Load from a slot
function ConsumptionPrototype:LoadFromSlot(slotNum)
    local filename = self.saveDirectory .. "/slot" .. slotNum .. ".json"
    local jsonStr, err = love.filesystem.read(filename)

    if not jsonStr then
        self.lastSaveMessage = "Load failed: " .. tostring(err)
        self.lastSaveMessageTime = love.timer.getTime()
        print("ERROR loading: " .. tostring(err))
        return false
    end

    local saveData = self:DecodeSaveData(jsonStr)
    if not saveData then
        self.lastSaveMessage = "Load failed: Invalid save data"
        self.lastSaveMessageTime = love.timer.getTime()
        print("ERROR: Invalid save data")
        return false
    end

    local success = self:LoadSaveData(saveData)
    if success then
        self.lastSaveMessage = "Loaded from Slot " .. slotNum
        self.lastSaveMessageTime = love.timer.getTime()
        self:LogEvent("info", "Game loaded from Slot " .. slotNum, {slot = slotNum})
        print("Loaded from " .. filename)
    end

    return success
end

-- Delete a save slot
function ConsumptionPrototype:DeleteSlot(slotNum)
    local filename = self.saveDirectory .. "/slot" .. slotNum .. ".json"
    local success = love.filesystem.remove(filename)

    if success then
        self.lastSaveMessage = "Deleted Slot " .. slotNum
        self.lastSaveMessageTime = love.timer.getTime()
    end
end

-- Get save slot info (for display)
function ConsumptionPrototype:GetSaveSlotInfo(slotNum)
    local filename = self.saveDirectory .. "/slot" .. slotNum .. ".json"
    local info = love.filesystem.getInfo(filename)

    if not info then
        return nil
    end

    local jsonStr = love.filesystem.read(filename)
    if not jsonStr then
        return nil
    end

    local saveData = self:DecodeSaveData(jsonStr)
    if not saveData then
        return nil
    end

    return {
        cycleNumber = saveData.simulation and saveData.simulation.cycleNumber or 0,
        characterCount = saveData.characters and #saveData.characters or 0,
        timestamp = saveData.timestamp or "Unknown",
        scenarioName = saveData.scenarioName or "Custom"
    }
end

-- Quick save (to auto-save slot)
function ConsumptionPrototype:QuickSave()
    local saveData = self:CreateSaveData()
    local jsonStr = self:EncodeSaveData(saveData)

    local info = love.filesystem.getInfo(self.saveDirectory)
    if not info then
        love.filesystem.createDirectory(self.saveDirectory)
    end

    local filename = self.saveDirectory .. "/quicksave.json"
    local success, err = love.filesystem.write(filename, jsonStr)

    if success then
        self.lastSaveMessage = "Quick Save complete"
        self.lastSaveMessageTime = love.timer.getTime()
        self:LogEvent("info", "Quick Save", {})
        print("Quick saved to " .. filename)
    else
        self.lastSaveMessage = "Quick Save failed"
        self.lastSaveMessageTime = love.timer.getTime()
        print("ERROR quick saving: " .. tostring(err))
    end
end

-- Quick load
function ConsumptionPrototype:QuickLoad()
    local filename = self.saveDirectory .. "/quicksave.json"
    local jsonStr, err = love.filesystem.read(filename)

    if not jsonStr then
        self.lastSaveMessage = "No Quick Save found"
        self.lastSaveMessageTime = love.timer.getTime()
        print("No quicksave file found")
        return false
    end

    local saveData = self:DecodeSaveData(jsonStr)
    if not saveData then
        self.lastSaveMessage = "Quick Load failed"
        self.lastSaveMessageTime = love.timer.getTime()
        return false
    end

    local success = self:LoadSaveData(saveData)
    if success then
        self.lastSaveMessage = "Quick Load complete"
        self.lastSaveMessageTime = love.timer.getTime()
        self:LogEvent("info", "Quick Load", {})
    end

    return success
end

-- Auto-save (called from Update)
function ConsumptionPrototype:CheckAutoSave()
    if not self.autoSaveEnabled then return end

    if self.cycleNumber > 0 and
       self.cycleNumber ~= self.lastAutoSaveCycle and
       self.cycleNumber % self.autoSaveInterval == 0 then
        self.lastAutoSaveCycle = self.cycleNumber

        local saveData = self:CreateSaveData()
        local jsonStr = self:EncodeSaveData(saveData)

        local info = love.filesystem.getInfo(self.saveDirectory)
        if not info then
            love.filesystem.createDirectory(self.saveDirectory)
        end

        local filename = self.saveDirectory .. "/autosave.json"
        local success = love.filesystem.write(filename, jsonStr)

        if success then
            self.lastSaveMessage = "Auto-saved"
            self.lastSaveMessageTime = love.timer.getTime()
            print("Auto-saved at cycle " .. self.cycleNumber)
        end
    end
end

-- Export to clipboard
function ConsumptionPrototype:ExportToClipboard()
    local saveData = self:CreateSaveData()
    local jsonStr = self:EncodeSaveData(saveData)

    love.system.setClipboardText(jsonStr)
    self.lastSaveMessage = "Exported to clipboard!"
    self.lastSaveMessageTime = love.timer.getTime()
    self:LogEvent("info", "Save data exported to clipboard", {})
end

-- Import from clipboard
function ConsumptionPrototype:ImportFromClipboard()
    local jsonStr = love.system.getClipboardText()

    if not jsonStr or jsonStr == "" then
        self.lastSaveMessage = "Clipboard is empty"
        self.lastSaveMessageTime = love.timer.getTime()
        return false
    end

    local saveData = self:DecodeSaveData(jsonStr)
    if not saveData then
        self.lastSaveMessage = "Invalid save data in clipboard"
        self.lastSaveMessageTime = love.timer.getTime()
        return false
    end

    local success = self:LoadSaveData(saveData)
    if success then
        self.lastSaveMessage = "Imported from clipboard!"
        self.lastSaveMessageTime = love.timer.getTime()
        self:LogEvent("info", "Save data imported from clipboard", {})
    end

    return success
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

-- Render character card at explicit coordinates (for scrolling)
function ConsumptionPrototype:RenderCharacterCardAt(character, x, y)
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
        love.graphics.print("!", x + 5, y + 52, 0, 0.7, 0.7)
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

    -- Possessions indicator
    local possessionCount = character.activeEffects and #character.activeEffects or 0
    if possessionCount > 0 then
        -- Check if any possession is degraded (<50% effectiveness)
        local hasDegraded = false
        for _, effect in ipairs(character.activeEffects) do
            if effect.currentEffectiveness and effect.currentEffectiveness < 0.5 then
                hasDegraded = true
                break
            end
        end
        if hasDegraded then
            love.graphics.setColor(0.9, 0.6, 0.3)  -- Orange for degraded
        else
            love.graphics.setColor(0.6, 0.7, 0.8)  -- Blue-gray for normal
        end
        love.graphics.print(possessionCount .. " items", x + w - 45, y + h - 18, 0, 0.5, 0.5)
    end
    -- Note: Click detection handled in MouseReleased with bounds checking
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
        elseif self.showAnalyticsModal then
            self.showAnalyticsModal = false
        elseif self.showAllocationPolicyModal then
            self.showAllocationPolicyModal = false
        elseif self.showTestingToolsModal then
            self.showTestingToolsModal = false
        elseif self.showSaveLoadModal then
            self.showSaveLoadModal = false
        elseif self.showHelpOverlay then
            self.showHelpOverlay = false
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
    elseif key == "f5" then
        -- Quick Save
        self:QuickSave()
    elseif key == "f9" then
        -- Quick Load
        self:QuickLoad()
    elseif key == "h" then
        -- Toggle help overlay
        self.showHelpOverlay = not self.showHelpOverlay
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
    elseif not self:IsAnyModalOpen() then
        -- Shortcuts only work when no modal is open
        if key == "1" then
            self.simulationSpeed = 1
        elseif key == "2" then
            self.simulationSpeed = 2
        elseif key == "3" then
            self.simulationSpeed = 5
        elseif key == "4" then
            self.simulationSpeed = 10
        elseif key == "c" then
            self.showCharacterCreator = true
        elseif key == "r" then
            self.showResourceInjector = true
        elseif key == "i" then
            self.showInventoryModal = true
        elseif key == "a" then
            self.showAnalyticsModal = true
            self.analyticsTab = "heatmap"
        elseif key == "p" then
            self.showAllocationPolicyModal = true
        elseif key == "t" then
            self.showTestingToolsModal = true
        elseif key == "s" then
            self.showSaveLoadModal = true
        elseif key == "return" then
            -- Open detail modal for selected character
            if self.selectedCharacter then
                self.detailCharacter = self.selectedCharacter
                self.showCharacterDetailModal = true
                self.detailScrollOffset = 0
            end
        elseif key == "delete" or key == "backspace" then
            -- Remove selected character (with confirmation via simple check)
            if self.selectedCharacter then
                self:RemoveCharacter(self.selectedCharacter)
                self.selectedCharacter = nil
            end
        elseif key == "left" then
            self:NavigateCharacterSelection(-1, 0)
        elseif key == "right" then
            self:NavigateCharacterSelection(1, 0)
        elseif key == "up" then
            self:NavigateCharacterSelection(0, -1)
        elseif key == "down" then
            self:NavigateCharacterSelection(0, 1)
        end
    end
end

-- Check if any modal is currently open
function ConsumptionPrototype:IsAnyModalOpen()
    return self.showCharacterCreator or
           self.showResourceInjector or
           self.showInventoryModal or
           self.showHeatmapModal or
           self.showCharacterDetailModal or
           self.showAnalyticsModal or
           self.showAllocationPolicyModal or
           self.showTestingToolsModal or
           self.showSaveLoadModal or
           self.showHelpOverlay
end

-- Navigate character selection with arrow keys
function ConsumptionPrototype:NavigateCharacterSelection(dx, dy)
    if #self.characters == 0 then return end

    -- Calculate grid dimensions
    local centerW = love.graphics.getWidth() - self.leftPanelWidth - self.rightPanelWidth
    local cardSpacing = 120
    local maxCols = math.max(1, math.floor((centerW - 40) / cardSpacing))

    -- Find current selection index
    local currentIdx = 0
    if self.selectedCharacter then
        for i, char in ipairs(self.characters) do
            if char == self.selectedCharacter and not char.hasEmigrated then
                currentIdx = i
                break
            end
        end
    end

    -- Build list of non-emigrated characters
    local activeChars = {}
    for i, char in ipairs(self.characters) do
        if not char.hasEmigrated then
            table.insert(activeChars, {char = char, idx = i})
        end
    end

    if #activeChars == 0 then return end

    -- Find position in active list
    local activeIdx = 1
    for i, entry in ipairs(activeChars) do
        if entry.char == self.selectedCharacter then
            activeIdx = i
            break
        end
    end

    -- Calculate new position
    local col = (activeIdx - 1) % maxCols
    local row = math.floor((activeIdx - 1) / maxCols)

    col = col + dx
    row = row + dy

    -- Wrap or clamp
    local maxRows = math.ceil(#activeChars / maxCols)
    if col < 0 then col = maxCols - 1; row = row - 1 end
    if col >= maxCols then col = 0; row = row + 1 end
    if row < 0 then row = maxRows - 1 end
    if row >= maxRows then row = 0 end

    local newIdx = row * maxCols + col + 1
    if newIdx > #activeChars then newIdx = #activeChars end
    if newIdx < 1 then newIdx = 1 end

    self.selectedCharacter = activeChars[newIdx].char
end

-- Remove a character from the simulation
function ConsumptionPrototype:RemoveCharacter(character)
    for i, char in ipairs(self.characters) do
        if char == character then
            table.remove(self.characters, i)
            self:LogEvent("character", character.name .. " was removed from the town")
            self:UpdateCharacterPositions()
            break
        end
    end
end

-- Render the keyboard shortcuts help overlay
function ConsumptionPrototype:RenderHelpOverlay()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local w, h = 500, 520
    local x = (screenW - w) / 2
    local y = (screenH - h) / 2

    -- Semi-transparent backdrop
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    -- Border
    love.graphics.setColor(0.4, 0.5, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    -- Title
    love.graphics.setColor(0.9, 0.9, 0.5)
    love.graphics.print("KEYBOARD SHORTCUTS", x + 20, y + 15, 0, 1.2, 1.2)

    -- Close hint
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Press H or ESC to close", x + w - 160, y + 20, 0, 0.75, 0.75)

    local contentY = y + 50
    local col1X = x + 20
    local col2X = x + 260

    -- Define shortcuts
    local shortcuts = {
        {category = "SIMULATION CONTROL", items = {
            {"SPACE", "Pause / Resume"},
            {"1", "Speed 1x"},
            {"2", "Speed 2x"},
            {"3", "Speed 5x"},
            {"4", "Speed 10x"},
        }},
        {category = "NAVIGATION", items = {
            {"TAB", "Cycle views (Grid/Heatmap/Log)"},
            {"Arrow Keys", "Navigate character selection"},
            {"ENTER", "Open selected character details"},
            {"DELETE", "Remove selected character"},
            {"ESC", "Close modal / Exit"},
        }},
        {category = "OPEN PANELS", items = {
            {"C", "Character Creator"},
            {"R", "Resource Injector"},
            {"I", "Inventory"},
            {"A", "Analytics"},
            {"P", "Allocation Policy"},
            {"T", "Testing Tools"},
            {"S", "Save/Load"},
            {"H", "This Help"},
        }},
        {category = "QUICK ACTIONS", items = {
            {"F5", "Quick Save"},
            {"F9", "Quick Load"},
        }},
    }

    -- Render shortcuts in two columns
    local itemY = contentY
    local colItems = 0
    local currentX = col1X
    local maxItemsPerCol = 14

    for _, section in ipairs(shortcuts) do
        -- Check if we need to switch columns
        if colItems + #section.items + 1 > maxItemsPerCol and currentX == col1X then
            currentX = col2X
            itemY = contentY
            colItems = 0
        end

        -- Section header
        love.graphics.setColor(0.6, 0.8, 0.9)
        love.graphics.print(section.category, currentX, itemY, 0, 0.8, 0.8)
        itemY = itemY + 20
        colItems = colItems + 1

        -- Items
        for _, item in ipairs(section.items) do
            -- Key
            love.graphics.setColor(0.9, 0.8, 0.4)
            love.graphics.print(item[1], currentX + 10, itemY, 0, 0.75, 0.75)
            -- Description
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(item[2], currentX + 90, itemY, 0, 0.75, 0.75)
            itemY = itemY + 18
            colItems = colItems + 1
        end

        itemY = itemY + 8
    end

    -- Footer
    love.graphics.setColor(0.4, 0.4, 0.45)
    love.graphics.line(x + 20, y + h - 40, x + w - 20, y + h - 40)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Tip: Most shortcuts only work when no modal is open", x + 20, y + h - 30, 0, 0.7, 0.7)
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
    elseif self.showAnalyticsModal then
        -- Scroll analytics modal (heatmap tab)
        self.analyticsScrollOffset = (self.analyticsScrollOffset or 0) - scrollAmount
        self.analyticsScrollOffset = math.max(0, math.min(self.analyticsScrollOffset, self.analyticsScrollMax or 0))
    elseif self.showAllocationPolicyModal then
        -- Scroll allocation policy modal
        self.allocationPolicyScrollOffset = (self.allocationPolicyScrollOffset or 0) - scrollAmount
        self.allocationPolicyScrollOffset = math.max(0, math.min(self.allocationPolicyScrollOffset, self.allocationPolicyScrollMax or 0))
    elseif self.showTestingToolsModal then
        -- Scroll testing tools modal
        self.testingToolsScrollOffset = (self.testingToolsScrollOffset or 0) - scrollAmount
        self.testingToolsScrollOffset = math.max(0, math.min(self.testingToolsScrollOffset, self.testingToolsScrollMax or 0))
    elseif self.showSaveLoadModal then
        -- Scroll save/load modal
        self.saveLoadScrollOffset = (self.saveLoadScrollOffset or 0) - scrollAmount
        self.saveLoadScrollOffset = math.max(0, math.min(self.saveLoadScrollOffset, self.saveLoadScrollMax or 0))
    else
        -- Check if mouse is over center panel areas
        local centerX = self.leftPanelWidth
        local centerW = screenW - self.leftPanelWidth - self.rightPanelWidth
        local centerY = self.topBarHeight
        local centerH = screenH - self.topBarHeight
        local gridH = math.floor(centerH * 0.6)
        local logY = centerY + gridH
        local logH = centerH - gridH

        if mx >= centerX and mx <= centerX + centerW then
            if my >= centerY and my < logY then
                -- Scroll character grid
                self.characterGridScrollOffset = (self.characterGridScrollOffset or 0) - scrollAmount
                self.characterGridScrollOffset = math.max(0, math.min(self.characterGridScrollOffset, self.characterGridScrollMax or 0))
            elseif my >= logY and my <= logY + logH then
                -- Scroll event log
                self.eventLogScrollOffset = (self.eventLogScrollOffset or 0) - scrollAmount
                self.eventLogScrollOffset = math.max(0, math.min(self.eventLogScrollOffset, self.eventLogScrollMax or 0))
            end
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
        -- Account for scroll offset
        local gridY = self.topBarHeight
        local gridH = math.floor((love.graphics.getHeight() - self.topBarHeight) * 0.6)

        for _, character in ipairs(self.characters) do
            if not character.hasEmigrated then
                local cx = character.position.x
                local cy = character.position.y - (self.characterGridScrollOffset or 0)
                local cw, ch = 110, 90

                -- Only check if click is within grid area
                if y >= gridY and y <= gridY + gridH then
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
