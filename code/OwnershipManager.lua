--
-- OwnershipManager.lua
-- Tracks building and land ownership, handles rent and profit distribution
--

local DataLoader = require("code.DataLoader")

local OwnershipManager = {}
OwnershipManager.__index = OwnershipManager

-- Asset types
local ASSET_TYPES = {
    BUILDING = "building",
    LAND = "land"
}

-- Special owner IDs
local TOWN_OWNER_ID = "TOWN"

function OwnershipManager:Create(landSystem, buildingManager)
    local manager = setmetatable({}, OwnershipManager)

    manager.landSystem = landSystem
    manager.buildingManager = buildingManager

    -- Building ownership: buildingId -> { ownerId, purchasePrice, purchasedCycle }
    manager.buildingOwnership = {}

    -- Quick lookup: ownerId -> { buildingIds }
    manager.buildingsByOwner = {}
    manager.buildingsByOwner[TOWN_OWNER_ID] = {}

    -- Rent tracking: buildingId -> { tenantId, landOwnerId, rentAmount, lastPaidCycle }
    manager.rentAgreements = {}

    -- Transaction history for auditing
    manager.transactionHistory = {}
    manager.maxHistorySize = 100

    print("[OwnershipManager] Created")

    return manager
end

-- ============================================================================
-- Building Ownership
-- ============================================================================

function OwnershipManager:RegisterBuilding(buildingId, ownerId, purchasePrice, currentCycle)
    ownerId = ownerId or TOWN_OWNER_ID

    self.buildingOwnership[buildingId] = {
        ownerId = ownerId,
        purchasePrice = purchasePrice or 0,
        purchasedCycle = currentCycle
    }

    -- Add to owner's building list
    if not self.buildingsByOwner[ownerId] then
        self.buildingsByOwner[ownerId] = {}
    end
    table.insert(self.buildingsByOwner[ownerId], buildingId)

    print(string.format("[OwnershipManager] Registered building %s owned by %s", buildingId, ownerId))
end

function OwnershipManager:GetBuildingOwner(buildingId)
    local ownership = self.buildingOwnership[buildingId]
    if ownership then
        return ownership.ownerId
    end
    return nil
end

function OwnershipManager:GetBuildingsOwnedBy(ownerId)
    return self.buildingsByOwner[ownerId] or {}
end

function OwnershipManager:TransferBuilding(buildingId, newOwnerId, price, currentCycle)
    local ownership = self.buildingOwnership[buildingId]
    if not ownership then
        return false, "Building not registered"
    end

    local oldOwnerId = ownership.ownerId

    -- Remove from old owner's list
    if self.buildingsByOwner[oldOwnerId] then
        for i, bid in ipairs(self.buildingsByOwner[oldOwnerId]) do
            if bid == buildingId then
                table.remove(self.buildingsByOwner[oldOwnerId], i)
                break
            end
        end
    end

    -- Add to new owner's list
    if not self.buildingsByOwner[newOwnerId] then
        self.buildingsByOwner[newOwnerId] = {}
    end
    table.insert(self.buildingsByOwner[newOwnerId], buildingId)

    -- Update ownership record
    ownership.ownerId = newOwnerId
    ownership.purchasePrice = price or ownership.purchasePrice
    ownership.purchasedCycle = currentCycle

    -- Record transaction
    self:RecordTransaction({
        type = "building_transfer",
        assetId = buildingId,
        from = oldOwnerId,
        to = newOwnerId,
        price = price or 0,
        cycle = currentCycle
    })

    print(string.format("[OwnershipManager] Transferred building %s from %s to %s for %d",
        buildingId, oldOwnerId, newOwnerId, price or 0))

    return true, oldOwnerId
end

-- ============================================================================
-- Asset Value Calculation
-- ============================================================================

function OwnershipManager:GetAssetValue(assetType, assetId)
    if assetType == ASSET_TYPES.BUILDING then
        return self:GetBuildingValue(assetId)
    elseif assetType == ASSET_TYPES.LAND then
        return self:GetLandValue(assetId)
    end
    return 0
end

function OwnershipManager:GetBuildingValue(buildingId)
    local ownership = self.buildingOwnership[buildingId]
    if not ownership then
        return 0
    end

    -- Base value is purchase price
    local value = ownership.purchasePrice or 0

    -- Could add appreciation/depreciation logic here
    -- For now, buildings retain their purchase value

    return value
end

function OwnershipManager:GetLandValue(plotId)
    if not self.landSystem then
        return 0
    end

    local plot = self.landSystem:GetPlotById(plotId)
    if plot then
        return self.landSystem:CalculatePlotPrice(plot)
    end

    return 0
end

function OwnershipManager:GetTotalAssetValue(ownerId)
    local totalValue = 0

    -- Sum building values
    local buildings = self:GetBuildingsOwnedBy(ownerId)
    for _, buildingId in ipairs(buildings) do
        totalValue = totalValue + self:GetBuildingValue(buildingId)
    end

    -- Sum land values
    if self.landSystem then
        local plots = self.landSystem:GetPlotsOwnedBy(ownerId)
        for _, plot in ipairs(plots) do
            totalValue = totalValue + self.landSystem:CalculatePlotPrice(plot)
        end
    end

    return totalValue
end

-- ============================================================================
-- Rent System
-- ============================================================================

function OwnershipManager:CreateRentAgreement(buildingId, tenantId, landOwnerId, rentAmount, currentCycle)
    self.rentAgreements[buildingId] = {
        tenantId = tenantId,
        landOwnerId = landOwnerId,
        rentAmount = rentAmount,
        lastPaidCycle = currentCycle,
        createdCycle = currentCycle
    }

    print(string.format("[OwnershipManager] Rent agreement: %s pays %d to %s for building %s",
        tenantId, rentAmount, landOwnerId, buildingId))
end

function OwnershipManager:GetRentAgreement(buildingId)
    return self.rentAgreements[buildingId]
end

function OwnershipManager:GetRentsDueBy(tenantId)
    local rents = {}
    for buildingId, agreement in pairs(self.rentAgreements) do
        if agreement.tenantId == tenantId then
            table.insert(rents, {
                buildingId = buildingId,
                landOwnerId = agreement.landOwnerId,
                rentAmount = agreement.rentAmount,
                lastPaidCycle = agreement.lastPaidCycle
            })
        end
    end
    return rents
end

function OwnershipManager:GetRentsOwedTo(landOwnerId)
    local rents = {}
    for buildingId, agreement in pairs(self.rentAgreements) do
        if agreement.landOwnerId == landOwnerId then
            table.insert(rents, {
                buildingId = buildingId,
                tenantId = agreement.tenantId,
                rentAmount = agreement.rentAmount,
                lastPaidCycle = agreement.lastPaidCycle
            })
        end
    end
    return rents
end

function OwnershipManager:ProcessRentPayment(buildingId, currentCycle)
    local agreement = self.rentAgreements[buildingId]
    if not agreement then
        return false, "No rent agreement found"
    end

    -- Check if rent is due (assuming rent is due every cycle)
    if agreement.lastPaidCycle >= currentCycle then
        return false, "Rent already paid this cycle"
    end

    agreement.lastPaidCycle = currentCycle

    -- Record transaction
    self:RecordTransaction({
        type = "rent_payment",
        buildingId = buildingId,
        from = agreement.tenantId,
        to = agreement.landOwnerId,
        amount = agreement.rentAmount,
        cycle = currentCycle
    })

    return true, agreement.rentAmount
end

function OwnershipManager:TerminateRentAgreement(buildingId)
    local agreement = self.rentAgreements[buildingId]
    if agreement then
        print(string.format("[OwnershipManager] Terminated rent agreement for building %s", buildingId))
        self.rentAgreements[buildingId] = nil
        return true
    end
    return false
end

-- ============================================================================
-- Profit Distribution (for businesses with workers)
-- ============================================================================

function OwnershipManager:CalculateProfitShare(buildingId, totalProfit, workerContributions)
    -- Default profit distribution: owner gets base share, workers split remainder
    local profitConfig = {
        ownerBaseShare = 0.4,  -- Owner gets 40% minimum
        workerSharePool = 0.6  -- Workers split 60%
    }

    local distribution = {
        ownerShare = 0,
        workerShares = {}
    }

    if totalProfit <= 0 then
        return distribution
    end

    -- Owner's base share
    distribution.ownerShare = totalProfit * profitConfig.ownerBaseShare

    -- Calculate total worker contribution
    local totalContribution = 0
    for _, contribution in pairs(workerContributions or {}) do
        totalContribution = totalContribution + contribution
    end

    -- Distribute worker pool based on contribution
    if totalContribution > 0 then
        local workerPool = totalProfit * profitConfig.workerSharePool
        for workerId, contribution in pairs(workerContributions) do
            local share = (contribution / totalContribution) * workerPool
            distribution.workerShares[workerId] = share
        end
    else
        -- No workers, owner gets everything
        distribution.ownerShare = totalProfit
    end

    return distribution
end

-- ============================================================================
-- Transaction History
-- ============================================================================

function OwnershipManager:RecordTransaction(transaction)
    table.insert(self.transactionHistory, transaction)

    -- Trim history if too large
    while #self.transactionHistory > self.maxHistorySize do
        table.remove(self.transactionHistory, 1)
    end
end

function OwnershipManager:GetTransactionHistory(filter)
    if not filter then
        return self.transactionHistory
    end

    local filtered = {}
    for _, transaction in ipairs(self.transactionHistory) do
        local match = true
        if filter.type and transaction.type ~= filter.type then
            match = false
        end
        if filter.ownerId and transaction.from ~= filter.ownerId and transaction.to ~= filter.ownerId then
            match = false
        end
        if filter.minCycle and transaction.cycle < filter.minCycle then
            match = false
        end
        if match then
            table.insert(filtered, transaction)
        end
    end
    return filtered
end

-- ============================================================================
-- Generic Asset Transfer
-- ============================================================================

function OwnershipManager:TransferAsset(assetType, assetId, fromOwnerId, toOwnerId, price, currentCycle)
    if assetType == ASSET_TYPES.BUILDING then
        return self:TransferBuilding(assetId, toOwnerId, price, currentCycle)
    elseif assetType == ASSET_TYPES.LAND then
        if self.landSystem then
            return self.landSystem:TransferOwnership(assetId, toOwnerId, price, currentCycle)
        end
        return false, "Land system not available"
    end
    return false, "Unknown asset type"
end

-- ============================================================================
-- Serialization
-- ============================================================================

function OwnershipManager:Serialize()
    return {
        buildingOwnership = self.buildingOwnership,
        rentAgreements = self.rentAgreements,
        transactionHistory = self.transactionHistory
    }
end

function OwnershipManager:Deserialize(data)
    if not data then return end

    self.buildingOwnership = data.buildingOwnership or {}
    self.rentAgreements = data.rentAgreements or {}
    self.transactionHistory = data.transactionHistory or {}

    -- Rebuild buildingsByOwner lookup
    self.buildingsByOwner = {}
    self.buildingsByOwner[TOWN_OWNER_ID] = {}

    for buildingId, ownership in pairs(self.buildingOwnership) do
        local ownerId = ownership.ownerId
        if not self.buildingsByOwner[ownerId] then
            self.buildingsByOwner[ownerId] = {}
        end
        table.insert(self.buildingsByOwner[ownerId], buildingId)
    end

    print("[OwnershipManager] Deserialized ownership data")
end

-- ============================================================================
-- Constants
-- ============================================================================

OwnershipManager.ASSET_TYPES = ASSET_TYPES
OwnershipManager.TOWN_OWNER_ID = TOWN_OWNER_ID

return OwnershipManager
