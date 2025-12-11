# Ownership, Land & Housing System - Implementation TODO

This document tracks implementation tasks for the economic/ownership system and housing system.

**Reference Documents:**
- `/docs/economic-system-design.md` - Economic system, land plots, emergent class
- `/docs/housing-system-design.md` - Housing types, assignment, fulfillment vectors

---

## Design Decisions Summary

### Key Rules
1. **All plots initially owned by TOWN** - Town receives money when elites buy land
2. **Craftsmen/laborers don't need to buy land** - Only wealthy/merchants must purchase
3. **Town can build on town-owned plots** - No restriction for town buildings
4. **Class calculated every 20 cycles** - Not every cycle (performance)
5. **Elites get auto-residence** - When elite immigrates, auto-place house on one of their plots
6. **Elite plots get suggested buildings** - Show relevant building options for remaining plots

### Relationship Types (Updated)
- spouse, parent, child, sibling
- employer, employee
- landlord, tenant
- business_partner
- friend, rival
- **colleague** (works at same building)
- **neighbour** (lives on adjacent plot)

---

## Phase 1: Data Foundation

### 1.1 New JSON Config Files
- [ ] Create `data/alpha/land_config.json`
  - Grid dimensions (plotWidth: 100, plotHeight: 100)
  - Base plot price and multipliers
  - Immigration land requirements by role
  - Overlay colors
- [ ] Create `data/alpha/class_thresholds.json`
  - Net worth thresholds for elite/upper/middle/lower
  - Capital ratio thresholds
  - Skill income thresholds
- [ ] Create `data/alpha/economic_systems.json`
  - Capitalist system config
  - Collectivist system config
  - Feudal system config
  - Default system selection

### 1.2 Modify Existing JSON Files
- [ ] Update `starting_locations.json`
  - Replace `classId` with `startingWealth` + `intendedRole`
  - `intendedRole`: 'wealthy' | 'merchant' | 'craftsman' | 'laborer'
- [ ] Rename `character_classes.json` → `class_behavior_templates.json`
  - Keep as behavior templates (craving modifiers, quality prefs)
  - Remove concept of "assigned class"
- [ ] Update `immigration_config.json`
  - Use `intendedRole` instead of class names
  - Add land requirements per role

### 1.3 Housing Data Files
- [ ] Add housing building types to `building_types.json`
  - Lodge (quality 0.3, capacity 12)
  - Tenement (quality 0.4, capacity 20)
  - Cottage (quality 0.5, capacity 6)
  - House (quality 0.6, capacity 8)
  - Apartment Block (quality 0.55, capacity 30)
  - Townhouse (quality 0.7, capacity 6)
  - Manor (quality 0.85, capacity 10)
  - Estate (quality 1.0, capacity 12)
- [ ] Add housing dimensions to `dimension_definitions.json`
  - `safety_shelter_housing_basic` (index 50, always enabled)
  - `safety_shelter_housing_good` (index 51, middle+)
  - `safety_shelter_housing_luxury` (index 52, upper+)
  - `safety_shelter_housing_prestige` (index 53, elite only)
- [ ] Add building fulfillment vectors to `fulfillment_vectors.json`
  - Add `buildings` section alongside `commodities`
  - Include all 8 housing types with vectors

---

## Phase 2: Core Lua Systems

### 2.1 Land System (NEW)
- [ ] Create `code/LandSystem.lua`
  - `LandSystem:Create(config)` - Initialize grid
  - `LandSystem:GetPlot(gridX, gridY)` - Get plot by grid coords
  - `LandSystem:GetPlotAtWorld(worldX, worldY)` - Get plot by world coords
  - `LandSystem:GetPlotOwner(plotId)` - Get owner ID
  - `LandSystem:TransferOwnership(plotId, newOwnerId, price)` - Handle sales
  - `LandSystem:CalculatePlotPrice(plot)` - Dynamic pricing
  - `LandSystem:GetPlotsOwnedBy(ownerId)` - List all plots for owner
  - `LandSystem:GetAvailablePlots()` - Unclaimed/town-owned plots
  - `LandSystem:GetTownOwnedPlots()` - Plots owned by town
  - `LandSystem:Render(overlay)` - Draw grid overlay
  - Initialize all plots as town-owned

### 2.2 Ownership Manager (NEW)
- [ ] Create `code/OwnershipManager.lua`
  - Track building ownership
  - Track land ownership (reference to LandSystem)
  - Handle rent collection (building on others' land)
  - Handle profit distribution
  - `OwnershipManager:GetAssetValue(assetType, assetId)`
  - `OwnershipManager:TransferAsset(assetType, assetId, from, to, price)`

### 2.3 Economics System (NEW)
- [ ] Create `code/EconomicsSystem.lua`
  - Per-character income tracking
  - Per-character expense tracking
  - Net worth calculation
  - Capital ratio calculation
  - `EconomicsSystem:UpdateCharacterEconomics(character, cycle)`
  - `EconomicsSystem:CollectRents(cycle)` - Process all rent payments
  - `EconomicsSystem:DistributeProfits(cycle)` - Building profit sharing

### 2.4 Housing System (NEW)
- [ ] Create `code/HousingSystem.lua`
  - `HousingSystem:GetAvailableHousing(emergentClass)`
  - `HousingSystem:AssignHousing(characterId, buildingId)`
  - `HousingSystem:EvictResident(characterId)`
  - `HousingSystem:GetHousingForCharacter(characterId)`
  - `HousingSystem:CalculateHousingSatisfaction(character)`
  - `HousingSystem:ProcessRelocationQueue()`
  - Track occupancy per building
  - Handle mixed occupancy (families + singles)

### 2.5 Update DataLoader.lua
- [ ] Add `loadLandConfig()`
- [ ] Add `loadClassThresholds()`
- [ ] Add `loadEconomicSystem()`
- [ ] Rename `loadCharacterClasses()` → `loadClassBehaviorTemplates()`
- [ ] Add `loadHousingFulfillmentVectors()`

---

## Phase 3: Character Model Updates

### 3.1 CharacterV3.lua Changes
- [ ] **REMOVE**: `char.class = class or "Middle"` (fixed assignment)
- [ ] **ADD**: `char.economics` table
  ```lua
  economics = {
    goldBalance = startingWealth,
    ownedAssets = {},      -- {type, assetId, percentage}
    laborIncome = 0,
    capitalIncome = 0,
    expenses = 0,
    netWorth = 0,
    capitalRatio = 0,
  }
  ```
- [ ] **ADD**: `char.relationships = {}`
  - Include: spouse, parent, child, sibling, employer, employee, landlord, tenant, colleague, neighbour
- [ ] **ADD**: `char.householdId = nil`
- [ ] **ADD**: `char.housingId = nil` (which building they live in)
- [ ] **ADD**: `char.employment` table
  ```lua
  employment = {
    employerId = nil,
    workplaceId = nil,
    wageRate = 0,
  }
  ```
- [ ] **ADD**: `char.emergentClass = nil` (calculated, not assigned)
- [ ] **ADD**: `char.lastClassCalculation = 0` (cycle number)

### 3.2 New Character Methods
- [ ] `CharacterV3:CalculateEmergentClass()`
  - Use class_thresholds.json
  - Based on netWorth + capitalRatio
  - Return 'elite', 'upper', 'middle', 'lower'
- [ ] `CharacterV3:UpdateEconomics(currentCycle)`
  - Calculate labor income from employment
  - Calculate capital income from owned assets
  - Calculate expenses (rent, consumption)
  - Update net worth
  - Update capital ratio
  - Every 20 cycles: recalculate emergent class
- [ ] `CharacterV3:OnClassChange(oldClass, newClass)`
  - Update craving vector based on new class template
  - Trigger housing preference change
  - Update social connections
- [ ] `CharacterV3:AddRelationship(targetId, type, metadata)`
- [ ] `CharacterV3:GetRelationship(targetId, type)`
- [ ] `CharacterV3:GetNeighbours()` - Based on housing location

---

## Phase 4: Immigration & Citizen Creation

### 4.1 Update AlphaWorld.lua
- [ ] Update citizen spawning to use `startingWealth` + `intendedRole`
- [ ] Remove class-based spawning logic
- [ ] Calculate initial emergent class from starting wealth
- [ ] **Elite immigration flow**:
  1. Check if enough town-owned plots available
  2. Open plot selection modal (separate from immigration modal)
  3. Transfer gold to town treasury
  4. Transfer plot ownership
  5. Auto-place appropriate house on one plot
  6. Mark house as residence
  7. Suggest buildings for remaining plots

### 4.2 Immigration Land Requirements
- [ ] **Wealthy**: Must buy 4+ plots
- [ ] **Merchant**: Must buy 2+ plots
- [ ] **Craftsman**: No land required (can rent)
- [ ] **Laborer**: No land required (will rent housing)

### 4.3 Plot Selection Modal (NEW)
- [ ] Create plot picker as separate modal from immigration
- [ ] Show grid with available (town-owned) plots
- [ ] Allow multi-select for wealthy/merchant immigrants
- [ ] Show plot prices, terrain, location bonuses
- [ ] Calculate total cost
- [ ] Confirm purchase transfers to town

### 4.4 Elite Auto-Setup
- [ ] When elite finishes land purchase:
  - Auto-place Manor or Estate on first plot
  - Mark as their residence
  - Show "Suggested Buildings" for remaining plots
- [ ] Elite building suggestions:
  - Workshop (income generation)
  - Market stall (trade income)
  - Warehouse (storage)
  - Additional housing (rent income)

---

## Phase 5: Allocation & Priority Updates

### 5.1 AllocationEngineV2.lua Changes
- [ ] Remove fixed class-based priority weights
- [ ] Priority based on:
  - Desperation score (unfulfilled cravings)
  - Fairness penalty (recent allocation success)
  - NOT emergent class
- [ ] Keep class-based quality acceptance (from behavior templates)

### 5.2 Consumption Mechanics Updates
- [ ] Class decay rates still apply (use emergent class)
- [ ] Class modifiers in craving slots still apply (use emergent class)

---

## Phase 6: Housing Implementation

### 6.1 Housing Assignment Logic
- [ ] Immigration gated by housing availability
- [ ] Family assignment rules (can't split)
- [ ] Singles can share (roommates)
- [ ] Mixed occupancy allowed
- [ ] Crowding effects on satisfaction

### 6.2 Rent System
- [ ] Housing rent paid to building owner
- [ ] Land rent paid to land owner (if different)
- [ ] Affordability checks
- [ ] Eviction after non-payment

### 6.3 Housing Satisfaction
- [ ] Apply building fulfillment vectors each cycle
- [ ] Check enabled dimensions per emergent class
- [ ] Apply quality multipliers
- [ ] Apply crowding modifiers

### 6.4 Relocation System
- [ ] Track citizens wanting better housing
- [ ] Queue-based relocation processing
- [ ] Class change triggers relocation desire

---

## Phase 7: UI Updates - Info System

### 7.1 Type Definition Updates (types.ts)
- [ ] Rename `CharacterClass` → `ClassBehaviorTemplate`
- [ ] Add `EmergentClassThresholds` interface
- [ ] Add `LandPlot` interface
- [ ] Add `LandGridConfig` interface
- [ ] Add `HousingConfig` interface
- [ ] Update `StarterCitizen`:
  - Remove `classId`
  - Add `startingWealth: number`
  - Add `intendedRole: 'wealthy' | 'merchant' | 'craftsman' | 'laborer'`
  - Add `housingBuildingIndex?: number` (index into starterBuildings)
- [ ] Add `Relationship` interface with colleague/neighbour
- [ ] Update `StarterBuilding`:
  - Add `ownerCitizenIndex?: number` (null = town-owned)
  - Add `initialOccupants?: number[]` (citizen indices for housing)
  - Add `rentRate?: number` (override default)
- [ ] Add `StarterLandPlot` interface:
  ```typescript
  interface StarterLandPlot {
    gridX: number;
    gridY: number;
    ownerCitizenIndex?: number;  // null = town-owned
  }
  ```
- [ ] Update `StartingLocation`:
  - Add `starterLandPlots?: StarterLandPlot[]`
  - Add `economicSystem?: 'capitalist' | 'collectivist' | 'feudal'`
  - Add `startingTreasury?: number`

### 7.2 StartingLocationManager.tsx Changes
- [ ] **Population Tab - Starter Citizens Updates**:
  - [ ] Remove `classId` dropdown from citizen editor
  - [ ] Add `startingWealth` number input field
    - Default values by role: wealthy=5000, merchant=2000, craftsman=500, laborer=100
  - [ ] Add `intendedRole` dropdown (wealthy/merchant/craftsman/laborer)
    - Show role descriptions in dropdown
  - [ ] Update citizen card display to show role + wealth instead of class
  - [ ] Add validation: wealthy must have wealth >= 3000, etc.
- [ ] **Population Tab - Starter Land Plots** (NEW):
  - [ ] Add "Starter Land Ownership" section
  - [ ] Allow defining which plots are pre-owned by starter citizens
  - [ ] Grid-based plot selector (mini version of land grid)
  - [ ] Assign plots to specific starter citizens (by index)
  - [ ] Show total plots per citizen
- [ ] **Population Tab - Starter Housing** (NEW):
  - [ ] Add "Starter Housing Assignments" section
  - [ ] Dropdown to select housing building from starterBuildings
  - [ ] Assign citizens to housing buildings
  - [ ] Validate: families must be together, capacity limits
- [ ] **Buildings Tab Updates**:
  - [ ] Add housing-specific fields when housing building selected:
    - Initial occupancy assignments
    - Rent rate override (optional)
    - Owner assignment (town or citizen index)
  - [ ] Show building ownership indicator
- [ ] **New Tab: Land & Economy** (optional):
  - [ ] Starting economic system selection (capitalist/collectivist/feudal)
  - [ ] Starting town treasury amount
  - [ ] Pre-defined land ownership map
- [ ] Update save/load logic for new fields
- [ ] Update JSON schema validation

### 7.3 CharacterClassManager.tsx Changes
- [ ] Rename to "Class Behavior Templates"
- [ ] Update labels/descriptions
- [ ] Keep editing capability (templates still needed)

### 7.4 New Components for New Data Files

#### 7.4.1 LandConfigManager.tsx (for `land_config.json`)
- [ ] Create new component `LandConfigManager.tsx`
- [ ] **Grid Settings Section**:
  - [ ] Plot width/height inputs (default 100x100)
  - [ ] World grid dimensions display
  - [ ] Grid preview visualization (mini-map style)
- [ ] **Pricing Section**:
  - [ ] Base plot price input
  - [ ] Location multipliers (center, edge, river-adjacent, etc.)
  - [ ] Terrain type multipliers
- [ ] **Immigration Land Requirements Section**:
  - [ ] Table: Role | Min Plots | Max Plots | Notes
  - [ ] Edit requirements per role (wealthy, merchant, craftsman, laborer)
- [ ] **Overlay Settings Section**:
  - [ ] Color picker for ownership colors (town, citizen, for-sale)
  - [ ] Grid line opacity/color

#### 7.4.2 ClassThresholdsManager.tsx (for `class_thresholds.json`)
- [ ] Create new component `ClassThresholdsManager.tsx`
- [ ] **Net Worth Thresholds Section**:
  - [ ] Table: Class | Min Net Worth | Max Net Worth
  - [ ] Slider or input for each class boundary
- [ ] **Capital Ratio Thresholds Section**:
  - [ ] Table: Class | Min Capital Ratio
  - [ ] Explanation text about capital ratio calculation
- [ ] **Skill Income Thresholds Section** (optional):
  - [ ] Income brackets for class determination
- [ ] **Visualization**:
  - [ ] Bar chart showing wealth distribution ranges
  - [ ] Preview of class assignments based on sample values

#### 7.4.3 EconomicSystemManager.tsx (for `economic_systems.json`)
- [ ] Create new component `EconomicSystemManager.tsx`
- [ ] **System Selection Section**:
  - [ ] Radio buttons: Capitalist / Collectivist / Feudal
  - [ ] Description of selected system
- [ ] **Per-System Configuration Tabs**:
  - [ ] **Capitalist Tab**:
    - [ ] Private ownership rules
    - [ ] Profit distribution settings
    - [ ] Tax rates (income, property, trade)
  - [ ] **Collectivist Tab**:
    - [ ] State ownership percentage
    - [ ] Resource distribution rules
    - [ ] Collective building ownership
  - [ ] **Feudal Tab**:
    - [ ] Lord/vassal land relationships
    - [ ] Tribute/tithe percentages
    - [ ] Noble land allocation rules
- [ ] **Default System Selector**:
  - [ ] Dropdown to set default for new games

#### 7.4.4 ImmigrationConfigManager.tsx (update existing or create)
- [ ] Update/create `ImmigrationConfigManager.tsx`
- [ ] **Role-Based Immigration Settings**:
  - [ ] Table: Role | Land Required | Min Wealth | Housing Required
  - [ ] Edit immigration criteria per role
- [ ] **Land Requirements Section**:
  - [ ] Wealthy: 4+ plots required
  - [ ] Merchant: 2+ plots required
  - [ ] Craftsman: 0 plots (can rent)
  - [ ] Laborer: 0 plots (can rent)
- [ ] **Housing Requirements Section**:
  - [ ] Min housing quality by role
  - [ ] Family housing rules

#### 7.4.5 HousingConfigManager.tsx (for housing in `building_types.json`)
- [ ] Create new component `HousingConfigManager.tsx`
- [ ] **Housing Types List**:
  - [ ] Filter building_types.json to show only housing
  - [ ] Grid/list view of housing buildings
- [ ] **Per-Housing Type Editor**:
  - [ ] Quality rating (0.0 - 1.0)
  - [ ] Capacity (max residents)
  - [ ] Base rent rate
  - [ ] Class restrictions (min class to occupy)
  - [ ] Fulfillment vector preview
- [ ] **Housing Quality Tiers**:
  - [ ] Define tier names and quality ranges
  - [ ] Assign housing types to tiers
- [ ] **Rent Rate Calculator**:
  - [ ] Base rate * quality * location multiplier preview

#### 7.4.6 BuildingFulfillmentManager.tsx (for `fulfillment_vectors.json` buildings section)
- [ ] Create new component or extend `FulfillmentVectorManager.tsx`
- [ ] **Building Fulfillment Vectors Tab**:
  - [ ] List all buildings with fulfillment vectors
  - [ ] Add new building fulfillment vector
- [ ] **Vector Editor for Buildings**:
  - [ ] Same interface as commodity vectors
  - [ ] Coarse dimension sliders
  - [ ] Fine dimension detailed editor
- [ ] **Housing-Specific Presets**:
  - [ ] Quick-fill templates for housing types
  - [ ] Copy from existing housing type

#### 7.4.7 RelationshipTypesManager.tsx (NEW - for relationship configuration)
- [ ] Create new component `RelationshipTypesManager.tsx`
- [ ] **Relationship Types List**:
  - [ ] spouse, parent, child, sibling
  - [ ] employer, employee
  - [ ] landlord, tenant
  - [ ] business_partner
  - [ ] friend, rival
  - [ ] colleague, neighbour
- [ ] **Per-Relationship Config**:
  - [ ] Relationship effects on satisfaction
  - [ ] Bi-directional vs uni-directional
  - [ ] Auto-create rules (colleague when same workplace, neighbour when adjacent plot)

### 7.5 Additional Type Definitions (types.ts)

- [ ] **LandConfig interface**:
  ```typescript
  interface LandConfig {
    gridSettings: {
      plotWidth: number;
      plotHeight: number;
    };
    pricing: {
      basePlotPrice: number;
      locationMultipliers: Record<string, number>;
      terrainMultipliers: Record<string, number>;
    };
    immigrationRequirements: Record<string, {
      minPlots: number;
      maxPlots: number;
    }>;
    overlayColors: {
      townOwned: string;
      citizenOwned: string;
      forSale: string;
      gridLines: string;
    };
  }
  ```

- [ ] **ClassThresholds interface**:
  ```typescript
  interface ClassThresholds {
    netWorthThresholds: {
      elite: { min: number };
      upper: { min: number; max: number };
      middle: { min: number; max: number };
      lower: { max: number };
    };
    capitalRatioThresholds: {
      elite: number;
      upper: number;
      middle: number;
    };
  }
  ```

- [ ] **EconomicSystem interface**:
  ```typescript
  interface EconomicSystem {
    type: 'capitalist' | 'collectivist' | 'feudal';
    config: CapitalistConfig | CollectivistConfig | FeudalConfig;
  }

  interface CapitalistConfig {
    privatOwnershipEnabled: boolean;
    profitDistribution: Record<string, number>;
    taxRates: { income: number; property: number; trade: number };
  }

  interface CollectivistConfig {
    stateOwnershipPercent: number;
    distributionRules: string[];
  }

  interface FeudalConfig {
    nobleAllocation: number;
    tributePercent: number;
  }
  ```

- [ ] **ImmigrationConfig interface** (update existing):
  ```typescript
  interface ImmigrationRoleConfig {
    role: 'wealthy' | 'merchant' | 'craftsman' | 'laborer';
    landRequired: number;
    minWealth: number;
    housingRequired: boolean;
    minHousingQuality: number;
  }
  ```

- [ ] **BuildingFulfillmentVector interface**:
  ```typescript
  interface BuildingFulfillmentVector {
    buildingTypeId: string;
    fulfillmentVector: {
      coarse: number[];
      fine: Record<string, number>;
    };
    applicationFrequency: 'per_cycle' | 'per_day' | 'continuous';
    qualityMultiplier: number;
  }
  ```

- [ ] **RelationshipType interface**:
  ```typescript
  interface RelationshipType {
    id: string;
    name: string;
    bidirectional: boolean;
    satisfactionEffect: number;
    autoCreateRule?: {
      trigger: string;
      condition: string;
    };
  }
  ```

### 7.6 API Updates (api.ts)
- [ ] Add `loadLandConfig()` / `saveLandConfig()`
- [ ] Add `loadClassThresholds()` / `saveClassThresholds()`
- [ ] Add `loadEconomicSystems()` / `saveEconomicSystems()`
- [ ] Add `loadImmigrationConfig()` / `saveImmigrationConfig()`
- [ ] Add `loadBuildingFulfillmentVectors()` / `saveBuildingFulfillmentVectors()`
- [ ] Add `loadRelationshipTypes()` / `saveRelationshipTypes()`
- [ ] Rename `loadCharacterClasses()` → `loadClassBehaviorTemplates()`
- [ ] Rename `saveCharacterClasses()` → `saveClassBehaviorTemplates()`

### 7.7 App.tsx Navigation Updates
- [ ] Add new menu items for new managers:
  - [ ] "Land Configuration" under Economy section
  - [ ] "Class Thresholds" under Economy section
  - [ ] "Economic Systems" under Economy section
  - [ ] "Immigration Config" under Population section
  - [ ] "Housing Config" under Buildings section
  - [ ] "Relationship Types" under Population section
- [ ] Update menu groupings/sections

---

## Phase 8: UI Updates - Game UI (Lua)

### 8.1 Land Distribution Overlay
- [ ] Toggle-able via UI button
- [ ] Show grid lines
- [ ] Color by ownership (town, citizens)
- [ ] Highlight available plots
- [ ] Show plot info on hover

### 8.2 Land Registry Panel
- [ ] List all landowners
- [ ] Show: plots owned, total value, rent income
- [ ] Drill-down to individual plots
- [ ] Transfer ownership button
- [ ] Set for sale button

### 8.3 Plot Selection During Building
- [ ] Show which plots building will occupy
- [ ] Check ownership (yours vs need to buy/rent)
- [ ] Calculate costs (construction + land)
- [ ] Options: Buy land, Rent land, Cancel

### 8.4 Housing Overview Panel
- [ ] Capacity by class tier
- [ ] Total rent income
- [ ] Building list with occupancy
- [ ] Relocation requests count

### 8.5 Housing Assignment Modal
- [ ] Filter/sort citizens
- [ ] Show fit indicators
- [ ] Multi-select for batch assignment
- [ ] Selection summary

### 8.6 Character Panel - Economics Tab
- [ ] Show income breakdown (labor vs capital)
- [ ] Show expenses (rent, consumption)
- [ ] Show net worth
- [ ] Show emergent class
- [ ] Show owned assets

### 8.7 Character Panel - Housing Tab
- [ ] Current residence
- [ ] Co-habitants
- [ ] Rent status
- [ ] Housing satisfaction breakdown

### 8.8 Immigration Flow Update
- [ ] Show land requirements by intended role
- [ ] Link to plot picker modal (not inline)
- [ ] Show remaining capital after land purchase
- [ ] For elites: show auto-residence info

---

## Phase 9: Save/Load & Migration

### 9.1 SaveManager.lua Updates
- [ ] Save land ownership state
- [ ] Save character economics
- [ ] Save housing assignments
- [ ] Save relationships

### 9.2 Backwards Compatibility
- [ ] Detect old saves (have `class`, no `economics`)
- [ ] Migration function:
  ```lua
  if citizen.class and not citizen.economics then
    citizen.economics = migrateFromOldClass(citizen.class)
    citizen.emergentClass = citizen.class
    citizen.class = nil
  end
  ```
- [ ] Map old class to starting economics values

---

## Phase 10: Testing & Polish

### 10.1 Test Scenarios
- [ ] New game with land system
- [ ] Elite immigration with land purchase
- [ ] Laborer immigration (no land)
- [ ] Class mobility (lower → middle → upper)
- [ ] Housing assignment and relocation
- [ ] Rent collection flow
- [ ] Profit distribution

### 10.2 Balance Testing
- [ ] Class threshold values
- [ ] Land pricing
- [ ] Rent rates
- [ ] Immigration capital amounts
- [ ] Housing capacity vs population

### 10.3 Performance
- [ ] Class calculation every 20 cycles (not every cycle)
- [ ] Land overlay rendering optimization
- [ ] Large population handling

---

## Implementation Order (Recommended)

1. **Data files first** (Phase 1) - Foundation
2. **Land System** (Phase 2.1) - Core mechanic
3. **Character economics** (Phase 3) - Enable emergent class
4. **Immigration updates** (Phase 4) - New citizen flow
5. **Housing building types** (Phase 1.3) - Add to data
6. **Housing system** (Phase 2.4) - Assignment logic
7. **UI updates** (Phase 7-8) - Make it usable
8. **Allocation updates** (Phase 5) - Remove class bias
9. **Save/load** (Phase 9) - Persistence
10. **Testing** (Phase 10) - Verify everything works

---

## Notes

- Keep class behavior templates - they define HOW each class behaves
- Emergent class determines WHICH template applies
- Land ownership is the primary path to wealth/elite status
- Housing is required for immigration (except laborers can rent)
- Town treasury receives land sale proceeds
- Building owners pay land rent to land owners (if different)
