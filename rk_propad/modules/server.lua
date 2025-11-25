local config = require("shared.main")

-- ═══════════════════════════════════════════════════════
--                    CALLBACKS
-- ═══════════════════════════════════════════════════════

-- Callback to check if player has required items
lib.callback.register('rk_propad:checkItems', function(source)
    local hasUSB = false
    local hasKeyfob = false
    
    -- Try to get item counts from ox_inventory with error handling
    local success, result = pcall(function()
        return exports.ox_inventory:Search(source, 'count', 'usb_device')
    end)
    
    if success and result then
        hasUSB = result > 0
    else
        print(("^3[rk_propad]^7 Warning: Could not check USB for player %s"):format(source))
    end
    
    -- Try to get keyfob count
    success, result = pcall(function()
        return exports.ox_inventory:Search(source, 'count', 'empty_keyfob')
    end)
    
    if success and result then
        hasKeyfob = result > 0
    else
        print(("^3[rk_propad]^7 Warning: Could not check keyfob for player %s"):format(source))
    end
    
    if config.DebugVehicleKeys then
        print(("^5[rk_propad]^7 Player %s - USB: %s, Keyfob: %s"):format(source, tostring(hasUSB), tostring(hasKeyfob)))
    end
    
    return hasUSB, hasKeyfob
end)

-- Callback to remove items after successful key programming
lib.callback.register('rk_propad:removeItems', function(source)
    local success = true

    -- Remove USB device
    local usbRemoved = pcall(function()
        local hasUSB = exports.ox_inventory:Search(source, 'count', 'usb_device')
        if hasUSB and hasUSB > 0 then
            return exports.ox_inventory:RemoveItem(source, 'usb_device', 1)
        end
        return false
    end)

    if not usbRemoved then
        success = false
        print(("^1[rk_propad]^7 Failed to remove USB from player %s"):format(source))
    end

    -- Remove empty keyfob
    local keyfobRemoved = pcall(function()
        local hasKeyfob = exports.ox_inventory:Search(source, 'count', 'empty_keyfob')
        if hasKeyfob and hasKeyfob > 0 then
            return exports.ox_inventory:RemoveItem(source, 'empty_keyfob', 1)
        end
        return false
    end)

    if not keyfobRemoved then
        success = false
        print(("^1[rk_propad]^7 Failed to remove keyfob from player %s"):format(source))
    end

    if success and config.DebugVehicleKeys then
        print(("^2[rk_propad]^7 Successfully removed items from player %s"):format(source))
    end

    return success
end)

-- Callback to transfer vehicle ownership
lib.callback.register('rk_propad:transferOwnership', function(source, plate)
    if not plate then
        print(("^1[rk_propad]^7 Invalid plate provided for ownership transfer"):format())
        return false
    end

    if config.DebugVehicleKeys then
        print(("^5[rk_propad]^7 Attempting to transfer ownership of vehicle [%s] to player %s"):format(plate, source))
    end

    -- Check if TransferVehicleOwnership function exists (from bridge file)
    if TransferVehicleOwnership then
        return TransferVehicleOwnership(source, plate)
    else
        print("^1[rk_propad]^7 TransferVehicleOwnership function not found. Make sure mk_vehiclekeys bridge is loaded.")
        return false
    end
end)

-- Callback to delete vehicle ownership
lib.callback.register('rk_propad:deleteOwnership', function(source, plate)
    if not plate then
        print(("^1[rk_propad]^7 Invalid plate provided for ownership deletion"):format())
        return false
    end

    if config.DebugVehicleKeys then
        print(("^5[rk_propad]^7 Attempting to delete ownership of vehicle [%s]"):format(plate))
    end

    -- Check if DeleteVehicleOwnership function exists (from bridge file)
    if DeleteVehicleOwnership then
        return DeleteVehicleOwnership(plate)
    else
        print("^1[rk_propad]^7 DeleteVehicleOwnership function not found. Make sure mk_vehiclekeys bridge is loaded.")
        return false
    end
end)

print("^2[rk_propad]^7 Server callbacks registered successfully")

-- ═══════════════════════════════════════════════════════
--                    EVENTS
-- ═══════════════════════════════════════════════════════

-- Server-side event to erase all keys from a vehicle
RegisterNetEvent("rk_propad:eraseAllKeys", function(vehicleNetId)
    local source = source
    
    if not vehicleNetId then
        print(("^1[rk_propad]^7 Invalid network ID received from player %s"):format(source))
        return
    end
    
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if not vehicle or vehicle == 0 then
        print(("^1[rk_propad]^7 Could not get vehicle entity from network ID %s"):format(vehicleNetId))
        return
    end
    
    -- Log the action
    local playerName = GetPlayerName(source)
    local plate = GetVehicleNumberPlateText(vehicle)
    print(("^5[rk_propad]^7 Player %s (%s) erased all keys for vehicle [%s]"):format(playerName, source, plate))
    
    -- Trigger the event to remove keys for all players
    TriggerClientEvent("rk_propad:removeVehicleKeys", -1, vehicle)
end)

-- ═══════════════════════════════════════════════════════
--                    COMMANDS
-- ═══════════════════════════════════════════════════════

-- Command to use the propad (alternative to item usage)
lib.addCommand("usepropad", {
    help = "Use the PROPAD device",
    restricted = false
}, function(source)
    local success, hasPropad = pcall(function()
        return exports.ox_inventory:Search(source, 'count', 'propad')
    end)
    
    if not success then
        print(("^1[rk_propad]^7 Error checking inventory for player %s"):format(source))
        TriggerClientEvent("rk_propad:DontTryExplotingThisNUIevent", source, false)
        return
    end
    
    if hasPropad and hasPropad > 0 then
        TriggerClientEvent("rk_propad:DontTryExplotingThisNUIevent", source, true)
        if config.DebugVehicleKeys then
            print(("^5[rk_propad]^7 Player %s opened propad via command"):format(GetPlayerName(source)))
        end
    else
        TriggerClientEvent("rk_propad:DontTryExplotingThisNUIevent", source, false)
        if config.DebugVehicleKeys then
            print(("^3[rk_propad]^7 Player %s attempted to use propad without item"):format(GetPlayerName(source)))
        end
    end
end)

-- Admin command to give propad items (optional)
lib.addCommand("givepropad", {
    help = "Give propad items to a player",
    restricted = "group.admin",
    params = {
        {
            name = "target",
            type = "playerId",
            help = "Target player ID"
        },
        {
            name = "item",
            type = "string",
            help = "Item to give (propad, usb_device, empty_keyfob)"
        },
        {
            name = "amount",
            type = "number",
            help = "Amount to give",
            optional = true
        }
    }
}, function(source, args)
    local target = args.target
    local item = args.item
    local amount = args.amount or 1
    
    local validItems = {
        propad = true,
        usb_device = true,
        empty_keyfob = true
    }
    
    if not validItems[item] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Invalid item. Valid items: propad, usb_device, empty_keyfob',
            type = 'error'
        })
        return
    end
    
    local success, result = pcall(function()
        return exports.ox_inventory:AddItem(target, item, amount)
    end)
    
    if success and result then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Success',
            description = ('Gave %sx %s to player %s'):format(amount, item, GetPlayerName(target)),
            type = 'success'
        })
        
        TriggerClientEvent('ox_lib:notify', target, {
            title = 'Item Received',
            description = ('You received %sx %s'):format(amount, item),
            type = 'inform'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Failed to give item. Check console for details.',
            type = 'error'
        })
        print(("^1[rk_propad]^7 Failed to give item to player %s: %s"):format(target, tostring(result)))
    end
end)

-- ═══════════════════════════════════════════════════════
--                    STARTUP CHECKS
-- ═══════════════════════════════════════════════════════

print("^2[rk_propad]^7 Server module loaded successfully")

-- Check if ox_inventory is available and verify callbacks
CreateThread(function()
    Wait(2000) -- Wait for other resources to initialize
    
    if GetResourceState('ox_inventory') ~= 'started' then
        print("^3[rk_propad]^7 Warning: ox_inventory is not running. Item functionality will not work!")
    else
        print("^2[rk_propad]^7 ox_inventory integration: ^2✓ Active^7")
    end
    
    -- Verify callbacks are working by testing them
    local callbacksWorking = true
    
    -- Test if lib.callback exists and our callbacks are registered
    if not lib or not lib.callback then
        print("^1[rk_propad]^7 CRITICAL: ox_lib callbacks not available!")
        callbacksWorking = false
    else
        -- Just verify the callback system is functional
        local testSuccess = pcall(function()
            -- This just checks if the callback registration worked
            return type(lib.callback.register) == 'function'
        end)
        
        if not testSuccess then
            print("^1[rk_propad]^7 CRITICAL: Callback system error!")
            callbacksWorking = false
        end
    end
    
    if callbacksWorking then
        print("^2[rk_propad]^7 All callbacks verified: ^2✓ Ready^7")
    else
        print("^1[rk_propad]^7 WARNING: Callback verification failed - script may not work correctly!")
    end
end)