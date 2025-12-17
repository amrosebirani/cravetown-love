# Specialized Starting Towns Design

**Created:** 2025-12-17
**Status:** Concept Design
**Related Documents:**
- [Marketplace Economy Design](marketplace_economy_design.md)
- [Meeting Notes Dec 2](../meetings/meeting_notes_2025-12-02_adwait.md) - Trade Foundation
- [Meeting Notes Dec 14](../meetings/meeting_notes_2025-12-14_adwait.md) - Initial discussion

---

## Executive Summary

Every new town starts with **one pre-built supply chain** - a complete production pipeline from natural resources to final commodity. This creates immediate **town identity**, natural **trade specialization**, and a clear **gameplay direction**. Towns become known for their specialty (Samosa Town, Mining Town, Jalebi Town) and trade their surplus on an open marketplace.

---

## 1. Core Concept

### 1.1 The Problem with Blank Slate Starts
- Player overwhelmed with choices
- No clear direction or identity
- All towns feel the same
- Trade has no natural basis (everyone produces everything)

### 1.2 The Specialized Start Solution
```
New Town = Starting Resources + One Complete Supply Chain + Identity

Where Supply Chain includes:
- Natural resource source (farm, mine, forest, water)
- Processing buildings (mill, forge, kitchen)
- Final product producer (bakery, smithy, street food stall)
- Initial workers assigned
```

### 1.3 Gameplay Loop Evolution
```
Phase 1: OPTIMIZE
  └─► Get your starting chain running efficiently
  └─► Build surplus of your specialty commodity

Phase 2: TRADE
  └─► Export surplus to marketplace
  └─► Import commodities you can't produce
  └─► Meet citizen cravings through trade

Phase 3: EXPAND
  └─► Add new supply chains
  └─► Attract specialized immigrants
  └─► Diversify or double-down on specialty

Phase 4: COMPETE/COOPERATE
  └─► Compete for market share in your specialty
  └─► Form trade agreements with complementary towns
  └─► React to market price fluctuations
```

---

## 2. Example Specialized Towns

### 2.1 Samosa Town 🥟
**Identity:** Street food capital, the snack hub

**Starting Supply Chain:**
```
Natural Resources          Processing              Final Product
─────────────────         ──────────────          ─────────────
Potato Farm ────────┐
                    ├───► Samosa Kitchen ───────► SAMOSA
Wheat Farm ─────────┤                              (exports)
(for flour)         │
                    │
Groundnut Farm ─────┘
(for oil)
```

**Starting Buildings:**
- 1x Potato Farm (2 workers)
- 1x Wheat Farm (2 workers)
- 1x Groundnut Farm (1 worker)
- 1x Mill (1 worker) - converts wheat to flour
- 1x Oil Press (1 worker) - converts groundnut to oil
- 1x Samosa Kitchen (2 workers)

**Starting Citizens:** 9-12 (workers + families)

**Trade Profile:**
- **Exports:** Samosas (high volume, moderate price)
- **Imports:** Clothing, tools, luxury items, variety foods

**Expansion Paths:**
- More street food (pakora, kachori)
- Restaurant district (higher quality versions)
- Spice trade (import spices, make premium samosas)

---

### 2.2 Mining Town ⛏️
**Identity:** Industrial backbone, raw material supplier

**Starting Supply Chain:**
```
Natural Resources          Processing              Final Product
─────────────────         ──────────────          ─────────────
Iron Mine ──────────────► Forge ─────────────────► IRON TOOLS
(requires mountain        (smelting + smithing)    (exports)
 terrain)
```

**Starting Buildings:**
- 1x Iron Mine (3 workers)
- 1x Forge (2 workers)
- 1x Basic Housing (for miners)

**Starting Citizens:** 8-10

**Trade Profile:**
- **Exports:** Iron tools, raw iron ore
- **Imports:** Food (almost all types), clothing, entertainment

**Expansion Paths:**
- Copper/Gold mining (different ores)
- Weapons manufacturing
- Jewelry (gold + gems)
- Coal mining for fuel

---

### 2.3 Jalebi Town 🍯
**Identity:** Sweet town, dessert paradise

**Starting Supply Chain:**
```
Natural Resources          Processing              Final Product
─────────────────         ──────────────          ─────────────
Sugarcane Farm ────────► Sugar Mill ─────┐
                                         ├──► Sweet Shop ──► JALEBI
Wheat Farm ────────────► Flour Mill ─────┤                   (exports)
                                         │
Beekeeping (optional) ──► Honey ─────────┘
```

**Starting Buildings:**
- 1x Sugarcane Farm (2 workers)
- 1x Wheat Farm (2 workers)
- 1x Sugar Mill (1 worker)
- 1x Flour Mill (1 worker)
- 1x Sweet Shop (2 workers)

**Starting Citizens:** 10-12

**Trade Profile:**
- **Exports:** Jalebi, sugar (raw commodity)
- **Imports:** Savory foods, tools, clothing

**Expansion Paths:**
- More sweets (gulab jamun, laddu, barfi)
- Sugar refinery (export refined sugar)
- Bakery goods (cakes, pastries)

---

### 2.4 Poha Town 🍚
**Identity:** Breakfast capital, morning energy supplier

**Starting Supply Chain:**
```
Natural Resources          Processing              Final Product
─────────────────         ──────────────          ─────────────
Rice Paddy ─────────────► Rice Mill ────┐
                         (to flattened  │
                          rice)         ├──► Poha Kitchen ──► POHA
                                        │                     (exports)
Groundnut Farm ─────────► Oil Press ────┤
                                        │
Onion Farm ─────────────────────────────┘
```

**Starting Buildings:**
- 1x Rice Paddy (2 workers)
- 1x Groundnut Farm (1 worker)
- 1x Onion Farm (1 worker)
- 1x Rice Mill (1 worker)
- 1x Oil Press (1 worker)
- 1x Poha Kitchen (2 workers)

**Starting Citizens:** 10-12

**Trade Profile:**
- **Exports:** Poha, rice, onions
- **Imports:** Sweets, meat products, tools

**Expansion Paths:**
- Other rice dishes (khichdi, pulao)
- Rice trading hub
- Vegetable farming expansion

---

### 2.5 More Town Archetypes

| Town Type | Primary Export | Key Resource | Terrain Preference |
|-----------|---------------|--------------|-------------------|
| **Fishing Village** | Fish, dried fish | Water | Coastal/River |
| **Textile Town** | Cloth, clothing | Cotton | Plains |
| **Pottery Town** | Pottery, bricks | Clay | River delta |
| **Timber Town** | Wood, furniture | Forest | Forest |
| **Spice Town** | Spices, masalas | Various crops | Fertile plains |
| **Dairy Town** | Milk, ghee, paneer | Cattle | Grassland |
| **Brick Town** | Bricks, tiles | Clay, coal | River + hills |
| **Herbal Town** | Medicines, herbs | Forest herbs | Forest edge |

---

## 3. Inter-Town Marketplace

### 3.1 Market Structure
```
┌─────────────────────────────────────────────────────────────┐
│                    OPEN MARKETPLACE                          │
│                                                              │
│   ┌───────────┐   ┌───────────┐   ┌───────────┐            │
│   │ Samosa    │   │ Mining    │   │ Jalebi    │   ...      │
│   │ Town      │   │ Town      │   │ Town      │            │
│   │           │   │           │   │           │            │
│   │ Sells:    │   │ Sells:    │   │ Sells:    │            │
│   │ - Samosas │   │ - Tools   │   │ - Jalebi  │            │
│   │           │   │ - Iron    │   │ - Sugar   │            │
│   │ Buys:     │   │ Buys:     │   │ Buys:     │            │
│   │ - Tools   │   │ - Food    │   │ - Tools   │            │
│   │ - Clothes │   │ - Clothes │   │ - Savory  │            │
│   └───────────┘   └───────────┘   └───────────┘            │
│                                                              │
│   Price Discovery: Supply/Demand across all towns           │
│   Settlement: Gold or barter                                │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Trade Mechanics

**Listing Surplus:**
```lua
-- Town automatically lists surplus commodities
function Town:UpdateMarketListings()
    for commodity, count in pairs(self.inventory) do
        local consumption = self:GetAverageConsumption(commodity)
        local production = self:GetAverageProduction(commodity)
        local surplus = count - (consumption * BUFFER_DAYS)

        if surplus > 0 then
            Market:ListForSale(self.id, commodity, surplus, self:GetAskPrice(commodity))
        end
    end
end
```

**Importing Needs:**
```lua
-- Town automatically bids on needed commodities
function Town:UpdateMarketBids()
    local unmetCravings = self:GetAggregateUnmetCravings()

    for craving, intensity in pairs(unmetCravings) do
        local commodities = CommodityCache:GetCommoditiesFulfilling(craving)
        for _, commodity in ipairs(commodities) do
            if not self:CanProduce(commodity) then
                local bidPrice = self:CalculateBidPrice(commodity, intensity)
                Market:PlaceBid(self.id, commodity, bidPrice)
            end
        end
    end
end
```

**Price Discovery:**
```lua
-- Global market price based on all listings
function Market:CalculatePrice(commodity)
    local totalSupply = 0
    local totalDemand = 0

    for _, listing in ipairs(self.listings[commodity]) do
        totalSupply = totalSupply + listing.quantity
    end

    for _, bid in ipairs(self.bids[commodity]) do
        totalDemand = totalDemand + bid.quantity
    end

    -- Supply/demand ratio determines price movement
    local ratio = totalDemand / math.max(totalSupply, 1)
    return self.basePrice[commodity] * ratio
end
```

### 3.3 Trade Routes & Caravans (Future)
```
Physical trade representation:
- Caravans travel between towns
- Travel time based on distance
- Risk of banditry (future feature)
- Trade route infrastructure improvements
```

---

## 4. Town Selection UI

### 4.1 New Game Flow
```
1. Select Difficulty
       ↓
2. SELECT TOWN SPECIALTY ← New screen
   ┌─────────────────────────────────────────────────────┐
   │                                                      │
   │  Choose Your Town's Specialty                       │
   │                                                      │
   │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
   │  │ 🥟       │  │ ⛏️       │  │ 🍯       │          │
   │  │ SAMOSA   │  │ MINING   │  │ JALEBI   │          │
   │  │ TOWN     │  │ TOWN     │  │ TOWN     │          │
   │  │          │  │          │  │          │          │
   │  │ Street   │  │ Industrial│  │ Sweet    │          │
   │  │ Food Hub │  │ Backbone │  │ Paradise │          │
   │  └──────────┘  └──────────┘  └──────────┘          │
   │                                                      │
   │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
   │  │ 🍚       │  │ 🐟       │  │ 🧵       │          │
   │  │ POHA     │  │ FISHING  │  │ TEXTILE  │          │
   │  │ TOWN     │  │ VILLAGE  │  │ TOWN     │          │
   │  └──────────┘  └──────────┘  └──────────┘          │
   │                                                      │
   │  [MORE SPECIALTIES...]                              │
   │                                                      │
   └─────────────────────────────────────────────────────┘
       ↓
3. Town Name Entry
       ↓
4. Game Starts with Pre-Built Supply Chain
```

### 4.2 Specialty Preview
When hovering/selecting a specialty, show:
```
┌─────────────────────────────────────────────────────────┐
│ SAMOSA TOWN                                             │
│                                                         │
│ You start with a complete samosa production chain:     │
│                                                         │
│ 🌾 Farms: Potato, Wheat, Groundnut                     │
│ 🏭 Processing: Mill, Oil Press                          │
│ 👨‍🍳 Production: Samosa Kitchen                          │
│                                                         │
│ Starting Citizens: 12                                   │
│ Starting Gold: 500                                      │
│                                                         │
│ TRADE FOCUS:                                            │
│ Export: Samosas 🥟                                      │
│ Import: Tools, Clothing, Variety Foods                 │
│                                                         │
│ EXPANSION PATHS:                                        │
│ • More street food varieties                           │
│ • Restaurant district                                   │
│ • Spice trading                                         │
│                                                         │
│ DIFFICULTY: ★★☆☆☆ (Easy - high demand product)        │
└─────────────────────────────────────────────────────────┘
```

---

## 5. Balance Considerations

### 5.1 Specialty Difficulty Ratings

| Specialty | Difficulty | Reason |
|-----------|------------|--------|
| Food towns | Easy | High, constant demand |
| Mining towns | Medium | Lower demand, but essential |
| Textile towns | Medium | Moderate demand, complex chain |
| Luxury towns | Hard | Low demand, price volatile |

### 5.2 Market Balance

**Preventing Monopolies:**
```lua
-- Price ceiling kicks in if one town dominates supply
if market.shareByTown[commodity][townId] > 0.7 then
    -- Apply price ceiling to prevent exploitation
    market.priceCeiling[commodity] = market.basePrice[commodity] * 1.5
end
```

**Preventing Crashes:**
```lua
-- Price floor kicks in if oversupply
if market.totalSupply[commodity] > market.totalDemand[commodity] * 2 then
    -- Apply price floor to prevent collapse
    market.priceFloor[commodity] = market.basePrice[commodity] * 0.5
end
```

### 5.3 Starting Resource Balance

Each specialty town should start with:
- Enough resources for ~10-20 production cycles
- Basic food/water for citizens (not dependent on first production)
- Small gold reserve for emergency imports
- Buffer to survive early optimization phase

---

## 6. Multiplayer/Multi-Town Considerations

### 6.1 Single Player Mode
- AI towns with different specialties populate the marketplace
- Player competes/cooperates with AI towns
- AI towns have personality (aggressive pricing, cooperative, etc.)

### 6.2 Multiplayer Mode (Future)
- Each player picks different specialty
- Natural trade emerges from complementary needs
- Competition within same specialty
- Alliances and trade agreements

### 6.3 AI Town Generation
```lua
function Market:GenerateAITowns(count)
    local specialties = shuffleArray(ALL_SPECIALTIES)

    for i = 1, count do
        local specialty = specialties[i % #specialties + 1]
        local aiTown = AITown:Create({
            specialty = specialty,
            personality = randomPersonality(),
            aggression = math.random() * 0.5 + 0.25,  -- 0.25-0.75
            cooperativeness = math.random()
        })
        self:RegisterTown(aiTown)
    end
end
```

---

## 7. Connection to Existing Systems

### 7.1 Integration with Marketplace Economy
From [Marketplace Economy Design](marketplace_economy_design.md):
- Internal market for citizen purchases remains
- External market for inter-town trade added
- Town gold flows: exports → gold in, imports → gold out
- Trade balance affects town prosperity

### 7.2 Integration with Trade Foundation
From Dec 2 meeting notes:
```
exportValue[commodity] = surplus × qualityMultiplier × scarcityBonus
importPriority[commodity] = unfulfilledCravings × urgencyMultiplier
```

### 7.3 Connection to Caricature Towns
From marketing strategy (Bengaluru, Mumbai, etc.):
- Caricature towns could have predefined specialties
- Bengaluru = Tech services (future commodity type)
- Mumbai = Finance/Banking services
- Chennai = Textile town
- Jaipur = Jewelry town

---

## 8. Implementation Phases

### Phase 1: Single Town Specialty (MVP)
- [ ] Create 3-4 specialty configurations
- [ ] Implement specialty selection UI
- [ ] Auto-build starting supply chain
- [ ] Assign starting workers
- [ ] Test balance for each specialty

### Phase 2: Marketplace Foundation
- [ ] Create marketplace data structure
- [ ] Implement listing/bidding system
- [ ] Add basic AI towns (static, simple behavior)
- [ ] Create market price display UI
- [ ] Add trade panel to town UI

### Phase 3: Dynamic AI Towns
- [ ] AI town production simulation
- [ ] AI pricing decisions
- [ ] AI personality types
- [ ] Market equilibrium balancing

### Phase 4: Advanced Trade
- [ ] Trade agreements between towns
- [ ] Caravan visualization (optional)
- [ ] Trade route bonuses
- [ ] Market events (shortages, booms)

---

## 9. Open Questions

1. **How many AI towns** should exist in the marketplace? (3? 5? 10?)
2. **Starting gold amount** - enough for how many imports?
3. **Should players be able to choose multiple specialties?** (harder but more flexible)
4. **Trade frequency** - real-time or turn-based cycles?
5. **Can towns lose their specialty** if they stop producing?
6. **Tariffs/trade restrictions** as player policy?
7. **Distance-based trade costs** or flat market?

---

## 10. Success Metrics

A successful implementation would show:
- [ ] Players immediately understand their town's identity
- [ ] Clear progression: optimize → trade → expand
- [ ] Emergent trade patterns based on supply/demand
- [ ] Meaningful decisions about specialization vs diversification
- [ ] Towns feel distinct from each other
- [ ] Trade creates interesting interdependencies

---

*Document created: 2025-12-17*
*Next steps: Review with Adwait, prioritize for implementation timeline*
