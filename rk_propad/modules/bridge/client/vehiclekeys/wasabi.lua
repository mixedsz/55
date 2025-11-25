---@diagnostic disable: duplicate-set-field, lowercase-global

if GetResourceState('wasabi_carlock') ~= 'started' then return end

print("^2[rk_propad]^7 Loading wasabi_carlock bridge...")

GiveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print("^1[rk_propad]^7 Invalid vehicle in wasabi_carlock GiveVehKeys")
        return false
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    local success, err = pcall(function()
        exports.wasabi_carlock:GiveKey(plate)
    end)
    
    if not success then
        print("^1[rk_propad]^7 Error giving keys with wasabi_carlock: " .. tostring(err))
        return false
    end
    
    print("^2[rk_propad]^7 Keys given via wasabi_carlock for plate: " .. plate)
    return true
end

RemoveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print("^1[rk_propad]^7 Invalid vehicle in wasabi_carlock RemoveVehKeys")
        return false
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    local success, err = pcall(function()
        exports.wasabi_carlock:RemoveKey(plate)
    end)
    
    if not success then
        print("^1[rk_propad]^7 Error removing keys with wasabi_carlock: " .. tostring(err))
        return false
    end
    
    print("^2[rk_propad]^7 Keys removed via wasabi_carlock for plate: " .. plate)
    return true
end

print("^2[rk_propad]^7 wasabi_carlock bridge loaded successfully")