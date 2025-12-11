# Missing Production Chains - Comprehensive Implementation Plan

## Overview

This document outlines all missing production chains in Cravetown, including:
1. Base resource production (farming, animal husbandry)
2. Processing chains (raw → intermediate → finished goods)
3. Combination products (combining multiple processed goods)

---

## 1. Textile Production Chain

### 1.1 Flax → Linen Chain

**New Commodities Needed:**
- `flax_seed` - Seeds for flax farming

**Farming Recipe (Farm):**
```
Flax Farming:
  Input: flax_seed (15)
  Output: flax (80), flax_seed (25)
  Time: 6300 seconds (1.75 hours)
```

**Processing Recipe (Textile Mill):**
```
Linen Weaving:
  Input: flax (30)
  Output: linen (15)
  Time: 2400 seconds (40 minutes)
```

### 1.2 Silk Production Chain

**Option A: Silkworm Farm (Complex)**

**New Commodities:**
- `silkworm_eggs` - Starting material
- `mulberry_leaves` - Silkworm food
- `mulberry_sapling` - For mulberry tree cultivation
- `silk_cocoon` - Raw silk before processing
- `raw_silk` - Unprocessed silk thread

**New Building: Sericulture Farm**
```
Mulberry Cultivation (Orchard):
  Input: mulberry_sapling (5)
  Output: mulberry_leaves (200), mulberry_sapling (7)
  Time: 172800 seconds (2 days)

Silkworm Raising (Sericulture Farm):
  Input: silkworm_eggs (100), mulberry_leaves (500)
  Output: silk_cocoon (50), silkworm_eggs (120)
  Time: 259200 seconds (3 days)

Silk Reeling (Textile Mill):
  Input: silk_cocoon (20)
  Output: silk (5)
  Time: 3600 seconds (1 hour)
```

**Option B: Simplified Import/Trade**
- Silk remains a trade-only luxury commodity
- Can be purchased from traders at high cost

### 1.3 Wool Production Chain

**New Building: Sheep Farm** (or expand existing animal husbandry)

**New Commodities:**
- `sheep` - Livestock
- `lamb` - Young sheep for breeding

```
Sheep Breeding (Sheep Farm):
  Input: sheep (4)
  Output: sheep (6), wool (30), mutton (15)
  Time: 259200 seconds (3 days)
  Note: Sustainable cycle - sheep produce wool without slaughter

Wool Shearing (Sheep Farm):
  Input: sheep (10)
  Output: wool (40), sheep (10)
  Time: 86400 seconds (1 day)
  Note: Non-destructive - same sheep returned
```

**Wool Processing (Textile Mill):**
```
Wool Spinning:
  Input: wool (20)
  Output: yarn (30)
  Time: 1800 seconds (30 minutes)

Woolen Cloth Weaving:
  Input: yarn (40), wool (10)
  Output: cloth (25)
  Time: 2400 seconds (40 minutes)
  Note: Thicker, warmer cloth variant
```

---

## 2. Animal Products Chain

### 2.1 Poultry Farm (Eggs & Chicken)

**New Building: Poultry Farm**

**New Commodities:**
- `chick` - Baby chicken for breeding
- `hen` - Egg-laying chicken

```
Chicken Breeding (Poultry Farm):
  Input: hen (10), feed (20)
  Output: hen (12), chick (15), eggs (50)
  Time: 172800 seconds (2 days)

Egg Collection (Poultry Farm):
  Input: hen (20), feed (10)
  Output: eggs (80), hen (20)
  Time: 86400 seconds (1 day)
  Note: Non-destructive egg production

Chicken Raising (Poultry Farm):
  Input: chick (20), feed (30)
  Output: chicken (15), hen (5)
  Time: 259200 seconds (3 days)
```

**New Commodity for Feed:**
- `feed` - Animal feed (can be produced from grains)

```
Feed Production (Farm or Mill):
  Input: wheat (20), maize (20)
  Output: feed (50)
  Time: 1800 seconds (30 minutes)
```

### 2.2 Beekeeping (Honey & Beeswax)

**New Building: Apiary**

**New Commodities:**
- `bee_colony` - Bee hive starter
- `beeswax` - For candles and other products

```
Honey Production (Apiary):
  Input: bee_colony (5), flowers (20)
  Output: honey (30), beeswax (10), bee_colony (6)
  Time: 259200 seconds (3 days)
  Note: Requires nearby flowers for best yield
```

### 2.3 Leather Processing

**New Building: Tannery**

**New Commodities:**
- `raw_hide` - Unprocessed animal skin
- `tanned_leather` - Higher quality leather

**Updated Hunting Lodge Outputs:**
```
Cattle Hunting (updated):
  Output: beef (25), raw_hide (4)
  Note: Changed from leather to raw_hide

Sheep Hunting (updated):
  Output: mutton (15), wool (8), raw_hide (2)
```

**Tannery Recipes:**
```
Basic Leather Tanning:
  Input: raw_hide (10)
  Output: leather (8)
  Time: 7200 seconds (2 hours)

Fine Leather Tanning:
  Input: raw_hide (10), oak_bark (5)
  Output: tanned_leather (6)
  Time: 14400 seconds (4 hours)
  Note: Higher quality for luxury goods
```

**New Commodity:**
- `oak_bark` - For tanning (byproduct of logging)

```
Bark Stripping (Logging Camp):
  Input: tree (2)
  Output: timber (10), oak_bark (15)
  Time: 2400 seconds (40 minutes)
```

---

## 3. Dye Production Chain

### 3.1 Dye Plant Farming

**New Commodities:**
- `indigo_seed` - Seeds for indigo farming
- `flower_seed` - Seeds for flower farming
- `madder` - Red dye plant (alternative to berries)
- `madder_seed` - Seeds for madder
- `woad` - Blue dye plant (alternative to indigo)
- `woad_seed` - Seeds for woad

**Farming Recipes:**
```
Indigo Farming (Farm):
  Input: indigo_seed (10)
  Output: indigo (60), indigo_seed (15)
  Time: 7200 seconds (2 hours)

Flower Farming (Farm):
  Input: flower_seed (20)
  Output: flowers (100), flower_seed (30)
  Time: 5400 seconds (1.5 hours)

Madder Farming (Farm):
  Input: madder_seed (12)
  Output: madder (50), madder_seed (18)
  Time: 10800 seconds (3 hours)
```

### 3.2 Dye Workshop

**New Building: Dye Workshop**

```
Red Dye Production (from berries):
  Input: berries (30)
  Output: red_dye (10)
  Time: 2400 seconds (40 minutes)

Red Dye Production (from madder):
  Input: madder (25)
  Output: red_dye (15)
  Time: 3000 seconds (50 minutes)
  Note: More efficient than berries

Blue Dye Production:
  Input: indigo (20)
  Output: blue_dye (12)
  Time: 3600 seconds (1 hour)

Yellow Dye Production:
  Input: flowers (40)
  Output: yellow_dye (10)
  Time: 2400 seconds (40 minutes)

Black Dye Production:
  Input: charcoal (15)
  Output: black_dye (20)
  Time: 1800 seconds (30 minutes)

Green Dye Production (combination):
  Input: blue_dye (5), yellow_dye (5)
  Output: green_dye (8)
  Time: 1200 seconds (20 minutes)

Purple Dye Production (combination):
  Input: red_dye (5), blue_dye (5)
  Output: purple_dye (6)
  Time: 1500 seconds (25 minutes)
  Note: Rare and valuable

Orange Dye Production (combination):
  Input: red_dye (5), yellow_dye (5)
  Output: orange_dye (8)
  Time: 1200 seconds (20 minutes)
```

**New Commodities:**
- `green_dye`
- `purple_dye`
- `orange_dye`

---

## 4. Dyed/Colored Products (Combinations)

### 4.1 Colored Cloth

**New Commodities:**
- `red_cloth`, `blue_cloth`, `yellow_cloth`, `green_cloth`, `purple_cloth`, `black_cloth`

**Dye Workshop or Textile Mill Recipes:**
```
Red Cloth Dyeing:
  Input: cloth (20), red_dye (5)
  Output: red_cloth (18)
  Time: 1800 seconds (30 minutes)

Blue Cloth Dyeing:
  Input: cloth (20), blue_dye (5)
  Output: blue_cloth (18)
  Time: 1800 seconds (30 minutes)

Yellow Cloth Dyeing:
  Input: cloth (20), yellow_dye (5)
  Output: yellow_cloth (18)
  Time: 1800 seconds (30 minutes)

Green Cloth Dyeing:
  Input: cloth (20), green_dye (5)
  Output: green_cloth (18)
  Time: 1800 seconds (30 minutes)

Purple Cloth Dyeing:
  Input: cloth (20), purple_dye (5)
  Output: purple_cloth (16)
  Time: 2100 seconds (35 minutes)
  Note: Lower yield due to precious dye

Black Cloth Dyeing:
  Input: cloth (20), black_dye (5)
  Output: black_cloth (18)
  Time: 1800 seconds (30 minutes)
```

### 4.2 Colored Clothing (Tailor Shop)

**New Commodities:**
- `colored_simple_clothes` - Dyed basic garments
- `formal_attire` - High-end colored clothing
- `uniform` - Standardized work clothing
- `ceremonial_robes` - Religious/formal wear

```
Colored Simple Clothes:
  Input: simple_clothes (5), red_dye (2)
  Output: colored_simple_clothes (5)
  Time: 900 seconds (15 minutes)
  Note: Can use any dye color

Formal Attire (Blue):
  Input: fine_clothes (3), blue_cloth (5), thread (10)
  Output: formal_attire (2)
  Time: 3600 seconds (1 hour)

Formal Attire (Purple):
  Input: fine_clothes (3), purple_cloth (5), thread (10), gold (1)
  Output: formal_attire (2)
  Time: 4200 seconds (1.1 hours)
  Note: Royal purple with gold trim

Work Uniform:
  Input: work_clothes (4), black_dye (2)
  Output: uniform (4)
  Time: 1200 seconds (20 minutes)

Ceremonial Robes:
  Input: silk (5), purple_dye (3), gold (2), thread (15)
  Output: ceremonial_robes (1)
  Time: 7200 seconds (2 hours)
  Note: Extremely valuable
```

### 4.3 Dyed Linen Products

```
Dyed Linen:
  Input: linen (15), blue_dye (3)
  Output: dyed_linen (14)
  Time: 1500 seconds (25 minutes)

Embroidered Linen:
  Input: dyed_linen (10), thread (20), gold (1)
  Output: embroidered_linen (5)
  Time: 3600 seconds (1 hour)
  Note: Luxury textile
```

---

## 5. Paper & Writing Materials Chain

### 5.1 Paper Production

**New Building: Paper Mill**

**New Commodities:**
- `wood_pulp` - Processed wood for paper
- `papyrus` - Alternative paper material (if near water)
- `parchment` - Animal skin writing material
- `ink` - Writing ink

```
Wood Pulp Production (Paper Mill):
  Input: timber (5), water (20)
  Output: wood_pulp (30)
  Time: 3600 seconds (1 hour)
  Note: Water may be abstracted or require well/river

Paper Making (Paper Mill):
  Input: wood_pulp (20)
  Output: paper (40)
  Time: 2400 seconds (40 minutes)

Fine Paper Making (Paper Mill):
  Input: wood_pulp (25), cloth (5)
  Output: paper (30), fine_paper (15)
  Time: 3600 seconds (1 hour)
```

**New Commodity:**
- `fine_paper` - Higher quality for books and documents

### 5.2 Ink Production

```
Black Ink Production (Dye Workshop or Paper Mill):
  Input: black_dye (5), oil (2)
  Output: ink (15)
  Time: 1200 seconds (20 minutes)

Colored Ink Production:
  Input: [any_dye] (5), oil (2)
  Output: [colored_ink] (12)
  Time: 1500 seconds (25 minutes)
```

**New Commodities:**
- `ink` (black)
- `red_ink`, `blue_ink` (for special documents)

### 5.3 Books & Documents

**New Building: Scriptorium** (or expand existing workshop)

**New Commodities:**
- `manuscript` - Hand-written document
- `ledger` - Accounting book
- `map` - Cartographic document

```
Book Binding (Scriptorium):
  Input: paper (20), leather (2), thread (5), ink (3)
  Output: book (2)
  Time: 7200 seconds (2 hours)

Illuminated Manuscript:
  Input: fine_paper (15), ink (5), gold (2), blue_dye (2), red_dye (2)
  Output: manuscript (1)
  Time: 14400 seconds (4 hours)
  Note: Extremely valuable religious/artistic text

Ledger Production:
  Input: paper (30), leather (3), ink (5)
  Output: ledger (3)
  Time: 3600 seconds (1 hour)

Map Making:
  Input: fine_paper (5), ink (3), [various_dyes] (2)
  Output: map (2)
  Time: 5400 seconds (1.5 hours)
```

---

## 6. Candles, Soap & Household Items

### 6.1 Candle Making

**New Building: Chandlery** (or add to existing workshop)

**New Commodities:**
- `tallow` - Animal fat for basic candles
- `tallow_candle` - Basic candle
- `beeswax_candle` - Premium candle

```
Tallow Rendering (Chandlery):
  Input: beef (10)
  Output: tallow (8)
  Time: 1800 seconds (30 minutes)
  Note: Byproduct of butchering

Tallow Candle Making:
  Input: tallow (10), thread (5)
  Output: tallow_candle (20)
  Time: 2400 seconds (40 minutes)
  Note: Basic, smoky candles

Beeswax Candle Making:
  Input: beeswax (8), thread (5)
  Output: beeswax_candle (15)
  Time: 2400 seconds (40 minutes)
  Note: Premium, clean-burning candles

Scented Candle Making:
  Input: beeswax (6), thread (4), perfume (2)
  Output: scented_candle (10)
  Time: 3000 seconds (50 minutes)
  Note: Luxury item
```

**New Commodities:**
- `tallow`
- `tallow_candle`
- `beeswax_candle`
- `scented_candle`

### 6.2 Soap Making

**New Building: Soap Works** (or add to Chandlery)

**New Commodities:**
- `lye` - Alkali for soap making
- `ash` - Byproduct of burning, used for lye
- `basic_soap` - Utility soap
- `scented_soap` - Luxury soap

```
Ash Collection (from any fire-using building):
  Input: firewood (20)
  Output: ash (15), [heat/cooking benefit]
  Note: Byproduct of heating/cooking

Lye Production (Soap Works):
  Input: ash (20), water (30)
  Output: lye (15)
  Time: 3600 seconds (1 hour)

Basic Soap Making:
  Input: oil (10), lye (8)
  Output: basic_soap (15)
  Time: 7200 seconds (2 hours)
  Note: Requires curing time

Scented Soap Making:
  Input: oil (8), lye (6), perfume (3)
  Output: scented_soap (10)
  Time: 7200 seconds (2 hours)

Herbal Soap Making:
  Input: oil (8), lye (6), flowers (10)
  Output: herbal_soap (12)
  Time: 7200 seconds (2 hours)
```

### 6.3 Lamp Oil

```
Lamp Oil Refining (Oil Press or separate):
  Input: oil (15)
  Output: lamp_oil (12)
  Time: 1200 seconds (20 minutes)
  Note: Purified for clean burning
```

---

## 7. Medicine & Perfume Chain

### 7.1 Herb Farming

**New Commodities:**
- `herb_seed` - Seeds for herb garden
- `medicinal_herbs` - Healing plants
- `aromatic_herbs` - Fragrant plants
- `spice_seed` - Seeds for spice plants
- `spices` - Already exists but needs farming recipe

```
Herb Farming (Farm):
  Input: herb_seed (15)
  Output: medicinal_herbs (40), aromatic_herbs (30), herb_seed (25)
  Time: 5400 seconds (1.5 hours)

Spice Farming (Farm):
  Input: spice_seed (10)
  Output: spices (30), spice_seed (15)
  Time: 7200 seconds (2 hours)
```

### 7.2 Apothecary

**New Building: Apothecary**

```
Basic Medicine:
  Input: medicinal_herbs (20)
  Output: medicine (10)
  Time: 3600 seconds (1 hour)

Herbal Remedy:
  Input: medicinal_herbs (15), honey (5)
  Output: medicine (12)
  Time: 2700 seconds (45 minutes)
  Note: Honey preserves and enhances

Healing Salve:
  Input: medicinal_herbs (10), oil (5), beeswax (3)
  Output: healing_salve (8)
  Time: 2400 seconds (40 minutes)

Tonic:
  Input: medicinal_herbs (15), wine (5)
  Output: tonic (10)
  Time: 1800 seconds (30 minutes)
```

**New Commodities:**
- `healing_salve`
- `tonic`

### 7.3 Perfumery

**New Building: Perfumery** (or add to Apothecary)

```
Flower Water Distillation:
  Input: flowers (50), water (20)
  Output: flower_water (30)
  Time: 3600 seconds (1 hour)

Rose Water (if roses added):
  Input: roses (40), water (15)
  Output: rose_water (25)
  Time: 3600 seconds (1 hour)

Basic Perfume:
  Input: flower_water (20), oil (5)
  Output: perfume (8)
  Time: 2400 seconds (40 minutes)

Fine Perfume:
  Input: flower_water (15), aromatic_herbs (10), oil (5)
  Output: fine_perfume (5)
  Time: 3600 seconds (1 hour)

Exotic Perfume:
  Input: flower_water (10), spices (5), oil (5), musk (2)
  Output: exotic_perfume (3)
  Time: 5400 seconds (1.5 hours)
  Note: Requires rare musk from hunting
```

**New Commodities:**
- `flower_water`
- `rose_water`
- `fine_perfume`
- `exotic_perfume`
- `musk` (rare hunting drop)
- `roses` (special flower type)
- `rose_bush` (planting material)

---

## 8. Construction Materials Chain

### 8.1 Cement Production

**New Building: Lime Kiln**

**New Commodities:**
- `limestone` - Raw calcium carbite rock
- `quickite` - Calcium oxide
- `mortar` - Binding mixture

```
Limestone Quarrying (Mine):
  Input: none
  Output: limestone (100)
  Time: 3600 seconds (1 hour)

Quicklite Burning (Lime Kiln):
  Input: limestone (50), coal (20)
  Output: quicklime (30)
  Time: 7200 seconds (2 hours)

Cement Production (Lime Kiln):
  Input: quicklime (20), clay (10)
  Output: cement (25)
  Time: 3600 seconds (1 hour)

Mortar Mixing:
  Input: cement (15), sand (30)
  Output: mortar (40)
  Time: 1800 seconds (30 minutes)
```

### 8.2 Advanced Construction Materials

**New Commodities:**
- `concrete` - Modern building material
- `plaster` - Wall finishing
- `stucco` - Decorative exterior

```
Concrete Mixing:
  Input: cement (20), sand (40), stone (30)
  Output: concrete (50)
  Time: 2400 seconds (40 minutes)

Plaster Making:
  Input: quicklime (15), sand (10)
  Output: plaster (20)
  Time: 1800 seconds (30 minutes)

Stucco Making:
  Input: plaster (15), marble (5)
  Output: stucco (15)
  Time: 2400 seconds (40 minutes)
```

---

## 9. Tools & Weapons Chain (Blacksmith)

### 9.1 Basic Tools

```
Axe Forging (Blacksmith):
  Input: iron (15), wood (10)
  Output: axe (5)
  Time: 1800 seconds (30 minutes)

Saw Forging (Blacksmith):
  Input: iron (20), wood (8)
  Output: saw (4)
  Time: 2100 seconds (35 minutes)

Pickaxe Forging (Blacksmith):
  Input: iron (18), wood (12)
  Output: pickaxe (4)
  Time: 2100 seconds (35 minutes)

Hoe Forging (Blacksmith):
  Input: iron (12), wood (10)
  Output: hoe (6)
  Time: 1500 seconds (25 minutes)

Scythe Forging (Blacksmith):
  Input: iron (20), wood (15)
  Output: scythe (3)
  Time: 2400 seconds (40 minutes)

Chisel Forging (Blacksmith):
  Input: iron (8)
  Output: chisel (10)
  Time: 900 seconds (15 minutes)

Needle Making (Blacksmith):
  Input: iron (3)
  Output: needle (50)
  Time: 600 seconds (10 minutes)

Nail Making (Blacksmith):
  Input: iron (10)
  Output: nails (100)
  Time: 1200 seconds (20 minutes)
```

### 9.2 Quality Tool Variants

**New Commodities:**
- `steel_axe`, `steel_pickaxe`, `steel_saw` - Upgraded tools

```
Steel Axe Forging:
  Input: steel (12), wood (10)
  Output: steel_axe (4)
  Time: 2400 seconds (40 minutes)
  Note: More durable, higher efficiency

Steel Pickaxe Forging:
  Input: steel (15), wood (12)
  Output: steel_pickaxe (3)
  Time: 2700 seconds (45 minutes)
```

### 9.3 Weapons (Optional - for guards/military)

**New Commodities:**
- `sword`, `spear`, `shield`, `armor`, `helmet`

```
Sword Forging:
  Input: steel (20), leather (3)
  Output: sword (2)
  Time: 3600 seconds (1 hour)

Spear Forging:
  Input: iron (10), wood (15)
  Output: spear (5)
  Time: 1800 seconds (30 minutes)

Shield Making:
  Input: wood (20), iron (8), leather (5)
  Output: shield (3)
  Time: 2400 seconds (40 minutes)

Armor Forging:
  Input: steel (40), leather (10)
  Output: armor (1)
  Time: 7200 seconds (2 hours)

Helmet Forging:
  Input: steel (15), leather (3)
  Output: helmet (2)
  Time: 2400 seconds (40 minutes)
```

---

## 10. Complete Clothing Chain (Tailor Shop)

### 10.1 Basic Clothing

```
Simple Clothes Making:
  Input: cloth (10), thread (8)
  Output: simple_clothes (4)
  Time: 1800 seconds (30 minutes)

Work Clothes Making:
  Input: cloth (15), thread (10), leather (3)
  Output: work_clothes (3)
  Time: 2400 seconds (40 minutes)
  Note: Reinforced for labor
```

### 10.2 Fine Clothing

```
Fine Clothes Making:
  Input: linen (12), thread (10)
  Output: fine_clothes (3)
  Time: 3000 seconds (50 minutes)

Luxury Clothes Making:
  Input: silk (8), thread (15), gold (1)
  Output: luxury_clothes (2)
  Time: 5400 seconds (1.5 hours)
```

### 10.3 Outerwear & Accessories

```
Winter Coat Making:
  Input: wool (20), cloth (10), thread (12)
  Output: winter_coat (2)
  Time: 3600 seconds (1 hour)

Boots Making:
  Input: leather (15), thread (8), nails (10)
  Output: boots (4)
  Time: 2400 seconds (40 minutes)

Hat Making:
  Input: cloth (8), thread (5)
  Output: hat (6)
  Time: 1200 seconds (20 minutes)

Wool Hat Making:
  Input: wool (10), thread (4)
  Output: wool_hat (5)
  Time: 1500 seconds (25 minutes)

Gloves Making:
  Input: leather (8), thread (5)
  Output: gloves (6)
  Time: 1200 seconds (20 minutes)

Wool Gloves Making:
  Input: wool (8), thread (4)
  Output: wool_gloves (6)
  Time: 1200 seconds (20 minutes)
```

**New Commodities:**
- `wool_hat`
- `gloves`
- `wool_gloves`

---

## 11. Luxury & Art Items

### 11.1 Jewelry (Jewellery Shop)

```
Silver Ring:
  Input: silver (5)
  Output: silver_ring (8)
  Time: 1800 seconds (30 minutes)

Gold Ring:
  Input: gold (3)
  Output: gold_ring (5)
  Time: 2100 seconds (35 minutes)

Silver Necklace:
  Input: silver (10), thread (3)
  Output: silver_necklace (4)
  Time: 2700 seconds (45 minutes)

Gold Necklace:
  Input: gold (8), thread (3)
  Output: gold_necklace (3)
  Time: 3600 seconds (1 hour)

Gemstone Jewelry:
  Input: gold (5), gemstone (3)
  Output: gemstone_jewelry (2)
  Time: 5400 seconds (1.5 hours)

Crown:
  Input: gold (20), gemstone (10)
  Output: crown (1)
  Time: 14400 seconds (4 hours)
  Note: Extremely valuable
```

**New Commodities:**
- `gemstone` - From mining (rare)
- `silver_ring`, `gold_ring`
- `silver_necklace`, `gold_necklace`
- `gemstone_jewelry`
- `crown`

**Mining Recipe:**
```
Gemstone Mining (Mine):
  Input: none
  Output: gemstone (3)
  Time: 14400 seconds (4 hours)
  Note: Rare, requires specific deposit
```

### 11.2 Art Workshop

**New Building: Art Workshop**

```
Painting Creation:
  Input: cloth (5), wood (3), red_dye (2), blue_dye (2), yellow_dye (2), oil (3)
  Output: painting (1)
  Time: 14400 seconds (4 hours)

Portrait Painting:
  Input: cloth (3), wood (2), [various_dyes] (5), oil (2), gold (1)
  Output: portrait (1)
  Time: 21600 seconds (6 hours)
  Note: Commissioned art

Tapestry Weaving:
  Input: wool (30), thread (40), [various_dyes] (10)
  Output: tapestry (1)
  Time: 86400 seconds (1 day)
  Note: Large decorative textile
```

**New Commodities:**
- `portrait`
- `tapestry`

### 11.3 Sculpture (Stonecutters)

Already exists (statue from marble), can add:

```
Bronze Sculpture:
  Input: bronze (30)
  Output: bronze_sculpture (1)
  Time: 14400 seconds (4 hours)

Small Figurine:
  Input: clay (5)
  Output: figurine (8)
  Time: 1800 seconds (30 minutes)
  Note: Decorative clay figures
```

**New Commodities:**
- `bronze_sculpture`
- `figurine`

---

## 12. Food Combinations & Advanced Recipes

### 12.1 Pastries (Bakery)

```
Pastry Making:
  Input: flour (8), butter (3), sugar (2), eggs (4)
  Output: pastries (10)
  Time: 1800 seconds (30 minutes)

Croissant Making:
  Input: flour (6), butter (5), eggs (2)
  Output: croissant (12)
  Time: 2400 seconds (40 minutes)

Fruit Pastry:
  Input: flour (6), butter (2), sugar (2), [any_fruit] (10)
  Output: fruit_pastry (8)
  Time: 2100 seconds (35 minutes)

Cookie Making:
  Input: flour (5), butter (2), sugar (3), eggs (2)
  Output: cookies (30)
  Time: 1200 seconds (20 minutes)
```

**New Commodities:**
- `croissant`
- `fruit_pastry`
- `cookies`

### 12.2 Preserved Foods

```
Smoked Meat (Preservery or Smokehouse):
  Input: beef (20), firewood (10)
  Output: smoked_meat (15)
  Time: 14400 seconds (4 hours)

Smoked Fish:
  Input: fish (25), firewood (8)
  Output: smoked_fish (20)
  Time: 10800 seconds (3 hours)

Salted Meat:
  Input: beef (15), salt (5)
  Output: salted_meat (12)
  Time: 7200 seconds (2 hours)

Canned Goods:
  Input: [vegetables or fruit] (20), glass (5), salt (2)
  Output: preserved_food (15)
  Time: 3600 seconds (1 hour)
```

**New Commodities:**
- `smoked_meat`
- `smoked_fish`
- `salted_meat`
- `fish` - Needs fishing building
- `salt` - Needs salt extraction

### 12.3 Salt Production

**New Building: Salt Works**

```
Salt Extraction (Salt Works - coastal):
  Input: none (seawater)
  Output: salt (50)
  Time: 86400 seconds (1 day)
  Note: Requires coastal placement

Salt Mining (Mine - inland):
  Input: none
  Output: salt (30)
  Time: 7200 seconds (2 hours)
  Note: Rock salt deposits
```

**New Commodity:**
- `salt`

### 12.4 Fishing

**New Building: Fishery**

**New Commodities:**
- `fish`
- `shellfish`
- `fishing_net` (tool)

```
Fishing (Fishery):
  Input: fishing_net (1)
  Output: fish (40), fishing_net (1)
  Time: 7200 seconds (2 hours)
  Note: Net returned with wear

Net Making (Textile Mill or Fishery):
  Input: thread (30)
  Output: fishing_net (2)
  Time: 3600 seconds (1 hour)

Shellfish Gathering (Fishery):
  Input: none
  Output: shellfish (20)
  Time: 3600 seconds (1 hour)
  Note: Coastal only
```

---

## 13. Summary: New Buildings Required

| Building | Category | Primary Products |
|----------|----------|------------------|
| Sheep Farm | Animal Husbandry | Wool, Mutton, Sheep |
| Poultry Farm | Animal Husbandry | Eggs, Chicken |
| Apiary | Animal Husbandry | Honey, Beeswax |
| Tannery | Processing | Leather, Tanned Leather |
| Dye Workshop | Processing | All Dyes |
| Paper Mill | Processing | Paper, Wood Pulp |
| Scriptorium | Crafting | Books, Manuscripts |
| Chandlery | Crafting | Candles |
| Soap Works | Processing | Soap, Lye |
| Apothecary | Processing | Medicine, Remedies |
| Perfumery | Processing | Perfume |
| Lime Kiln | Processing | Cement, Quickite |
| Art Workshop | Crafting | Paintings, Tapestries |
| Salt Works | Extraction | Salt |
| Fishery | Extraction | Fish, Shellfish |
| Sericulture Farm | Animal Husbandry | Silk (optional) |

---

## 14. Summary: New Commodities Required

### Seeds & Planting Materials
- flax_seed, indigo_seed, flower_seed, madder_seed, herb_seed, spice_seed
- rose_bush, mulberry_sapling (if silk chain implemented)

### Raw Materials
- raw_hide, oak_bark, limestone, ash, musk
- fish, shellfish, salt
- gemstone

### Animal Products
- sheep, lamb, hen, chick, feed
- bee_colony, beeswax, tallow
- silk_cocoon, raw_silk (if silk chain)

### Processed Textiles
- dyed_linen, embroidered_linen
- red_cloth, blue_cloth, yellow_cloth, green_cloth, purple_cloth, black_cloth

### Dyes
- green_dye, purple_dye, orange_dye
- madder (dye plant)

### Paper & Writing
- wood_pulp, fine_paper, parchment
- ink, red_ink, blue_ink
- manuscript, ledger, map

### Household
- tallow_candle, beeswax_candle, scented_candle
- basic_soap, scented_soap, herbal_soap
- lye

### Medicine & Perfume
- medicinal_herbs, aromatic_herbs
- healing_salve, tonic
- flower_water, rose_water, fine_perfume, exotic_perfume

### Construction
- quicklime, mortar, concrete, plaster, stucco

### Tools
- steel_axe, steel_pickaxe, steel_saw
- fishing_net

### Weapons (optional)
- sword, spear, shield, armor, helmet

### Clothing
- wool_hat, gloves, wool_gloves
- colored_simple_clothes, formal_attire, uniform, ceremonial_robes

### Jewelry
- silver_ring, gold_ring, silver_necklace, gold_necklace
- gemstone_jewelry, crown

### Art
- portrait, tapestry, bronze_sculpture, figurine

### Food
- smoked_meat, smoked_fish, salted_meat
- croissant, fruit_pastry, cookies
- roses (if added)

---

## 15. Implementation Priority

### Phase 1: Core Missing Chains (High Priority) - IMPLEMENTING NOW
1. Flax → Linen (completes textile variety)
2. Sheep Farm → Wool (sustainable wool source)
3. Poultry Farm → Eggs (eggs currently have no source)
4. Apiary → Honey (honey currently has no source)
5. Dye Workshop → All Dyes (enables colored products)
6. Tannery → Leather processing

### Phase 2: Processing & Crafting (Medium Priority)
1. Paper Mill → Paper, Books
2. Blacksmith → Complete tool recipes
3. Tailor → Complete clothing recipes
4. Medicine/Apothecary chain
5. Candles & Soap production

### Phase 3: Combinations & Luxury (Lower Priority)
1. Colored cloth and clothing
2. Jewelry expansion
3. Art workshop
4. Perfumery
5. Construction materials (cement, lime)

### Phase 4: Deferred Chains - SEE LATER TODO SECTION
1. Silk production (complex chain)
2. ~~Weapons/Military~~ - DEFERRED
3. ~~Salt Production~~ - DEFERRED
4. ~~Fishing industry~~ - DEFERRED

---

## 16. Production Chain Diagrams

### Textile Chain
```
Cotton ─────────────────────────────────────────┐
    │                                           │
    ▼                                           │
Thread ──────────┬──────────────────────────────┤
                 │                              │
Flax ────────────┼─────────────► Linen ─────────┤
                 │                              │
Wool ────────────┼─────────────► Yarn ──────────┤
    │            │                              │
    │            ▼                              ▼
    │         Cloth ◄───────────────────────────┘
    │            │
    │            ├──────► [+ Dye] ──────► Colored Cloth
    │            │                              │
    │            ▼                              ▼
    │      Simple Clothes              Colored Clothes
    │            │                              │
    │            ├──────► Work Clothes          │
    │            │                              │
    └────────────┼──────► Winter Coat ◄─────────┘
                 │
                 ▼
            Fine Clothes ──► [+ Gold] ──► Luxury Clothes
```

### Dye Chain
```
Berries ─────────────────────► Red Dye ────┬────────────────────────┐
                                           │                        │
Madder ──────────────────────► Red Dye ────┤                        │
                                           │                        │
Indigo ──────────────────────► Blue Dye ───┼───► Purple Dye         │
                                           │         │              │
Flowers ─────────────────────► Yellow Dye ─┼───► Green Dye          │
                                           │         │              │
Charcoal ────────────────────► Black Dye ──┘         │              │
                                                     │              │
                                                     ▼              ▼
                                              [Colored Products: Cloth, Clothes, Pottery, etc.]
```

### Animal Products Chain
```
Sheep Farm                    Poultry Farm                 Apiary
    │                              │                          │
    ├──► Wool ──► Yarn            ├──► Eggs ──► Baking       ├──► Honey ──► Medicine
    │         ──► Cloth           │         ──► Cooking       │          ──► Candles
    │                             │                           │
    ├──► Mutton ──► Cooking       ├──► Chicken ──► Cooking    └──► Beeswax ──► Candles
    │                             │                                        ──► Polish
    └──► Raw Hide ──► Tannery     └──► Feathers ──► Bedding
              │                                  ──► Arrows
              ▼
           Leather ──► Shoes, Boots, Armor, Book Binding
```

### Paper & Books Chain
```
Tree ──► Timber ──► Wood Pulp ──► Paper ──┬──► Books
                                          │
                         ┌────────────────┤
                         │                │
                         ▼                ▼
                    Fine Paper      Manuscripts
                         │                │
                         ▼                ▼
                    Ledgers          [+ Gold, Dyes]
                                          │
                                          ▼
                                  Illuminated Manuscript
```

---

## 17. LATER TODO - Deferred Implementation

The following production chains are deferred for later implementation:

### 17.1 Salt Production Chain (DEFERRED)
**Reason:** Requires coastal/terrain-specific placement logic

**When to implement:** After terrain system supports coastal detection

**Components:**
- Salt Works building (coastal extraction)
- Salt Mining recipe (inland alternative)
- `salt` commodity
- Salt-based food preservation recipes (salted_meat, etc.)
- Recipes requiring salt: pickles, preserved foods, curing

**Dependent features:**
- Smoked/salted meat preservation
- Enhanced pickling recipes
- Long-term food storage

---

### 17.2 Military/Weapons Chain (DEFERRED)
**Reason:** Requires combat/guard system to be meaningful

**When to implement:** When town defense or military units are added

**Components:**
- Weapons: sword, spear, bow, arrows, shield
- Armor: helmet, armor, chainmail, leather_armor
- Military buildings: Barracks, Armory, Training Ground

**Recipes to add:**
```
Sword Forging (Blacksmith):
  Input: steel (20), leather (3)
  Output: sword (2)

Spear Forging (Blacksmith):
  Input: iron (10), wood (15)
  Output: spear (5)

Bow Making (Workshop):
  Input: wood (15), thread (10)
  Output: bow (3)

Arrow Making (Workshop):
  Input: wood (5), iron (2), feathers (10)
  Output: arrows (50)

Shield Making (Blacksmith):
  Input: wood (20), iron (8), leather (5)
  Output: shield (3)

Armor Forging (Blacksmith):
  Input: steel (40), leather (10)
  Output: armor (1)

Helmet Forging (Blacksmith):
  Input: steel (15), leather (3)
  Output: helmet (2)

Chainmail Making (Blacksmith):
  Input: iron (50)
  Output: chainmail (1)

Leather Armor (Tannery):
  Input: tanned_leather (15), thread (10)
  Output: leather_armor (2)
```

---

### 17.3 Fishing Industry (DEFERRED)
**Reason:** Requires water/coastal placement and possibly boats

**When to implement:** When water bodies and coastal mechanics exist

**Components:**
- Fishery building
- Boat building (optional)
- `fish`, `shellfish`, `fishing_net` commodities

**Recipes:**
```
Fishing (Fishery):
  Input: fishing_net (1)
  Output: fish (40), fishing_net (1)

Net Making (Textile Mill):
  Input: thread (30)
  Output: fishing_net (2)

Shellfish Gathering (Fishery):
  Input: none
  Output: shellfish (20)
```

**Dependent features:**
- Fish-based food recipes
- Smoked fish (requires salt - also deferred)
- Fish oil production

---

### 17.4 Silk Production (DEFERRED - COMPLEX)
**Reason:** Very complex multi-step chain

**When to implement:** As a late-game luxury chain

**Components:**
- Mulberry trees (orchard)
- Sericulture Farm building
- `mulberry_sapling`, `mulberry_leaves`, `silkworm_eggs`, `silk_cocoon`, `raw_silk`

**Full chain:**
1. Mulberry Cultivation → mulberry_leaves
2. Silkworm Raising → silk_cocoon
3. Silk Reeling → silk

**Alternative:** Keep silk as trade-only import commodity

---

### 17.5 Advanced Food Preservation (DEFERRED)
**Reason:** Depends on salt production

**When to implement:** After salt is implemented

**Recipes requiring salt:**
```
Salted Meat:
  Input: beef (15), salt (5)
  Output: salted_meat (12)

Smoked Fish:
  Input: fish (25), firewood (8), salt (3)
  Output: smoked_fish (20)

Proper Pickling:
  Input: vegetables (20), salt (5), vinegar (5)
  Output: pickles (18)

Cheese Aging (enhanced):
  Input: cheese (10), salt (2)
  Output: aged_cheese (8)
```

---

*Document Version: 1.1*
*Updated: Added Later TODO section for deferred implementations*
*Created for: Cravetown Production Chain Implementation*
