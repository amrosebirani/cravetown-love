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

    === CONSUMPTION PROTOTYPE ===
    Various UI interactions for testing consumption system
]]

return Protocol
