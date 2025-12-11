--
-- GameSettings.lua
-- Centralized game settings management for CraveTown
--

local json = require("code.json")

GameSettings = {}
GameSettings.__index = GameSettings

-- Settings file path
GameSettings.SETTINGS_FILE = "game_settings.json"

-- Default settings
GameSettings.DEFAULTS = {
    -- Gameplay
    gameplay = {
        autoPauseOnCritical = true,
        autoPauseOnWarning = false,
        autoPauseOnInfo = false,
        tutorialHints = true,
        notificationFrequency = "normal",  -- minimal, normal, verbose
        autosaveEnabled = true,
        autosaveInterval = 25,  -- cycles
        showProductionNumbers = true,
        showSatisfactionNumbers = true
    },

    -- Display
    display = {
        fullscreen = false,
        vsync = true,
        uiScale = 1.0,
        showCharacterNames = "hover",  -- always, hover, never
        showBuildingNames = true,
        colorBlindMode = "none",  -- none, protanopia, deuteranopia, tritanopia
        cameraZoomSpeed = 0.1,
        cameraPanSpeed = 500
    },

    -- Audio
    audio = {
        masterVolume = 0.8,
        musicVolume = 0.6,
        sfxVolume = 0.8,
        ambientVolume = 0.5,
        notificationSounds = true,
        uiSounds = true
    },

    -- Accessibility
    accessibility = {
        largerText = false,
        highContrast = false,
        reducedMotion = false,
        screenReaderMode = false
    }
}

-- Singleton instance
local instance = nil

function GameSettings:GetInstance()
    if not instance then
        instance = setmetatable({}, GameSettings)
        instance:Load()
    end
    return instance
end

function GameSettings:Create()
    return self:GetInstance()
end

function GameSettings:Load()
    -- Start with defaults
    self.settings = self:DeepCopy(self.DEFAULTS)

    -- Try to load saved settings
    local content = love.filesystem.read(self.SETTINGS_FILE)
    if content then
        local ok, savedSettings = pcall(json.decode, content)
        if ok and savedSettings then
            -- Merge saved settings into defaults (preserving any new default keys)
            self:MergeSettings(self.settings, savedSettings)
        end
    end
end

function GameSettings:Save()
    local content = json.encode(self.settings)
    local success, message = love.filesystem.write(self.SETTINGS_FILE, content)
    if not success then
        print("Failed to save settings: " .. (message or "unknown error"))
    end
    return success
end

function GameSettings:DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for key, value in pairs(orig) do
            copy[key] = self:DeepCopy(value)
        end
    else
        copy = orig
    end
    return copy
end

function GameSettings:MergeSettings(target, source)
    for key, value in pairs(source) do
        if type(value) == 'table' and type(target[key]) == 'table' then
            self:MergeSettings(target[key], value)
        else
            target[key] = value
        end
    end
end

-- =============================================================================
-- GETTERS
-- =============================================================================

function GameSettings:Get(category, key)
    if self.settings[category] and self.settings[category][key] ~= nil then
        return self.settings[category][key]
    end
    -- Return default if not found
    if self.DEFAULTS[category] and self.DEFAULTS[category][key] ~= nil then
        return self.DEFAULTS[category][key]
    end
    return nil
end

function GameSettings:GetCategory(category)
    return self.settings[category] or self.DEFAULTS[category] or {}
end

-- =============================================================================
-- SETTERS
-- =============================================================================

function GameSettings:Set(category, key, value)
    if not self.settings[category] then
        self.settings[category] = {}
    end
    self.settings[category][key] = value
    self:Save()
end

function GameSettings:SetMultiple(category, values)
    if not self.settings[category] then
        self.settings[category] = {}
    end
    for key, value in pairs(values) do
        self.settings[category][key] = value
    end
    self:Save()
end

-- =============================================================================
-- CONVENIENCE GETTERS
-- =============================================================================

-- Gameplay
function GameSettings:IsAutoPauseOnCritical()
    return self:Get("gameplay", "autoPauseOnCritical")
end

function GameSettings:IsAutoPauseOnWarning()
    return self:Get("gameplay", "autoPauseOnWarning")
end

function GameSettings:IsTutorialHintsEnabled()
    return self:Get("gameplay", "tutorialHints")
end

function GameSettings:GetNotificationFrequency()
    return self:Get("gameplay", "notificationFrequency")
end

function GameSettings:IsAutosaveEnabled()
    return self:Get("gameplay", "autosaveEnabled")
end

function GameSettings:GetAutosaveInterval()
    return self:Get("gameplay", "autosaveInterval")
end

function GameSettings:IsShowProductionNumbers()
    return self:Get("gameplay", "showProductionNumbers")
end

-- Display
function GameSettings:IsFullscreen()
    return self:Get("display", "fullscreen")
end

function GameSettings:GetUIScale()
    return self:Get("display", "uiScale")
end

function GameSettings:GetCharacterNamesMode()
    return self:Get("display", "showCharacterNames")
end

function GameSettings:GetColorBlindMode()
    return self:Get("display", "colorBlindMode")
end

function GameSettings:GetCameraZoomSpeed()
    return self:Get("display", "cameraZoomSpeed")
end

function GameSettings:GetCameraPanSpeed()
    return self:Get("display", "cameraPanSpeed")
end

-- Audio
function GameSettings:GetMasterVolume()
    return self:Get("audio", "masterVolume")
end

function GameSettings:GetMusicVolume()
    return self:Get("audio", "musicVolume")
end

function GameSettings:GetSFXVolume()
    return self:Get("audio", "sfxVolume")
end

function GameSettings:IsNotificationSoundsEnabled()
    return self:Get("audio", "notificationSounds")
end

-- Accessibility
function GameSettings:IsLargerTextEnabled()
    return self:Get("accessibility", "largerText")
end

function GameSettings:IsHighContrastEnabled()
    return self:Get("accessibility", "highContrast")
end

function GameSettings:IsReducedMotionEnabled()
    return self:Get("accessibility", "reducedMotion")
end

-- =============================================================================
-- RESET
-- =============================================================================

function GameSettings:ResetCategory(category)
    if self.DEFAULTS[category] then
        self.settings[category] = self:DeepCopy(self.DEFAULTS[category])
        self:Save()
    end
end

function GameSettings:ResetAll()
    self.settings = self:DeepCopy(self.DEFAULTS)
    self:Save()
end

-- =============================================================================
-- APPLY SETTINGS
-- =============================================================================

function GameSettings:ApplyDisplaySettings()
    local fullscreen = self:IsFullscreen()
    local vsync = self:Get("display", "vsync")

    -- Apply fullscreen
    local currentFullscreen = love.window.getFullscreen()
    if currentFullscreen ~= fullscreen then
        love.window.setFullscreen(fullscreen)
    end

    -- Apply vsync
    love.window.setVSync(vsync and 1 or 0)
end

return GameSettings
