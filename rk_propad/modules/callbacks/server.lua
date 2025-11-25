local config = require("shared.main")

-- Callback to check if player has required items
lib.callback.register('rk_propad:checkItems', function(source)
    -- Check for USB device
    local hasUSB = false
    local hasKeyfob = false
    
    -- Try to get item counts from ox_inventory
    local success, result = pcall(function()
        return exports.ox_inventory:Search(source, 'count', 'usb_device')
    end)
    
    if success and result then
        hasUSB = result > 0
    end
    
    -- Try to get keyfob count
    success, result = pcall(function()
        return exports.ox_inventory:Search(source, 'count', 'empty_keyfob')
    end)
    
    if success and result then
        hasKeyfob = result > 0
    end
    
    print(("^5[rk_propad]^7 Player %s - USB: %s, Keyfob: %s"):format(source, tostring(hasUSB), tostring(hasKeyfob)))
    
    return hasUSB, hasKeyfob
end)

-- Callback to remove items after successful key programming
lib.callback.register('rk_propad:removeItems', function(source)
    local success = true
    
    -- Remove USB device
    local hasUSB = exports.ox_inventory:Search(source, 'count', 'usb_device')
    if hasUSB and hasUSB > 0 then
        local removed = exports.ox_inventory:RemoveItem(source, 'usb_device', 1)
        if not removed then
            success = false
            print(("^1[rk_propad]^7 Failed to remove USB from player %s"):format(source))
        end
    end
    
    -- Remove empty keyfob
    local hasKeyfob = exports.ox_inventory:Search(source, 'count', 'empty_keyfob')
    if hasKeyfob and hasKeyfob > 0 then
        local removed = exports.ox_inventory:RemoveItem(source, 'empty_keyfob', 1)
        if not removed then
            success = false
            print(("^1[rk_propad]^7 Failed to remove keyfob from player %s"):format(source))
        end
    end
    
    if success then
        print(("^2[rk_propad]^7 Successfully removed items from player %s"):format(source))
    end
    
    return success
end)

print("^2[rk_propad]^7 Server callbacks registered successfully")