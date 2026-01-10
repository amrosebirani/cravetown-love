-- CheatConsole.lua
-- Command parser and executor for cheat codes
-- Opens with backtick (`) key

local CheatConsole = {}

-- Parse input string into tokens
function CheatConsole:Tokenize(input)
    local tokens = {}
    for token in input:gmatch("%S+") do
        table.insert(tokens, token)
    end
    return tokens
end

-- Main entry point - parse and execute a command
function CheatConsole:ParseAndExecute(input, world)
    local tokens = self:Tokenize(input)

    if #tokens == 0 then
        return nil
    end

    local cmd = tokens[1]:lower()

    -- Command dispatch table
    if cmd == "add" then
        return self:HandleAdd(tokens, world)
    elseif cmd == "remove" then
        return self:HandleRemove(tokens, world)
    elseif cmd == "set" then
        return self:HandleSet(tokens, world)
    elseif cmd == "increase" then
        return self:HandleModifySatisfaction(tokens, world, 1)
    elseif cmd == "decrease" then
        return self:HandleModifySatisfaction(tokens, world, -1)
    elseif cmd == "max" then
        return self:HandleMaxSatisfaction(tokens, world)
    elseif cmd == "clear" then
        return self:HandleClear(tokens, world)
    elseif cmd == "fill" then
        return self:HandleFill(tokens, world)
    elseif cmd == "spawn" then
        return self:HandleSpawn(tokens, world)
    elseif cmd == "kill" or cmd == "remove_citizen" then
        return self:HandleKillCitizen(tokens, world)
    elseif cmd == "pause" then
        return self:HandlePause(world)
    elseif cmd == "resume" then
        return self:HandleResume(world)
    elseif cmd == "speed" then
        return self:HandleSpeed(tokens, world)
    elseif cmd == "advance" then
        return self:HandleAdvance(tokens, world)
    elseif cmd == "refresh" then
        return self:HandleRefresh(tokens, world)
    elseif cmd == "accept" then
        return self:HandleAcceptAll(tokens, world)
    elseif cmd == "list" then
        return self:HandleList(tokens, world)
    elseif cmd == "stats" then
        return self:HandleStats(world)
    elseif cmd == "help" then
        return self:HandleHelp()
    else
        return "Unknown command: " .. cmd .. " (type 'help' for commands)"
    end
end

-- =============================================================================
-- ADD COMMANDS
-- =============================================================================

function CheatConsole:HandleAdd(tokens, world)
    if #tokens < 2 then
        return "Usage: add <item> <amount> OR add gold <amount>"
    end

    local item = tokens[2]:lower()

    if item == "gold" then
        local amount = tonumber(tokens[3]) or 1000
        world.gold = (world.gold or 0) + amount
        return "Added " .. amount .. " gold (total: " .. world.gold .. ")"
    else
        -- Add commodity
        local amount = tonumber(tokens[3]) or 1
        if world.AddToInventory then
            world:AddToInventory(item, amount)
            local newTotal = world:GetInventoryCount(item) or amount
            return "Added " .. amount .. " " .. item .. " (total: " .. newTotal .. ")"
        else
            return "Error: Inventory system not available"
        end
    end
end

-- =============================================================================
-- REMOVE COMMANDS
-- =============================================================================

function CheatConsole:HandleRemove(tokens, world)
    if #tokens < 2 then
        return "Usage: remove <item> <amount>"
    end

    local item = tokens[2]:lower()
    local amount = tonumber(tokens[3]) or 1

    if world.RemoveFromInventory then
        local removed = world:RemoveFromInventory(item, amount)
        local remaining = world:GetInventoryCount(item) or 0
        return "Removed " .. removed .. " " .. item .. " (remaining: " .. remaining .. ")"
    else
        return "Error: Inventory system not available"
    end
end

-- =============================================================================
-- SET COMMANDS
-- =============================================================================

function CheatConsole:HandleSet(tokens, world)
    if #tokens < 3 then
        return "Usage: set satisfaction <class|all> <value> OR set gold <amount>"
    end

    local target = tokens[2]:lower()

    if target == "gold" then
        local amount = tonumber(tokens[3]) or 0
        world.gold = amount
        return "Set gold to " .. amount
    elseif target == "satisfaction" then
        return self:SetSatisfaction(tokens, world)
    else
        return "Unknown set target: " .. target
    end
end

function CheatConsole:SetSatisfaction(tokens, world)
    if #tokens < 4 then
        return "Usage: set satisfaction <class|all> <value>"
    end

    local classFilter = tokens[3]:lower()
    local value = tonumber(tokens[4])

    if not value then
        return "Invalid satisfaction value"
    end

    value = math.max(0, math.min(100, value))

    local count = 0
    local citizens = world.citizens or {}

    for _, citizen in ipairs(citizens) do
        local citizenClass = (citizen.emergentClass or citizen.class or "middle"):lower()
        -- Normalize class names
        if citizenClass == "working" or citizenClass == "poor" then
            citizenClass = "lower"
        end

        if classFilter == "all" or citizenClass == classFilter then
            -- Set satisfaction for all coarse dimensions
            if citizen.satisfaction then
                for key, _ in pairs(citizen.satisfaction) do
                    citizen.satisfaction[key] = value
                end
            end
            -- Also set fine satisfaction if available
            if citizen.satisfactionFine then
                for idx, _ in pairs(citizen.satisfactionFine) do
                    citizen.satisfactionFine[idx] = value
                end
            end
            count = count + 1
        end
    end

    if count == 0 then
        return "No citizens matched class: " .. classFilter
    end

    return "Set satisfaction to " .. value .. " for " .. count .. " " .. classFilter .. " class citizens"
end

-- =============================================================================
-- MODIFY SATISFACTION (INCREASE/DECREASE)
-- =============================================================================

function CheatConsole:HandleModifySatisfaction(tokens, world, direction)
    -- increase satisfaction lower 5
    -- decrease satisfaction elite 10
    if #tokens < 4 then
        return "Usage: increase/decrease satisfaction <class|all> <amount>"
    end

    local target = tokens[2]:lower()
    if target ~= "satisfaction" then
        return "Usage: increase/decrease satisfaction <class|all> <amount>"
    end

    local classFilter = tokens[3]:lower()
    local amount = tonumber(tokens[4]) or 5
    amount = amount * direction

    local count = 0
    local citizens = world.citizens or {}

    for _, citizen in ipairs(citizens) do
        local citizenClass = (citizen.emergentClass or citizen.class or "middle"):lower()
        if citizenClass == "working" or citizenClass == "poor" then
            citizenClass = "lower"
        end

        if classFilter == "all" or citizenClass == classFilter then
            if citizen.satisfaction then
                for key, val in pairs(citizen.satisfaction) do
                    citizen.satisfaction[key] = math.max(0, math.min(100, val + amount))
                end
            end
            if citizen.satisfactionFine then
                for idx, val in pairs(citizen.satisfactionFine) do
                    citizen.satisfactionFine[idx] = math.max(0, math.min(100, val + amount))
                end
            end
            count = count + 1
        end
    end

    if count == 0 then
        return "No citizens matched class: " .. classFilter
    end

    local verb = direction > 0 and "Increased" or "Decreased"
    return verb .. " satisfaction by " .. math.abs(amount) .. " for " .. count .. " " .. classFilter .. " class citizens"
end

-- =============================================================================
-- MAX SATISFACTION
-- =============================================================================

function CheatConsole:HandleMaxSatisfaction(tokens, world)
    local count = 0
    local citizens = world.citizens or {}

    for _, citizen in ipairs(citizens) do
        if citizen.satisfaction then
            for key, _ in pairs(citizen.satisfaction) do
                citizen.satisfaction[key] = 100
            end
        end
        if citizen.satisfactionFine then
            for idx, _ in pairs(citizen.satisfactionFine) do
                citizen.satisfactionFine[idx] = 100
            end
        end
        count = count + 1
    end

    return "Set all " .. count .. " citizens to 100% satisfaction"
end

-- =============================================================================
-- CLEAR INVENTORY
-- =============================================================================

function CheatConsole:HandleClear(tokens, world)
    if #tokens < 2 then
        return "Usage: clear inventory"
    end

    local target = tokens[2]:lower()

    if target == "inventory" then
        if world.inventory then
            local itemCount = 0
            for _ in pairs(world.inventory) do
                itemCount = itemCount + 1
            end
            world.inventory = {}
            return "Cleared inventory (" .. itemCount .. " item types removed)"
        else
            return "No inventory to clear"
        end
    else
        return "Unknown clear target: " .. target
    end
end

-- =============================================================================
-- FILL INVENTORY
-- =============================================================================

function CheatConsole:HandleFill(tokens, world)
    if #tokens < 2 then
        return "Usage: fill inventory [amount]"
    end

    local target = tokens[2]:lower()
    local amount = tonumber(tokens[3]) or 100

    if target == "inventory" then
        local commodities = world.commodities or {}
        local count = 0

        for id, _ in pairs(commodities) do
            if world.AddToInventory then
                world:AddToInventory(id, amount)
                count = count + 1
            end
        end

        return "Added " .. amount .. " of each commodity (" .. count .. " types)"
    else
        return "Unknown fill target: " .. target
    end
end

-- =============================================================================
-- SPAWN CITIZEN
-- =============================================================================

function CheatConsole:HandleSpawn(tokens, world)
    if #tokens < 2 then
        return "Usage: spawn citizen <class> OR spawn citizens <count>"
    end

    local target = tokens[2]:lower()

    if target == "citizen" then
        local class = tokens[3] and tokens[3]:lower() or "middle"
        -- Validate class
        local validClasses = {lower = true, middle = true, upper = true, elite = true, working = true, poor = true}
        if not validClasses[class] then
            return "Invalid class. Use: lower, middle, upper, elite"
        end

        -- Use world's citizen spawning if available
        if world.SpawnCitizen then
            local citizen = world:SpawnCitizen(class)
            if citizen then
                return "Spawned " .. (citizen.name or "citizen") .. " (" .. class .. " class)"
            else
                return "Failed to spawn citizen"
            end
        elseif world.citizenGenerator then
            local CharacterV3 = require("consumption.CharacterV3")
            local citizen = CharacterV3.Create(class)
            if citizen then
                citizen.name = world.citizenGenerator:GenerateName()
                table.insert(world.citizens, citizen)
                return "Spawned " .. citizen.name .. " (" .. class .. " class)"
            end
        else
            return "Citizen spawning not available"
        end
    elseif target == "citizens" then
        local count = tonumber(tokens[3]) or 5
        local spawned = 0

        local classes = {"lower", "middle", "upper", "elite"}
        for i = 1, count do
            local class = classes[math.random(1, #classes)]
            if world.SpawnCitizen then
                if world:SpawnCitizen(class) then
                    spawned = spawned + 1
                end
            end
        end

        return "Spawned " .. spawned .. " random citizens"
    else
        return "Usage: spawn citizen <class> OR spawn citizens <count>"
    end
end

-- =============================================================================
-- KILL CITIZEN
-- =============================================================================

function CheatConsole:HandleKillCitizen(tokens, world)
    if #tokens < 3 then
        return "Usage: kill citizen <name>"
    end

    -- Join remaining tokens as the name
    local name = table.concat(tokens, " ", 3)
    name = name:lower()

    local citizens = world.citizens or {}
    for i, citizen in ipairs(citizens) do
        if citizen.name and citizen.name:lower():find(name, 1, true) then
            local removedName = citizen.name
            table.remove(citizens, i)
            return "Removed citizen: " .. removedName
        end
    end

    return "No citizen found with name containing: " .. name
end

-- =============================================================================
-- TIME CONTROLS
-- =============================================================================

function CheatConsole:HandlePause(world)
    if world.timeSystem then
        world.timeSystem.mPaused = true
        return "Game paused"
    elseif world.isPaused ~= nil then
        world.isPaused = true
        return "Game paused"
    end
    return "Pause not available"
end

function CheatConsole:HandleResume(world)
    if world.timeSystem then
        world.timeSystem.mPaused = false
        return "Game resumed"
    elseif world.isPaused ~= nil then
        world.isPaused = false
        return "Game resumed"
    end
    return "Resume not available"
end

function CheatConsole:HandleSpeed(tokens, world)
    if #tokens < 2 then
        return "Usage: speed <1-4>"
    end

    local speed = tonumber(tokens[2])
    if not speed or speed < 1 or speed > 4 then
        return "Speed must be between 1 and 4"
    end

    if world.timeSystem then
        world.timeSystem.mSpeedLevel = speed
        return "Set game speed to " .. speed
    end

    return "Time system not available"
end

function CheatConsole:HandleAdvance(tokens, world)
    if #tokens < 2 then
        return "Usage: advance <days>"
    end

    local days = tonumber(tokens[2]) or 1

    if world.timeSystem then
        local ticksPerDay = 24 * 60  -- Assuming 1 tick per minute
        world.timeSystem.mTotalTicks = (world.timeSystem.mTotalTicks or 0) + (days * ticksPerDay)
        world.timeSystem.mDay = (world.timeSystem.mDay or 1) + days
        return "Advanced " .. days .. " day(s)"
    end

    return "Time system not available"
end

-- =============================================================================
-- IMMIGRATION CONTROLS
-- =============================================================================

function CheatConsole:HandleRefresh(tokens, world)
    if #tokens < 2 then
        return "Usage: refresh immigrants"
    end

    local target = tokens[2]:lower()

    if target == "immigrants" then
        if world.immigrationSystem and world.immigrationSystem.RegenerateQueue then
            local count = world.immigrationSystem:RegenerateQueue()
            return "Refreshed immigration queue (" .. count .. " new applicants)"
        else
            return "Immigration system not available"
        end
    end

    return "Unknown refresh target: " .. target
end

function CheatConsole:HandleAcceptAll(tokens, world)
    if #tokens < 2 then
        return "Usage: accept all"
    end

    local target = tokens[2]:lower()

    if target == "all" then
        if world.immigrationSystem and world.immigrationSystem.queue then
            local count = #world.immigrationSystem.queue
            for _, applicant in ipairs(world.immigrationSystem.queue) do
                if world.immigrationSystem.AcceptApplicant then
                    world.immigrationSystem:AcceptApplicant(applicant)
                end
            end
            world.immigrationSystem.queue = {}
            return "Accepted " .. count .. " immigrants"
        else
            return "Immigration system not available"
        end
    end

    return "Usage: accept all"
end

-- =============================================================================
-- LIST COMMANDS
-- =============================================================================

function CheatConsole:HandleList(tokens, world)
    if #tokens < 2 then
        return "Usage: list commodities"
    end

    local target = tokens[2]:lower()

    if target == "commodities" then
        local commodities = world.commodities or {}
        local ids = {}
        for id, _ in pairs(commodities) do
            table.insert(ids, id)
        end
        table.sort(ids)

        if #ids == 0 then
            return "No commodities loaded"
        end

        -- Return first 20 commodities to avoid flooding
        local display = {}
        for i = 1, math.min(20, #ids) do
            table.insert(display, ids[i])
        end

        local result = "Commodities (" .. #ids .. " total): " .. table.concat(display, ", ")
        if #ids > 20 then
            result = result .. " ..."
        end
        return result
    end

    return "Unknown list target: " .. target
end

-- =============================================================================
-- STATS COMMAND
-- =============================================================================

function CheatConsole:HandleStats(world)
    local stats = {}

    -- Gold
    table.insert(stats, "Gold: " .. (world.gold or 0))

    -- Citizens
    local citizens = world.citizens or {}
    local classCounts = {lower = 0, middle = 0, upper = 0, elite = 0}
    local totalSat = 0

    for _, citizen in ipairs(citizens) do
        local class = (citizen.emergentClass or citizen.class or "middle"):lower()
        if class == "working" or class == "poor" then class = "lower" end
        classCounts[class] = (classCounts[class] or 0) + 1

        if citizen.GetAverageSatisfaction then
            totalSat = totalSat + citizen:GetAverageSatisfaction()
        elseif citizen.satisfaction then
            local sum, count = 0, 0
            for _, v in pairs(citizen.satisfaction) do
                sum = sum + v
                count = count + 1
            end
            totalSat = totalSat + (count > 0 and sum / count or 50)
        end
    end

    table.insert(stats, "Citizens: " .. #citizens)
    table.insert(stats, "  Lower: " .. classCounts.lower .. ", Middle: " .. classCounts.middle)
    table.insert(stats, "  Upper: " .. classCounts.upper .. ", Elite: " .. classCounts.elite)

    local avgSat = #citizens > 0 and (totalSat / #citizens) or 0
    table.insert(stats, "Avg Satisfaction: " .. string.format("%.1f", avgSat) .. "%")

    -- Buildings
    local buildings = world.buildings or {}
    table.insert(stats, "Buildings: " .. #buildings)

    -- Inventory items
    local invCount = 0
    local invItems = 0
    for _, qty in pairs(world.inventory or {}) do
        if qty > 0 then
            invItems = invItems + 1
            invCount = invCount + qty
        end
    end
    table.insert(stats, "Inventory: " .. invItems .. " types, " .. invCount .. " items")

    return table.concat(stats, "\n")
end

-- =============================================================================
-- HELP COMMAND
-- =============================================================================

function CheatConsole:HandleHelp()
    local help = {
        "=== Cheat Console Commands ===",
        "",
        "SATISFACTION:",
        "  set satisfaction <class|all> <value>",
        "  increase satisfaction <class> <amount>",
        "  decrease satisfaction <class> <amount>",
        "  max satisfaction",
        "",
        "INVENTORY:",
        "  add <item> <amount>",
        "  remove <item> <amount>",
        "  clear inventory",
        "  fill inventory [amount]",
        "",
        "GOLD:",
        "  add gold <amount>",
        "  set gold <amount>",
        "",
        "CITIZENS:",
        "  spawn citizen <class>",
        "  spawn citizens <count>",
        "  kill citizen <name>",
        "",
        "TIME:",
        "  pause / resume",
        "  speed <1-4>",
        "  advance <days>",
        "",
        "IMMIGRATION:",
        "  refresh immigrants",
        "  accept all",
        "",
        "DEBUG:",
        "  list commodities",
        "  stats",
        "  help",
        "",
        "Classes: lower, middle, upper, elite",
        "Press ` to close console"
    }
    return table.concat(help, "\n")
end

return CheatConsole
