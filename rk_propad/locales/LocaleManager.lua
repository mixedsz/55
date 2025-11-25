local config = require 'shared.main'

---@class LocaleManager 
---@field private primaryLocale table<string, string>
---@field private fallbackLocale table<string, string>
---@field private currentLocale string
---@field private fallbackLocaleKey string
local LocaleManager = lib.class('LocaleManager')

---Loads a locale file using lib.loadJson with error handling
---@param localeKey string The locale key to load (e.g., 'en', 'fr')
---@param isFallback? boolean Whether this is a fallback locale load
---@return table<string, string> The loaded locale data or empty table on failure
local function loadLocaleFile(localeKey, isFallback)
    local success, result = pcall(lib.loadJson, ('locales.json.%s'):format(localeKey))
    
    if not success then
        local logPrefix = isFallback and '^3[FALLBACK]^7' or '^2[PRIMARY]^7'
        local errorMsg = ('%s Failed to load locale file for %s: %s^7'):format(logPrefix, localeKey, tostring(result))
        print(errorMsg)
        return {}
    end
    
    if type(result) ~= 'table' then
        local logPrefix = isFallback and '^3[FALLBACK]^7' or '^2[PRIMARY]^7'
        print(('%s Invalid locale file format for %s (expected table, got %s)^7'):format(logPrefix, localeKey, type(result)))
        return {}
    end
    

    
    return result
end

---Validates locale data structure and content
---@param localeData table<string, string> The locale data to validate
---@param localeKey string The locale key for error reporting
---@return boolean isValid Whether the locale data is valid
local function validateLocaleData(localeData, localeKey)
    if not localeData or type(localeData) ~= 'table' then
        print(('^1[VALIDATION] Invalid locale data for %s^7'):format(localeKey))
        return false
    end
    
    local keyCount = 0
    local invalidKeys = {}
    
    for key, value in pairs(localeData) do
        keyCount = keyCount + 1
        if type(key) ~= 'string' or type(value) ~= 'string' then
            table.insert(invalidKeys, ('%s:%s'):format(type(key), type(value)))
        end
    end
    
    if #invalidKeys > 0 then
        print(('^1[VALIDATION] Invalid key types in %s: %s^7'):format(localeKey, table.concat(invalidKeys, ', ')))
        return false
    end
    
    if keyCount == 0 then
        print(('^1[VALIDATION] Empty locale file for %s^7'):format(localeKey))
        return false
    end
    
    return true
end

---Constructor for LocaleManager
---@param config table Configuration containing Locale key
function LocaleManager:constructor(config)
    self.primaryLocale = {}
    self.fallbackLocale = {}
    self.currentLocale = 'en'
    self.fallbackLocaleKey = 'en'
    
    if not config or not config.Locale then
        print('^1[LOCALE] Invalid config provided, using default English locale^7')
        self.currentLocale = 'en'
    else
        self.currentLocale = config.Locale
    end
    
    -- Load primary locale
    self.primaryLocale = loadLocaleFile(self.currentLocale, false)
    if not validateLocaleData(self.primaryLocale, self.currentLocale) then
        print(('^3[LOCALE] Primary locale %s failed validation, falling back to English^7'):format(self.currentLocale))
        self.currentLocale = 'en'
        self.primaryLocale = loadLocaleFile(self.currentLocale, false)
    end
    
    -- Load fallback locale
    self.fallbackLocale = loadLocaleFile(self.fallbackLocaleKey, true)
    if not validateLocaleData(self.fallbackLocale, self.fallbackLocaleKey) then
        print(('^1[LOCALE] Critical: Fallback locale %s failed validation^7'):format(self.fallbackLocaleKey))
        self.fallbackLocale = {}
    end
    
    -- Set global data
    LocaleData = self.primaryLocale
end

---Translate a locale key with optional arguments
---@param key string The locale key to translate
---@param ... any Variable arguments for string interpolation
---@return string The translated string or the key if not found
function LocaleManager:translate(key, ...)
    if not key or type(key) ~= 'string' then
        print(('^1[TRANSLATE] Invalid key provided: %s^7'):format(tostring(key)))
        return ''
    end
    
    -- Try primary locale first, then fallback
    local str = self.primaryLocale[key] or self.fallbackLocale[key]
    
    if not str then
        local warningMsg = ('^3[TRANSLATE] Missing locale key: %s (locale: %s)^7'):format(key, self.currentLocale)
        print(warningMsg)
        return key
    end
    
    -- Handle string interpolation with arguments
    local argCount = select('#', ...)
    if argCount > 0 then
        local args = {...}
        local success, result = pcall(function()
            return str:gsub('{(%d+)}', function(n)
                local index = tonumber(n)
                if not index or index < 1 or index > #args then
                    print(('^1[INTERPOLATION] Invalid argument index %s for key: %s (args: %d)^7'):format(n, key, #args))
                    return ''
                end
                return tostring(args[index])
            end)
        end)
        
        if not success then
            print(('^1[INTERPOLATION] Error processing key %s: %s^7'):format(key, tostring(result)))
            return str
        end
        
        return result
    end
    
    return str
end

local localeManager = LocaleManager:new(config)

Locale = function(key, ...)
    return localeManager:translate(key, ...)
end

return localeManager

