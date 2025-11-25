---@diagnostic disable: duplicate-set-field, lowercase-global

if GetResourceState('qs-vehiclekeys') ~= 'started' then return end

print("^2[rk_propad]^7 Loading qs-vehiclekeys bridge...")

GiveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print("^1[rk_propad]^7 Invalid vehicle in qs-vehiclekeys GiveVehKeys")
        return false
    end
    
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local plate = GetVehicleNumberPlateText(vehicle)
    
    local success, err = pcall(function()
        exports['qs-vehiclekeys']:GiveKeys(plate, model, true)
    end)
    
    if not success then
        print("^1[rk_propad]^7 Error giving keys with qs-vehiclekeys: " .. tostring(err))
        return false
    end
    
    print("^2[rk_propad]^7 Keys given via qs-vehiclekeys for " .. model .. " [" .. plate .. "]")
    return true
end

RemoveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print("^1[rk_propad]^7 Invalid vehicle in qs-vehiclekeys RemoveVehKeys")
        return false
    end
    
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local plate = GetVehicleNumberPlateText(vehicle)
    
    local success, err = pcall(function()
        exports['qs-vehiclekeys']:RemoveKeys(plate, model)
    end)
    
    if not success then
        print("^1[rk_propad]^7 Error removing keys with qs-vehiclekeys: " .. tostring(err))
        return false
    end
    
    print("^2[rk_propad]^7 Keys removed via qs-vehiclekeys for " .. model .. " [" .. plate .. "]")
    return true
end

print("^2[rk_propad]^7 qs-vehiclekeys bridge loaded successfully")