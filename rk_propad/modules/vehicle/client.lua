local vehFunctions = {}

local vehlist = require('shared.vehicles')

function vehFunctions.GetVehBrand()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)

    if not vehicle or vehicle == 0 then return nil end

    local model = GetEntityModel(vehicle)
    
    for modelName, vehicleData in pairs(vehlist) do
        if GetHashKey(modelName) == model then
            return vehicleData.brand
        end
    end

    return nil
end

function vehFunctions.GetStatus()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle or vehicle == 0 then return nil end
    
    local health = GetVehicleBodyHealth(vehicle)
    local fuel = GetVehicleFuelLevel(vehicle)
    
    return {
        health = math.floor(health),
        fuel = math.floor(fuel)
    }
end

function vehFunctions.GetModifications()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    
    if not vehicle or vehicle == 0 then return nil end
    
    return {
        engine = GetVehicleMod(vehicle, 11),
        brakes = GetVehicleMod(vehicle, 12),
        transmission = GetVehicleMod(vehicle, 13),
        suspension = GetVehicleMod(vehicle, 15),
        armor = GetVehicleMod(vehicle, 16),
        turbo = IsToggleModOn(vehicle, 18),
        xenon = IsToggleModOn(vehicle, 22)
    }
end
return vehFunctions