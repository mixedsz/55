---@diagnostic disable: duplicate-set-field, lowercase-global

local config = require('shared.main')

if not config.DebugVehicleKeys then return end

GiveVehKeys = function(vehicle)
    print('Giving vehicle keys for', vehicle)
end

RemoveVehKeys = function(vehicle)
    print('Removing vehicle keys for', vehicle)
end
