--
-- Protocol.lua - Message protocol definitions for MCP communication
-- This file can be extended as new game features are added
--

local Protocol = {}

Protocol.VERSION = "1.0"

-- Message types
Protocol.MessageTypes = {
    HANDSHAKE = "handshake",
    HANDSHAKE_ACK = "handshake_ack",
    REQUEST = "request",
    RESPONSE = "response",
    EVENT = "event"
}

-- Available methods
Protocol.Methods = {
    GET_STATE = "get_state",
    SEND_INPUT = "send_input",
    SEND_ACTION = "send_action",
    CONTROL = "control",
    QUERY = "query",
    GET_LOGS = "get_logs"
}

-- Event types for logging (extend as game grows)
Protocol.EventTypes = {
    -- Building events
    BUILDING_PLACED = "building_placed",
    BUILDING_REMOVED = "building_removed",
    BUILDING_SELECTED = "building_selected",

    -- Worker events
    WORKER_ASSIGNED = "worker_assigned",
    WORKER_REMOVED = "worker_removed",

    -- Production events
    PRODUCTION_STARTED = "production_started",
    PRODUCTION_COMPLETE = "production_complete",
    GRAIN_SELECTED = "grain_selected",
    MINE_RESOURCE_SELECTED = "mine_resource_selected",

    -- Resource events
    RESOURCE_ADDED = "resource_added",
    RESOURCE_REMOVED = "resource_removed",

    -- Character events
    CHARACTER_HIRED = "character_hired",
    CHARACTER_FIRED = "character_fired",
    CRAVING_SATISFIED = "craving_satisfied",
    CRAVING_UNFULFILLED = "craving_unfulfilled",

    -- UI/State events
    STATE_CHANGED = "state_changed",
    MODE_CHANGED = "mode_changed",
    UI_ACTION = "ui_action",
    MODAL_OPENED = "modal_opened",
    MODAL_CLOSED = "modal_closed",
    MENU_OPENED = "menu_opened",
    MENU_CLOSED = "menu_closed",

    -- Game flow events
    GAME_STARTED = "game_started",
    TOWN_NAMED = "town_named",

    -- Consumption Prototype events
    CONSUMPTION_CYCLE_COMPLETE = "consumption_cycle_complete",
    CONSUMPTION_CHARACTER_ADDED = "consumption_character_added",
    CONSUMPTION_RESOURCE_INJECTED = "consumption_resource_injected",
    CONSUMPTION_POLICY_CHANGED = "consumption_policy_changed",
    CONSUMPTION_RIOT_TRIGGERED = "consumption_riot_triggered",
    CONSUMPTION_CIVIL_UNREST = "consumption_civil_unrest",
    CONSUMPTION_SATISFACTION_SET = "consumption_satisfaction_set",
    CONSUMPTION_CRAVING_MODIFIED = "consumption_craving_modified",
    CONSUMPTION_SIMULATION_PAUSED = "consumption_simulation_paused",
    CONSUMPTION_SIMULATION_RESUMED = "consumption_simulation_resumed",
    CONSUMPTION_SPEED_CHANGED = "consumption_speed_changed",
    CONSUMPTION_ALLOCATION_COMPLETE = "consumption_allocation_complete",

    -- System events
    ERROR = "error",
    WARNING = "warning"
}

-- Control commands
Protocol.ControlCommands = {
    PAUSE = "pause",
    RESUME = "resume",
    SET_SPEED = "set_speed",
    SCREENSHOT = "screenshot",
    RESET = "reset",
    HEADLESS = "headless",
    QUIT = "quit"
}

-- Input types
Protocol.InputTypes = {
    KEY = "key",
    MOUSE = "mouse"
}

-- Key actions
Protocol.KeyActions = {
    PRESS = "press",
    RELEASE = "release",
    TAP = "tap"
}

-- Mouse actions
Protocol.MouseActions = {
    PRESS = "press",
    RELEASE = "release",
    CLICK = "click",
    MOVE = "move",
    SCROLL = "scroll"
}

-- High-level game actions (extend as game grows)
Protocol.GameActions = {
    -- Building actions
    PLACE_BUILDING = "place_building",
    SELECT_BUILDING = "select_building",
    CANCEL_PLACEMENT = "cancel_placement",
    START_BUILDING_PLACEMENT = "start_building_placement",

    -- Worker actions
    ASSIGN_WORKER = "assign_worker",
    REMOVE_WORKER = "remove_worker",

    -- Production actions
    SET_PRODUCTION = "set_production",
    SELECT_GRAIN = "select_grain",
    SELECT_MINE_RESOURCE = "select_mine_resource",

    -- Camera actions
    MOVE_CAMERA = "move_camera",
    MOVE_CAMERA_BY = "move_camera_by",
    ZOOM_CAMERA = "zoom_camera",

    -- UI actions
    OPEN_MENU = "open_menu",
    CLOSE_MENU = "close_menu",
    CLICK_BUTTON = "click_button",

    -- Character actions
    HIRE_CHARACTER = "hire_character",

    -- Game flow actions
    ADVANCE_TIME = "advance_time",
    START_GAME = "start_game",
    SET_TOWN_NAME = "set_town_name",
    RETURN_TO_LAUNCHER = "return_to_launcher"
}

-- Consumption Prototype actions (for game balance testing)
Protocol.ConsumptionActions = {
    -- Simulation control
    PAUSE_SIMULATION = "pause_simulation",
    RESUME_SIMULATION = "resume_simulation",
    SET_SIMULATION_SPEED = "set_simulation_speed",
    SKIP_CYCLES = "skip_cycles",

    -- Character management
    ADD_CHARACTER = "add_character",
    ADD_RANDOM_CHARACTERS = "add_random_characters",
    REMOVE_CHARACTER = "remove_character",

    -- Resource management
    INJECT_RESOURCE = "inject_resource",
    SET_INVENTORY = "set_inventory",
    CLEAR_INVENTORY = "clear_inventory",

    -- Allocation policy
    SET_ALLOCATION_POLICY = "set_allocation_policy",
    APPLY_POLICY_PRESET = "apply_policy_preset",

    -- Testing/debugging actions
    TRIGGER_RIOT = "trigger_riot",
    TRIGGER_CIVIL_UNREST = "trigger_civil_unrest",
    SET_ALL_SATISFACTION = "set_all_satisfaction",
    SET_CHARACTER_SATISFACTION = "set_character_satisfaction",
    MODIFY_CHARACTER_CRAVING = "modify_character_craving",
    RESET_FATIGUE = "reset_fatigue",
    RESET_HISTORY = "reset_history",

    -- Queries specific to consumption
    GET_CHARACTER_DETAILS = "get_character_details",
    GET_ALLOCATION_DETAILS = "get_allocation_details",
    GET_CONSUMPTION_STATS = "get_consumption_stats"
}

-- Available keys (Love2D key names)
Protocol.AvailableKeys = {
    -- Movement/WASD
    "w", "a", "s", "d",
    -- Arrow keys
    "up", "down", "left", "right",
    -- Common keys
    "space", "return", "escape", "tab",
    "backspace", "delete",
    -- Function keys
    "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
    -- Modifiers
    "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt",
    -- Numbers
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
}

--[[
    GAME CONTROLS REFERENCE (for AI agents)

    === GLOBAL CONTROLS ===
    F5          : Hot reload (development)
    F11         : Toggle fullscreen
    Alt+Enter   : Toggle fullscreen
    Escape      : Return to launcher / Cancel / Quit

    === VERSION SELECTOR MODE ===
    Mouse wheel : Scroll version list
    Left click  : Select version

    === LAUNCHER MODE ===
    Left click  : Select game mode

    === MAIN GAME - TOWN VIEW STATE ===
    W/Up        : Move camera up
    A/Left      : Move camera left
    S/Down      : Move camera down
    D/Right     : Move camera right

    === MAIN GAME - BUILDING PLACEMENT STATE ===
    Mouse move  : Position building preview
    Left click  : Place building (if valid position)
    Right click : Cancel placement
    W/Up        : Increase building height (variable-size buildings)
    S/Down      : Decrease building height (variable-size buildings)
    D/Right     : Increase building width (variable-size buildings)
    A/Left      : Decrease building width (variable-size buildings)
    Edge scroll : Move camera when mouse near screen edges

    === BUILDING MENU (bottom panel) ===
    Left click  : Select building type to place
    Hover       : Show building info tooltip

    === TOP BAR MENU ===
    Left click  : Toggle inventory/nature/stats/music panels

    === MODALS (Town Name, Grain Selection, etc.) ===
    Text input  : Type text (for name input)
    Return      : Confirm
    Escape      : Cancel
    Left click  : Select options

    === INVENTORY DRAWER ===
    Mouse wheel : Scroll inventory list

    === CONSUMPTION PROTOTYPE MODE ===
    Space       : Toggle simulation pause/play
    Escape      : Return to launcher

    UI Buttons (use cravetown_action with consumption actions):
    - "Add Character": Adds a new character with random cravings
    - "Inject Resource": Opens resource injection dialog
    - Allocation Policy: Toggle between priority modes

    === CONSUMPTION PROTOTYPE - CHARACTER MODEL (6 LAYERS) ===

    Layer 1 - Identity:
        - name: Character's display name
        - role: "citizen" (currently only type)

    Layer 2 - Base Cravings (49 fine-grained dimensions):
        Categories: Food, Drink, Shelter, Comfort, Social, Stimulation,
                   Beauty, Purpose, Novelty
        Each category has 4-7 specific cravings (total 49)
        Example: Food = {satiation, variety, quality, ritual, nostalgia, health, indulgence}

    Layer 3 - Current Cravings:
        Same structure as base cravings but modified by consumption history
        Aggregated to 9 coarse dimensions for allocation

    Layer 4 - Satisfaction (0.0 to 1.0):
        - satisfaction: Overall satisfaction level
        - Affects consumption priority and social consequences

    Layer 5 - Commodity Multipliers (Fatigue):
        Per-commodity multipliers that decrease effectiveness
        Example: eating bread repeatedly gives diminishing satisfaction

    Layer 6 - Consumption History:
        Tracks what and when each character consumed
        Used to calculate fatigue decay over time

    === CONSUMPTION PROTOTYPE - ALLOCATION ENGINE ===

    Priority Modes:
    - "highest_craving": Characters with highest unfilled craving get priority
    - "lowest_satisfaction": Least satisfied characters get priority
    - "oldest_consumption": Characters who haven't consumed longest get priority
    - "round_robin": Fair turn-based distribution

    Fairness Options:
    - fairness_weight (0-1): How much to factor fairness into allocation
    - per_capita_cap: Maximum units any character can receive per cycle
    - allow_partial: Whether to allow partial satisfaction of cravings

    === CONSUMPTION PROTOTYPE - KEY METRICS FOR BALANCE ===

    Statistics tracked:
    - total_consumption: Total units consumed across all time
    - total_cycles: Number of allocation cycles run
    - avg_satisfaction: Average satisfaction across all characters
    - min_satisfaction / max_satisfaction: Satisfaction range
    - gini_coefficient: Inequality measure (0=equal, 1=unequal)
    - characters_below_threshold: Count of chars below satisfaction threshold

    Per-Character Metrics:
    - satisfaction history over time
    - craving fulfillment rates by category
    - consumption patterns and fatigue levels
    - time since last consumption

    === CONSUMPTION PROTOTYPE - TESTING SCENARIOS ===

    Use these actions to test game balance:
    1. trigger_riot: See how system handles crisis (resets satisfaction)
    2. trigger_civil_unrest: Moderate satisfaction reduction
    3. set_all_satisfaction: Test recovery from different starting points
    4. inject_resource: Test allocation with varying resource levels
    5. skip_cycles: Fast-forward simulation
    6. apply_policy_preset: Test different allocation strategies

    Policy Presets:
    - "equal": Pure round-robin, maximum fairness
    - "needs_based": Priority to highest cravings
    - "utilitarian": Maximize total satisfaction
    - "rawlsian": Priority to worst-off individuals
]]

return Protocol
