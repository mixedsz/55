-- RK ProPad Initialization
-- Copyright (c) 2025 rk.dev - @9zku - All rights reserved.
-- This file initializes the script environment and sets up global functions

local SCRIPT_NAME = "rk_propad"
local SCRIPT_VERSION = "1.0.4"
local AUTHOR = "RK x AnnoyingTV"

-- Print initialization message
print(("^2[%s]^7 Loading v%s by %s"):format(SCRIPT_NAME, SCRIPT_VERSION, AUTHOR))

-- Global vehicle key system functions
-- These are placeholders that will be overridden by bridge files if a supported system is detected
GiveVehKeys = GiveVehKeys or function(vehicle)
    if not vehicle or vehicle == 0 then
        print(("^3[%s]^7 Warning: Invalid vehicle in GiveVehKeys"):format(SCRIPT_NAME))
        return false
    end
    
    -- Auto-start fallback when no key system is detected
    print(("^2[%s]^7 No key system - Auto-starting vehicle %s"):format(SCRIPT_NAME, vehicle))
    
    -- Set vehicle as owned and driveable
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    
    -- Make sure engine is on
    SetVehicleEngineOn(vehicle, true, true, false)
    
    -- Prevent the vehicle from being locked
    SetVehicleDoorsLocked(vehicle, 1) -- 1 = Unlocked
    
    return true
end

RemoveVehKeys = RemoveVehKeys or function(vehicle)
    if not vehicle or vehicle == 0 then
        print(("^3[%s]^7 Warning: Invalid vehicle in RemoveVehKeys"):format(SCRIPT_NAME))
        return false
    end
    
    -- Auto-start fallback when no key system is detected
    print(("^2[%s]^7 No key system - Removing access from vehicle %s"):format(SCRIPT_NAME, vehicle))
    
    -- Remove ownership
    SetVehicleHasBeenOwnedByPlayer(vehicle, false)
    SetVehicleNeedsToBeHotwired(vehicle, true)
    
    -- Turn off engine
    SetVehicleEngineOn(vehicle, false, false, true)
    
    -- Lock the vehicle
    SetVehicleDoorsLocked(vehicle, 2) -- 2 = Locked
    
    return true
end

-- Utility function for debug logging
DebugPrint = function(message, level)
    local config = require("shared.main")
    if config.DebugVehicleKeys then
        local prefix = "^7"
        if level == "error" then
            prefix = "^1[ERROR]^7"
        elseif level == "warning" then
            prefix = "^3[WARNING]^7"
        elseif level == "success" then
            prefix = "^2[SUCCESS]^7"
        end
        print(("^5[%s]^7 %s %s"):format(SCRIPT_NAME, prefix, message))
    end
end

-- Vehicle key system detection
local function DetectVehicleKeySystem()
    local systems = {
        { name = "mk_vehiclekeys", resource = "mk_vehiclekeys" },
        { name = "mk_utils", resource = "mk_utils" },
        { name = "wasabi_carlock", resource = "wasabi_carlock" },
        { name = "qs-vehiclekeys", resource = "qs-vehiclekeys" },
        { name = "MrNewbVehicleKeys", resource = "MrNewbVehicleKeys" }
    }

    for _, system in ipairs(systems) do
        if GetResourceState(system.resource) == "started" then
            print(("^2[%s]^7 Detected vehicle key system: ^5%s^7"):format(SCRIPT_NAME, system.name))
            return system.name
        end
    end

    -- Additional diagnostic logging
    print(("^3[%s]^7 No vehicle key system detected - Checking resource states..."):format(SCRIPT_NAME))
    for _, system in ipairs(systems) do
        local state = GetResourceState(system.resource)
        if state ~= "missing" then
            print(("^3[%s]^7   %s: ^3%s^7 (not started)"):format(SCRIPT_NAME, system.resource, state))
        end
    end

    print(("^3[%s]^7 Using auto-start mode"):format(SCRIPT_NAME))
    return "auto-start"
end

-- Initialize on resource start
CreateThread(function()
    Wait(1000) -- Wait for other resources to load
    
    local keySystem = DetectVehicleKeySystem()
    
    -- Verify ox_lib is loaded
    if not lib then
        print(("^1[%s]^7 CRITICAL ERROR: ox_lib is not loaded! This resource requires ox_lib to function."):format(SCRIPT_NAME))
        return
    end
    
    print(("^2[%s]^7 Successfully initialized v%s"):format(SCRIPT_NAME, SCRIPT_VERSION))
    
    if keySystem == "auto-start" then
        print(("^2[%s]^7 Vehicle mode: ^3Auto-Start (No key system required)^7"):format(SCRIPT_NAME))
    else
        print(("^2[%s]^7 Vehicle key integration: ^5%s^7"):format(SCRIPT_NAME, keySystem))
    end
    
    -- Check for required dependencies
    local dependencies = {
        { name = "ox_lib", required = true },
        { name = "ox_inventory", required = false }
    }
    
    for _, dep in ipairs(dependencies) do
        local state = GetResourceState(dep.name)
        if state == "started" then
            print(("^2[%s]^7 Dependency %s: ^2✓ Running^7"):format(SCRIPT_NAME, dep.name))
        elseif dep.required then
            print(("^1[%s]^7 CRITICAL: Required dependency %s is not running!"):format(SCRIPT_NAME, dep.name))
        else
            print(("^3[%s]^7 Optional dependency %s: ^3✗ Not found^7"):format(SCRIPT_NAME, dep.name))
        end
    end
end)

-- Global utility functions
GetScriptVersion = function()
    return SCRIPT_VERSION
end

GetScriptName = function()
    return SCRIPT_NAME
end

-- Export version info
exports("GetVersion", GetScriptVersion)
exports("GetScriptName", GetScriptName)

print(("^2[%s]^7 Core initialization complete"):format(SCRIPT_NAME))