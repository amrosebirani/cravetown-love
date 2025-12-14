-- ConsumptionPrototypeState.lua
-- State wrapper for ConsumptionPrototype (Phase 6: Interactive UI)

local ConsumptionPrototype = require("code.ConsumptionPrototype")

local ConsumptionPrototypeState = {}

function ConsumptionPrototypeState:enter()
    print("\n=== Consumption Prototype (Phase 5 Complete System) ===\n")

    -- Create the consumption prototype
    self.prototype = ConsumptionPrototype:Create()

    print("Consumption Prototype ready!")
    print("Controls:")
    print("  - Click 'Add Character' to create characters")
    print("  - Click 'Inject Resource' to add commodities")
    print("  - Press SPACE to start/pause simulation")
    print("  - ESC to return to launcher")
    print("")
end

function ConsumptionPrototypeState:update(dt)
    if self.prototype then
        self.prototype:Update(dt)
    end
end

function ConsumptionPrototypeState:draw()
    if self.prototype then
        self.prototype:Render()
    end
end

function ConsumptionPrototypeState:keypressed(key)
    if self.prototype and self.prototype.KeyPressed then
        return self.prototype:KeyPressed(key)
    end
    return false
end

-- Alias for capital K version (main.lua uses this)
function ConsumptionPrototypeState:KeyPressed(key)
    return self:keypressed(key)
end

return ConsumptionPrototypeState
