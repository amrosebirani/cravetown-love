# Era Narrative Script: "The Rise of Prosperityville"

**Created:** 2025-01-22
**Status:** Design Complete
**Type:** Scripted Game System
**Related Documents:**
- [Era Progression System Design](era_progression_system_design.md)
- [Trade System Design](trade_system_design.md)
- [Implementation TODO](../todo-lists/era_trade_system_implementation_todo.md)

---

## Introduction: The Scripted Game System

> "Considering the challenge of distilling an epic story into a game, I started to develop a general approach that I call the 'scripted game system.' Essentially, this is a method of distilling the key parts of a story and presenting them in game form. It enables episodes to be linked together in a storyline that compresses some parts, but expands the key adventures that the players will play in detail."
> — *Rules of Play*

This document presents Cravetown's era progression as an **epic town saga** - compressing time but expanding key moments of drama, growth, and hardship. The script serves as:

1. **Tutorial guidance** - Teaches systems through story
2. **Emotional anchoring** - Makes mechanics feel meaningful
3. **Pacing framework** - Guides when to introduce complexity
4. **Achievement milestones** - Celebrates player progress

---

## Character Bible: Persistent NPCs

These characters persist across eras, aging and evolving with the town:

### Founders (Generation 1)

| Name | Role | Era Introduced | Fate | Significance |
|------|------|----------------|------|--------------|
| **Kamala** | Wagon Master / Founder | Settlement | Dies in Town era (age 72) | Spiritual leader, speaks at key moments |
| **Govind** | Elder Farmer | Settlement | Dies in Settlement (first death) | Teaches mortality early |
| **Arjun** | Kamala's Son / Guard Captain | Settlement | Lives through City | Security, protection themes |
| **Priya** | Tailor | Village | Lives through City | Craftsmanship, comfort themes |
| **Brother Thomas** | Traveling Monk / Teacher | Village | Dies in Metropolis | Education, faith, legacy |

### Second Generation

| Name | Role | Era Introduced | Significance |
|------|------|----------------|--------------|
| **Ravi** | First Child Born on Journey | Settlement (child) | Symbol of hope, becomes adult in Town |
| **Meera** | Blacksmith's Daughter | Village | Ravi's wife, first wedding |
| **Marcus Miller** | Wealthy Miller | Town | Class conflict, elite emergence |
| **Vijay** | Mason / Worker Leader | City | Worker rights, class tension |

### Third Generation

| Name | Role | Era Introduced | Significance |
|------|------|----------------|--------------|
| **Arjun Jr.** | Guard Captain's Son | City | Continuity of protection |
| **Little Meera** | Ravi's Daughter | City | Future doctor, hope |
| **The Miller Twins** | Elite Children | City | Class privilege questions |

---

## PROLOGUE: The Journey

*[Opening cinematic or text crawl - plays before Settlement era begins]*

```
════════════════════════════════════════════════════════════════════════════════

                              YEAR ONE OF THE JOURNEY

The wagons creak along the dusty road as twelve weary families approach
the valley. They've traveled for months, fleeing famine and seeking
opportunity. Among them are farmers, craftsmen, and dreamers.

As the sun sets, the wagon master - an elderly woman named Kamala -
raises her hand. The caravan stops.

"This is the place," she says, pointing to a clearing near a gentle stream.
"Here, we build our future."

The settlers look at each other. Some with hope. Some with fear.
All of them hungry.

════════════════════════════════════════════════════════════════════════════════

                              PROSPERITYVILLE BEGINS

════════════════════════════════════════════════════════════════════════════════
```

**[GAMEPLAY BEGINS - Settlement Era]**

---

## ACT I: SETTLEMENT ERA
### "The Hungry Season"

**Time Period:** Year 1, Spring through Winter
**Cravings Active:** Biological only
**Core Drama:** Survival against nature and starvation
**Tone:** Desperate hope, primal survival

---

### Episode 1.1: First Seeds

**Trigger:** Game start + 3 cycles (tutorial integration)

**Event Type:** Tutorial / Achievement

```
┌────────────────────────────────────────────────────────────────────────────┐
│                           THE FIRST MORNING                                 │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  The first night is cold. The children cry from hunger.                   │
│  In the morning, Kamala gathers the settlers.                             │
│                                                                            │
│  "We have three priorities," she announces, her voice steady              │
│  despite her years:                                                        │
│                                                                            │
│      ╔═══════════════════════════════════════════════╗                    │
│      ║  1. FOOD   - Without it, we perish           ║                    │
│      ║  2. WATER  - The stream is our lifeline      ║                    │
│      ║  3. SHELTER - Winter will not wait for us    ║                    │
│      ╚═══════════════════════════════════════════════╝                    │
│                                                                            │
│  "Everything else can wait."                                               │
│                                                                            │
│  The settlers nod. They understand. Today, they plant seeds.              │
│  Tomorrow, they pray for rain.                                             │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  TIP: Build a FARM to grow wheat. Assign workers to begin production.     │
│                                                                            │
│                              [ Begin Work ]                                │
└────────────────────────────────────────────────────────────────────────────┘
```

**Gameplay Integration:**
- Highlights Farm in building menu
- Tutorial arrow points to build button

---

### Episode 1.2: First Harvest

**Trigger:** First wheat production completes

**Event Type:** Achievement / Celebration

```
┌────────────────────────────────────────────────────────────────────────────┐
│                            🌾 FIRST HARVEST 🌾                              │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  The wheat stalks bend heavy with grain.                                  │
│                                                                            │
│  Young Ravi - just seven years old - runs through the field,              │
│  laughing. It's the first laughter heard in Prosperityville               │
│  since the journey began.                                                  │
│                                                                            │
│  That night, there is bread.                                               │
│                                                                            │
│  It's rough. It's simple. But it's THEIRS.                                │
│                                                                            │
│  Kamala raises her cup of water:                                           │
│                                                                            │
│      "To the first of many harvests.                                       │
│       To the children who will never know the road.                        │
│       To Prosperityville."                                                 │
│                                                                            │
│  The settlers echo: "To Prosperityville!"                                  │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ✦ Achievement Unlocked: FIRST HARVEST                                     │
│  ✦ +20 Wheat added to inventory                                            │
│  ✦ +5 Satisfaction (Biological) for all citizens                          │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 1.3: The Hungry Week

**Trigger:** Food inventory < 10 for 3+ cycles

**Event Type:** Crisis / Player Choice

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          ⚠️ THE HUNGRY WEEK ⚠️                              │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  The grain stores run empty three days before the harvest.                │
│                                                                            │
│  Maya, a young mother, approaches you with hollow eyes:                   │
│                                                                            │
│      "My children haven't eaten since yesterday.                           │
│       Please... is there nothing left?"                                    │
│                                                                            │
│  You look at the inventory. A few scraps of bread.                        │
│  Enough for some. Not enough for all.                                      │
│                                                                            │
│  Kamala watches from the doorway. This is YOUR decision now.              │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  HOW DO YOU DISTRIBUTE THE REMAINING FOOD?                                 │
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [A] Ration equally - Everyone gets the same, even if it's little   │  │
│  │     → All citizens receive small satisfaction boost                 │  │
│  │     → No one is full, but no one is forgotten                       │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [B] Prioritize children - They need it most                        │  │
│  │     → Families with children receive full rations                   │  │
│  │     → Adults go hungry; workers may slow down                       │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [C] Prioritize workers - Without them, no harvest comes            │  │
│  │     → Farm workers receive full rations                             │  │
│  │     → Others go hungry; families may resent the decision            │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [D] Trust the harvest - It will come. Hold what remains.           │  │
│  │     → No distribution; save food for emergency                      │  │
│  │     → Risk: If harvest is late, consequences are severe             │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

**Consequences:**
- Choice A: +2 satisfaction all, no penalties
- Choice B: +5 satisfaction families, -3 satisfaction workers, -10% productivity
- Choice C: +5 satisfaction workers, -5 satisfaction families, +10% productivity
- Choice D: Gamble - if harvest comes in 2 cycles, +10 all; if not, -15 all and 1 death risk

---

### Episode 1.4: First Death

**Trigger:** First citizen death (natural causes, starvation, or age)

**Event Type:** Narrative / Mortality Theme

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              ✝ FIRST LOSS ✝                                │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Old man Govind doesn't wake with the others.                             │
│                                                                            │
│  He was quiet - always the first to rise, the last to complain.           │
│  His hands built the first walls of the lodge.                            │
│  His stories kept the children calm on the darkest nights of the journey. │
│                                                                            │
│  Now those hands are still.                                                │
│                                                                            │
│  The settlers gather in silence. There is no temple, no priest.           │
│  Just the wind and the weight of loss.                                     │
│                                                                            │
│  Kamala speaks:                                                            │
│                                                                            │
│      "Remember him.                                                        │
│       Remember that we are not just building a town.                       │
│       We are building something that will outlast us all.                  │
│                                                                            │
│       That is our only immortality."                                       │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ✦ Govind has passed away (Age 68)                                         │
│  ✦ Population: 14 → 13                                                     │
│  ✦ -3 Satisfaction (all citizens) for 5 cycles                            │
│  ✦ Memory: "Govind's Dedication" - Workers +5% efficiency at Lodge        │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 1.5: Winter's Test

**Trigger:** First winter season arrives (cycle 40-50)

**Event Type:** Seasonal Challenge

```
┌────────────────────────────────────────────────────────────────────────────┐
│                           ❄️ WINTER'S TEST ❄️                               │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  The first snow falls.                                                     │
│                                                                            │
│  It's beautiful - the children make snow figures and laugh.               │
│  But the elders exchange worried glances.                                  │
│                                                                            │
│  Winter in a new land is no laughing matter.                              │
│                                                                            │
│  Kamala calls a meeting:                                                   │
│                                                                            │
│      "We have [X] units of food stored.                                    │
│       Winter will last approximately 20 cycles.                            │
│       We need at least [Y] to survive without loss.                        │
│                                                                            │
│       Are we ready?"                                                        │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │  WINTER SURVIVAL CHECK                                           │     │
│  │  ──────────────────────────────────────────────────────────────  │     │
│  │  Food stores:        [CURRENT] / [REQUIRED]     [STATUS]         │     │
│  │  Wood for heating:   [CURRENT] / [REQUIRED]     [STATUS]         │     │
│  │  Shelter capacity:   [CURRENT] / [REQUIRED]     [STATUS]         │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  TIP: Production slows in winter. Stock up during autumn!                  │
│                                                                            │
│                           [ Face the Winter ]                              │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### ERA TRANSITION: Settlement → Village

**Trigger:** Population ≥ 15, Satisfaction ≥ 45%, Sustained 20 cycles

**Event Type:** Era Advancement

```
════════════════════════════════════════════════════════════════════════════════

                              🏘️ GROWING PAINS 🏘️

════════════════════════════════════════════════════════════════════════════════

A year has passed. Against all odds, the settlement has survived.

The hungry weeks are behind you.
The first winter is a memory.
New faces have joined - drawn by word of fertile land and fair leadership.

But survival is not enough.

Last week, wild dogs attacked the livestock pen.
Yesterday, a stranger passed through - friendly, but who knows about the next?
The children shiver in threadbare clothes handed down three times over.

Your people no longer just need FOOD.

They need SAFETY.
They need COMFORT.

New cravings awaken. New challenges arise.

════════════════════════════════════════════════════════════════════════════════

                         Welcome to the VILLAGE era

════════════════════════════════════════════════════════════════════════════════

                              NEW UNLOCKS

    ╔═══════════════════════════════════════════════════════════════════╗
    ║  CRAVINGS                                                         ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ SAFETY    - Security from threats, stable shelter             ║
    ║  ✦ TOUCH     - Comfortable clothing, furniture, warmth           ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  BUILDINGS                                                        ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ Guard Post   - Protects citizens, deters threats              ║
    ║  ✦ Tailor       - Produces clothing for comfort and warmth       ║
    ║  ✦ Carpenter    - Crafts furniture and building materials        ║
    ║  ✦ Smithy       - Forges tools and metal goods                   ║
    ║  ✦ Warehouse    - Stores surplus goods safely                    ║
    ╚═══════════════════════════════════════════════════════════════════╝

════════════════════════════════════════════════════════════════════════════════

                              [ Continue ]

════════════════════════════════════════════════════════════════════════════════
```

---

## ACT II: VILLAGE ERA
### "The Growing Years"

**Time Period:** Years 2-3
**Cravings Active:** Biological, Safety, Touch
**Core Drama:** Building community, facing external threats
**Tone:** Cautious optimism, community building

---

### Episode 2.1: The Night Watch

**Trigger:** Village era begins + 5 cycles

**Event Type:** Introduction / Safety System

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          🛡️ THE NIGHT WATCH 🛡️                             │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  The attacks come at night.                                                │
│                                                                            │
│  First, it's wolves taking chickens from the pen.                         │
│  Then, shadows moving at the edge of the village.                         │
│  Your people sleep with one eye open.                                      │
│                                                                            │
│  Arjun, Kamala's son - now a strong man of thirty - steps forward.        │
│                                                                            │
│      "Let me form a watch," he says.                                       │
│      "Give me three strong arms and I'll keep this village safe.          │
│       No wolf, no bandit, will touch what we've built."                    │
│                                                                            │
│  Kamala looks at you. This is your village now.                           │
│  She nods, but the decision is yours.                                      │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  BUILD A GUARD POST to establish village security.                         │
│  Assign workers to begin patrols.                                          │
│                                                                            │
│  Without security, citizens will feel unsafe and may leave.                │
│                                                                            │
│                         [ Establish the Watch ]                            │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 2.2: Bandit Scare

**Trigger:** Village era + 15 cycles (scheduled event)

**Event Type:** Crisis / Tension Builder

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          ⚔️ BANDIT SCARE ⚔️                                 │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Arjun's patrol spots torches on the hill at midnight.                    │
│                                                                            │
│  Bandits. Maybe twenty of them. Surveying the village.                    │
│                                                                            │
│  By morning, they're gone. But the message is clear:                      │
│  You have something worth taking.                                          │
│                                                                            │
│  The villagers gather, fear in their eyes.                                │
│                                                                            │
│  "We need better defenses," Arjun reports.                                │
│  "More guards. Stronger walls. A place the bandits will                   │
│   think twice about raiding."                                              │
│                                                                            │
│  Old Kamala speaks:                                                        │
│      "Or... we could offer them something. Trade, not war.                │
│       Not all who live outside villages are enemies."                      │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ⚠️ Safety satisfaction has dropped to 35%                                 │
│  Citizens are anxious. Address security concerns soon.                     │
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [A] Strengthen defenses - Build more Guard Posts, assign more      │  │
│  │     guards. Show strength.                                          │  │
│  │     → +15 Safety satisfaction when complete                         │  │
│  │     → Bandits will not return                                        │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [B] Attempt diplomacy - Send an envoy with gifts.                  │  │
│  │     → Risk: May lose resources if they refuse                       │  │
│  │     → Reward: Potential trade partner if they accept                │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [C] Do nothing - Perhaps they were just passing through.           │  │
│  │     → 50% chance they attack within 20 cycles                       │  │
│  │     → 50% chance they move on                                        │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 2.3: The Tailor's Arrival

**Trigger:** Village era + 20 cycles OR first tailor shop built

**Event Type:** Immigration / Introduction

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        🧵 THE TAILOR'S ARRIVAL 🧵                           │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Spring brings a new face to Prosperityville.                             │
│                                                                            │
│  Her name is Priya. Her fingers work magic with thread.                   │
│  She arrives with nothing but a worn sewing kit and a dream.              │
│                                                                            │
│  "I can clothe your people," she says, examining the patched              │
│  garments the villagers wear.                                              │
│                                                                            │
│      "Real clothes. Not these rags you've been wearing.                    │
│       Clothes that will last. Clothes that will keep                       │
│       your children warm through winter."                                  │
│                                                                            │
│  The villagers look down at their threadbare shirts.                      │
│  For the first time, they feel self-conscious.                            │
│  For the first time, they want more than just survival.                   │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │  IMMIGRANT APPLICATION                                           │     │
│  │  ────────────────────────────────────────────────────────────── │     │
│  │  Name:     Priya                                                 │     │
│  │  Class:    Middle                                                │     │
│  │  Vocation: Tailor                                                │     │
│  │  Traits:   Creative, Meticulous                                  │     │
│  │                                                                  │     │
│  │  "In my old village, I dressed the merchant's family.            │     │
│  │   Here, I'll dress everyone like merchants."                     │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│                                                                            │
│               [ Accept Priya ]        [ Decline ]                          │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 2.4: First Wedding

**Trigger:** First marriage event (two compatible citizens of age)

**Event Type:** Celebration / Social

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         💒 FIRST WEDDING 💒                                 │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Love blooms even in the hardest soil.                                    │
│                                                                            │
│  Young Ravi - the boy who laughed in the wheat field -                    │
│  is a young man now. He's asked permission to marry                       │
│  Meera, the blacksmith's daughter.                                         │
│                                                                            │
│  They exchange vows under the old oak tree at the village center.         │
│  The whole village gathers, bringing what gifts they can spare.           │
│                                                                            │
│  Kamala, grey-haired now but eyes still sharp, wipes a tear.              │
│                                                                            │
│      "This," she says, "this is why we came here.                          │
│       Not just to survive.                                                 │
│       To LIVE."                                                            │
│                                                                            │
│  The villagers cheer. Someone produces a fiddle.                          │
│  For one night, there is music and dancing and joy.                       │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ✦ Ravi and Meera are now married!                                         │
│  ✦ +10 Social satisfaction for all citizens                                │
│  ✦ Housing assignment updated                                              │
│  ✦ Possibility of children in future cycles                                │
│                                                                            │
│           "May their home be filled with laughter and grain."              │
│                              - Village blessing                            │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### ERA TRANSITION: Village → Town

**Trigger:** Population ≥ 35, Satisfaction ≥ 50%, Guard Post + Tailor built

```
════════════════════════════════════════════════════════════════════════════════

                          🏛️ A PLACE TO CALL HOME 🏛️

════════════════════════════════════════════════════════════════════════════════

Three years. Thirty-five souls. One thriving village.

You've conquered hunger. You've built walls.
Your people wear proper clothes and sleep in warm beds.
Children are born who have never known the road.

But humanity craves more than survival.

A traveling monk stops at your village and asks:
    "Where do your children learn their letters?"

A young man returns from travels and says:
    "I've seen towns with gathering halls, where people share
     stories and dreams. Why don't we have one?"

The questions multiply. And with them, new desires.

Your people want to LEARN.
They want to BELIEVE.
They want to BELONG to something larger than themselves.

════════════════════════════════════════════════════════════════════════════════

                           Welcome to the TOWN era

════════════════════════════════════════════════════════════════════════════════

                              NEW UNLOCKS

    ╔═══════════════════════════════════════════════════════════════════╗
    ║  CRAVINGS                                                         ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ PSYCHOLOGICAL      - Education, meaning, spiritual needs      ║
    ║  ✦ SOCIAL CONNECTION  - Friendship, community, belonging         ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  BUILDINGS                                                        ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ School     - Educates citizens, raises literacy               ║
    ║  ✦ Temple     - Provides spiritual fulfillment and community     ║
    ║  ✦ Tavern     - Social gathering place, entertainment            ║
    ║  ✦ Library    - Advanced learning and research                   ║
    ║  ✦ Hospital   - Healthcare for the sick and injured              ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  SYSTEM CHANGES                                                   ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ Time slots expanded: 6 periods per day now active             ║
    ║    (Early Morning, Morning, Afternoon, Evening, Night, Late)     ║
    ║  ✦ Citizens will have more complex daily routines                ║
    ╚═══════════════════════════════════════════════════════════════════╝

════════════════════════════════════════════════════════════════════════════════

                              [ Continue ]

════════════════════════════════════════════════════════════════════════════════
```

---

## ACT III: TOWN ERA
### "The Awakening"

**Time Period:** Years 4-7
**Cravings Active:** Biological, Safety, Touch, Psychological, Social Connection
**Core Drama:** Cultural development, class emergence, community building
**Tone:** Growth and growing pains, philosophical questions

---

### Episode 3.1: The Schoolhouse

**Trigger:** Town era begins + 5 cycles

**Event Type:** Introduction / Education System

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          📚 THE SCHOOLHOUSE 📚                              │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  The traveling monk stays.                                                 │
│                                                                            │
│  Brother Thomas, they call him, with his weathered books                  │
│  and endless patience for children's questions.                           │
│                                                                            │
│  "Knowledge," he says, "is the seed of civilization.                      │
│   Every great city began with someone who could read."                     │
│                                                                            │
│  A group of children gather at his feet each morning,                     │
│  learning letters and numbers in the shade of the oak tree.               │
│                                                                            │
│  Their parents watch with a mixture of pride... and unease.               │
│                                                                            │
│      "Will learning make them too good for the farm?"                      │
│      the farmers whisper among themselves.                                 │
│                                                                            │
│      "Or will it make them wise enough to make the                         │
│       farm produce twice as much?" counters the miller.                    │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  BUILD A SCHOOL to formalize education.                                    │
│  Educated citizens are more productive and innovative.                     │
│                                                                            │
│                        [ Support Education ]                               │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 3.2: The Education Debate

**Trigger:** School built + 10 cycles

**Event Type:** Player Choice / Values

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         ⚖️ THE DEBATE ⚖️                                    │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  A heated argument erupts at the town gathering.                          │
│                                                                            │
│  The FARMERS speak:                                                        │
│      "Our children should work the fields!                                 │
│       Books don't grow wheat. Dreams don't feed mouths.                    │
│       We need hands, not heads full of fancy ideas."                       │
│                                                                            │
│  The CRAFTSMEN counter:                                                    │
│      "An educated child can become anything -                              │
│       a doctor, a merchant, even a leader!                                 │
│       Do you want your grandchildren to be dirt farmers forever?"          │
│                                                                            │
│  Brother Thomas tries to mediate:                                          │
│      "Perhaps there is a middle path..."                                   │
│                                                                            │
│  The town looks to you. What kind of society will Prosperityville be?     │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [A] Universal education - Every child attends school               │  │
│  │     → +Psychological satisfaction, slower labor pool growth        │  │
│  │     → Long-term: Higher productivity, more class mobility          │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [B] Selective education - Only craftsmen's children attend         │  │
│  │     → Class divisions begin to solidify                            │  │
│  │     → Craftsmen +10 satisfaction, farmers -5 satisfaction          │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [C] Family choice - Each family decides for their own children     │  │
│  │     → Mixed outcomes, some educated, some not                       │  │
│  │     → No immediate satisfaction change                              │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 3.3: Founder's Passing

**Trigger:** Kamala reaches age 72 OR Town era + 30 cycles

**Event Type:** Major Narrative / Death of Key Character

```
┌────────────────────────────────────────────────────────────────────────────┐
│                     ✝ THE FOUNDER'S PASSING ✝                              │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Kamala passes peacefully in her sleep, at the age of seventy-two.        │
│                                                                            │
│  She led twelve wagons out of famine.                                     │
│  She saw a settlement become a village become a town.                     │
│  She witnessed the first harvest, the first wedding, the first school.   │
│                                                                            │
│  Her last words, spoken to you at sunset:                                 │
│                                                                            │
│      "Build something that lasts.                                          │
│       Not just buildings. Not just walls.                                  │
│                                                                            │
│       Build a place where children can dream                               │
│       of things we never imagined.                                         │
│                                                                            │
│       That is the only immortality we get."                                │
│                                                                            │
│  ─────────────────────────────────────────────────────────────────────    │
│                                                                            │
│  The town gathers to mourn. Someone suggests building a temple            │
│  in her memory - a place to mark births, deaths, marriages,               │
│  and the passage of seasons.                                               │
│                                                                            │
│  For the first time, the people think about LEGACY.                       │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ✦ Kamala, Founder of Prosperityville, has passed (Age 72)                │
│  ✦ -10 Satisfaction (all citizens) for 10 cycles - period of mourning    │
│  ✦ +5 Psychological satisfaction when Temple is built                      │
│  ✦ Memory: "Kamala's Vision" - Immigrant attraction +10%                   │
│                                                                            │
│           "She showed us the way. Now we must walk it ourselves."          │
│                              - Arjun, at the funeral                       │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 3.4: The Class Divide Emerges

**Trigger:** First Manor built OR wealth gap exceeds threshold

**Event Type:** Economic / Social Tension

```
┌────────────────────────────────────────────────────────────────────────────┐
│                       💰 THE CLASS DIVIDE 💰                                │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Not everyone shares equally in Prosperityville's success.                │
│                                                                            │
│  The Miller family owns the only mill in town.                            │
│  Slowly, their wealth has grown. They've hired helpers.                   │
│  They dress in finer clothes. They eat better food.                       │
│                                                                            │
│  Marcus Miller approaches you with a proposal:                            │
│                                                                            │
│      "I wish to build a proper house. Not a lodge - a HOUSE.              │
│       One befitting my family's... contribution to this town.             │
│                                                                            │
│       I have the gold. I have the right.                                   │
│       Do I have your blessing?"                                            │
│                                                                            │
│  Behind him, the workers watch and whisper.                               │
│  Some admire his success. Some resent it.                                 │
│                                                                            │
│  Do you allow luxury housing while others share crowded lodges?           │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [A] Approve the Manor - Wealth should be rewarded                  │  │
│  │     → Manor construction unlocked                                   │  │
│  │     → Elite class begins to form                                    │  │
│  │     → Workers: -5 satisfaction ("Why do they get more?")            │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [B] Approve with conditions - Fund public works first              │  │
│  │     → Miller must contribute to town hospital/school               │  │
│  │     → Delayed Manor, but goodwill maintained                        │  │
│  │     → Sets precedent: wealth comes with obligation                  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [C] Deny the request - Equality must be maintained                 │  │
│  │     → Miller: -15 satisfaction, may emigrate                        │  │
│  │     → Workers: +5 satisfaction                                      │  │
│  │     → Wealthy families less likely to immigrate                     │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### ERA TRANSITION: Town → City

**Trigger:** Population ≥ 75, Treasury ≥ 3000, Elite ≥ 5%

```
════════════════════════════════════════════════════════════════════════════════

                          👑 RISE OF THE ELITE 👑

════════════════════════════════════════════════════════════════════════════════

Seven years. Seventy-five citizens. One prosperous town.

The children who were born on the journey are now adults.
The town has a school, a temple, a tavern, a hospital.
Your people are fed, safe, educated, and connected.

But wealth has concentrated in certain hands.
The Miller family built their manor. The merchants followed.
Now there are those who OWN, and those who WORK.

The wealthy seek STATUS. They seek PRESTIGE.
They seek tools and luxuries worthy of their position.

And they've heard whispers of something more...

A delegation of merchants approaches you:

    "We've heard of towns beyond the mountains.
     Towns where we could TRADE our surplus for goods we cannot make.
     Isn't it time Prosperityville looked outward?"

The world is larger than your valley.
Perhaps it's time to reach beyond it.

════════════════════════════════════════════════════════════════════════════════

                           Welcome to the CITY era

════════════════════════════════════════════════════════════════════════════════

                              NEW UNLOCKS

    ╔═══════════════════════════════════════════════════════════════════╗
    ║  CRAVINGS                                                         ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ SOCIAL STATUS  - Prestige, reputation, visible success        ║
    ║  ✦ UTILITY        - Tools, practical equipment                   ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  BUILDINGS                                                        ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ Bank        - Manages wealth, enables investment              ║
    ║  ✦ Workshop    - Advanced tool and equipment production          ║
    ║  ✦ Manor       - Luxury housing for the elite                    ║
    ║  ✦ Courthouse  - Law and administration                          ║
    ║  ✦ Depot       - Trade goods storage and handling                ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  🌍 TRADE SYSTEM NOW AVAILABLE                                    ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  Establish trade routes with neighboring towns!                   ║
    ║  Export your surplus. Import what you need.                       ║
    ║  The world awaits...                                              ║
    ╚═══════════════════════════════════════════════════════════════════╝

════════════════════════════════════════════════════════════════════════════════

                              [ Continue ]

════════════════════════════════════════════════════════════════════════════════
```

---

## ACT IV: CITY ERA
### "The Trading Years"

**Time Period:** Years 8-15
**Cravings Active:** +Social Status, Utility
**Core Drama:** Trade relations, class conflict, economic growth
**Tone:** Expansion and tension, opportunity and inequality

---

### Episode 4.1: The Emissary

**Trigger:** City era + 5 cycles (scheduled)

**Event Type:** Trade System Introduction

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         🤝 THE EMISSARY 🤝                                  │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  The stranger arrives on a fine horse, wearing clothes                    │
│  nicer than anything seen in Prosperityville.                             │
│                                                                            │
│  "I am Abbas," he announces, dismounting in the town square.              │
│  "Trade emissary from Saltshore, the fishing village by the eastern sea." │
│                                                                            │
│  He spreads a map on the tavern table.                                    │
│                                                                            │
│      "Your wheat reaches far and wide in reputation.                       │
│       Our fish could fill your bellies with variety.                       │
│       Our salt could preserve your meat through winter.                    │
│                                                                            │
│       Shall we talk business?"                                             │
│                                                                            │
│  The merchants lean forward eagerly.                                       │
│  The farmers look uncertain.                                               │
│  A new era beckons.                                                        │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │  TRADE PARTNER DISCOVERED                                        │     │
│  │  ────────────────────────────────────────────────────────────── │     │
│  │  SALTSHORE - Fishing Village                                     │     │
│  │                                                                  │     │
│  │  They offer:  Fish, Dried Fish, Salt                            │     │
│  │  They seek:   Wheat, Vegetables, Tools                          │     │
│  │                                                                  │     │
│  │  Personality: Friendly, fair prices                              │     │
│  │  Establishment cost: 500 gold                                    │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│                                                                            │
│           [ Open Trade Panel ]        [ Decline for Now ]                  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 4.2: First Caravan

**Trigger:** First trade exchange completes

**Event Type:** Achievement / Celebration

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        🐪 FIRST CARAVAN 🐪                                  │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  The trade agreement is signed.                                            │
│  Prosperityville will send wheat east. Saltshore will send fish west.     │
│                                                                            │
│  Three weeks later, the first caravan arrives.                            │
│                                                                            │
│  The whole city gathers to watch the wagons roll through the gates,       │
│  laden with barrels of salted fish and blocks of pure sea salt.           │
│                                                                            │
│  The children have never seen the ocean.                                   │
│  They crowd around the Saltshore merchants, asking endless questions      │
│  about ships and whales and islands made of ice.                          │
│                                                                            │
│  That night, for the first time, Prosperityville eats fish.               │
│                                                                            │
│  Abbas raises a toast:                                                     │
│      "To prosperity through partnership!                                   │
│       May our roads be safe and our scales be fair."                       │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ✦ Achievement Unlocked: FIRST TRADE                                       │
│  ✦ Trade Summary:                                                          │
│      Exported: 50 Wheat (+400 gold), 20 Vegetables (+120 gold)            │
│      Imported: 30 Fish, 10 Salt                                            │
│  ✦ Saltshore trust level: 10%                                              │
│  ✦ +5 Exotic satisfaction (new food variety!)                              │
│                                                                            │
│              "The world grows smaller, and we grow larger."                │
│                              - City merchant proverb                       │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 4.3: Worker's Grievance

**Trigger:** City era + wealth inequality exceeds threshold

**Event Type:** Crisis / Class Conflict

```
┌────────────────────────────────────────────────────────────────────────────┐
│                       ✊ WORKER'S GRIEVANCE ✊                               │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Not everyone celebrates the trade profits.                               │
│                                                                            │
│  The merchants grow wealthy. The manor district expands.                  │
│  But the workers' wages stay the same.                                    │
│                                                                            │
│  A crowd gathers outside the Courthouse.                                  │
│  Their leader, a mason named Vijay, carries a petition.                   │
│                                                                            │
│      "We built this city with our HANDS!" he declares.                    │
│      "Every brick. Every road. Every wall that keeps YOU safe.            │
│                                                                            │
│       The merchants count gold while we count copper.                      │
│       The elite eat fish while we eat the same grain as always.           │
│                                                                            │
│       We don't want revolution. We want FAIRNESS."                         │
│                                                                            │
│  ─────────────────────────────────────────────────────────────────────    │
│                       THE WORKERS' PETITION                                │
│  ─────────────────────────────────────────────────────────────────────    │
│  1. Higher wages for manual labor                                          │
│  2. Guaranteed food rations regardless of employment                       │
│  3. A seat on the city council for worker representation                   │
│  ─────────────────────────────────────────────────────────────────────    │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [A] Accept all demands - Appease workers                           │  │
│  │     → Workers: +20 satisfaction                                     │  │
│  │     → Elite: -15 satisfaction, may emigrate                         │  │
│  │     → Production costs increase 15%                                 │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [B] Accept wage increase only - Compromise                         │  │
│  │     → Workers: +10 satisfaction                                     │  │
│  │     → Elite: -5 satisfaction                                        │  │
│  │     → Production costs increase 8%                                  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [C] Reject demands - Maintain current order                        │  │
│  │     → Workers: -15 satisfaction, productivity -10%                  │  │
│  │     → Risk: Strike possible if satisfaction drops further          │  │
│  │     → Elite: +5 satisfaction                                        │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [D] Public debate - Let the town decide                            │  │
│  │     → Outcome based on current class satisfaction balance           │  │
│  │     → Everyone feels heard; no immediate penalties                  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 4.4: The Second Generation

**Trigger:** City era + 30 cycles (generational milestone)

**Event Type:** Narrative / Reflection

```
┌────────────────────────────────────────────────────────────────────────────┐
│                    👨‍👩‍👧‍👦 THE SECOND GENERATION 👨‍👩‍👧‍👦                          │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Fifteen years since the wagons stopped.                                  │
│                                                                            │
│  The children of the journey are now the leaders of the city.             │
│                                                                            │
│  • Arjun commands the city guard, his hair now grey at the temples        │
│  • Priya runs the tailor's guild, training the next generation            │
│  • Ravi and Meera have children of their own - Little Meera shows         │
│    talent as a healer; young Amit dreams of becoming a merchant           │
│                                                                            │
│  Brother Thomas, old now and nearly blind, still teaches in the school.   │
│  His students have become teachers themselves.                             │
│                                                                            │
│  A new generation has never known hunger.                                  │
│  They dream of things their parents never imagined.                       │
│                                                                            │
│      "What kind of city will they inherit?" asks Brother Thomas,          │
│       looking out at the bustling streets.                                 │
│                                                                            │
│      "The kind we build for them," you reply.                              │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ✦ GENERATIONAL MILESTONE                                                  │
│  ────────────────────────────────────────────────────────────────────     │
│  Population:                95 citizens                                    │
│  Second generation adults:  23 (first children now grown)                 │
│  Third generation:          12 (children of children)                      │
│  Founders remaining:        4 (most have passed)                          │
│                                                                            │
│  The choices you've made echo in their futures.                           │
│  The choices you'll make will shape their children.                       │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### ERA TRANSITION: City → Metropolis

**Trigger:** Population ≥ 150, Treasury ≥ 10000, Active Trade Routes ≥ 1

```
════════════════════════════════════════════════════════════════════════════════

                        ✨ COSMOPOLITAN DREAMS ✨

════════════════════════════════════════════════════════════════════════════════

Fifteen years. One hundred fifty souls. One thriving city.

Trade caravans arrive weekly. Gold flows through your markets.
Your citizens are educated, connected, and proud.
Your elite wear fine clothes and live in manors.

And yet, they want MORE.

Whispers spread of lands beyond the trade routes.
Merchants speak of silk from the east, spices from the south,
gems that sparkle like captured starlight.

Your people's appetites have grown sophisticated.

They crave the EXOTIC - rare items from foreign lands.
They desire the LUXURIOUS - beautiful objects that shimmer and shine.
Some even seek darker pleasures... VICE.

A caravan arrives from Sandhaven, the desert oasis.
They bring goods you've never seen before: silks in impossible colors,
spices that make the tongue dance, gems that seem to hold fire within.

Their leader approaches:
    "Join the great trade network,
     and the world's treasures will flow to your city."

The final era dawns.

════════════════════════════════════════════════════════════════════════════════

                         Welcome to the METROPOLIS era

════════════════════════════════════════════════════════════════════════════════

                              NEW UNLOCKS

    ╔═══════════════════════════════════════════════════════════════════╗
    ║  CRAVINGS                                                         ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ EXOTIC GOODS   - Rare imports, foreign delicacies             ║
    ║  ✦ SHINY OBJECTS  - Gems, precious metals, beautiful things      ║
    ║  ✦ VICE           - Intoxicants, gambling, indulgence            ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  BUILDINGS                                                        ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ Market     - Hub for exotic goods trade                       ║
    ║  ✦ Jeweler    - Crafts precious jewelry and ornaments            ║
    ║  ✦ Brewery    - Produces alcoholic beverages                     ║
    ║  ✦ Theater    - Entertainment and cultural events                ║
    ║  ✦ Casino     - Gambling establishment (high risk/reward)        ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  TRADE EXPANSION                                                  ║
    ║  ─────────────────────────────────────────────────────────────── ║
    ║  ✦ Additional trade route slots unlocked                          ║
    ║  ✦ Exotic trade partner available: SANDHAVEN                      ║
    ║    - Offers: Silk, Spices, Gems                                   ║
    ║    - Seeks: Everything (trade hub)                                ║
    ╚═══════════════════════════════════════════════════════════════════╝

════════════════════════════════════════════════════════════════════════════════

        "We have become the city Kamala dreamed of.
         Now we must decide: what kind of city do WE dream of?"

════════════════════════════════════════════════════════════════════════════════

                              [ Continue ]

════════════════════════════════════════════════════════════════════════════════
```

---

## ACT V: METROPOLIS ERA
### "The Golden Age (and Its Shadows)"

**Time Period:** Years 16+
**Cravings Active:** All 10 categories
**Core Drama:** Managing prosperity, vice, legacy
**Tone:** Complexity, moral choices, legacy building

---

### Episode 5.1: The Exotic Merchants

**Trigger:** Metropolis era + 3 cycles

**Event Type:** Trade Expansion

```
┌────────────────────────────────────────────────────────────────────────────┐
│                      🏜️ THE EXOTIC MERCHANTS 🏜️                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  The Sandhaven merchants spread their wares in the market square.         │
│                                                                            │
│  Silks in colors your people have never seen -                            │
│  deep purples, shimmering golds, blues like the midnight sky.             │
│                                                                            │
│  Spices that make the nose tingle and the mouth water -                   │
│  pepper that burns, cinnamon that warms, saffron worth more than gold.    │
│                                                                            │
│  Gems that seem to hold captured sunlight -                               │
│  rubies like frozen fire, emeralds like spring leaves, diamonds           │
│  that scatter rainbows across the cobblestones.                           │
│                                                                            │
│  The elite crowd around, gold in hand, eyes wide with desire.             │
│  The workers watch through windows, dreaming of things                    │
│  they may never afford.                                                    │
│                                                                            │
│  Prosperity has a new face: foreign, dazzling, tempting.                  │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │  NEW TRADE PARTNER: SANDHAVEN (Desert Oasis)                     │     │
│  │  ────────────────────────────────────────────────────────────── │     │
│  │  Exports available:                                              │     │
│  │    • Silk        - luxury fabric (+15 Touch, +10 Status)        │     │
│  │    • Spices      - exotic flavoring (+10 Exotic)                │     │
│  │    • Gems        - precious stones (+20 Shiny)                  │     │
│  │    • Incense     - aromatic luxury (+5 Psychological)           │     │
│  │                                                                  │     │
│  │  They seek: Wheat, Tools, Cloth, Iron (high demand for all)     │     │
│  │  Establishment cost: 1500 gold                                   │     │
│  │  Personality: Opportunistic, premium prices                      │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│                                                                            │
│       [ Establish Sandhaven Route ]    [ View Trade Panel ]                │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 5.2: The Vice Question

**Trigger:** Metropolis era + treasury > 15000 gold

**Event Type:** Player Choice / Ethics

```
┌────────────────────────────────────────────────────────────────────────────┐
│                       🎰 THE VICE QUESTION 🎰                               │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  With wealth comes temptation.                                             │
│                                                                            │
│  A consortium of merchants presents a proposal:                           │
│  "THE ENTERTAINMENT DISTRICT"                                              │
│                                                                            │
│      "People need release," argues the lead merchant.                      │
│      "They work hard. They earn gold. Let them enjoy it!                   │
│                                                                            │
│       A brewery for ales and wines.                                        │
│       A theater for drama and music.                                       │
│       A casino for those who dream of fortune.                             │
│                                                                            │
│       Why should our citizens spend their gold in other cities?"           │
│                                                                            │
│  Brother Thomas - old now, voice trembling - protests:                    │
│                                                                            │
│      "This will corrupt our youth!                                         │
│       We built this city on honest labor, not dice and drink.             │
│       Kamala would never have allowed this."                               │
│                                                                            │
│  The merchants mutter. The workers look interested.                       │
│  The elite see profit. The families see danger.                           │
│                                                                            │
│  What kind of city will Prosperityville become?                           │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [A] Approve all - Brewery, Theater, and Casino                     │  │
│  │     → Vice cravings can be fully satisfied                          │  │
│  │     → High tax revenue from entertainment                           │  │
│  │     → Risk: Addiction events, productivity loss                     │  │
│  │     → Brother Thomas: -20 satisfaction, may leave                   │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [B] Approve Brewery and Theater only - Moderate entertainment      │  │
│  │     → Alcohol and entertainment available                           │  │
│  │     → Gambling remains forbidden                                    │  │
│  │     → Balanced approach                                             │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [C] Approve Theater only - Culture, not corruption                 │  │
│  │     → Only entertainment satisfaction available                     │  │
│  │     → Traditional values maintained                                 │  │
│  │     → Some citizens will seek vice elsewhere                        │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [D] Reject all - Maintain traditional values                       │  │
│  │     → Vice cravings cannot be satisfied locally                     │  │
│  │     → -10 satisfaction for citizens with vice cravings              │  │
│  │     → Brother Thomas: +10 satisfaction                              │  │
│  │     → Reputation: "City of Virtue"                                  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 5.3: Immigration Wave

**Trigger:** Population > 120, Satisfaction > 60%

**Event Type:** Growth Management

```
┌────────────────────────────────────────────────────────────────────────────┐
│                     🚶 THE IMMIGRATION WAVE 🚶                              │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Word of Prosperityville's wealth spreads far.                            │
│                                                                            │
│  Caravans now arrive not just with goods, but with PEOPLE.                │
│  Families fleeing hardship. Craftsmen seeking opportunity.                │
│  Scholars drawn by the library. Merchants by the markets.                 │
│                                                                            │
│  This season's applicants include:                                         │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │ • The Chen Family (5 members)                                    │     │
│  │   Wealthy merchants from the east. Seek trade opportunities.     │     │
│  │   Would bring 2000 gold in investment.                           │     │
│  │                                                                  │     │
│  │ • Master Okonkwo                                                 │     │
│  │   Master jeweler seeking a workshop. Elite craftsman.            │     │
│  │   Could establish luxury goods production.                       │     │
│  │                                                                  │     │
│  │ • The Displaced Village (15 members)                             │     │
│  │   Refugees from drought. Desperate, with nothing but hope.       │     │
│  │   Mix of farmers and laborers.                                   │     │
│  │                                                                  │     │
│  │ • "The Scholar"                                                  │     │
│  │   Mysterious academic. Claims to know "ancient knowledge."       │     │
│  │   No references. Refuses to give full name.                      │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│                                                                            │
│  Housing capacity: 165  │  Current population: 150                         │
│  Applicants waiting: 23 │  Can accept: Up to 15                            │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  HOW DO YOU MANAGE THE INFLUX?                                             │
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ [A] Accept all who can be housed - Open doors policy              │  │
│  │ [B] Prioritize skilled workers - Merit-based immigration          │  │
│  │ [C] Prioritize refugees - Compassionate approach                  │  │
│  │ [D] Accept wealthy only - Elite-focused growth                    │  │
│  │ [E] Close borders temporarily - Consolidate current population    │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

### Episode 5.4: The Legacy Project

**Trigger:** Metropolis era + 50 cycles

**Event Type:** End-Game / Legacy Building

```
┌────────────────────────────────────────────────────────────────────────────┐
│                      🏛️ THE LEGACY PROJECT 🏛️                              │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Twenty years since the wagons stopped.                                   │
│                                                                            │
│  The original settlers are elders now, grey-haired and proud.             │
│  Their grandchildren run through streets they could never have            │
│  imagined during the hungry first year.                                    │
│                                                                            │
│  The City Council proposes a question:                                     │
│                                                                            │
│      "What will we build that will outlast us all?                         │
│       What monument will tell future generations                           │
│       who we were and what we valued?"                                     │
│                                                                            │
│  Four proposals emerge:                                                    │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │ 📚 THE GRAND LIBRARY                                             │     │
│  │ "Preserve knowledge for a thousand generations."                 │     │
│  │ → Education bonus for entire city                                │     │
│  │ → Attracts scholars and researchers                              │     │
│  │ → Cost: 5000 gold, 500 stone, 200 lumber                         │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │ 🌳 THE MEMORIAL GARDENS                                          │     │
│  │ "Honor all who built this city, from Kamala to the last child." │     │
│  │ → Community satisfaction bonus                                   │     │
│  │ → Reduces grief from deaths                                      │     │
│  │ → Cost: 3000 gold, 300 stone, special plants                     │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │ 🎓 THE TRADE ACADEMY                                             │     │
│  │ "Train the merchants and leaders of tomorrow."                   │     │
│  │ → Trade efficiency bonus                                         │     │
│  │ → Attracts wealthy immigrants                                    │     │
│  │ → Cost: 4000 gold, 400 stone, 150 lumber                         │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │ 🏥 THE GREAT HOSPITAL                                            │     │
│  │ "Care for all, rich and poor alike, from birth to death."       │     │
│  │ → Health bonus for entire city                                   │     │
│  │ → Reduces death rate                                             │     │
│  │ → Cost: 4500 gold, 450 stone, 200 lumber                         │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  CHOOSE YOUR LEGACY:                                                       │
│                                                                            │
│  [A] Grand Library    [B] Memorial Gardens                                 │
│  [C] Trade Academy    [D] Great Hospital                                   │
│  [E] Build All (over time - requires massive resources)                   │
│                                                                            │
│  Your choice becomes Prosperityville's defining monument.                  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## EPILOGUE: The Continuing Story

**Trigger:** After significant Metropolis playtime (100+ cycles)

```
════════════════════════════════════════════════════════════════════════════════

                         📖 THE CONTINUING STORY 📖

════════════════════════════════════════════════════════════════════════════════

From twelve wagons to a thriving metropolis.
From starvation to sophistication.
From survival to legacy.

This is the story of Prosperityville.

But it's not over.

New challenges await. New generations will rise.
Trade routes will shift. Crises will come.
The choices you've made echo forward through time.

    • The education policy you set shapes how children learn
    • The class structure you built determines who prospers
    • The trade relationships you forged connect you to the world
    • The values you chose define who your people are

Kamala's words, inscribed now on the temple wall:

    ╔═══════════════════════════════════════════════════════════════════╗
    ║                                                                   ║
    ║   "We did not inherit this land from our ancestors.              ║
    ║    We are borrowing it from our children."                       ║
    ║                                                                   ║
    ║                        - Kamala, Founder                         ║
    ║                          (Year 1 - Year 7)                       ║
    ║                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════╝

What happens next... is up to you.

════════════════════════════════════════════════════════════════════════════════

                           [ Continue Playing ]

════════════════════════════════════════════════════════════════════════════════
```

---

## Appendix A: Event Trigger Reference

| Event ID | Era | Trigger Type | Trigger Condition |
|----------|-----|--------------|-------------------|
| `first_morning` | Settlement | Scheduled | Game start + 3 cycles |
| `first_harvest` | Settlement | Achievement | First wheat production |
| `hungry_week` | Settlement | Crisis | Food < 10 for 3 cycles |
| `first_death` | Settlement | Narrative | Any citizen death |
| `winters_test` | Settlement | Seasonal | Cycle 40-50 |
| `era_1_to_2` | Settlement | Transition | Population, satisfaction thresholds |
| `night_watch` | Village | Scheduled | Era start + 5 cycles |
| `bandit_scare` | Village | Scheduled | Era start + 15 cycles |
| `tailor_arrival` | Village | Immigration | Era start + 20 cycles |
| `first_wedding` | Village | Achievement | First marriage |
| `era_2_to_3` | Village | Transition | Population, buildings thresholds |
| `schoolhouse` | Town | Scheduled | Era start + 5 cycles |
| `education_debate` | Town | Choice | School built + 10 cycles |
| `founders_passing` | Town | Narrative | Kamala age 72 OR era + 30 cycles |
| `class_divide` | Town | Economic | Manor built OR wealth gap |
| `era_3_to_4` | Town | Transition | Population, treasury, elite thresholds |
| `emissary` | City | Scheduled | Era start + 5 cycles |
| `first_caravan` | City | Achievement | First trade exchange |
| `workers_grievance` | City | Crisis | Wealth inequality threshold |
| `second_generation` | City | Narrative | Era + 30 cycles |
| `era_4_to_5` | City | Transition | Population, treasury, trade route |
| `exotic_merchants` | Metropolis | Scheduled | Era start + 3 cycles |
| `vice_question` | Metropolis | Choice | Treasury > 15000 |
| `immigration_wave` | Metropolis | Growth | Population > 120, satisfaction > 60 |
| `legacy_project` | Metropolis | End-game | Era + 50 cycles |
| `epilogue` | Metropolis | Reflection | Era + 100 cycles |

---

## Appendix B: Character Fate Timeline

| Character | Settlement | Village | Town | City | Metropolis |
|-----------|------------|---------|------|------|------------|
| Kamala | Leader (60s) | Elder (60s) | **Dies** (72) | Memory | Memory |
| Govind | **Dies** (68) | Memory | Memory | Memory | Memory |
| Arjun | Young (20s) | Guard Capt (30s) | Commander (40s) | Elder (50s) | **Dies** (60s) |
| Priya | - | Arrives (30s) | Master (40s) | Guild Head (50s) | Elder (60s) |
| Brother Thomas | - | Arrives (50s) | Teacher (60s) | Elder (70s) | **Dies** (80s) |
| Ravi | Child (7) | Youth (10s) | Adult (20s) | Parent (30s) | Elder (40s) |
| Meera | - | Youth (10s) | Wife (20s) | Parent (30s) | Elder (40s) |
| Marcus Miller | - | - | Wealthy (30s) | Elite (40s) | Patriarch (50s) |
| Vijay | - | - | - | Worker Leader | Elder |
| Little Meera | - | - | - | Child | Doctor |
| Arjun Jr. | - | - | - | Child | Guard Capt |

---

## Appendix C: Choice Consequence Summary

| Choice | Option A | Option B | Option C | Option D |
|--------|----------|----------|----------|----------|
| Hungry Week | Equal rations | Children first | Workers first | Wait for harvest |
| Bandit Scare | Strengthen defenses | Diplomacy | Do nothing | - |
| Education Debate | Universal | Selective | Family choice | - |
| Class Divide | Approve Manor | Conditional approval | Deny | - |
| Worker's Grievance | Accept all | Wage increase only | Reject | Public debate |
| Vice Question | All vice | Brewery+Theater | Theater only | Reject all |
| Immigration Wave | Open doors | Merit-based | Compassionate | Elite-only | Close borders |
| Legacy Project | Library | Gardens | Academy | Hospital | All |

Each choice creates lasting effects on satisfaction, class dynamics, and city character.

---

## Implementation Notes

### Data Files to Create

| File | Content |
|------|---------|
| `data/alpha/narrative/era_events.json` | Event definitions, triggers, text |
| `data/alpha/narrative/key_characters.json` | Persistent NPC data |
| `data/alpha/narrative/choice_consequences.json` | Choice outcomes |

### Code Modules to Create

| Module | Purpose |
|--------|---------|
| `code/NarrativeSystem.lua` | Event scheduling, triggering, tracking |
| `code/ui/NarrativeModal.lua` | Story text display |
| `code/ui/ChoiceModal.lua` | Player choice interface |
| `code/CharacterTracker.lua` | Track persistent NPCs across eras |

### Integration Points

- Hook into `EraSystem` for era transitions
- Hook into citizen lifecycle for birth/death events
- Hook into production for achievement events
- Hook into economy for crisis events
- Hook into immigration for arrival events
