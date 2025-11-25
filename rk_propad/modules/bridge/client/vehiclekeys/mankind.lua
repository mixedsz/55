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