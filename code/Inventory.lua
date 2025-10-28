--
-- Inventory - manages commodity storage for the town
--

require("code/CommodityTypes")

Inventory = {}
Inventory.__index = Inventory

function Inventory:Create()
    local this = {
        mStorage = {},  -- [commodityId] = quantity
        mCapacity = {},  -- [commodityId] = max capacity (optional)
        mUnlimited = true  -- Town has unlimited storage by default
    }

    -- Initialize all commodities to 0
    local allCommodities = CommodityTypes.getAllCommodities()
    for _, commodity in ipairs(allCommodities) do
        this.mStorage[commodity.id] = 0
        this.mCapacity[commodity.id] = commodity.stackSize * 10  -- Default capacity
    end

    setmetatable(this, self)
    return this
end

function Inventory:Add(commodityId, amount)
    if not self.mStorage[commodityId] then
        self.mStorage[commodityId] = 0
    end

    if self.mUnlimited then
        self.mStorage[commodityId] = self.mStorage[commodityId] + amount
        return amount
    else
        local capacity = self.mCapacity[commodityId] or math.huge
        local available = capacity - self.mStorage[commodityId]
        local added = math.min(amount, available)
        self.mStorage[commodityId] = self.mStorage[commodityId] + added
        return added
    end
end

function Inventory:Remove(commodityId, amount)
    if not self.mStorage[commodityId] then
        return 0
    end

    local available = self.mStorage[commodityId]
    local removed = math.min(amount, available)
    self.mStorage[commodityId] = self.mStorage[commodityId] - removed
    return removed
end

function Inventory:Get(commodityId)
    return self.mStorage[commodityId] or 0
end

function Inventory:Set(commodityId, amount)
    self.mStorage[commodityId] = amount
end

function Inventory:Has(commodityId, amount)
    return self:Get(commodityId) >= amount
end

function Inventory:GetAll()
    return self.mStorage
end

function Inventory:GetNonZero()
    local nonZero = {}
    for commodityId, quantity in pairs(self.mStorage) do
        if quantity > 0 then
            nonZero[commodityId] = quantity
        end
    end
    return nonZero
end

function Inventory:SetCapacity(commodityId, capacity)
    self.mCapacity[commodityId] = capacity
end

function Inventory:GetCapacity(commodityId)
    return self.mCapacity[commodityId] or math.huge
end

function Inventory:Clear()
    for commodityId, _ in pairs(self.mStorage) do
        self.mStorage[commodityId] = 0
    end
end

return Inventory
