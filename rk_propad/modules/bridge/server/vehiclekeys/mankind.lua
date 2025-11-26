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

print(("^2[rk_propad]^7 Loading %s server bridge..."):format(mkResource))

local config = require("shared.main")

-- Function to transfer vehicle ownership
TransferVehicleOwnership = function(source, plate)
    if not config.DeleteAndAdd then
        if config.DebugVehicleKeys then
            print("^3[rk_propad]^7 DeleteAndAdd is disabled, skipping ownership transfer")
        end
        return false
    end

    local playerIdentifier = nil

    -- Get player identifier (support common frameworks)
    local success, identifier = pcall(function()
        -- Try getting identifier from mk_vehiclekeys/mk_utils export first
        local mkIdentifier = exports[mkResource]:GetPlayerIdentifier(source)
        if mkIdentifier then
            return mkIdentifier
        end

        -- Fallback to standard FiveM identifiers
        for _, id in ipairs(GetPlayerIdentifiers(source)) do
            if string.match(id, "license:") then
                return id
            end
        end
        return nil
    end)

    if success and identifier then
        playerIdentifier = identifier
    else
        print("^1[rk_propad]^7 Failed to get player identifier for source: " .. source)
        return false
    end

    if not playerIdentifier then
        print("^1[rk_propad]^7 No valid identifier found for player: " .. source)
        return false
    end

    -- Use mk_vehiclekeys/mk_utils export to transfer ownership
    local transferSuccess = pcall(function()
        exports[mkResource]:TransferVehicleOwnership(plate, playerIdentifier)
    end)

    if not transferSuccess then
        -- Fallback to direct database operations if export doesn't exist
        if config.DebugVehicleKeys then
            print(("^3[rk_propad]^7 %s TransferVehicleOwnership export not found, using database fallback"):format(mkResource))
        end

        -- Try oxmysql first
        if GetResourceState('oxmysql') == 'started' then
            local affectedRows = MySQL.query.await(
                'UPDATE owned_vehicles SET owner = ? WHERE plate = ?',
                {playerIdentifier, plate}
            )

            if affectedRows and affectedRows > 0 then
                print(("^2[rk_propad]^7 Vehicle [%s] ownership transferred to %s"):format(plate, playerIdentifier))
                return true
            else
                if config.DebugVehicleKeys then
                    print(("^3[rk_propad]^7 No existing ownership found for vehicle [%s], vehicle may not be in database"):format(plate))
                end
                return false
            end
        else
            print("^1[rk_propad]^7 No database resource found (oxmysql). Cannot transfer ownership.")
            return false
        end
    else
        print(("^2[rk_propad]^7 Vehicle [%s] ownership transferred to %s via %s"):format(plate, playerIdentifier, mkResource))
        return true
    end

    return false
end

-- Function to delete vehicle from owned_vehicles table
DeleteVehicleOwnership = function(plate)
    if not config.DeleteAndAdd then
        if config.DebugVehicleKeys then
            print("^3[rk_propad]^7 DeleteAndAdd is disabled, skipping ownership deletion")
        end
        return false
    end

    -- Use mk_vehiclekeys/mk_utils export to remove vehicle
    local deleteSuccess = pcall(function()
        exports[mkResource]:RemoveVehicleFromDatabase(plate)
    end)

    if not deleteSuccess then
        -- Fallback to direct database operations if export doesn't exist
        if config.DebugVehicleKeys then
            print(("^3[rk_propad]^7 %s RemoveVehicleFromDatabase export not found, using database fallback"):format(mkResource))
        end

        -- Try oxmysql first
        if GetResourceState('oxmysql') == 'started' then
            local affectedRows = MySQL.query.await(
                'DELETE FROM owned_vehicles WHERE plate = ?',
                {plate}
            )

            if affectedRows and affectedRows > 0 then
                print(("^2[rk_propad]^7 Vehicle [%s] deleted from owned_vehicles table"):format(plate))
                return true
            else
                if config.DebugVehicleKeys then
                    print(("^3[rk_propad]^7 No ownership found for vehicle [%s] in database"):format(plate))
                end
                return false
            end
        else
            print("^1[rk_propad]^7 No database resource found (oxmysql). Cannot delete ownership.")
            return false
        end
    else
        print(("^2[rk_propad]^7 Vehicle [%s] deleted from database via %s"):format(plate, mkResource))
        return true
    end

    return false
end

print(("^2[rk_propad]^7 %s server bridge loaded successfully"):format(mkResource))
