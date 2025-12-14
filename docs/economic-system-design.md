# Economic System & Character Model Design

## Overview

This document defines the economic foundation of CraveTown, including:
- **Land plot system** - Map divided into purchasable plots
- Character relationships and family structure
- Ownership model (who owns what)
- Emergent class system based on wealth/ownership
- Economic system types (capitalist, collectivist, feudal)
- Value creation and wealth flows
- Class mobility mechanics

## Core Principle: Emergent Class

**Class is NOT assigned - it is calculated based on wealth and ownership.**

Instead of tagging characters as "lower", "middle", "elite", etc., class emerges from:
1. **Net Worth** - Total value of owned assets
2. **Income Sources** - Labor vs capital income
3. **Asset Types** - Land, buildings, shares, commodities

---

## 1. Land Plot System

The map is divided into a grid of **purchasable land plots**. Land ownership is the foundation of the economic system.

### 1.1 Plot Grid Structure

```typescript
interface LandPlot {
  id: string;                    // e.g., "plot_12_8" (col_row)
  gridX: number;                 // Grid column (0-indexed)
  gridY: number;                 // Grid row (0-indexed)
  worldX: number;                // World coordinate X (top-left)
  worldY: number;                // World coordinate Y (top-left)
  width: number;                 // Plot width in world units
  height: number;                // Plot height in world units

  // Ownership
  ownerId: string | null;        // Character ID, 'state', or null (unclaimed)
  purchasePrice: number;         // Current market price
  purchasedCycle: number | null; // When it was purchased

  // Value factors
  baseValue: number;             // Base land value
  locationMultiplier: number;    // Near river/resources = higher
  developmentBonus: number;      // Increases with nearby buildings

  // Terrain
  terrainType: TerrainType;      // 'grass', 'forest', 'mountain', 'water', 'desert'
  isBlocked: boolean;            // Mountains, water = unbuildable
  naturalResources: string[];    // Resources present on this plot

  // Development
  buildings: string[];           // Building IDs on this plot
  zoning?: ZoningType;           // Optional zoning restrictions
}

type TerrainType = 'grass' | 'forest' | 'rocky' | 'fertile' | 'water' | 'mountain' | 'desert';
type ZoningType = 'residential' | 'commercial' | 'industrial' | 'agricultural' | 'mixed' | 'none';
```

### 1.2 Grid Configuration

```typescript
interface LandGridConfig {
  // Grid dimensions
  plotWidth: number;             // Width of each plot (e.g., 100 world units)
  plotHeight: number;            // Height of each plot (e.g., 100 world units)
  gridColumns: number;           // Number of columns (e.g., 32 for 3200 wide map)
  gridRows: number;              // Number of rows (e.g., 24 for 2400 tall map)

  // Pricing
  basePlotPrice: number;         // Base price for standard plot (e.g., 100 gold)
  locationPriceMultipliers: {
    riverAdjacent: number;       // e.g., 1.5x
    resourceRich: number;        // e.g., 1.3x
    centralLocation: number;     // e.g., 1.2x
    edgeLocation: number;        // e.g., 0.8x
  };

  // Initial state
  stateOwnedPlots: string[];     // Plot IDs owned by state at start
  unbuildablePlots: string[];    // Plot IDs that can't be developed (water, mountains)
}
```

### 1.3 Plot Pricing Formula

```typescript
function calculatePlotPrice(plot: LandPlot, gridConfig: LandGridConfig): number {
  let price = gridConfig.basePlotPrice;

  // Location multiplier
  price *= plot.locationMultiplier;

  // Terrain value
  const terrainMultipliers = {
    'fertile': 1.4,
    'grass': 1.0,
    'forest': 0.9,    // Trees need clearing
    'rocky': 0.7,
    'desert': 0.5,
  };
  price *= terrainMultipliers[plot.terrainType] || 1.0;

  // Natural resources bonus
  if (plot.naturalResources.length > 0) {
    price *= 1 + (plot.naturalResources.length * 0.15);
  }

  // Development bonus (nearby buildings increase value)
  price *= (1 + plot.developmentBonus);

  // Market demand (more buyers = higher prices)
  const demandMultiplier = calculateMarketDemand();
  price *= demandMultiplier;

  return Math.round(price);
}
```

### 1.4 Immigration & Land Requirements

Immigrants must purchase land to enter the town:

```typescript
interface ImmigrationLandRequirement {
  // Minimum land requirements by intended class
  requirements: {
    wealthy: {
      minPlots: 4,               // Wealthy immigrants want large estates
      minValue: 2000,            // Or high-value plots
      description: "Seeking estate land"
    },
    merchant: {
      minPlots: 2,
      minValue: 500,
      description: "Seeking commercial land"
    },
    craftsman: {
      minPlots: 1,
      minValue: 200,
      description: "Seeking workshop land"
    },
    laborer: {
      minPlots: 0,               // Laborers don't need land
      minValue: 0,
      description: "Will rent housing"
    }
  };

  // Immigration flow
  immigrationProcess: {
    step1: "Immigrant arrives with capital",
    step2: "Immigrant requests land purchase",
    step3: "Payment transferred to seller (state or citizen)",
    step4: "Land ownership transferred",
    step5: "Immigrant can now build or settle"
  };
}
```

### 1.5 Immigration Land Purchase Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     IMMIGRATION REQUEST                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Immigrant: Heinrich Mueller                                        │
│  Capital: 800 gold                                                  │
│  Family: 4 (spouse + 2 children)                                    │
│  Intended Role: Merchant                                            │
│                                                                     │
│  LAND REQUIREMENTS                                                  │
│  ├─ Minimum Plots: 2                                                │
│  ├─ Minimum Value: 500 gold                                         │
│  └─ Purpose: Commercial establishment + residence                   │
│                                                                     │
│  AVAILABLE PLOTS (within budget)                                    │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ Plot 15-12  │ Grass  │ 150 gold │ Near market    │ ☐ Select     │|
│  │ Plot 15-13  │ Grass  │ 140 gold │ Adjacent       │ ☐ Select     │|
│  │ Plot 16-12  │ Forest │ 120 gold │ Needs clearing │ ☐ Select     │|
│  │ Plot 14-14  │ Grass  │ 180 gold │ River adjacent │ ☐ Select     │|
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  Selected: 2 plots | Total Cost: 290 gold                           │
│  Remaining Capital: 510 gold (for building + startup)               │
│                                                                     │
│                    [Reject Immigration]  [Approve & Transfer]       │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.6 Land Rent System

When a building is placed on land owned by someone else:

```typescript
interface LandRentAgreement {
  plotId: string;
  landOwnerId: string;           // Who owns the land
  buildingOwnerId: string;       // Who owns the building on it
  buildingId: string;

  // Rent terms
  rentPerCycle: number;          // Gold paid per cycle
  rentType: 'fixed' | 'percentage' | 'profit_share';
  percentageRate?: number;       // If percentage-based (e.g., 0.1 = 10% of revenue)

  // Contract
  startCycle: number;
  duration: number | 'perpetual'; // Cycles or indefinite
  terminationNotice: number;     // Cycles notice required

  // Status
  rentPaidThrough: number;       // Last cycle rent was paid
  inArrears: boolean;            // Behind on rent?
  arrearsAmount: number;         // How much owed
}
```

### 1.7 Rent Calculation

```typescript
function calculateLandRent(plot: LandPlot, building: Building): number {
  // Base rent is percentage of land value
  const baseRentRate = 0.02;  // 2% of land value per cycle
  let rent = plot.purchasePrice * baseRentRate;

  // Building type multiplier
  const buildingMultipliers = {
    'housing': 1.0,
    'production': 1.2,
    'commercial': 1.5,
    'entertainment': 1.3,
  };
  rent *= buildingMultipliers[building.category] || 1.0;

  // Building size affects rent
  const sizeMultiplier = Math.sqrt(building.width * building.height) / 10;
  rent *= sizeMultiplier;

  return Math.round(rent);
}
```

### 1.8 Rent Flow Diagram

```
┌──────────────────┐     Labor      ┌──────────────────┐
│     WORKER       │───────────────▶│    BUILDING      │
│   (Employee)     │                │   (Production)   │
└──────────────────┘                └────────┬─────────┘
                                             │
                                             │ Revenue
                                             ▼
                                    ┌──────────────────┐
                                    │  BUILDING OWNER  │
                                    │  (Capitalist)    │
                                    └────────┬─────────┘
                                             │
                          ┌──────────────────┼──────────────────┐
                          │                  │                  │
                          ▼                  ▼                  ▼
                   ┌────────────┐     ┌────────────┐     ┌────────────┐
                   │   WAGES    │     │  PROFITS   │     │ LAND RENT  │
                   │ (Workers)  │     │  (Keep)    │     │ (Landlord) │
                   └────────────┘     └────────────┘     └─────┬──────┘
                                                               │
                                                               ▼
                                                      ┌──────────────────┐
                                                      │   LAND OWNER     │
                                                      │    (Elite)       │
                                                      └──────────────────┘
```

### 1.9 Land Distribution Overlay

Visual overlay showing plot ownership:

```typescript
interface LandOverlayConfig {
  enabled: boolean;
  showGrid: boolean;              // Show plot boundaries
  showOwnership: boolean;         // Color by owner
  showZoning: boolean;            // Color by zone type
  showValue: boolean;             // Show price/value indicators
  showAvailable: boolean;         // Highlight unclaimed plots

  colors: {
    unowned: [number, number, number, number];      // e.g., [0.5, 0.5, 0.5, 0.3]
    stateOwned: [number, number, number, number];   // e.g., [0.2, 0.4, 0.8, 0.4]
    playerOwned: [number, number, number, number];  // If player-controlled entity
    citizenOwned: [number, number, number, number]; // e.g., varies by citizen
    gridLines: [number, number, number, number];    // e.g., [0.3, 0.3, 0.3, 0.5]
  };

  // Interaction
  clickToSelect: boolean;
  showTooltipOnHover: boolean;
  tooltipInfo: ('owner' | 'value' | 'buildings' | 'rent')[];
}
```

### 1.10 Overlay UI Mockup

```
┌─────────────────────────────────────────────────────────────────────┐
│ MAP OVERLAYS                                           [X]          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ ☑ Land Distribution Overlay                                        │
│   ├─ ☑ Show Grid Lines                                             │
│   ├─ ☑ Color by Ownership                                          │
│   ├─ ☐ Color by Zoning                                             │
│   ├─ ☑ Show Available Plots                                        │
│   └─ ☐ Show Land Values                                            │
│                                                                     │
│ LEGEND                                                              │
│ ┌───────────────────────────────────────────────────────────────┐  │
│ │ ▓▓ Unclaimed (45 plots)     ░░ State Owned (12 plots)         │  │
│ │ ██ Mueller Family (8 plots) ▒▒ Schmidt Family (4 plots)       │  │
│ │ ▄▄ Other Citizens (31 plots)                                  │  │
│ └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│ STATISTICS                                                          │
│ ├─ Total Plots: 768 (32 × 24)                                      │
│ ├─ Buildable: 650 (85%)                                            │
│ ├─ Owned by Citizens: 43 (6%)                                      │
│ ├─ Owned by State: 12 (2%)                                         │
│ ├─ Unclaimed: 595 (92%)                                            │
│ └─ Total Land Value: 58,400 gold                                   │
│                                                                     │
│                              [View Land Registry]                   │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.11 Land Registry Panel

```
┌─────────────────────────────────────────────────────────────────────┐
│ LAND REGISTRY                                     [Filter] [Sort]   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ SEARCH: [________________] [By Owner ▼]                             │
│                                                                     │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Owner          │ Plots │ Total Value │ Rent Income │ Buildings  │ │
│ ├────────────────┼───────┼─────────────┼─────────────┼────────────┤ │
│ │ Mueller Family │   8   │   1,240 g   │    45 g/c   │     3      │ │
│ │ Schmidt Family │   4   │     680 g   │    28 g/c   │     2      │ │
│ │ Weber, Hans    │   2   │     320 g   │     0 g/c   │     1      │ │
│ │ State          │  12   │   1,800 g   │    62 g/c   │     5      │ │
│ │ [Unclaimed]    │ 595   │  54,360 g   │      -      │     -      │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ SELECTED: Mueller Family                                            │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Plot ID   │ Location  │ Value │ Terrain │ Buildings │ Rent     │ │
│ ├───────────┼───────────┼───────┼─────────┼───────────┼──────────┤ │
│ │ 15-12     │ Central   │ 180 g │ Grass   │ Shop      │ -        │ │
│ │ 15-13     │ Central   │ 160 g │ Grass   │ House     │ -        │ │
│ │ 16-12     │ Central   │ 140 g │ Grass   │ -         │ -        │ │
│ │ 16-13     │ Central   │ 140 g │ Grass   │ Workshop* │ 12 g/c   │ │
│ │ ...       │           │       │         │           │          │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│ * Building owned by Hans Weber (renting land)                       │
│                                                                     │
│           [View on Map]  [Transfer Ownership]  [Set For Sale]       │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.12 Plot Selection During Building Placement

When placing a building, show plot information:

```
┌─────────────────────────────────────────────────────────────────────┐
│ PLACING: Bakery (3×2 plots required)                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ SELECTED PLOTS: 15-12, 15-13, 15-14, 16-12, 16-13, 16-14           │
│                                                                     │
│ OWNERSHIP CHECK                                                     │
│ ├─ 15-12: Owned by YOU ✓                                           │
│ ├─ 15-13: Owned by YOU ✓                                           │
│ ├─ 15-14: Owned by Mueller Family                                  │
│ │         └─ Rent Required: 15 gold/cycle                          │
│ ├─ 16-12: Owned by YOU ✓                                           │
│ ├─ 16-13: Unclaimed                                                │
│ │         └─ Purchase Required: 140 gold                           │
│ └─ 16-14: Unclaimed                                                │
│           └─ Purchase Required: 140 gold                           │
│                                                                     │
│ COST SUMMARY                                                        │
│ ├─ Building Construction: 500 gold                                 │
│ ├─ Land Purchase (2 plots): 280 gold                               │
│ ├─ Land Rent (1 plot): 15 gold/cycle ongoing                       │
│ └─ TOTAL UPFRONT: 780 gold                                         │
│                                                                     │
│           [Cancel]  [Purchase Land & Build]  [Build (Rent Land)]   │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.13 Land System Configuration JSON

```json
{
  "version": "1.0.0",
  "gridConfig": {
    "plotWidth": 100,
    "plotHeight": 100,
    "gridColumns": 32,
    "gridRows": 24,
    "totalPlots": 768
  },
  "pricing": {
    "basePlotPrice": 100,
    "locationMultipliers": {
      "riverAdjacent": 1.5,
      "resourceRich": 1.3,
      "centralLocation": 1.2,
      "edgeLocation": 0.8,
      "nearMarket": 1.4,
      "nearRoad": 1.1
    },
    "terrainMultipliers": {
      "fertile": 1.4,
      "grass": 1.0,
      "forest": 0.9,
      "rocky": 0.7,
      "desert": 0.5
    },
    "rentBaseRate": 0.02,
    "rentBuildingMultipliers": {
      "housing": 1.0,
      "production": 1.2,
      "commercial": 1.5,
      "entertainment": 1.3
    }
  },
  "immigration": {
    "landRequirements": {
      "wealthy": {"minPlots": 4, "minValue": 2000},
      "merchant": {"minPlots": 2, "minValue": 500},
      "craftsman": {"minPlots": 1, "minValue": 200},
      "laborer": {"minPlots": 0, "minValue": 0}
    },
    "allowRentOnlyImmigration": true,
    "rentOnlyClasses": ["laborer"]
  },
  "overlay": {
    "defaultEnabled": false,
    "gridLineColor": [0.3, 0.3, 0.3, 0.5],
    "unownedColor": [0.5, 0.5, 0.5, 0.3],
    "stateOwnedColor": [0.2, 0.4, 0.8, 0.4],
    "availableHighlight": [0.2, 0.8, 0.2, 0.4]
  }
}
```

### 1.14 Land Value Appreciation

Land value changes over time based on development:

```typescript
function updatePlotValue(plot: LandPlot, cycle: number): void {
  // Base appreciation (general town growth)
  const baseAppreciation = 0.001;  // 0.1% per cycle

  // Development bonus from nearby buildings
  const nearbyBuildings = getBuildingsInRadius(plot, 200);
  let developmentBonus = 0;
  for (const building of nearbyBuildings) {
    developmentBonus += getBuildingPrestigeValue(building) * 0.01;
  }

  // Infrastructure bonus (roads, markets)
  const infrastructureBonus = hasNearbyInfrastructure(plot) ? 0.05 : 0;

  // Update values
  plot.developmentBonus = developmentBonus;
  plot.locationMultiplier *= (1 + baseAppreciation);

  // Recalculate purchase price
  plot.purchasePrice = calculatePlotPrice(plot, gridConfig);
}
```

---

## 2. Character Relationship Model

### 2.1 Relationship Types

```typescript
type RelationshipType =
  | 'spouse'           // Marriage partner
  | 'parent'           // Parent of
  | 'child'            // Child of
  | 'sibling'          // Brother/sister
  | 'employer'         // Employs this person
  | 'employee'         // Works for this person
  | 'landlord'         // Rents housing to
  | 'tenant'           // Rents housing from
  | 'business_partner' // Co-owns assets with
  | 'friend'           // Social connection
  | 'rival';           // Negative relationship
```

### 1.2 Relationship Data Structure

```typescript
interface Relationship {
  targetId: string;           // Other character's ID
  type: RelationshipType;
  strength: number;           // 0.0 to 1.0 (for social relationships)
  establishedCycle: number;   // When relationship started
  metadata?: {
    contractTerms?: any;      // For employer/tenant relationships
    sharePercentage?: number; // For business partners
  };
}
```

### 1.3 Household Structure

A **Household** is a group of characters living together:

```typescript
interface Household {
  id: string;
  headOfHousehold: string;    // Character ID
  members: string[];          // All member character IDs
  housingId?: string;         // Building they live in

  // Calculated
  totalIncome: number;        // Sum of all member incomes
  totalExpenses: number;      // Rent + consumption
  householdWealth: number;    // Combined net worth
}
```

### 1.4 Family Formation Rules

| Event | Conditions | Result |
|-------|------------|--------|
| Marriage | Two singles, age 18+, compatible | New household or merge |
| Birth | Married couple, housing capacity | New child character |
| Coming of Age | Child reaches 18 | Can form own household |
| Death | Age/health/events | Inheritance triggers |
| Divorce | Low relationship, events | Household splits |

---

## 2. Ownership Model

### 2.1 Ownable Asset Types

```typescript
type AssetType =
  | 'building'         // Production buildings, housing
  | 'land'             // Land plots (for future expansion)
  | 'shares'           // Fractional ownership of buildings
  | 'commodity_stock'  // Stored commodities
  | 'gold'             // Currency
  | 'durable_goods'    // Furniture, tools, etc.
  | 'trade_rights';    // Exclusive trade route access
```

### 2.2 Ownership Record

```typescript
interface OwnershipRecord {
  assetType: AssetType;
  assetId: string;            // Building ID, commodity ID, etc.
  ownerId: string;            // Character ID or 'state' or 'collective'
  ownershipPercentage: number; // 0.0 to 1.0 (for shared ownership)
  acquiredCycle: number;
  acquisitionMethod: 'purchase' | 'inheritance' | 'grant' | 'founding';

  // For income-generating assets
  lastIncomeCollected: number; // Cycle
  incomeRate?: number;         // Per cycle (calculated from asset)
}
```

### 2.3 Asset Valuation

Each asset has a calculated value:

```typescript
interface AssetValuation {
  assetId: string;
  baseValue: number;           // Construction cost or market value
  currentValue: number;        // Depreciated or appreciated value
  incomeMultiplier: number;    // For income-generating assets

  // Calculated income potential
  projectedIncome: number;     // Expected income per cycle
}
```

### 2.4 Building Ownership

Buildings can be owned by:
- **Individual Character** - Receives all profits/rent
- **Partnership** - Multiple characters with share percentages
- **State/Collective** - Government owns, profits go to treasury
- **Unowned** - Newly constructed, awaiting assignment

```typescript
interface BuildingOwnership {
  buildingId: string;
  owners: Array<{
    characterId: string;      // or 'state'
    sharePercentage: number;  // Must sum to 1.0
  }>;

  // Economics
  operatingCosts: number;     // Per cycle
  revenue: number;            // From production/rent
  profit: number;             // Revenue - costs

  // Distribution
  profitDistribution: 'proportional' | 'fixed' | 'reinvest';
}
```

---

## 3. Emergent Class System

### 3.1 Class Calculation Formula

Class is calculated each cycle based on:

```typescript
function calculateClass(character: Character): EmergentClass {
  const netWorth = calculateNetWorth(character);
  const capitalIncome = calculateCapitalIncome(character);
  const laborIncome = calculateLaborIncome(character);
  const totalIncome = capitalIncome + laborIncome;

  // Capital ratio: how much income comes from ownership vs labor
  const capitalRatio = totalIncome > 0 ? capitalIncome / totalIncome : 0;

  // Thresholds (configurable per economic system)
  const thresholds = getClassThresholds(currentEconomicSystem);

  if (netWorth >= thresholds.elite.netWorth &&
      capitalRatio >= thresholds.elite.capitalRatio) {
    return 'elite';
  }
  if (netWorth >= thresholds.upper.netWorth ||
      capitalRatio >= thresholds.upper.capitalRatio) {
    return 'upper';
  }
  if (netWorth >= thresholds.middle.netWorth ||
      laborIncome >= thresholds.middle.skillIncome) {
    return 'middle';
  }
  return 'lower';
}
```

### 3.2 Class Thresholds (Capitalist System)

| Class | Net Worth | Capital Ratio | OR Skill Income |
|-------|-----------|---------------|-----------------|
| Elite | >= 10,000 | >= 0.8 | - |
| Upper | >= 3,000 | >= 0.5 | OR >= 100/cycle |
| Middle | >= 500 | >= 0.2 | OR >= 40/cycle |
| Lower | < 500 | < 0.2 | AND < 40/cycle |

### 3.3 Class Indicators (Not Labels)

Instead of storing class as a fixed attribute, we:
1. **Calculate class dynamically** each cycle
2. **Store wealth metrics** that determine class
3. **Class affects behavior** but behavior affects class (feedback loop)

```typescript
interface CharacterEconomics {
  // Stored values (updated each cycle)
  goldBalance: number;
  ownedAssets: OwnershipRecord[];

  // Cached calculations (recalculated each cycle)
  netWorth: number;
  capitalIncome: number;
  laborIncome: number;
  totalIncome: number;
  capitalRatio: number;
  emergentClass: EmergentClass;  // Calculated, not assigned

  // History for mobility tracking
  classHistory: Array<{cycle: number; class: EmergentClass}>;
}
```

### 3.4 What Class Affects

Once calculated, emergent class influences:

| Aspect | How Class Affects It |
|--------|---------------------|
| Craving Vector | Higher classes have more luxury/status cravings |
| Quality Acceptance | Higher classes reject poor quality goods |
| Housing Preferences | Higher classes seek better housing |
| Emigration Threshold | Higher classes leave sooner if unsatisfied |
| Social Connections | Classes tend to associate with similar classes |
| Consumption Patterns | Different spending priorities |

**Key insight**: Class affects cravings, but doesn't define the person. A wealthy person still has biological needs; they just ALSO have luxury needs.

---

## 4. Economic System Types

### 4.1 System Definitions

```typescript
type EconomicSystemType =
  | 'capitalist'      // Private ownership, profit motive
  | 'collectivist'    // State/collective ownership
  | 'feudal'          // Land-based hierarchy, tribute
  | 'mixed';          // Hybrid system
```

### 4.2 Capitalist System

```typescript
const CAPITALIST_SYSTEM = {
  id: 'capitalist',
  name: 'Free Market',

  ownership: {
    buildingsCanBePrivate: true,
    landCanBePrivate: true,
    maxOwnershipPerPerson: 1.0,  // No limit
    inheritanceAllowed: true,
    inheritanceTax: 0.1,  // 10%
  },

  income: {
    wagesSetBy: 'market',  // or 'employer' or 'state'
    profitsGoTo: 'owners',
    rentAllowed: true,
    interestAllowed: true,
  },

  classThresholds: {
    elite: { netWorth: 10000, capitalRatio: 0.8 },
    upper: { netWorth: 3000, capitalRatio: 0.5, skillIncome: 100 },
    middle: { netWorth: 500, capitalRatio: 0.2, skillIncome: 40 },
  },

  mobility: {
    classChangeEnabled: true,
    wealthAccumulationRate: 1.0,  // Normal
  }
};
```

### 4.3 Collectivist System

```typescript
const COLLECTIVIST_SYSTEM = {
  id: 'collectivist',
  name: 'Collective Ownership',

  ownership: {
    buildingsCanBePrivate: false,  // All state-owned
    landCanBePrivate: false,
    maxOwnershipPerPerson: 0,      // No private ownership
    inheritanceAllowed: false,
    inheritanceTax: 1.0,           // 100% to state
  },

  income: {
    wagesSetBy: 'state',
    profitsGoTo: 'treasury',       // Redistributed
    rentAllowed: false,            // Free housing
    interestAllowed: false,
  },

  classThresholds: {
    // In collectivist system, class is based on role/skill, not wealth
    elite: { role: 'administrator', skillLevel: 5 },
    upper: { role: 'specialist', skillLevel: 4 },
    middle: { role: 'skilled_worker', skillLevel: 2 },
  },

  mobility: {
    classChangeEnabled: true,      // Based on skill/merit
    wealthAccumulationRate: 0.1,   // Very limited
  }
};
```

### 4.4 Feudal System

```typescript
const FEUDAL_SYSTEM = {
  id: 'feudal',
  name: 'Feudal Hierarchy',

  ownership: {
    buildingsCanBePrivate: true,   // But tied to land grants
    landCanBePrivate: true,        // Granted by higher lord
    maxOwnershipPerPerson: 'by_title', // Limited by social rank
    inheritanceAllowed: true,
    inheritanceTax: 0,             // No tax, but obligations
  },

  income: {
    wagesSetBy: 'tradition',       // Fixed rates
    profitsGoTo: 'owners',
    rentAllowed: true,             // Tribute to lords
    interestAllowed: false,        // Usury banned
  },

  classThresholds: {
    // Feudal class is primarily by birth/title
    elite: { title: ['lord', 'baron', 'count'] },
    upper: { title: ['knight', 'merchant_guild'] },
    middle: { title: ['freeman', 'craftsman'] },
    // Lower = serf (default)
  },

  mobility: {
    classChangeEnabled: false,     // Very limited
    titleGrantRequired: true,      // Need lord's permission
    wealthAccumulationRate: 0.5,   // Limited
  },

  obligations: {
    tributeRate: 0.3,              // 30% to lord
    laborDays: 2,                  // Days per week owed
  }
};
```

### 4.5 Why Class Matters Less in Collectivism

In a collectivist system:
- No private ownership = no capital income
- Class becomes about **role/skill** not wealth
- Still affects: housing assignment priority, job allocation, prestige needs
- Doesn't affect: wealth (everyone similar), ownership (none)

```typescript
// In collectivist system, "class" is really "role tier"
function calculateCollectivistClass(character: Character): EmergentClass {
  const skillLevel = character.vocation?.skillLevel || 1;
  const role = character.assignedRole;

  if (role === 'administrator' || skillLevel >= 5) return 'elite';
  if (role === 'specialist' || skillLevel >= 3) return 'upper';
  if (skillLevel >= 2) return 'middle';
  return 'lower';
}
```

---

## 5. Value Creation & Wealth Flows

### 5.1 How Elites Create Value

In a capitalist system, elites justify their wealth by:

| Role | Value Creation | Income Source |
|------|---------------|---------------|
| **Building Owner** | Provides production capacity | Profits from building output |
| **Land Owner** | Provides space for buildings | Rent from land use |
| **Investor** | Funds new construction | Returns on investment |
| **Trade Facilitator** | Enables external trade | Trade margins |
| **Knowledge Holder** | Unlocks advanced recipes | Licensing fees |

### 5.2 Income Flow Diagram

```
                    ┌─────────────────────┐
                    │   EXTERNAL TRADE    │
                    └──────────┬──────────┘
                               │ Imports/Exports
                               ▼
┌──────────────┐    ┌─────────────────────┐    ┌──────────────┐
│   WORKERS    │───▶│   PRODUCTION        │───▶│  COMMODITIES │
│ (Labor)      │    │   BUILDINGS         │    │  (Output)    │
└──────────────┘    └──────────┬──────────┘    └──────┬───────┘
       ▲                       │                      │
       │ Wages                 │ Profits              │ Sales
       │                       ▼                      ▼
┌──────┴───────┐    ┌─────────────────────┐    ┌──────────────┐
│  TREASURY    │◀───│   BUILDING OWNERS   │◀───│  CONSUMERS   │
│  (Taxes)     │    │   (Capitalists)     │    │  (Citizens)  │
└──────────────┘    └─────────────────────┘    └──────────────┘
                               │
                               │ Rent
                               ▼
                    ┌─────────────────────┐
                    │   LAND OWNERS       │
                    │   (If different)    │
                    └─────────────────────┘
```

### 5.3 Building Profit Calculation

```typescript
function calculateBuildingProfit(building: Building, cycle: number): number {
  // Revenue from production
  const outputValue = calculateOutputValue(building.production);

  // Costs
  const inputCosts = calculateInputCosts(building.consumption);
  const laborCosts = calculateLaborCosts(building.workers);
  const maintenanceCosts = building.maintenancePerCycle;
  const landRent = building.landRentPerCycle || 0;

  const grossProfit = outputValue - inputCosts - laborCosts - maintenanceCosts - landRent;

  // Taxes
  const taxRate = getTaxRate(building.category);
  const taxes = grossProfit * taxRate;

  const netProfit = grossProfit - taxes;

  return netProfit;
}
```

### 5.4 Profit Distribution

```typescript
function distributeProfits(building: Building, profit: number) {
  const ownership = getBuildingOwnership(building.id);

  for (const owner of ownership.owners) {
    const share = profit * owner.sharePercentage;

    if (owner.characterId === 'state') {
      addToTreasury(share);
    } else {
      const character = getCharacter(owner.characterId);
      character.goldBalance += share;
      character.capitalIncome += share;  // Track for class calculation
    }
  }
}
```

---

## 6. Wage & Labor System

### 6.1 Wage Determination

Wages depend on economic system:

| System | Wage Determination |
|--------|-------------------|
| Capitalist | Market-based: supply/demand + skill premium |
| Collectivist | State-set: standardized by role |
| Feudal | Traditional: fixed by custom |

### 6.2 Wage Calculation (Capitalist)

```typescript
function calculateWage(character: Character, workplace: Building): number {
  const baseWage = workplace.baseWageRate || 10;

  // Skill multiplier
  const skillLevel = character.vocation?.skillLevel || 1;
  const skillMultiplier = 1 + (skillLevel - 1) * 0.2;  // +20% per skill level

  // Supply/demand adjustment
  const workerDemand = getTotalWorkerDemand(workplace.workCategory);
  const workerSupply = getAvailableWorkers(workplace.workCategory);
  const marketMultiplier = workerDemand / Math.max(1, workerSupply);

  // Clamp market multiplier
  const clampedMarket = Math.max(0.5, Math.min(2.0, marketMultiplier));

  return baseWage * skillMultiplier * clampedMarket;
}
```

### 6.3 Labor Income vs Capital Income

```typescript
interface IncomeBreakdown {
  laborIncome: number;      // From wages
  capitalIncome: number;    // From ownership (profits, rent, interest)
  transferIncome: number;   // From government (welfare, subsidies)
  totalIncome: number;
}

function calculateIncomeBreakdown(character: Character): IncomeBreakdown {
  const laborIncome = character.workplace
    ? calculateWage(character, character.workplace)
    : 0;

  const capitalIncome = character.ownedAssets.reduce((sum, asset) => {
    return sum + getAssetIncome(asset);
  }, 0);

  const transferIncome = getGovernmentTransfers(character);

  return {
    laborIncome,
    capitalIncome,
    transferIncome,
    totalIncome: laborIncome + capitalIncome + transferIncome
  };
}
```

---

## 7. Class Mobility

### 7.1 Upward Mobility Paths

| From | To | Requirements |
|------|-----|-------------|
| Lower | Middle | Accumulate 500 gold OR skill level 3 |
| Middle | Upper | Accumulate 3,000 gold OR own income-generating asset |
| Upper | Elite | Accumulate 10,000 gold AND capital ratio > 0.8 |

### 7.2 Downward Mobility Triggers

| Trigger | Effect |
|---------|--------|
| Asset loss (fire, bankruptcy) | Net worth drops, class recalculates |
| Sustained unemployment | Income drops, savings depleted |
| Bad investments | Capital income becomes negative |
| Inheritance split | Wealth divided among heirs |

### 7.3 Class Change Events

```typescript
function onClassChange(character: Character, oldClass: string, newClass: string) {
  // Update craving vector based on new class
  recalculateCravingVector(character, newClass);

  // Trigger housing preference change
  if (needsHousingUpgrade(character, newClass)) {
    addToRelocationQueue(character);
  }

  // Social effects
  updateSocialConnections(character, oldClass, newClass);

  // Notification
  emitEvent('class_change', {
    characterId: character.id,
    oldClass,
    newClass,
    reason: determineChangeReason(character)
  });
}
```

---

## 8. Changes to Existing Character Model

### 8.1 Fields to REMOVE from CharacterV3

```lua
-- REMOVE these static class assignments:
char.class = class or "Middle"  -- NO! Class should be calculated

-- REMOVE fixed allocation priority based on class:
char.allocationPriority = 0  -- This should be calculated from need, not class
```

### 8.2 Fields to ADD to CharacterV3

```lua
-- ADD: Economic state
char.economics = {
    goldBalance = startingGold or 0,
    ownedAssets = {},           -- Array of ownership records
    laborIncome = 0,            -- Updated each cycle
    capitalIncome = 0,          -- Updated each cycle
    expenses = 0,               -- Rent, consumption, taxes
    netWorth = 0,               -- Calculated: gold + asset values
    capitalRatio = 0,           -- capitalIncome / totalIncome
}

-- ADD: Relationship tracking
char.relationships = {}         -- Array of Relationship objects
char.householdId = nil          -- Which household they belong to

-- ADD: Employment
char.employment = {
    employerId = nil,           -- Character ID of employer (or 'state')
    workplaceId = nil,          -- Building ID where they work
    wageRate = 0,               -- Current wage per cycle
    contractType = 'at_will',   -- 'at_will', 'contract', 'serf'
}

-- KEEP but RENAME:
char.emergentClass = nil        -- Calculated each cycle, not assigned
```

### 8.3 New Methods to ADD

```lua
-- Calculate emergent class based on economics
function CharacterV3:CalculateEmergentClass()
    local netWorth = self.economics.netWorth
    local capitalRatio = self.economics.capitalRatio
    local laborIncome = self.economics.laborIncome

    local thresholds = CharacterV3._EconomicSystem.classThresholds

    if netWorth >= thresholds.elite.netWorth and
       capitalRatio >= thresholds.elite.capitalRatio then
        return "elite"
    elseif netWorth >= thresholds.upper.netWorth or
           capitalRatio >= thresholds.upper.capitalRatio or
           laborIncome >= thresholds.upper.skillIncome then
        return "upper"
    elseif netWorth >= thresholds.middle.netWorth or
           laborIncome >= thresholds.middle.skillIncome then
        return "middle"
    else
        return "lower"
    end
end

-- Update economics each cycle
function CharacterV3:UpdateEconomics(currentCycle)
    -- Calculate labor income
    if self.employment.workplaceId then
        self.economics.laborIncome = self.employment.wageRate
    else
        self.economics.laborIncome = 0
    end

    -- Calculate capital income
    self.economics.capitalIncome = 0
    for _, asset in ipairs(self.economics.ownedAssets) do
        self.economics.capitalIncome = self.economics.capitalIncome +
            CharacterV3.GetAssetIncome(asset, currentCycle)
    end

    -- Calculate expenses
    self.economics.expenses = self:CalculateExpenses()

    -- Update gold balance
    local totalIncome = self.economics.laborIncome + self.economics.capitalIncome
    self.economics.goldBalance = self.economics.goldBalance + totalIncome - self.economics.expenses

    -- Calculate net worth
    self.economics.netWorth = self:CalculateNetWorth()

    -- Calculate capital ratio
    if totalIncome > 0 then
        self.economics.capitalRatio = self.economics.capitalIncome / totalIncome
    else
        self.economics.capitalRatio = 0
    end

    -- Update emergent class
    local oldClass = self.emergentClass
    self.emergentClass = self:CalculateEmergentClass()

    -- Handle class change
    if oldClass and oldClass ~= self.emergentClass then
        self:OnClassChange(oldClass, self.emergentClass)
    end
end

-- Calculate net worth from gold + assets
function CharacterV3:CalculateNetWorth()
    local worth = self.economics.goldBalance

    for _, asset in ipairs(self.economics.ownedAssets) do
        worth = worth + CharacterV3.GetAssetValue(asset)
    end

    return worth
end

-- Add/remove relationships
function CharacterV3:AddRelationship(targetId, relationshipType, metadata)
    table.insert(self.relationships, {
        targetId = targetId,
        type = relationshipType,
        strength = 0.5,
        establishedCycle = CharacterV3._currentCycle,
        metadata = metadata
    })
end

function CharacterV3:GetRelationship(targetId, relationshipType)
    for _, rel in ipairs(self.relationships) do
        if rel.targetId == targetId and
           (not relationshipType or rel.type == relationshipType) then
            return rel
        end
    end
    return nil
end
```

### 8.4 Changes to character_classes.json

The existing `character_classes.json` should be **repurposed** as **class behavior templates**, not assignments:

```json
{
  "version": "2.0.0",
  "description": "Behavior templates for each emergent class level",
  "classTemplates": {
    "elite": {
      "description": "High wealth, capital-focused income",
      "cravingModifiers": {
        "luxury_multiplier": 1.5,
        "status_multiplier": 1.8,
        "biological_multiplier": 0.8
      },
      "qualityPreferences": {
        "minimum": "good",
        "preferred": ["luxury", "masterwork"],
        "rejected": ["poor", "basic"]
      },
      "emigrationThreshold": 45,
      "housingPreferences": ["estate", "manor"]
    },
    "upper": { ... },
    "middle": { ... },
    "lower": { ... }
  }
}
```

---

## 9. Data Model: New JSON Files

### 9.1 economic_systems.json

```json
{
  "version": "1.0.0",
  "systems": {
    "capitalist": {
      "name": "Free Market",
      "description": "Private ownership with profit motive",
      "ownership": {
        "privateOwnershipAllowed": true,
        "maxOwnershipPerPerson": null,
        "inheritanceAllowed": true,
        "inheritanceTax": 0.1
      },
      "income": {
        "wageSystem": "market",
        "profitDistribution": "owners",
        "rentAllowed": true
      },
      "classThresholds": {
        "elite": {"netWorth": 10000, "capitalRatio": 0.8},
        "upper": {"netWorth": 3000, "capitalRatio": 0.5, "skillIncome": 100},
        "middle": {"netWorth": 500, "capitalRatio": 0.2, "skillIncome": 40}
      },
      "taxation": {
        "incomeTax": {"lower": 0, "middle": 0.1, "upper": 0.15, "elite": 0.2},
        "capitalGainsTax": 0.15,
        "propertyTax": 0.02
      }
    },
    "collectivist": {
      "name": "Collective Ownership",
      "description": "State/collective ownership of production",
      "ownership": {
        "privateOwnershipAllowed": false,
        "maxOwnershipPerPerson": 0,
        "inheritanceAllowed": false,
        "inheritanceTax": 1.0
      },
      "income": {
        "wageSystem": "state",
        "profitDistribution": "treasury",
        "rentAllowed": false
      },
      "classThresholds": {
        "elite": {"role": "administrator", "skillLevel": 5},
        "upper": {"role": "specialist", "skillLevel": 4},
        "middle": {"skillLevel": 2}
      },
      "taxation": {
        "incomeTax": {"all": 0},
        "note": "No income tax - state provides directly"
      }
    },
    "feudal": {
      "name": "Feudal Hierarchy",
      "description": "Land-based hierarchy with tribute obligations",
      "ownership": {
        "privateOwnershipAllowed": true,
        "requiresTitle": true,
        "inheritanceAllowed": true,
        "inheritanceTax": 0
      },
      "income": {
        "wageSystem": "traditional",
        "profitDistribution": "owners",
        "rentAllowed": true,
        "tributeRequired": true,
        "tributeRate": 0.3
      },
      "classThresholds": {
        "elite": {"titleRequired": ["lord", "baron", "count"]},
        "upper": {"titleRequired": ["knight", "guild_master"]},
        "middle": {"titleRequired": ["freeman", "craftsman"]}
      },
      "mobility": {
        "titleGrantRequired": true,
        "description": "Class change requires title grant from higher lord"
      }
    }
  },
  "defaultSystem": "capitalist"
}
```

### 9.2 ownership_config.json

```json
{
  "version": "1.0.0",
  "assetTypes": {
    "building": {
      "canBeOwned": true,
      "canBeShared": true,
      "depreciationRate": 0.001,
      "incomeType": "profits"
    },
    "land": {
      "canBeOwned": true,
      "canBeShared": false,
      "depreciationRate": 0,
      "incomeType": "rent"
    },
    "shares": {
      "canBeOwned": true,
      "canBeShared": true,
      "depreciationRate": 0,
      "incomeType": "dividends"
    }
  },
  "transferRules": {
    "sale": {
      "enabled": true,
      "taxRate": 0.05
    },
    "gift": {
      "enabled": true,
      "taxRate": 0.1
    },
    "inheritance": {
      "enabled": true,
      "taxRate": 0.1,
      "splitMethod": "equal"
    }
  }
}
```

---

## 10. Implementation Phases

### Phase 1: Core Data Structures
1. Add economics fields to CharacterV3
2. Create economic_systems.json
3. Create ownership tracking system
4. Implement net worth calculation

### Phase 2: Income System
1. Implement wage calculation
2. Implement profit calculation for buildings
3. Implement profit distribution
4. Track labor vs capital income

### Phase 3: Emergent Class
1. Remove static class assignment
2. Implement class calculation formula
3. Create class change event system
4. Update craving vector on class change

### Phase 4: Relationships
1. Add relationship tracking to characters
2. Implement household system
3. Marriage/family formation mechanics
4. Inheritance system

### Phase 5: Economic Systems
1. Implement capitalist system fully
2. Add collectivist system variant
3. Add feudal system variant
4. UI for economic system selection

### Phase 6: UI Integration
1. Character panel shows economics
2. Building panel shows ownership/profits
3. Town analytics shows wealth distribution
4. Class mobility visualization

---

## 11. Summary

### Key Changes from Current System

| Current | New |
|---------|-----|
| `class` is assigned at creation | `emergentClass` is calculated each cycle |
| Fixed allocation priority by class | Priority based on need, not class |
| No ownership tracking | Full asset ownership system |
| No income tracking | Labor + capital income tracked |
| No relationships | Full relationship graph |
| Single economic model | Multiple economic systems |

### Why This Matters

1. **Emergent Gameplay**: Class mobility creates stories
2. **Economic Meaning**: Elites have a purpose (capital providers)
3. **System Flexibility**: Can model different economic systems
4. **Realistic Dynamics**: Wealth concentration, mobility, inequality emerge naturally
5. **Player Agency**: Economic policy choices matter
