---@diagnostic disable: duplicate-set-field, lowercase-global

-- Check for mk_vehiclekeys or mk_utils (some systems use mk_utils as the main resource)
local mkResource = nil
if GetResourceState('mk_vehiclekeys') == 'started' then
    mkResource = 'mk_vehiclekeys'
elseif GetResourceState('mk_utils') == 'started' then
    mkResource = 'mk_utils'
end

if not mkResource then
    if GetResourceState('mk_vehiclekeys') ~= 'missing' or GetResourceState('mk_utils') ~= 'missing' then
        print("^3[rk_propad]^7 mk_vehiclekeys/mk_utils found but not started. Current states:")
        print("^3[rk_propad]^7   mk_vehiclekeys: " .. GetResourceState('mk_vehiclekeys'))
        print("^3[rk_propad]^7   mk_utils: " .. GetResourceState('mk_utils'))
    end
    return
end

print(("^2[rk_propad]^7 Loading %s bridge..."):format(mkResource))

GiveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print(("^1[rk_propad]^7 Invalid vehicle in %s GiveVehKeys"):format(mkResource))
        return false
    end

    local success, err = pcall(function()
        exports[mkResource]:AddKey(vehicle)
    end)

    if not success then
        print(("^1[rk_propad]^7 Error giving keys with %s: %s"):format(mkResource, tostring(err)))
        return false
    end

    -- Automatically start the engine after adding keys
    CreateThread(function()
        Wait(100)
        if DoesEntityExist(vehicle) then
            -- Start the engine using mk_vehiclekeys/mk_utils export
            local startSuccess = pcall(function()
                exports[mkResource]:StartEngine(vehicle)
            end)

            if not startSuccess then
                -- Fallback to native if export doesn't exist
                SetVehicleEngineOn(vehicle, true, true, false)
            end
            print("^2[rk_propad]^7 Engine automatically started")
        end
    end)

    print(("^2[rk_propad]^7 Keys given via %s"):format(mkResource))
    return true
end

RemoveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print(("^1[rk_propad]^7 Invalid vehicle in %s RemoveVehKeys"):format(mkResource))
        return false
    end

    local success, err = pcall(function()
        exports[mkResource]:RemoveKey(vehicle)
    end)

    if not success then
        print(("^1[rk_propad]^7 Error removing keys with %s: %s"):format(mkResource, tostring(err)))
        return false
    end

    print(("^2[rk_propad]^7 Keys removed via %s"):format(mkResource))
    return true
end

print(("^2[rk_propad]^7 %s bridge loaded successfully"):format(mkResource))