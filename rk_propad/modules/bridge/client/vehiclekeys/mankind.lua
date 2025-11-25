---@diagnostic disable: duplicate-set-field, lowercase-global

if GetResourceState('mk_vehiclekeys') ~= 'started' then return end

print("^2[rk_propad]^7 Loading mk_vehiclekeys bridge...")

GiveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print("^1[rk_propad]^7 Invalid vehicle in mk_vehiclekeys GiveVehKeys")
        return false
    end

    local success, err = pcall(function()
        exports["mk_vehiclekeys"]:AddKey(vehicle)
    end)

    if not success then
        print("^1[rk_propad]^7 Error giving keys with mk_vehiclekeys: " .. tostring(err))
        return false
    end

    -- Automatically start the engine after adding keys
    CreateThread(function()
        Wait(100)
        if DoesEntityExist(vehicle) then
            -- Start the engine using mk_vehiclekeys export
            local startSuccess = pcall(function()
                exports["mk_vehiclekeys"]:StartEngine(vehicle)
            end)

            if not startSuccess then
                -- Fallback to native if export doesn't exist
                SetVehicleEngineOn(vehicle, true, true, false)
            end
            print("^2[rk_propad]^7 Engine automatically started")
        end
    end)

    print("^2[rk_propad]^7 Keys given via mk_vehiclekeys")
    return true
end

RemoveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print("^1[rk_propad]^7 Invalid vehicle in mk_vehiclekeys RemoveVehKeys")
        return false
    end
    
    local success, err = pcall(function()
        exports["mk_vehiclekeys"]:RemoveKey(vehicle)
    end)
    
    if not success then
        print("^1[rk_propad]^7 Error removing keys with mk_vehiclekeys: " .. tostring(err))
        return false
    end
    
    print("^2[rk_propad]^7 Keys removed via mk_vehiclekeys")
    return true
end

print("^2[rk_propad]^7 mk_vehiclekeys bridge loaded successfully")