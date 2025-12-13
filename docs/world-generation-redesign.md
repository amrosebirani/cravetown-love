# World Generation Redesign - Region-Based Approach

## Current Problem

The current world generation system:
1. Places forests randomly across the map
2. Places rivers randomly
3. Places mountains randomly
4. Then tries to place buildings with collision checking against all of the above
5. Each building placement requires iterating through all obstacles

This leads to:
- Buildings colliding with forests (as seen in screenshot)
- Inefficient collision checking (O(n*m) for n buildings and m obstacles)
- Unpredictable building placement
- No logical town layout (buildings scattered wherever they fit)

## Proposed Solution: Region-Based Zoning

Instead of random placement with collision checking, we define **zones** first, then place content within zones.

### Zone Types

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   ┌──────────┐                                    ┌──────────┐ │
│   │ FOREST   │                                    │ MOUNTAIN │ │
│   │ ZONE     │                                    │ ZONE     │ │
│   │          │     ┌────────────────────┐         │          │ │
│   └──────────┘     │                    │         │          │ │
│                    │   TOWN CENTER      │         └──────────┘ │
│                    │   (buildings)      │                      │
│   ┌──────────┐     │                    │      ┌──────────┐   │
│   │ FARMLAND │     └────────────────────┘      │ RIVER    │   │
│   │ ZONE     │                                 │ ZONE     │   │
│   │          │     ┌────────────────────┐      │          │   │
│   │          │     │  RESIDENTIAL       │      │          │   │
│   └──────────┘     │  ZONE              │      └──────────┘   │
│                    └────────────────────┘                      │
│   ┌──────────┐                                                 │
│   │ RESOURCE │     ┌────────────────────┐                      │
│   │ ZONE     │     │  INDUSTRIAL        │                      │
│   │ (mines)  │     │  ZONE              │                      │
│   └──────────┘     └────────────────────┘                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Zone Definitions

```lua
ZoneType = {
    TOWN_CENTER = "town_center",     -- Main buildings: bakery, market, town hall
    RESIDENTIAL = "residential",      -- Cottages, lodges, houses
    INDUSTRIAL = "industrial",        -- Workshops, smithies, factories
    FARMLAND = "farmland",           -- Farms, fields, barns
    FOREST = "forest",               -- Trees, lumber camps
    MOUNTAIN = "mountain",           -- Mountains, mines
    RIVER = "river",                 -- River course, fishing spots
    RESOURCE = "resource",           -- Specific resource deposits
    WILDERNESS = "wilderness"        -- Empty/buffer zone
}
```

### World Generation Algorithm

#### Phase 1: Zone Layout Generation

```lua
function WorldGenerator:GenerateZoneLayout(worldWidth, worldHeight, locationConfig)
    local zones = {}

    -- 1. Define major geographical features based on location
    -- e.g., "river_valley" places river through middle
    -- e.g., "mountain_pass" places mountains on sides

    if locationConfig.hasRiver then
        zones.river = self:PlaceRiverZone(locationConfig.riverPosition)
    end

    if locationConfig.hasMountains then
        zones.mountains = self:PlaceMountainZone(locationConfig.mountainPosition)
    end

    -- 2. Place town center away from geographical obstacles
    zones.townCenter = self:FindTownCenterLocation(zones)

    -- 3. Place other zones radiating from town center
    zones.residential = self:PlaceAdjacentZone(zones.townCenter, "residential", 0.3)
    zones.industrial = self:PlaceAdjacentZone(zones.townCenter, "industrial", 0.2)
    zones.farmland = self:PlaceFarmlandZone(zones)

    -- 4. Fill remaining areas with forest/wilderness
    zones.forest = self:FillForestZones(zones)

    return zones
end
```

#### Phase 2: Zone Content Generation

```lua
function WorldGenerator:PopulateZones(zones, startingConfig)
    -- Each zone type has its own content generator

    -- Forest zones get trees
    for _, forestZone in ipairs(zones.forest) do
        self:GenerateTreesInZone(forestZone)
    end

    -- Mountain zones get mountain meshes
    for _, mountainZone in ipairs(zones.mountains) do
        self:GenerateMountainsInZone(mountainZone)
    end

    -- Town center gets main buildings
    self:PlaceBuildingsInZone(zones.townCenter, startingConfig.townBuildings)

    -- Residential gets housing
    self:PlaceBuildingsInZone(zones.residential, startingConfig.housingBuildings)

    -- Farmland gets farms
    self:PlaceBuildingsInZone(zones.farmland, startingConfig.farmBuildings)
end
```

### Zone Data Structure

```lua
Zone = {
    type = ZoneType.TOWN_CENTER,
    bounds = {
        x = 400,
        y = 400,
        width = 800,
        height = 600
    },
    -- Grid-based slots for easy placement
    gridSize = 80,  -- Building grid size
    occupiedSlots = {},  -- Set of {gridX, gridY} that are taken

    -- Zone-specific properties
    properties = {
        fertileGround = true,
        flatTerrain = true,
        waterAccess = false
    }
}
```

### Building Placement Within Zones

```lua
function Zone:PlaceBuilding(buildingType, preferredGridX, preferredGridY)
    -- Check if preferred slot is available
    local slotKey = preferredGridX .. "," .. preferredGridY

    if not self.occupiedSlots[slotKey] then
        self.occupiedSlots[slotKey] = true
        return self:GridToWorld(preferredGridX, preferredGridY)
    end

    -- Find nearest available slot (spiral outward)
    local x, y = self:FindNearestFreeSlot(preferredGridX, preferredGridY)
    if x then
        self.occupiedSlots[x .. "," .. y] = true
        return self:GridToWorld(x, y)
    end

    return nil  -- Zone full
end
```

### Location Templates

Each starting location defines a zone layout template:

```json
{
    "id": "fertile_plains",
    "name": "Fertile Plains",
    "zoneLayout": {
        "type": "plains_layout",
        "river": {
            "enabled": true,
            "position": "east",
            "width": 120
        },
        "mountains": {
            "enabled": false
        },
        "forest": {
            "coverage": 0.25,
            "positions": ["northwest", "southeast"]
        },
        "townCenter": {
            "position": "center",
            "size": "medium"
        }
    },
    "zonePreferences": {
        "farmland": {
            "preferredDirection": "west",
            "minDistance": 200
        },
        "industrial": {
            "preferredDirection": "east",
            "nearRiver": true
        }
    }
}
```

### Benefits

1. **No Collision Checking During Placement**
   - Buildings are placed in their designated zones
   - Each zone manages its own grid of available slots
   - O(1) lookup for slot availability

2. **Predictable Town Layout**
   - Farms are in farmland areas
   - Houses are in residential areas
   - Industrial buildings near resources

3. **Logical Town Growth**
   - As population grows, residential zone expands
   - Can easily find where to place new buildings

4. **Performance**
   - No iterating through all trees/mountains/rivers
   - Zone-based queries are fast
   - Rendering can use zone culling

5. **Moddable**
   - Location templates define zone layouts
   - Easy to create new map types
   - Clear separation of concerns

### Migration Path

1. **Phase 1**: Create ZoneManager class with zone definitions
2. **Phase 2**: Create zone layout generators for each location type
3. **Phase 3**: Modify building placement to use zones
4. **Phase 4**: Modify Forest/Mountain/River to generate within zones
5. **Phase 5**: Update starting_locations.json with zone templates

### Implementation Priority

1. Create `code/ZoneManager.lua` with basic zone structure
2. Create `code/WorldZoneGenerator.lua` for zone layout
3. Update `AlphaWorld:Create()` to use zone-based generation
4. Update `Forest.lua` to accept zone boundaries
5. Update `SetupStarterContent` to place buildings by zone

### Example Zone Layout for "Fertile Plains"

```
World Size: 3200 x 2400

Zone Layout:
- River Zone: x=2400-2600, full height (east side)
- Forest Zone 1: x=0-600, y=0-800 (northwest)
- Forest Zone 2: x=2000-2400, y=1600-2400 (southeast, before river)
- Town Center: x=1000-1800, y=800-1400 (center)
- Residential: x=800-1200, y=1400-2000 (south of center)
- Farmland: x=100-800, y=800-1800 (west)
- Industrial: x=1800-2200, y=800-1200 (east, near river)
```

This ensures:
- Buildings never overlap forests
- Town has logical layout
- Resources are accessible
- Room for expansion
