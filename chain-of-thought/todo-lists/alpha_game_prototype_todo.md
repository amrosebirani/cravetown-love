# Game Prototype TODO List - Alpha Release

**Purpose:** Birthday gift alpha prototype for Mansi
**Target Date:** Tomorrow
**Priority:** Playable demo with core loop

---

## Priority Order

1. **P0 - Must Have:** Birthday screen, day/night cycle, slot-based cravings, basic UI
2. **P1 - Should Have:** Immigration, building placement, world view
3. **P2 - Nice to Have:** Loan system, trade system
4. **P3 - Cut if needed:** Advanced analytics, insights

---

## Phase 1: Birthday Screen (P0)

### Task 1.1: Create Birthday Splash Screen
- Animated "Happy Birthday Mansi!" title
- Subtitle: "This game is dedicated to you"
- Gentle animation (floating hearts, stars, or particles)
- "Click to Continue" prompt
- Store in `code/BirthdaySplash.lua`

### Task 1.2: Integrate Splash into Game Flow
- Show before title screen
- Play once per session
- Skip with any key/click after 2 seconds

---

## Phase 2: Time System Overhaul (P0)

### Task 2.1: Create TimeManager.lua
- Track current time of day (0-24 hours)
- Track current day number
- Speed settings: Normal (5 min/day), Fast (2.5 min), Faster (60 sec)
- Get current slot based on time
- Events: onSlotChange, onDayChange

### Task 2.2: Update Main Loop
- Replace cycle-based updates with time-based
- Call slot processing when slot changes
- Update UI to show time of day, not cycle number

### Task 2.3: Visual Day/Night Cycle
- Gradual lighting changes based on time
- Sky color shifts (optional for alpha)
- Time display in top bar: "Day 5, Morning (8:00)"

---

## Phase 3: Slot-Based Craving System (P0)

### Task 3.1: Load Craving-Slot Mappings
- Load from `craving_slots.json`
- Build lookup: slot → active cravings
- Apply class/trait modifiers

### Task 3.2: Refactor Craving Accumulation
- Only accumulate cravings active in current slot
- Track last accumulation per craving per slot
- Reset accumulation tracking on slot change

### Task 3.3: Refactor Allocation Engine
- Run allocation at slot boundaries
- For each character:
  - Get active cravings for this slot
  - Find optimal commodity bundle (new algorithm)
  - Allocate from inventory
  - Apply satisfaction

### Task 3.4: New Allocation Algorithm
- Input: Character's active craving vector for slot
- Goal: Find commodities that best satisfy the vector
- Greedy approach for alpha:
  1. Sort cravings by urgency
  2. For each craving, pick best available commodity
  3. Allocate until inventory depleted or satisfied

---

## Phase 4: Satisfaction & Fatigue Updates (P0)

### Task 4.1: Fine-Level Satisfaction Tracking
- Change `satisfactionCoarse[9]` to `satisfactionFine[49]`
- Compute coarse as average of fine dimensions
- Update all satisfaction calculations

### Task 4.2: Slot-Based Fatigue
- Track freshness per commodity per slot (not cycle)
- Cooldown in slots, not cycles
- Update substitution logic accordingly

### Task 4.3: Durable Goods - Daily Application
- Apply durable effects once per day
- Choose specific slot (e.g., "late_night" for beds)
- Update CharacterV2.lua

---

## Phase 5: Remove/Simplify Systems (P0)

### Task 5.1: Remove Consequences System (Temporary)
- Comment out emigration logic
- Comment out protest logic
- Comment out riot logic
- Keep satisfaction tracking

### Task 5.2: Remove Consumption Budget
- Allocate based on inventory availability only
- Remove budget-related code paths

---

## Phase 6: Data-Driven Hardcoded Values (P0)

### Task 6.1: Make Classes Data-Driven
- Load class definitions from JSON
- Remove hardcoded "Elite", "Upper", etc.
- Update all class references

### Task 6.2: Make Craving Counts Dynamic
- Compute fine count from loaded dimensions
- Compute coarse count from loaded categories
- Remove hardcoded 49 and 9

---

## Phase 7: World View UI (P1)

### Task 7.1: Basic World Rendering
- Grid-based terrain
- Building placement visualization
- Character sprites moving
- Path planning, from place of work to residence etc

### Task 7.2: Top Bar
- Town name
- Day number and time of day
- Population count
- Speed controls (Normal/Fast/Faster)
- Pause button

### Task 7.3: Left Panel
- Quick stats (overall happiness)
- Alerts (shortages)
- Mini-map (simplified)

### Task 7.4: Right Panel
- Selected entity details
- Building info
- Character summary

### Task 7.5: Bottom Bar
- Event log
- Filter buttons

---

## Phase 8: Building System (P1)

### Task 8.1: Building Placement
- Select building from menu
- Ghost preview on map
- Place with click
- Check natural resources for efficiency

### Task 8.2: Production Integration
- Buildings produce at configured rate
- Output goes to town inventory
- Show production status

---

## Phase 9: Immigration (P1)

### Task 9.1: Immigrant Generation
- Generate immigrants based on attractiveness
- Create profiles with needs/traits
- Add to immigration queue

### Task 9.2: Immigration Panel
- Show waiting immigrants
- Display compatibility score
- Accept/Reject buttons

### Task 9.3: Procedural Backstory
- Generate from craving profile
- Template: "[Name] seeks [top need] after [hardship related to low dimension]"

---

## Phase 10: Economy Basics (P2)

### Task 10.1: Trade System
- Sell commodities for gold
- Buy commodities with gold
- Fixed world prices (15% above local)

### Task 10.2: Loan System
- Request loan from world bank
- Track debt and interest
- Monthly repayment (every 30 days)
- Credit rating impact

---

## Phase 11: Polish (P2)

### Task 11.1: Icon System
- Decide: Emoji or spritesheet
- Implement icon rendering helper
- Apply to commodities, buildings, status

### Task 11.2: Notifications
- Toast notifications for events
- Color-coded by severity
- Auto-dismiss after delay

---

## Files to Create/Update

### New Files:
- `code/BirthdaySplash.lua`
- `code/TimeManager.lua`
- `code/SlotManager.lua`

### Major Updates:
- Better to create CharacterV3 and AllocationEngineV3, by inspiration from v2 files
- `code/ConsumptionPrototype.lua` - Time system integration
- `code/consumption/CharacterV2.lua` - Fine satisfaction, slot-based
- `code/consumption/AllocationEngineV2.lua` - New algorithm
- `code/consumption/CravingManager.lua` - Slot mappings

---

## Minimum Viable Alpha Checklist

- [ ] Birthday splash screen with animation
- [ ] Day/night cycle visible
- [ ] 6 time slots working
- [ ] Characters have needs per slot
- [ ] Allocation happens at slot boundaries
- [ ] Can see character satisfaction
- [ ] Can place basic buildings
- [ ] Buildings produce goods
- [ ] Basic immigration works
- [ ] No crashes during gameplay

---

## Change Log

| Date | Change |
|------|--------|
| 2025-12-06 | Created initial TODO list |
