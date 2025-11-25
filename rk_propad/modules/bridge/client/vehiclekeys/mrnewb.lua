---@diagnostic disable: duplicate-set-field, lowercase-global

if GetResourceState('MrNewbVehicleKeys') ~= 'started' then return end

print("^2[rk_propad]^7 Loading MrNewbVehicleKeys bridge...")

GiveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print("^1[rk_propad]^7 Invalid vehicle in MrNewbVehicleKeys GiveVehKeys")
        return false
    end
    
    local success, err = pcall(function()
        exports.MrNewbVehicleKeys:GiveKeys(vehicle)
    end)
    
    if not success then
        print("^1[rk_propad]^7 Error giving keys with MrNewbVehicleKeys: " .. tostring(err))
        return false
    end
    
    print("^2[rk_propad]^7 Keys given via MrNewbVehicleKeys")
    return true
end

RemoveVehKeys = function(vehicle)
    if not vehicle or vehicle == 0 then
        print("^1[rk_propad]^7 Invalid vehicle in MrNewbVehicleKeys RemoveVehKeys")
        return false
    end
    
    local success, err = pcall(function()
        exports.MrNewbVehicleKeys:RemoveKeys(vehicle)
    end)
    
    if not success then
        print("^1[rk_propad]^7 Error removing keys with MrNewbVehicleKeys: " .. tostring(err))
        return false
    end
    
    print("^2[rk_propad]^7 Keys removed via MrNewbVehicleKeys")
    return true
end

print("^2[rk_propad]^7 MrNewbVehicleKeys bridge loaded successfully")