local config = require("shared.main")
local nui = require("modules.nui.client")
local vehicleFunctions = require("modules.vehicle.client")
local localeManager = require("locales.LocaleManager")

local tabletObject = nil
local currentBrand = nil
local hasKeySystem = false

-- Detect if a key system is running
CreateThread(function()
    Wait(2000) -- Wait for resources to load
    
    hasKeySystem = GetResourceState('mk_vehiclekeys') == 'started' or 
                   GetResourceState('wasabi_carlock') == 'started' or
                   GetResourceState('qs-vehiclekeys') == 'started' or
                   GetResourceState('MrNewbVehicleKeys') == 'started'
    
    if hasKeySystem then
        print("^2[rk_propad]^7 Vehicle key system detected - Full key functionality enabled")
    else
        print("^3[rk_propad]^7 No key system detected - Auto-start mode enabled")
    end
end)

-- Safety check for vehicle key functions
if not GiveVehKeys then
    print("^1[rk_propad]^7 CRITICAL: GiveVehKeys function not found! Check your init.lua")
    GiveVehKeys = function(vehicle)
        print("^3[rk_propad]^7 Using emergency fallback GiveVehKeys")
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        return true
    end
end

if not RemoveVehKeys then
    print("^1[rk_propad]^7 CRITICAL: RemoveVehKeys function not found! Check your init.lua")
    RemoveVehKeys = function(vehicle)
        print("^3[rk_propad]^7 Using emergency fallback RemoveVehKeys")
        SetVehicleHasBeenOwnedByPlayer(vehicle, false)
        SetVehicleNeedsToBeHotwired(vehicle, true)
        SetVehicleEngineOn(vehicle, false, false, true)
        return true
    end
end

RegisterNetEvent("rk_propad:DontTryExplotingThisNUIevent", function(hasPropad)
    if tabletObject then
        return
    end

    if not hasPropad then
        config.Notify(Locale("title_error"), Locale("error_no_propad"), "error")
        return
    end

    local isInVehicle = IsPedInAnyVehicle(cache.ped, false)
    if not isInVehicle then
        config.Notify(Locale("title_error"), Locale("error_not_in_vehicle"), "error")
        return
    end

    local hasUSB, hasKeyfob = lib.callback.await("rk_propad:checkItems", false)

    -- Create and attach tablet prop
    tabletObject = CreateObject("prop_cs_tablet", 0, 0, 0, true, true, true)
    AttachEntityToEntity(
        tabletObject,
        cache.ped,
        GetPedBoneIndex(cache.ped, 60309),
        0.03,
        0.002,
        -0.0,
        10.0,
        160.0,
        0.0,
        true,
        true,
        false,
        true,
        1,
        true
    )

    -- Play tablet animation
    lib.playAnim(
        cache.ped,
        "amb@code_human_in_bus_passenger_idles@female@tablet@base",
        "base",
        8.0,
        8.0,
        -1,
        49,
        0.0,
        false,
        false,
        false
    )

    -- Enable NUI focus
    SetNuiFocus(true, true)

    -- Send config to NUI
    nui:msg("setConfig", {
        serverLogo = config.ServerLogo,
        carBrands = config.carBrands,
        hackDuration = {
            programKeyDuration = config.HackDuration.ProgramKey,
            eraseKeysDuration = config.HackDuration.EraseKeys
        },
        tabs = config.Tabs,
        NoBrandFound = config.NoBrandFound
    })

    Wait(100)

    -- Get current vehicle brand
    currentBrand = vehicleFunctions.GetVehBrand()

    -- Set NUI visibility
    nui:msg("setVisible", {
        status = true,
        currentBrand = currentBrand,
        hasUSB = hasUSB,
        hasKeyfob = hasKeyfob,
        locale = localeManager.primaryLocale,
        vehicleStatus = vehicleFunctions.GetStatus(),
        vehicleMods = vehicleFunctions.GetModifications()
    })
end)

RegisterNetEvent("rk_propad:removeVehicleKeys", function(vehicle)
    if not vehicle or vehicle == 0 then
        return
    end
    RemoveVehKeys(vehicle)
end)

-- NUI Callback: Check brand compatibility
nui:cb("checkBrand", function(data, cb)
    -- Allow "Other" option to skip brand validation
    if data.brand == "Other" or data.brand == "other" then
        cb({ success = true })
        return
    end

    if not currentBrand then
        config.Notify(Locale("title_error"), Locale("error_invalid_vehicle"), "error")
        cb({ success = false })
        return
    end

    if currentBrand ~= data.brand then
        config.Notify(Locale("title_error"), Locale("error_wrong_brand", data.brand), "error")
        cb({ success = false })
        return
    end

    cb({ success = true })
end)

-- NUI Callback: Check items
nui:cb("checkItems", function(data, cb)
    local hasUSB, hasKeyfob = lib.callback.await("rk_propad:checkItems", false)
    cb({
        hasUSB = hasUSB,
        hasKeyfob = hasKeyfob
    })
end)

-- NUI Callback: Close tablet
nui:cb("close", function(data, cb)
    if tabletObject then
        ClearPedTasks(PlayerPedId())
        DeleteObject(tabletObject)
        tabletObject = nil
    end

    SetNuiFocus(false, false)
    cb("ok")
end)

-- NUI Callback: Program key
nui:cb("programKey", function(data, cb)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)

    if not vehicle or vehicle == 0 then
        config.Notify(Locale("title_error"), Locale("error_program_key"), "error")
        cb({ success = false })
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))

    -- Debug logging
    if config.DebugVehicleKeys then
        print(("^5[rk_propad]^7 Programming keys for vehicle: %s [%s]"):format(vehicleName, plate))
    end

    local success = GiveVehKeys(vehicle)

    if success then
        -- Remove items
        lib.callback.await("rk_propad:removeItems", false)

        -- Transfer vehicle ownership if DeleteAndAdd is enabled
        if config.DeleteAndAdd and hasKeySystem then
            local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
            local transferSuccess = lib.callback.await("rk_propad:transferOwnership", false, plate, vehicleNetId)
            if transferSuccess and config.DebugVehicleKeys then
                print(("^2[rk_propad]^7 Successfully transferred ownership of vehicle [%s]"):format(plate))
            end
        end

        -- Set hotwired state for mk_vehiclekeys
        if hasKeySystem then
            CreateThread(function()
                Wait(100)
                if DoesEntityExist(vehicle) then
                    Entity(vehicle).state:set('Hotwired', 'Successful', true)
                    if config.DebugVehicleKeys then
                        print(("^5[rk_propad]^7 Set Hotwired state for vehicle"):format())
                    end
                end
            end)
        end

        -- Show appropriate notification
        if hasKeySystem then
            if config.DeleteAndAdd then
                config.Notify(
                    Locale("title_success"),
                    Locale("success_key_programmed") .. "\nVehicle ownership transferred!",
                    "success"
                )
            else
                config.Notify(Locale("title_success"), Locale("success_key_programmed"), "success")
            end
        else
            config.Notify(
                "✓ Vehicle Programmed",
                string.format(
                    "Vehicle %s [%s] is now ready to drive!\n" ..
                    "Engine started automatically (No key system detected)",
                    vehicleName,
                    plate
                ),
                "success"
            )
        end

        -- Make sure engine stays on in auto-start mode
        if not hasKeySystem then
            CreateThread(function()
                Wait(100)
                if DoesEntityExist(vehicle) then
                    SetVehicleEngineOn(vehicle, true, true, false)
                end
            end)
        end

        cb({ success = true })
    else
        print("^1[rk_propad]^7 Failed to give keys")
        config.Notify("Error", "Failed to program keys", "error")
        cb({ success = false })
    end
end)

-- NUI Callback: Erase keys
nui:cb("eraseKeys", function(data, cb)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)

    if not vehicle or vehicle == 0 then
        config.Notify(Locale("title_error"), Locale("error_erase_keys"), "error")
        cb({ success = false })
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))

    -- Debug logging
    if config.DebugVehicleKeys then
        print(("^5[rk_propad]^7 Erasing keys for vehicle: %s [%s]"):format(vehicleName, plate))
    end

    TriggerServerEvent("rk_propad:eraseAllKeys", NetworkGetNetworkIdFromEntity(vehicle))

    -- Delete vehicle ownership if DeleteAndAdd is enabled
    if config.DeleteAndAdd and hasKeySystem then
        local deleteSuccess = lib.callback.await("rk_propad:deleteOwnership", false, plate)
        if deleteSuccess and config.DebugVehicleKeys then
            print(("^2[rk_propad]^7 Successfully deleted ownership of vehicle [%s]"):format(plate))
        end
    end

    -- Show appropriate notification
    if hasKeySystem then
        if config.DeleteAndAdd then
            config.Notify(
                Locale("title_success"),
                Locale("success_keys_erased") .. "\nVehicle ownership removed!",
                "success"
            )
        else
            config.Notify(Locale("title_success"), Locale("success_keys_erased"), "success")
        end
    else
        config.Notify(
            "✓ Keys Erased",
            string.format(
                "Vehicle %s [%s] access removed!\n" ..
                "Engine turned off (No key system detected)",
                vehicleName,
                plate
            ),
            "success"
        )
    end

    cb({ success = true })
end)

-- Export for ox_inventory item usage
exports('usePropad', function(data, slot)
    local hasPropad = exports.ox_inventory:Search('count', 'propad')
    if hasPropad and hasPropad > 0 then
        TriggerEvent("rk_propad:DontTryExplotingThisNUIevent", true)
    else
        TriggerEvent("rk_propad:DontTryExplotingThisNUIevent", false)
    end
end)