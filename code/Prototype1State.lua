--
-- Prototype1State - Consumption Engine prototype
-- Character behavior, craving systems, resource allocation
--

Prototype1State = {}
Prototype1State.__index = Prototype1State

local ConsumptionPrototype = require("code.ConsumptionPrototype")

function Prototype1State:Create()
    local this = {
        prototype = nil
    }
    setmetatable(this, self)
    return this
end

function Prototype1State:Enter(params)
    print("Entering Prototype 1: Consumption Engine")
    self.prototype = ConsumptionPrototype:Create()
end

function Prototype1State:Exit()
    self.prototype = nil
end

function Prototype1State:Update(dt)
    if self.prototype then
        self.prototype:Update(dt)
    end
end

function Prototype1State:Render()
    if self.prototype then
        self.prototype:Render()
    end
end

function Prototype1State:keypressed(key)
    if self.prototype then
        self.prototype:KeyPressed(key)
        return key == "escape"  -- Signal that we handled escape
    end
    return false
end

function Prototype1State:OnMouseWheel(dx, dy)
    -- Future: Handle mouse wheel for scrolling
end

function Prototype1State:textinput(t)
    if self.prototype then
        self.prototype:TextInput(t)
    end
end

return Prototype1State
