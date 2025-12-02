# Task Creation Rubric

**Purpose:** Ensure all new features are consistently implemented across all relevant systems. Use this checklist when planning any new feature or system change.

---

## Core Feature Implementation Checklist

When implementing any new feature, always consider the following areas:

### 1. Data Layer
- [ ] Update relevant JSON data files (fulfillment_vectors, recipes, etc.)
- [ ] Add schema documentation for new fields
- [ ] Update data version number if schema changes
- [ ] Ensure backward compatibility with existing saves

### 2. Core Logic
- [ ] Implement core functionality in appropriate module
- [ ] Add helper/utility functions as needed
- [ ] Handle edge cases and validation
- [ ] Add appropriate logging/debugging output

### 3. Character System (if character-related)
- [ ] Update CharacterV2.lua with new state/layers
- [ ] Add getter/setter functions
- [ ] Update character initialization
- [ ] Consider trait/class interactions

### 4. Allocation System (if resource-related)
- [ ] Update AllocationEngineV2.lua logic
- [ ] Modify commodity selection algorithms
- [ ] Handle substitution rules if applicable
- [ ] Update priority calculations if needed

### 5. Cycle Processing
- [ ] Integrate into Update loop at correct timing
- [ ] Add per-cycle updates (decay, growth, etc.)
- [ ] Handle cycle-boundary events

### 6. Save/Load Support
- [ ] Add to CreateSaveData serialization
- [ ] Add to LoadSaveData deserialization
- [ ] Handle migration from old save formats
- [ ] Test save/load round-trip

### 7. Event Logging
- [ ] Add LogEvent calls for notable events
- [ ] Use consistent event type naming
- [ ] Include relevant data in event payload

---

## UI Implementation Checklist

### 8. Consumption Prototype UI
- [ ] **Character Detail Modal**: Add section for new data
- [ ] **Character Cards**: Add indicators/badges if relevant
- [ ] **Edit Mode**: Add controls to modify new data
- [ ] **Analytics/Heatmap**: Include in summary views if applicable
- [ ] **History Display**: Update to show new event types

### 9. Information System UI
- [ ] **New Tab** (if major new entity type)
- [ ] **Detail View**: Display new fields in existing tabs
- [ ] **Edit Controls**: Allow editing new fields
- [ ] **Search/Filter**: Include new fields in filtering
- [ ] **Validation**: Add input validation for new fields

### 10. Testing Tools UI
- [ ] Add test scenarios for new feature
- [ ] Add debug controls/buttons
- [ ] Add visualization helpers

---

## Integration Checklist

### 11. MCP Server Integration
- [ ] **New Tools**: Add MCP tools for querying/modifying new data
- [ ] **Existing Tools**: Update existing tools if schema changed
- [ ] **Prompts**: Add/update prompts for new capabilities
- [ ] **Documentation**: Update MCP tool descriptions

### 12. Cross-System Integration
- [ ] Town Consequences: Does this affect riots/emigration/unrest?
- [ ] Productivity: Does this affect character productivity?
- [ ] Commodity Cache: Does this need cache invalidation?
- [ ] Substitution Rules: Does this interact with substitution?

---

## Documentation Checklist

### 13. Code Documentation
- [ ] Add function comments for new public functions
- [ ] Update module header comments
- [ ] Add inline comments for complex logic

### 14. Implementation Plan Updates
- [ ] Update changelog in implementation plan
- [ ] Mark tasks as complete
- [ ] Document any deviations from plan

---

## Feature-Specific Considerations

### For New Commodity Types
- [ ] Add to fulfillment_vectors.json
- [ ] Define quality multipliers
- [ ] Set up substitution hierarchies
- [ ] Add to InfoSystem commodity list
- [ ] Consider MCP commodity tools

### For New Character Attributes
- [ ] Add to CharacterV2 initialization
- [ ] Add to character detail modal
- [ ] Add to character card display
- [ ] Add to save/load
- [ ] Consider trait/class modifiers
- [ ] Add MCP character query support

### For New Mechanics/Systems
- [ ] Create dedicated module if complex
- [ ] Add configuration to consumption_mechanics.json
- [ ] Add to cycle processing
- [ ] Create UI section
- [ ] Add InfoSystem tab if major
- [ ] Add MCP tools for control

### For UI-Only Changes
- [ ] Update relevant render functions
- [ ] Handle mouse/keyboard input
- [ ] Add to edit mode if applicable
- [ ] Test scrolling/layout

---

## Quick Reference: Common Oversights

| Often Forgotten | Where to Add |
|-----------------|--------------|
| Save/Load support | ConsumptionPrototype CreateSaveData/LoadSaveData |
| InfoSystem display | InfoSystemState.lua relevant tab |
| MCP tool updates | mcp-server tools |
| Character card indicators | RenderCharacterCardAt |
| Edit mode controls | detailEditMode sections |
| Event logging | LogEvent calls |
| Analytics inclusion | UpdateStatistics, RecordHistoricalData |

---

## Template: Feature Implementation Tasks

```markdown
## [Feature Name] - Implementation Plan

### Phase 1: Data & Core
- [ ] Task 1.1: Update data schema
- [ ] Task 1.2: Implement core logic
- [ ] Task 1.3: Add to character state (if needed)

### Phase 2: Processing & Integration
- [ ] Task 2.1: Add to allocation logic (if needed)
- [ ] Task 2.2: Integrate into cycle processing
- [ ] Task 2.3: Add event logging

### Phase 3: Persistence
- [ ] Task 3.1: Add to save data
- [ ] Task 3.2: Add to load data

### Phase 4: Consumption Prototype UI
- [ ] Task 4.1: Add to character detail modal
- [ ] Task 4.2: Add to character cards
- [ ] Task 4.3: Add edit mode controls
- [ ] Task 4.4: Update history/analytics display

### Phase 5: Information System UI
- [ ] Task 5.1: Add/update InfoSystem tab
- [ ] Task 5.2: Add detail view display
- [ ] Task 5.3: Add edit controls

### Phase 6: MCP Integration
- [ ] Task 6.1: Add/update MCP tools
- [ ] Task 6.2: Update MCP prompts
- [ ] Task 6.3: Test MCP integration

### Phase 7: Testing & Polish
- [ ] Task 7.1: Add test scenarios
- [ ] Task 7.2: Verify balance/behavior
- [ ] Task 7.3: Fix edge cases
```

---

## Change Log

| Date | Change |
|------|--------|
| 2025-12-02 | Created initial rubric |
