# Housing System Design Document

## Overview

Housing in CraveTown is a prerequisite for population growth. Unlike consumable commodities that are allocated through the craving system, housing must be **pre-built** before citizens can immigrate. This creates a strategic building decision where players must anticipate population growth and build appropriate housing.

## Core Concepts

### 1. Housing as a Gate for Immigration

- Citizens (and their families) **cannot immigrate** without available housing
- Housing capacity determines the **maximum population ceiling**
- Different housing types attract different social classes
- Housing quality affects multiple shelter-related fine dimensions

### 2. Housing Categories by Class

Each social class has housing preferences and requirements:

| Class | Acceptable Housing | Ideal Housing | Rejected Housing |
|-------|-------------------|---------------|------------------|
| Elite | Manor, Estate | Estate | Anything below Manor |
| Upper | Townhouse, Manor | Manor | Lodge, Tenement |
| Middle | House, Cottage, Townhouse | Townhouse | Lodge (with penalty) |
| Lower | Lodge, Tenement, Cottage, House | Cottage | None (accepts all) |

### 3. Housing Types by Occupancy

**Single Occupancy** - For individuals without family
**Family Occupancy** - For head of household + dependents (spouse, children, elderly)
**Mixed Occupancy** - Unrelated singles CAN share family homes (roommates)

---

## Housing Building Types

### Lower Class Housing

#### 1. **Lodge** (`lodge`)
- **Description**: Communal sleeping quarters with shared facilities
- **Capacity**: 12 beds
- **Occupancy Type**: Singles only OR families (with major penalty)
- **Class Suitability**: Lower, Middle (with penalty)
- **Housing Quality Tier**: Poor
- **Housing Quality Value**: 0.3
- **Rent**: 2 gold/cycle per occupant
- **Construction Cost**: Low (50 gold, 20 wood)
- **Size**: 80x60

#### 2. **Tenement** (`tenement`)
- **Description**: Multi-family building with cramped apartments
- **Capacity**: 4 units × 5 people = 20 people max
- **Occupancy Type**: Families or mixed singles
- **Class Suitability**: Lower
- **Housing Quality Tier**: Basic
- **Housing Quality Value**: 0.4
- **Rent**: 3 gold/cycle per occupant
- **Construction Cost**: Medium-Low (150 gold, 40 wood, 20 stone)
- **Size**: 100x80

### Lower/Middle Class Housing

#### 3. **Cottage** (`cottage`)
- **Description**: Small cozy home for a family
- **Capacity**: 1 unit × 6 people
- **Occupancy Type**: Family or mixed singles
- **Class Suitability**: Lower, Middle
- **Housing Quality Tier**: Basic
- **Housing Quality Value**: 0.5
- **Rent**: 5 gold/cycle per occupant
- **Construction Cost**: Medium (200 gold, 30 wood, 10 stone)
- **Size**: 60x60
- **Upgradeable To**: House

#### 4. **House** (`house`)
- **Description**: Standard single-family dwelling
- **Capacity**: 1 unit × 8 people
- **Occupancy Type**: Family or mixed singles
- **Class Suitability**: Middle, Lower (aspirational)
- **Housing Quality Tier**: Good
- **Housing Quality Value**: 0.6
- **Rent**: 8 gold/cycle per occupant
- **Construction Cost**: Medium (350 gold, 50 wood, 30 stone)
- **Size**: 70x70
- **Upgradeable To**: Townhouse

### Middle/Upper Class Housing

#### 5. **Townhouse** (`townhouse`)
- **Description**: Multi-story urban dwelling with quality finishes
- **Capacity**: 1 unit × 6 people
- **Occupancy Type**: Family or mixed singles
- **Class Suitability**: Middle, Upper
- **Housing Quality Tier**: Good
- **Housing Quality Value**: 0.7
- **Rent**: 12 gold/cycle per occupant
- **Construction Cost**: Medium-High (500 gold, 60 wood, 50 stone, 10 glass)
- **Size**: 50x80 (narrow but tall)
- **Upgradeable To**: Manor

### Upper Class Housing

#### 6. **Manor** (`manor`)
- **Description**: Large prestigious home with grounds
- **Capacity**: 1 unit × 10 people
- **Occupancy Type**: Family or mixed singles
- **Class Suitability**: Upper, Elite
- **Housing Quality Tier**: Luxury
- **Housing Quality Value**: 0.85
- **Rent**: 20 gold/cycle per occupant
- **Construction Cost**: High (1000 gold, 100 wood, 80 stone, 20 glass, 10 marble)
- **Size**: 120x100
- **Upgradeable To**: Estate

### Elite Class Housing

#### 7. **Estate** (`estate`)
- **Description**: Grand property with multiple buildings and extensive grounds
- **Capacity**: 1 unit × 12 people
- **Occupancy Type**: Family or mixed singles
- **Class Suitability**: Elite only
- **Housing Quality Tier**: Masterwork
- **Housing Quality Value**: 1.0
- **Rent**: 35 gold/cycle per occupant
- **Construction Cost**: Very High (2500 gold, 200 wood, 150 stone, 50 glass, 30 marble, 10 gold_item)
- **Size**: 200x150

### Efficient Housing (Late Game)

#### 8. **Apartment Block** (`apartment_block`)
- **Description**: Modern multi-family residential building
- **Capacity**: 6 units × 5 people = 30 people max
- **Occupancy Type**: Families or mixed singles
- **Class Suitability**: Middle
- **Housing Quality Tier**: Good
- **Housing Quality Value**: 0.55
- **Rent**: 6 gold/cycle per occupant
- **Construction Cost**: High but efficient (800 gold, 80 wood, 100 stone, 30 glass)
- **Size**: 100x100

---

## Housing Summary Table

| Building | Quality | Capacity | Rent/Person | Target Class | Upgrade Path |
|----------|---------|----------|-------------|--------------|--------------|
| Lodge | 0.3 | 12 | 2 | Lower | - |
| Tenement | 0.4 | 20 (4×5) | 3 | Lower | - |
| Cottage | 0.5 | 6 | 5 | Lower/Middle | → House |
| House | 0.6 | 8 | 8 | Middle | → Townhouse |
| Apartment | 0.55 | 30 (6×5) | 6 | Middle | - |
| Townhouse | 0.7 | 6 | 12 | Middle/Upper | → Manor |
| Manor | 0.85 | 10 | 20 | Upper/Elite | → Estate |
| Estate | 1.0 | 12 | 35 | Elite | - |

---

## Rent/Tribute System

### How Rent Works

1. **Rent is paid per cycle** by each occupant to the town treasury
2. **Rent rate** is determined by housing quality tier
3. **Citizens must be able to afford rent** - if they can't:
   - Satisfaction penalty applied
   - After X cycles, forced to seek cheaper housing
   - If no cheaper housing available, risk of homelessness/emigration

### Rent Calculation

```
rent_per_cycle = housing.rentPerOccupant × num_occupants
```

### Affordability Check

```
can_afford = citizen.income >= (rent + basic_needs_cost)
```

If a citizen cannot afford rent:
- Apply "financial_stress" modifier to satisfaction
- After 5 cycles of inability to pay: seek cheaper housing
- After 10 cycles: risk emigration

### Treasury Impact

```
housing_revenue = Σ(all_occupied_housing.rent × occupants)
```

This creates a meaningful economic loop where:
- Better housing = more rent revenue
- But requires wealthier citizens to fill
- Class balance affects treasury income

---

## Craving System Integration

### New Fine Dimensions for Housing

We need multiple housing-related fine dimensions under the `safety` coarse dimension to model aspirational housing needs:

#### Current (Keep):
- `safety_shelter_housing` (index 10) - Base housing need

#### New Dimensions to Add:

```json
{
  "id": "safety_shelter_housing_basic",
  "index": 50,
  "parentCoarse": "safety",
  "name": "Basic Housing",
  "tags": ["shelter", "housing", "basic"],
  "aggregationWeight": 0.0,
  "enablementCondition": {
    "type": "always_enabled"
  },
  "description": "Desire for basic shelter - always active"
}

{
  "id": "safety_shelter_housing_good",
  "index": 51,
  "parentCoarse": "safety",
  "name": "Quality Housing",
  "tags": ["shelter", "housing", "good", "aspirational"],
  "aggregationWeight": 0.0,
  "enablementCondition": {
    "type": "class_minimum",
    "minimumClass": "middle"
  },
  "description": "Desire for quality housing - enabled for middle class and above"
}

{
  "id": "safety_shelter_housing_luxury",
  "index": 52,
  "parentCoarse": "safety",
  "name": "Luxury Housing",
  "tags": ["shelter", "housing", "luxury", "aspirational"],
  "aggregationWeight": 0.0,
  "enablementCondition": {
    "type": "class_minimum",
    "minimumClass": "upper"
  },
  "description": "Desire for luxury housing - enabled for upper class and above"
}

{
  "id": "safety_shelter_housing_prestige",
  "index": 53,
  "parentCoarse": "safety",
  "name": "Prestige Housing",
  "tags": ["shelter", "housing", "prestige", "elite"],
  "aggregationWeight": 0.0,
  "enablementCondition": {
    "type": "class_minimum",
    "minimumClass": "elite"
  },
  "description": "Desire for prestige housing - enabled for elite only"
}
```

### How Housing Dimensions Work

| Dimension | Enabled For | Fulfilled By | Weight When Active |
|-----------|-------------|--------------|-------------------|
| `housing_basic` | Everyone | Any housing | 0.35 |
| `housing_good` | Middle+ | House, Townhouse+ | 0.15 |
| `housing_luxury` | Upper+ | Manor, Estate | 0.20 |
| `housing_prestige` | Elite | Estate only | 0.25 |

### Class Migration & Housing Aspirations

When a citizen's class changes (e.g., Lower → Middle):

1. **New dimension enabled**: `safety_shelter_housing_good` becomes active
2. **Craving vector updated**: They now have a non-zero craving for quality housing
3. **Current housing evaluated**: If in Lodge/Tenement, satisfaction penalty
4. **Relocation desire**: System flags them as wanting to relocate
5. **If housing available**: Automatic or manual reassignment
6. **If no housing**: Satisfaction penalty continues until resolved

### Satisfaction Calculation

```
housing_satisfaction = Σ(enabled_dimensions × fulfillment)

Where fulfillment for each dimension:
- housing_basic: fulfilled if has any housing
- housing_good: fulfilled if housing.quality >= 0.6
- housing_luxury: fulfilled if housing.quality >= 0.85
- housing_prestige: fulfilled if housing.quality >= 1.0
```

---

## Housing Assignment System

### Occupancy Rules

1. **Family Assignment**:
   - Head of household + all dependents assigned together
   - Cannot split families across buildings
   - Family size must fit in unit capacity

2. **Singles Assignment**:
   - Can be assigned individually
   - Can share with other singles (roommates)
   - Can share family homes if space available

3. **Mixed Occupancy**:
   - Family takes priority for unit
   - Remaining capacity can be filled with singles
   - Example: Family of 4 in House (8 capacity) + 4 singles

### Assignment Priority

When housing becomes available:

1. **Immigration Queue** - New arrivals waiting for housing
2. **Relocation Queue** - Current citizens wanting better housing
3. **Priority Order**:
   - Class priority (configurable: elite-first or lower-first)
   - Family size (larger families first)
   - Wait time (longer waiters first)

### Crowding Effects

| Occupancy % | Satisfaction Modifier |
|-------------|----------------------|
| 0-50% | 1.1 (spacious bonus) |
| 51-75% | 1.0 (comfortable) |
| 76-100% | 0.95 (full) |
| 101-125% | 0.75 (crowded) |
| 126%+ | 0.5 (severely overcrowded) |

---

## Upgrade System

### Upgrade Paths

```
Cottage (0.5) → House (0.6) → Townhouse (0.7) → Manor (0.85) → Estate (1.0)
```

### Upgrade Requirements

1. **Building must be empty** (occupants temporarily relocated)
2. **Upgrade materials provided**
3. **Construction time** (varies by upgrade)
4. **Gold cost** (difference + labor)

### Upgrade Costs

| From | To | Materials | Gold | Time |
|------|-----|-----------|------|------|
| Cottage | House | +20 wood, +20 stone | 150 | 3 cycles |
| House | Townhouse | +10 wood, +20 stone, +10 glass | 200 | 4 cycles |
| Townhouse | Manor | +40 wood, +30 stone, +10 glass, +10 marble | 500 | 6 cycles |
| Manor | Estate | +100 wood, +70 stone, +30 glass, +20 marble, +10 gold_item | 1500 | 10 cycles |

### During Upgrade

- Occupants must relocate temporarily
- If no temporary housing: upgrade blocked OR occupants unhappy
- Building produces no rent during upgrade

---

## Immigration Flow

### Pre-Immigration Check

```
1. Immigration candidate appears (family or single)
2. Determine required housing class based on immigrant's class
3. Search for available housing:
   a. First: Ideal housing for their class
   b. Second: Acceptable housing for their class
   c. Third: Any housing (with penalty warning)
4. If housing found:
   a. Reserve housing
   b. Allow immigration
   c. Assign housing on arrival
   d. Start collecting rent
5. If no housing:
   a. Immigration blocked
   b. Show "Housing Needed: [Class] - [Type]" notification
   c. Candidate waits in queue (limited time)
   d. After timeout, candidate leaves
```

### Immigration Queue Display

```
┌─────────────────────────────────────────────────┐
│ IMMIGRATION QUEUE (3 waiting)                   │
├─────────────────────────────────────────────────┤
│ 1. Upper Family (4) - Needs: Manor/Townhouse   │
│    Wait: 5 cycles | Leaves in: 10 cycles       │
│                                                 │
│ 2. Middle Family (6) - Needs: House/Cottage    │
│    Wait: 3 cycles | Leaves in: 12 cycles       │
│                                                 │
│ 3. Lower Single - Needs: Any housing           │
│    Wait: 1 cycle | Leaves in: 14 cycles        │
└─────────────────────────────────────────────────┘
```

---

## UI Requirements

### 1. Housing Overview Panel

```
┌─────────────────────────────────────────────────────────────┐
│ HOUSING OVERVIEW                           [Filter] [Sort]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ CAPACITY BY CLASS                                           │
│ ┌─────────┬──────────┬──────────┬───────────┬────────────┐ │
│ │ Class   │ Capacity │ Occupied │ Available │ Rent/Cycle │ │
│ ├─────────┼──────────┼──────────┼───────────┼────────────┤ │
│ │ Elite   │    12    │    8     │     4     │    280     │ │
│ │ Upper   │    24    │   20     │     4     │    400     │ │
│ │ Middle  │    80    │   72     │     8     │    576     │ │
│ │ Lower   │   120    │  115     │     5     │    345     │ │
│ └─────────┴──────────┴──────────┴───────────┴────────────┘ │
│                                                             │
│ TOTAL RENT INCOME: 1,601 gold/cycle                        │
│                                                             │
│ HOUSING BUILDINGS                                           │
│ • 1 Estate (12 cap) - 8 occupied                           │
│ • 2 Manors (20 cap) - 18 occupied                          │
│ • 4 Townhouses (24 cap) - 22 occupied                      │
│ • 8 Houses (64 cap) - 58 occupied                          │
│ • 10 Cottages (60 cap) - 52 occupied                       │
│ • 3 Tenements (60 cap) - 57 occupied                       │
│ • 2 Lodges (24 cap) - 20 occupied                          │
│                                                             │
│ RELOCATION REQUESTS: 5                                      │
│ • 2 Middle→Upper (want Townhouse)                          │
│ • 3 Lower→Middle (want House)                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2. Building Housing Panel (when clicking housing building)

```
┌─────────────────────────────────────────────────────────────┐
│ MANOR - "Westwood Manor"                    [Rename] [Sell] │
├─────────────────────────────────────────────────────────────┤
│ Quality: ████████░░ 0.85 (Luxury)                          │
│ Capacity: 10 | Occupied: 7 | Rent: 140 gold/cycle          │
│                                                             │
│ OCCUPANTS                                                   │
│ ┌─────────────────────────────────────────────────────────┐│
│ │ 👤 Lord Pemberton (Upper) - Head of Household           ││
│ │ 👤 Lady Pemberton (Upper) - Spouse                      ││
│ │ 👤 Edward Pemberton (Upper) - Child                     ││
│ │ 👤 Clara Pemberton (Upper) - Child                      ││
│ │ 👤 Margaret (Middle) - Single, Roommate                 ││
│ │ 👤 Thomas (Middle) - Single, Roommate                   ││
│ │ 👤 James (Middle) - Single, Roommate                    ││
│ │ ░░ Empty Slot                                           ││
│ │ ░░ Empty Slot                                           ││
│ │ ░░ Empty Slot                                           ││
│ └─────────────────────────────────────────────────────────┘│
│                                                             │
│ [Assign Citizen] [Evict Selected] [Upgrade to Estate]      │
└─────────────────────────────────────────────────────────────┘
```

### 3. Citizen Housing Info (in Character Panel)

```
┌─────────────────────────────────────────────────────────────┐
│ HOUSING - Thomas Baker                                      │
├─────────────────────────────────────────────────────────────┤
│ Current: Westwood Manor (Luxury)                           │
│ Role: Single Roommate                                       │
│ Rent Paid: 20 gold/cycle                                   │
│                                                             │
│ HOUSING SATISFACTION                                        │
│ ├─ Basic Housing:    ████████████ 100% ✓                   │
│ ├─ Quality Housing:  ████████████ 100% ✓                   │
│ ├─ Luxury Housing:   ░░░░░░░░░░░░ N/A (Upper+ only)       │
│ └─ Prestige Housing: ░░░░░░░░░░░░ N/A (Elite only)        │
│                                                             │
│ Overall: SATISFIED                                          │
│                                                             │
│ [Request Relocation] [View Housing Options]                │
└─────────────────────────────────────────────────────────────┘
```

### 4. Build Menu - Housing Section

```
┌─────────────────────────────────────────────────────────────┐
│ BUILD > HOUSING                        [Filter by Class ▼] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ LOWER CLASS                                                 │
│ ┌──────────┬───────────┬──────────┬──────────┬───────────┐ │
│ │ Lodge    │ Cap: 12   │ Q: 0.3   │ R: 2/p   │ 50g      │ │
│ │ Tenement │ Cap: 20   │ Q: 0.4   │ R: 3/p   │ 150g     │ │
│ └──────────┴───────────┴──────────┴──────────┴───────────┘ │
│                                                             │
│ MIDDLE CLASS                                                │
│ ┌──────────┬───────────┬──────────┬──────────┬───────────┐ │
│ │ Cottage  │ Cap: 6    │ Q: 0.5   │ R: 5/p   │ 200g     │ │
│ │ House    │ Cap: 8    │ Q: 0.6   │ R: 8/p   │ 350g     │ │
│ │ Apartment│ Cap: 30   │ Q: 0.55  │ R: 6/p   │ 800g     │ │
│ └──────────┴───────────┴──────────┴──────────┴───────────┘ │
│                                                             │
│ UPPER CLASS                                                 │
│ ┌──────────┬───────────┬──────────┬──────────┬───────────┐ │
│ │ Townhouse│ Cap: 6    │ Q: 0.7   │ R: 12/p  │ 500g     │ │
│ │ Manor    │ Cap: 10   │ Q: 0.85  │ R: 20/p  │ 1000g    │ │
│ └──────────┴───────────┴──────────┴──────────┴───────────┘ │
│                                                             │
│ ELITE CLASS                                                 │
│ ┌──────────┬───────────┬──────────┬──────────┬───────────┐ │
│ │ Estate   │ Cap: 12   │ Q: 1.0   │ R: 35/p  │ 2500g    │ │
│ └──────────┴───────────┴──────────┴──────────┴───────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5. Housing Assignment Modal

Triggered when clicking "Assign Citizen" from the Building Housing Panel.

```
┌─────────────────────────────────────────────────────────────────────┐
│ ASSIGN CITIZEN TO: Westwood Manor                              [X] │
├─────────────────────────────────────────────────────────────────────┤
│ Available Slots: 3 of 10                                            │
│ Housing Quality: Luxury (0.85) | Target Class: Upper/Elite          │
│                                                                     │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ FILTER: [All ▼] [Unhoused ▼] [Class: Any ▼]    🔍 Search...    │ │
│ │ SORT BY: [Name ▼] [Class ▼] [Family Size ▼] [Wait Time ▼]      │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ ELIGIBLE CITIZENS                                          3 slots  │
│ ┌───────────────────────────────────────────────────────────┬─────┐ │
│ │ ☐ Harrison Family (Upper, 5 people)                       │ ⚠️  │ │
│ │   Lord Harrison, Lady Harrison, 3 children                │     │ │
│ │   Currently: Townhouse (wants upgrade) | Wait: 8 cycles   │     │ │
│ ├───────────────────────────────────────────────────────────┼─────┤ │
│ │ ☐ Elizabeth Moore (Upper, Single)                         │ ✓   │ │
│ │   Currently: Unhoused (Immigration Queue)                 │     │ │
│ │   Wait: 3 cycles | Leaves in: 12 cycles                   │     │ │
│ ├───────────────────────────────────────────────────────────┼─────┤ │
│ │ ☐ Robert Shaw (Middle, Single)                            │ ✓   │ │
│ │   Currently: Cottage (roommate) | Wants upgrade           │     │ │
│ │   Wait: 5 cycles                                          │     │ │
│ ├───────────────────────────────────────────────────────────┼─────┤ │
│ │ ☐ William Turner (Middle, Single)                         │ ✓   │ │
│ │   Currently: Unhoused (Immigration Queue)                 │     │ │
│ │   Wait: 1 cycle | Leaves in: 14 cycles                    │     │ │
│ └───────────────────────────────────────────────────────────┴─────┘ │
│                                                                     │
│ ⚠️ = Won't fit (family too large for available slots)              │
│ ✓ = Good fit for housing quality                                   │
│                                                                     │
│ SELECTION SUMMARY                                                   │
│ Selected: Elizabeth Moore, Robert Shaw (2 people)                   │
│ Remaining Slots After: 1                                            │
│                                                                     │
│                              [Cancel]  [Assign Selected (2)]        │
└─────────────────────────────────────────────────────────────────────┘
```

**Assignment Modal Features:**
- Shows housing details (quality, target class, available slots)
- Filter options for citizen list
- Sort options for organizing candidates
- Visual indicators for fit (✓ good fit, ⚠️ won't fit)
- Multi-select for batch assignment
- Selection summary before confirming
- Family grouping (families shown as single selectable unit)

### 6. Filter & Sort Options

#### Housing Overview Filters

```
┌─────────────────────────────────────────────────────────────────────┐
│ FILTER BY:                                                          │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────────┐   │
│ │ Type ▼      │ │ Class ▼     │ │ Occupancy ▼ │ │ Quality ▼     │   │
│ │ ☐ All       │ │ ☐ All       │ │ ☐ All       │ │ ☐ All         │   │
│ │ ☑ Lodge     │ │ ☑ Elite     │ │ ☐ Empty     │ │ ☐ Poor        │   │
│ │ ☑ Tenement  │ │ ☑ Upper     │ │ ☐ Partial   │ │ ☐ Basic       │   │
│ │ ☑ Cottage   │ │ ☑ Middle    │ │ ☐ Full      │ │ ☐ Good        │   │
│ │ ☑ House     │ │ ☑ Lower     │ │ ☐ Overcrowd │ │ ☐ Luxury      │   │
│ │ ☑ Apartment │ │             │ │             │ │ ☐ Masterwork  │   │
│ │ ☑ Townhouse │ │             │ │             │ │               │   │
│ │ ☑ Manor     │ │             │ │             │ │               │   │
│ │ ☑ Estate    │ │             │ │             │ │               │   │
│ └─────────────┘ └─────────────┘ └─────────────┘ └───────────────┘   │
│                                                                     │
│ SORT BY:                                                            │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ ○ Name (A-Z)        ○ Occupancy (Low→High)   ○ Rent (High→Low) │ │
│ │ ○ Type              ○ Occupancy (High→Low)   ○ Rent (Low→High) │ │
│ │ ○ Quality (High)    ○ Available Slots        ○ Construction    │ │
│ │ ○ Quality (Low)     ○ Crowding Level                           │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│                                    [Reset Filters]  [Apply]         │
└─────────────────────────────────────────────────────────────────────┘
```

#### Citizen Housing Filters (in Assignment Modal)

| Filter | Options | Description |
|--------|---------|-------------|
| Housing Status | All, Unhoused, Housed, Wants Relocation | Current housing situation |
| Class | Elite, Upper, Middle, Lower, Any | Social class filter |
| Family Status | All, Singles Only, Families Only | Occupancy type |
| Fit Status | All, Good Fit, Acceptable, Poor Fit | Compatibility with building |
| Queue Type | All, Immigration, Relocation | Where they're waiting |

| Sort | Description |
|------|-------------|
| Name (A-Z) | Alphabetical by citizen name |
| Class (High→Low) | Elite first, then Upper, Middle, Lower |
| Class (Low→High) | Lower first, then Middle, Upper, Elite |
| Family Size | Largest families first |
| Wait Time | Longest waiters first (priority) |
| Urgency | Immigration timeout (closest to leaving first) |
| Satisfaction | Lowest satisfaction first |

### 7. Integration with Existing Panels

Housing information should appear contextually across multiple existing UI panels:

#### 7.1 Main HUD Integration

```
┌─────────────────────────────────────────────────────────────────────┐
│ CRAVETOWN                              Cycle: 142  │ Gold: 5,230    │
├─────────────────────────────────────────────────────────────────────┤
│ Pop: 215/264  │  Happiness: 72%  │  🏠 Housing: 215/264 (81%)      │
│                                      └─ 12 waiting, 5 relocating    │
└─────────────────────────────────────────────────────────────────────┘
```

- **Housing indicator** in main HUD showing occupied/capacity
- Click opens Housing Overview Panel
- Warning color if housing critically low or immigration blocked

#### 7.2 Character Detail Panel - Housing Tab

When viewing any citizen, add a Housing tab alongside existing tabs:

```
┌─────────────────────────────────────────────────────────────────────┐
│ THOMAS BAKER                                                   [X]  │
├──────────┬──────────┬──────────┬──────────┬──────────┬─────────────┤
│ Overview │ Cravings │ Work     │ Family   │ HOUSING  │ History     │
├──────────┴──────────┴──────────┴──────────┴──────────┴─────────────┤
│                                                                     │
│ CURRENT RESIDENCE                                                   │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ 🏠 Westwood Manor                                    [Go To ➜]  │ │
│ │ Type: Manor | Quality: Luxury (0.85)                            │ │
│ │ Role: Single Roommate | Unit: Main House                        │ │
│ │ Co-habitants: Lord Pemberton (family of 4), 2 other singles     │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ HOUSING ECONOMICS                                                   │
│ ├─ Rent: 20 gold/cycle                                             │
│ ├─ Income: 45 gold/cycle                                           │
│ ├─ Rent-to-Income: 44% (Comfortable)                               │
│ └─ Rent Status: Paid through Cycle 145                             │
│                                                                     │
│ HOUSING SATISFACTION BREAKDOWN                                      │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Dimension           │ Enabled │ Fulfillment │ Status            │ │
│ ├─────────────────────┼─────────┼─────────────┼───────────────────┤ │
│ │ Basic Shelter       │   ✓     │  40/40      │ ████████████ 100% │ │
│ │ Quality Housing     │   ✓     │  35/35      │ ████████████ 100% │ │
│ │ Luxury Housing      │   ✗     │   -/30      │ (Upper+ only)     │ │
│ │ Prestige Housing    │   ✗     │   -/40      │ (Elite only)      │ │
│ ├─────────────────────┼─────────┼─────────────┼───────────────────┤ │
│ │ Weather Protection  │   ✓     │  32/35      │ █████████░░░  91% │ │
│ │ Warmth              │   ✓     │  28/30      │ █████████░░░  93% │ │
│ └─────────────────────┴─────────┴─────────────┴───────────────────┘ │
│                                                                     │
│ HOUSING PREFERENCES                                                 │
│ Ideal: Townhouse, House | Acceptable: Cottage, Manor               │
│ Current Assessment: ABOVE EXPECTATIONS (living in Manor)           │
│                                                                     │
│                    [Request Relocation] [View All Housing]          │
└─────────────────────────────────────────────────────────────────────┘
```

#### 7.3 Building Info Panel - Housing Section

When clicking any housing building on the map:

```
┌─────────────────────────────────────────────────────────────────────┐
│ 🏠 WESTWOOD MANOR                              [Rename] [Demolish]  │
├─────────────────────────────────────────────────────────────────────┤
│ Type: Manor | Category: Housing                                     │
│                                                                     │
│ HOUSING STATUS                                                      │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Quality:    ████████░░ 0.85 (Luxury)                            │ │
│ │ Occupancy:  ███████░░░ 7/10 (70%)                               │ │
│ │ Rent/Cycle: 140 gold (7 occupants × 20 gold)                    │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ TARGET CLASS: Upper, Elite                                          │
│ UPGRADE PATH: Manor → Estate (requires 1500 gold + materials)      │
│                                                                     │
│ OCCUPANTS (7)                                        [Manage ➜]     │
│ • Pemberton Family (4) - Upper Class                               │
│ • Margaret (Single) - Middle Class                                 │
│ • Thomas (Single) - Middle Class                                   │
│ • James (Single) - Middle Class                                    │
│                                                                     │
│ AVAILABLE SLOTS: 3                                                  │
│                                                                     │
│           [Assign Citizens]  [View Details]  [Upgrade]              │
└─────────────────────────────────────────────────────────────────────┘
```

#### 7.4 Immigration Panel Integration

When viewing immigration candidates, show housing availability:

```
┌─────────────────────────────────────────────────────────────────────┐
│ IMMIGRATION                                                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ HOUSING AVAILABILITY FOR IMMIGRANTS                                 │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Class   │ Waiting │ Available Slots │ Status                    │ │
│ ├─────────┼─────────┼─────────────────┼───────────────────────────┤ │
│ │ Elite   │    1    │       4         │ ✓ Can accept              │ │
│ │ Upper   │    2    │       3         │ ✓ Can accept              │ │
│ │ Middle  │    5    │       2         │ ⚠️ 3 blocked              │ │
│ │ Lower   │    4    │       0         │ ❌ All blocked            │ │
│ └─────────┴─────────┴─────────────────┴───────────────────────────┘ │
│                                                                     │
│ ⚠️ BUILD MORE HOUSING: 7 immigrants blocked due to housing shortage│
│ Recommended: 2 Cottages or 1 Tenement for Lower/Middle class       │
│                                                                     │
│ IMMIGRATION QUEUE                                                   │
│ ...                                                                 │
└─────────────────────────────────────────────────────────────────────┘
```

#### 7.5 Notifications Integration

Housing-related notifications that appear in the notification system:

| Event | Priority | Message | Action |
|-------|----------|---------|--------|
| Immigration Blocked | High | "5 immigrants waiting - no housing available" | Open Housing Overview |
| Housing Full | Medium | "All Middle-class housing is full" | Open Build Menu > Housing |
| Citizen Homeless | Critical | "Thomas Baker is now homeless!" | Open Citizen Panel |
| Rent Unpaid | Medium | "3 citizens behind on rent" | Open Rent Management |
| Relocation Available | Low | "Housing available for 2 relocation requests" | Open Assignment Modal |
| Building Upgraded | Info | "Cottage upgraded to House" | Go to Building |

#### 7.6 Satisfaction Panel Integration

In the overall satisfaction breakdown, add housing as a visible component:

```
┌─────────────────────────────────────────────────────────────────────┐
│ TOWN SATISFACTION: 72%                                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ SATISFACTION BREAKDOWN                                              │
│ ├─ Biological (Food, Water, Health)     ████████░░  78%            │
│ ├─ Safety (Security, HOUSING)           ███████░░░  68%  ⚠️        │
│ │   └─ Housing Component                ██████░░░░  62%            │
│ ├─ Touch (Comfort, Clothing)            ████████░░  82%            │
│ ├─ Psychological (Purpose, Peace)       ███████░░░  71%            │
│ ├─ Status (Reputation)                  ██████░░░░  65%            │
│ └─ Social (Friendship)                  ████████░░  75%            │
│                                                                     │
│ ⚠️ HOUSING ISSUES:                                                  │
│ • 12 citizens in substandard housing for their class               │
│ • 5 citizens requesting relocation                                 │
│ • 3 overcrowded buildings                                          │
│                                                                     │
│                              [View Housing Details]                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Building Fulfillment Vectors

### Concept

Just like commodities have fulfillment vectors that satisfy cravings when consumed, **buildings also have fulfillment vectors** that satisfy cravings by their existence. Housing buildings fulfill shelter-related cravings for their occupants every cycle.

### Key Differences from Commodity Vectors

| Aspect | Commodities | Buildings |
|--------|-------------|-----------|
| Application | On consumption | Continuous (per cycle) |
| Scope | Per citizen who consumes | All occupants |
| Degradation | One-time or durability-based | Permanent (until destroyed) |
| Scaling | Quantity consumed | Quality tier × crowding modifier |

### Building Fulfillment Vector Structure

Building fulfillment vectors follow the same schema as commodities:

```json
{
  "building_id": "manor",
  "fulfillmentVector": {
    "coarse": [0, 35, 8, 5, 10, 0, 0, 0, 0],
    "fine": {
      "safety_shelter_housing_basic": 40,
      "safety_shelter_housing_good": 35,
      "safety_shelter_housing_luxury": 30,
      "safety_shelter_weather": 25,
      "safety_shelter_warmth": 20,
      "touch_furniture_functional": 15,
      "psychological_peace_relaxation": 12,
      "psychological_peace_solitude": 10,
      "status_reputation_display": 20
    }
  },
  "tags": ["housing", "shelter", "luxury", "upper_class"],
  "qualityMultipliers": {
    "poor": 0.5,
    "basic": 1.0,
    "good": 1.3,
    "luxury": 1.6,
    "masterwork": 2.0
  }
}
```

### Housing Building Fulfillment Vectors

| Building | Basic | Good | Luxury | Prestige | Weather | Warmth | Status |
|----------|-------|------|--------|----------|---------|--------|--------|
| Lodge | 25 | 0 | 0 | 0 | 15 | 10 | 0 |
| Tenement | 30 | 0 | 0 | 0 | 18 | 12 | 0 |
| Cottage | 35 | 20 | 0 | 0 | 22 | 18 | 5 |
| House | 40 | 30 | 0 | 0 | 28 | 22 | 10 |
| Apartment | 35 | 25 | 0 | 0 | 25 | 20 | 5 |
| Townhouse | 40 | 35 | 20 | 0 | 30 | 25 | 15 |
| Manor | 40 | 35 | 30 | 0 | 32 | 28 | 25 |
| Estate | 40 | 35 | 35 | 40 | 35 | 30 | 40 |

### Complete Building Fulfillment Vectors JSON

```json
{
  "buildings": {
    "lodge": {
      "id": "lodge",
      "fulfillmentVector": {
        "coarse": [0, 15, 2, 0, 0, 0, 0, 0, 0],
        "fine": {
          "safety_shelter_housing_basic": 25,
          "safety_shelter_weather": 15,
          "safety_shelter_warmth": 10,
          "touch_furniture_functional": 5
        }
      },
      "tags": ["housing", "shelter", "poor", "lower_class", "communal"],
      "qualityMultipliers": {
        "poor": 0.6,
        "basic": 1.0,
        "good": 1.2
      }
    },
    "tenement": {
      "id": "tenement",
      "fulfillmentVector": {
        "coarse": [0, 18, 3, 0, 0, 0, 0, 0, 0],
        "fine": {
          "safety_shelter_housing_basic": 30,
          "safety_shelter_weather": 18,
          "safety_shelter_warmth": 12,
          "touch_furniture_functional": 8
        }
      },
      "tags": ["housing", "shelter", "basic", "lower_class"],
      "qualityMultipliers": {
        "poor": 0.6,
        "basic": 1.0,
        "good": 1.2
      }
    },
    "cottage": {
      "id": "cottage",
      "fulfillmentVector": {
        "coarse": [0, 22, 5, 2, 2, 0, 0, 0, 0],
        "fine": {
          "safety_shelter_housing_basic": 35,
          "safety_shelter_housing_good": 20,
          "safety_shelter_weather": 22,
          "safety_shelter_warmth": 18,
          "touch_furniture_functional": 12,
          "psychological_peace_relaxation": 8,
          "status_reputation_display": 5
        }
      },
      "tags": ["housing", "shelter", "basic", "lower_class", "middle_class"],
      "qualityMultipliers": {
        "poor": 0.5,
        "basic": 1.0,
        "good": 1.3,
        "luxury": 1.5
      }
    },
    "house": {
      "id": "house",
      "fulfillmentVector": {
        "coarse": [0, 28, 8, 5, 5, 0, 0, 0, 0],
        "fine": {
          "safety_shelter_housing_basic": 40,
          "safety_shelter_housing_good": 30,
          "safety_shelter_weather": 28,
          "safety_shelter_warmth": 22,
          "touch_furniture_functional": 15,
          "psychological_peace_relaxation": 12,
          "psychological_peace_solitude": 8,
          "status_reputation_display": 10
        }
      },
      "tags": ["housing", "shelter", "good", "middle_class"],
      "qualityMultipliers": {
        "poor": 0.5,
        "basic": 1.0,
        "good": 1.4,
        "luxury": 1.8
      }
    },
    "apartment_block": {
      "id": "apartment_block",
      "fulfillmentVector": {
        "coarse": [0, 25, 6, 3, 3, 2, 0, 0, 0],
        "fine": {
          "safety_shelter_housing_basic": 35,
          "safety_shelter_housing_good": 25,
          "safety_shelter_weather": 25,
          "safety_shelter_warmth": 20,
          "touch_furniture_functional": 12,
          "psychological_peace_relaxation": 8,
          "social_friendship_casual": 5,
          "status_reputation_display": 5
        }
      },
      "tags": ["housing", "shelter", "good", "middle_class", "efficient"],
      "qualityMultipliers": {
        "poor": 0.5,
        "basic": 1.0,
        "good": 1.3,
        "luxury": 1.6
      }
    },
    "townhouse": {
      "id": "townhouse",
      "fulfillmentVector": {
        "coarse": [0, 32, 10, 8, 8, 2, 0, 0, 0],
        "fine": {
          "safety_shelter_housing_basic": 40,
          "safety_shelter_housing_good": 35,
          "safety_shelter_housing_luxury": 20,
          "safety_shelter_weather": 30,
          "safety_shelter_warmth": 25,
          "touch_furniture_functional": 18,
          "touch_sensory_luxury": 8,
          "psychological_peace_relaxation": 15,
          "psychological_peace_solitude": 12,
          "social_friendship_intimate": 5,
          "status_reputation_display": 15
        }
      },
      "tags": ["housing", "shelter", "good", "middle_class", "upper_class"],
      "qualityMultipliers": {
        "good": 0.8,
        "luxury": 1.2,
        "masterwork": 1.6
      }
    },
    "manor": {
      "id": "manor",
      "fulfillmentVector": {
        "coarse": [0, 35, 12, 10, 12, 3, 5, 0, 0],
        "fine": {
          "safety_shelter_housing_basic": 40,
          "safety_shelter_housing_good": 35,
          "safety_shelter_housing_luxury": 30,
          "safety_shelter_weather": 32,
          "safety_shelter_warmth": 28,
          "touch_furniture_functional": 20,
          "touch_sensory_luxury": 15,
          "psychological_peace_relaxation": 18,
          "psychological_peace_solitude": 15,
          "psychological_entertainment_arts": 10,
          "social_friendship_intimate": 8,
          "exotic_items_novelty": 10,
          "status_reputation_display": 25
        }
      },
      "tags": ["housing", "shelter", "luxury", "upper_class", "elite_class"],
      "qualityMultipliers": {
        "good": 0.7,
        "luxury": 1.0,
        "masterwork": 1.5
      }
    },
    "estate": {
      "id": "estate",
      "fulfillmentVector": {
        "coarse": [0, 40, 15, 12, 20, 5, 10, 15, 0],
        "fine": {
          "safety_shelter_housing_basic": 40,
          "safety_shelter_housing_good": 35,
          "safety_shelter_housing_luxury": 35,
          "safety_shelter_housing_prestige": 40,
          "safety_shelter_weather": 35,
          "safety_shelter_warmth": 30,
          "touch_furniture_functional": 25,
          "touch_sensory_luxury": 25,
          "psychological_peace_relaxation": 25,
          "psychological_peace_solitude": 20,
          "psychological_entertainment_arts": 15,
          "psychological_entertainment_games": 10,
          "social_friendship_intimate": 12,
          "exotic_items_novelty": 15,
          "shiny_decorative_art": 15,
          "status_reputation_display": 40
        }
      },
      "tags": ["housing", "shelter", "masterwork", "elite_class", "prestigious"],
      "qualityMultipliers": {
        "luxury": 0.8,
        "masterwork": 1.2
      }
    }
  }
}
```

### How Building Fulfillment is Applied

```
Every cycle, for each occupied housing building:

1. Get building's base fulfillment vector
2. Apply quality multiplier based on building's quality tier
3. Apply crowding modifier (less fulfillment if overcrowded)
4. For each occupant:
   a. Check which housing dimensions are enabled for their class
   b. Add applicable fulfillment to their satisfaction
   c. Apply any trait modifiers
```

### Calculation Example

```
Citizen: Thomas (Middle Class)
Housing: Manor (Luxury quality)
Crowding: 70% (comfortable)

Enabled Dimensions for Middle Class:
- safety_shelter_housing_basic ✓
- safety_shelter_housing_good ✓
- safety_shelter_housing_luxury ✗ (needs Upper+)
- safety_shelter_housing_prestige ✗ (needs Elite)

Base Fulfillment from Manor:
- housing_basic: 40
- housing_good: 35
- housing_luxury: 30 (not applied - dimension not enabled)

Quality Multiplier (Luxury): 1.0
Crowding Modifier (70%): 1.0

Final Fulfillment Applied:
- housing_basic: 40 × 1.0 × 1.0 = 40
- housing_good: 35 × 1.0 × 1.0 = 35

Thomas receives 75 total housing fulfillment points
```

### Integration with Fulfillment Vectors File

Building fulfillment vectors should be stored in a separate file or section:

**Option A**: Add to `fulfillment_vectors.json` with a new `buildings` key (alongside `commodities`)

**Option B**: Create `building_fulfillment_vectors.json` as a separate file

Recommended: **Option A** - keeps all fulfillment data in one place with consistent schema.

```json
{
  "version": "1.2.0",
  "note": "Fulfillment vectors for commodities and buildings",
  "commodities": { ... },
  "buildings": {
    "lodge": { ... },
    "house": { ... },
    ...
  }
}
```

---

## Data Model Updates

### Building Type Housing Config

```typescript
interface HousingConfig {
  // Capacity
  maxOccupants: number;           // Total people capacity
  unitsCount: number;             // Number of units (1 for single-family, 4+ for apartments)

  // Class compatibility
  targetClasses: string[];        // Classes this housing is designed for
  acceptableClasses: string[];    // Classes that can live here (broader)

  // Quality
  housingQuality: number;         // 0.0 to 1.0
  qualityTier: 'poor' | 'basic' | 'good' | 'luxury' | 'masterwork';

  // Economics
  rentPerOccupant: number;        // Gold per cycle per person

  // Upgrades
  upgradeableTo?: string;         // Building type ID
  upgradeCost?: {
    materials: Record<string, number>;
    gold: number;
    cycles: number;
  };
}
```

### Character Class Housing Preferences

```typescript
interface HousingPreferences {
  // Ideal housing types (in order of preference)
  idealHousing: string[];         // e.g., ["estate", "manor"]

  // Acceptable housing types
  acceptableHousing: string[];    // e.g., ["manor", "townhouse"]

  // Housing they will refuse (won't immigrate to)
  rejectedHousing: string[];      // e.g., ["lodge", "tenement"]

  // Craving dimensions enabled for this class
  enabledHousingCravings: string[]; // e.g., ["housing_basic", "housing_good"]

  // Minimum quality before satisfaction penalty
  minimumQuality: number;         // e.g., 0.7 for upper class
}
```

### Housing Assignment

```typescript
interface HousingAssignment {
  buildingId: string;           // The housing building
  unitIndex: number;            // Which unit (0 for single-unit buildings)

  // Occupants
  headOfHousehold?: string;     // Citizen ID (if family)
  occupants: string[];          // All citizen IDs living here
  isFamily: boolean;            // Family unit or roommates

  // Tracking
  assignedAt: number;           // Cycle when assigned
  rentPaidThrough: number;      // Last cycle rent was paid

  // Calculated
  crowdingLevel: number;        // occupants / capacity
  satisfactionModifier: number; // Based on quality match + crowding
}
```

---

## Implementation Phases

### Phase 1: Data Model & Dimensions
1. Add housing fine dimensions to dimension_definitions.json
2. Add housingPreferences to character_classes.json
3. Add housingConfig to building types
4. Create HousingAssignment type

### Phase 2: Building Types
1. Update existing cottage
2. Add: lodge, tenement, house, townhouse, manor, estate, apartment_block
3. Create info-system UI for housing config editor

### Phase 3: Core Logic
1. Housing assignment system
2. Rent collection system
3. Immigration gating by housing
4. Relocation queue system

### Phase 4: Craving Integration
1. Housing dimension fulfillment calculation
2. Class-based dimension enablement
3. Satisfaction impact from housing

### Phase 5: Upgrade System
1. Upgrade path validation
2. Temporary relocation during upgrade
3. Material/gold/time requirements

### Phase 6: UI
1. Housing overview panel
2. Building housing management
3. Citizen housing info
4. Build menu housing section
5. Immigration queue display

---

## Summary

The housing system creates meaningful strategic decisions:

| Decision | Trade-off |
|----------|-----------|
| Build cheap housing | More capacity, but lower class citizens, less rent |
| Build luxury housing | Attracts wealthy, high rent, but expensive to build |
| Upgrade vs new build | Upgrade is cheaper but requires vacancy |
| Class balance | Mixed classes = diverse economy, but housing complexity |

Key mechanics:
- **Housing gates immigration** - must build before growth
- **Rent provides income** - better housing = more revenue
- **Class aspirations drive relocation** - upward mobility needs housing
- **Multiple craving dimensions** - enabled progressively by class
- **Upgrade paths** - grow housing with your citizens
