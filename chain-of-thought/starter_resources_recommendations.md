# Starter Resources Recommendations

## Analysis of Production Chains & Potential Deadlocks

### Current Issues
The current starter resources are minimal and missing critical seeds/natural resources that are required to bootstrap production chains. Without these, players face deadlocks where buildings cannot produce anything.

---

## Critical Resource Categories

### 1. Grain Seeds (Essential for Farming)
Farms require seeds to produce crops. Seeds are consumed and partially regenerated during farming. Without initial seeds, farms are useless.

| Seed | Produces | Input → Output | Priority |
|------|----------|----------------|----------|
| `wheat_seed` | wheat | 20 → 10 wheat + 30 seeds | **HIGH** - bread production |
| `barley_seeds` | barley → beer | 20 → 10 barley + 30 seeds | MEDIUM - brewing |
| `maize_seed` | maize | 20 → 10 maize + 30 seeds | LOW - grain variety |
| `rice_seed` | rice | 20 → 10 rice + 30 seeds | LOW - grain variety |
| `rye_seeds` | rye → whiskey | 20 → 10 rye + 30 seeds | LOW - distilling |
| `oats_seeds` | oats | 20 → 10 oats + 30 seeds | LOW - grain variety |

### 2. Vegetable Seeds (Specific Types)
Each vegetable has its own seed type:

| Seed | Produces | Input → Output | Priority |
|------|----------|----------------|----------|
| `potato_seed` | potato | 15 → 120 potato + 25 seeds | **HIGH** - staple food |
| `carrot_seed` | carrot | 20 → 100 carrot + 30 seeds | **HIGH** - common vegetable |
| `cabbage_seed` | cabbage | 15 → 60 cabbage + 22 seeds | MEDIUM |
| `onion_seed` | onion | 20 → 90 onion + 30 seeds | MEDIUM - cooking ingredient |
| `tomato_seed` | tomato | 12 → 80 tomato + 20 seeds | MEDIUM |
| `lettuce_seed` | lettuce | 25 → 70 lettuce + 35 seeds | LOW |

### 3. Fruit Saplings (For Orchards)
Orchards use saplings, not seeds:

| Sapling | Produces | Priority |
|---------|----------|----------|
| `apple_sapling` | apples | **HIGH** - common fruit |
| `orange_sapling` | oranges | MEDIUM |
| `pear_sapling` | pears | MEDIUM |
| `peach_sapling` | peaches | LOW |
| `mango_sapling` | mangoes | LOW - exotic |
| `watermelon_seed` | watermelons | MEDIUM - (uses seeds not sapling) |
| `date_palm_sapling` | dates | LOW - exotic |

### 4. Industrial Crop Seeds

| Seed | Produces | Input → Output | Priority |
|------|----------|----------------|----------|
| `cotton_seed` | cotton → cloth | 10 → 80 cotton + 15 seeds | **HIGH** - clothing chain |
| `flax_seed` | flax → linen | 15 → 80 flax + 25 seeds | MEDIUM - linen production |
| `herb_seed` | herbs → medicine | varies | MEDIUM - health |
| `indigo_seed` | indigo → dye | varies | LOW - dye production |
| `flower_seed` | flowers | varies | LOW - decoration |

### 5. Tree Saplings (For Rubber/Special Products)

| Sapling | Produces | Priority |
|---------|----------|----------|
| `rubber_tree_sapling` | latex → rubber → shoes | MEDIUM - footwear chain |
| `coconut_palm_sapling` | coconuts | LOW - exotic |

### 6. Raw Materials (Natural Resources)
These are obtained from extraction buildings (mines, logging camps, wells) but having some starter stock prevents early-game stalls.

| Resource | Source Building | Used For | Priority |
|----------|-----------------|----------|----------|
| `timber` | Logging Camp (tree → timber) | lumber, planks, firewood | **HIGH** |
| `tree` | Logging Camp (free) | timber | MEDIUM (can be generated) |
| `water` | Well (free) | hydration, cooking, brewing | **HIGH** |
| `iron_ore` | Mine (free) | tools, metal goods | MEDIUM |
| `coal` | Mine (free) | smelting, heating | MEDIUM |
| `stone` | Mine (free) | construction | MEDIUM |
| `clay` | Mine (free) | pottery, bricks | LOW |
| `sand` | Mine (free) | glass | LOW |

### 4. Basic Processed Goods (Bootstrap Buffer)
Some processed goods to prevent immediate crises while production ramps up.

| Resource | Source | Used For | Priority |
|----------|--------|----------|----------|
| `bread` | Bakery (wheat) | food | **HIGH** |
| `flour` | Mill (wheat) | baking | MEDIUM |
| `lumber` | Sawmill (timber) | construction, furniture | **HIGH** |
| `cloth` | Textile Mill (yarn) | clothing | **HIGH** |
| `thread` | Textile Mill (cotton) | tailoring | MEDIUM |
| `firewood` | Sawmill (timber) | heating, cooking | MEDIUM |

### 5. Animal Products (from Hunting/Ranches - usually free extraction)
| Resource | Source | Priority |
|----------|--------|----------|
| `beef` | Hunting/Ranch | MEDIUM - protein |
| `chicken` | Hunting/Ranch | MEDIUM - protein |
| `milk` | Ranch (cow) | MEDIUM - dairy |
| `wool` | Ranch (sheep) | MEDIUM - textiles |
| `eggs` | Ranch (chicken) | LOW |
| `leather` | Tannery (hide) | LOW - footwear |

---

## Recommended Starter Resource Sets by Location Type

### Base Set (All Locations Should Have)
These prevent immediate deadlocks regardless of terrain:

```json
"starterResources": [
  // === GRAIN SEEDS (Critical for bread production) ===
  {"commodityId": "wheat_seed", "quantity": 50},

  // === VEGETABLE SEEDS (Pick 2-3 common vegetables) ===
  {"commodityId": "potato_seed", "quantity": 30},
  {"commodityId": "carrot_seed", "quantity": 30},
  {"commodityId": "cabbage_seed", "quantity": 20},

  // === INDUSTRIAL CROP SEEDS ===
  {"commodityId": "cotton_seed", "quantity": 25},

  // === WATER (Universal need) ===
  {"commodityId": "water", "quantity": 100},

  // === FOOD BUFFER (Prevents starvation while production starts) ===
  {"commodityId": "wheat", "quantity": 50},
  {"commodityId": "bread", "quantity": 40},
  {"commodityId": "beef", "quantity": 20},
  {"commodityId": "potato", "quantity": 30},
  {"commodityId": "carrot", "quantity": 25},
  {"commodityId": "apple", "quantity": 20},

  // === WOOD/CONSTRUCTION (For building and furniture) ===
  {"commodityId": "timber", "quantity": 30},
  {"commodityId": "lumber", "quantity": 40},
  {"commodityId": "firewood", "quantity": 50},

  // === TEXTILES (For clothing) ===
  {"commodityId": "cotton", "quantity": 30},
  {"commodityId": "cloth", "quantity": 20},
  {"commodityId": "thread", "quantity": 15}
]
```

### Location-Specific Additions

#### River Valley (Farming Focus)
Add to base set:
```json
{"commodityId": "flax_seed", "quantity": 20},
{"commodityId": "onion_seed", "quantity": 20},
{"commodityId": "tomato_seed", "quantity": 15},
{"commodityId": "herb_seed", "quantity": 15},
{"commodityId": "apple_sapling", "quantity": 8},
{"commodityId": "fish", "quantity": 30}
```

#### Mountain Pass (Mining Focus)
Add to base set:
```json
{"commodityId": "iron_ore", "quantity": 60},
{"commodityId": "copper_ore", "quantity": 40},
{"commodityId": "coal", "quantity": 80},
{"commodityId": "stone", "quantity": 100}
```

#### Fertile Plains (Agriculture Focus)
Add to base set:
```json
{"commodityId": "wheat_seed", "quantity": 30},      // Extra wheat seeds (total 80)
{"commodityId": "barley_seeds", "quantity": 30},
{"commodityId": "onion_seed", "quantity": 25},
{"commodityId": "tomato_seed", "quantity": 20},
{"commodityId": "lettuce_seed", "quantity": 25},
{"commodityId": "apple_sapling", "quantity": 10},
{"commodityId": "pear_sapling", "quantity": 8},
{"commodityId": "milk", "quantity": 20},
{"commodityId": "eggs", "quantity": 30}
```

#### Forest Edge (Lumber Focus)
Add to base set:
```json
{"commodityId": "tree", "quantity": 20},
{"commodityId": "timber", "quantity": 60},          // Extra timber
{"commodityId": "lumber", "quantity": 80},          // Extra lumber
{"commodityId": "rubber_tree_sapling", "quantity": 10},
{"commodityId": "apple_sapling", "quantity": 15},
{"commodityId": "pear_sapling", "quantity": 10}
```

#### Crossroads (Trade Focus)
Add to base set:
```json
{"commodityId": "silk", "quantity": 10},
{"commodityId": "spices", "quantity": 15},
{"commodityId": "wine", "quantity": 20},
{"commodityId": "gold", "quantity": 20},
{"commodityId": "watermelon_seed", "quantity": 15}, // Exotic produce
{"commodityId": "mango_sapling", "quantity": 5}
```
Plus extra of everything for trading buffer.

#### Iron Mountains (Heavy Industry Focus)
Add to base set:
```json
{"commodityId": "iron_ore", "quantity": 100},
{"commodityId": "copper_ore", "quantity": 60},
{"commodityId": "coal", "quantity": 100},
{"commodityId": "stone", "quantity": 80},
{"commodityId": "iron_bar", "quantity": 30},
{"commodityId": "copper_bar", "quantity": 20}
```

---

## Deadlock Prevention Checklist

Before finalizing starter resources, verify these production chains can bootstrap:

### Food Chain
- [ ] Wheat seeds → Farm → Wheat → Bakery → Bread
- [ ] Vegetable seeds → Farm → Vegetables
- [ ] Water available for hydration and cooking

### Clothing Chain
- [ ] Cotton seeds → Farm → Cotton → Textile Mill → Yarn → Cloth
- [ ] Thread available for Tailor Shop
- [ ] Cloth available for clothing production

### Construction Chain
- [ ] Timber/Tree available for Sawmill
- [ ] Lumber available for building construction
- [ ] Stone/Clay available for masonry (if relevant buildings exist)

### Tool Chain
- [ ] Iron ore available (or mine present) for Blacksmith
- [ ] Coal available for Smelter

---

## Summary: Minimum Viable Starter Set

For a town to function without deadlocks, these are the **absolute minimum**:

### Grain & Vegetable Seeds (Specific)
1. **wheat_seed** (50) - For grain/bread production
2. **potato_seed** (30) - Staple vegetable
3. **carrot_seed** (30) - Common vegetable
4. **cabbage_seed** (20) - Vegetable variety
5. **cotton_seed** (25) - For clothing chain

### Immediate Supplies
6. **water** (100) - Universal need
7. **wheat** (50) - Immediate food buffer
8. **bread** (40) - Ready-to-eat food
9. **potato** (30) - Ready vegetables
10. **carrot** (25) - Ready vegetables
11. **apple** (20) - Ready fruit
12. **beef** (20) - Protein source

### Construction & Textiles
13. **timber** (30) - For sawmill to start
14. **lumber** (40) - For construction
15. **firewood** (50) - For heating/cooking
16. **cotton** (30) - Raw textile
17. **cloth** (20) - For immediate clothing
18. **thread** (15) - For tailoring

### Additional Per Location Focus
- **Farming locations**: Add `flax_seed`, `onion_seed`, `tomato_seed`, `apple_sapling`
- **Mining locations**: Add `iron_ore`, `copper_ore`, `coal`, `stone`
- **Forest locations**: Add `tree`, extra `timber`/`lumber`, saplings
- **Trade locations**: Add luxury goods, exotic seeds/saplings
