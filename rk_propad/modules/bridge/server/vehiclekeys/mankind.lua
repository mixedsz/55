---@diagnostic disable: duplicate-set-field, lowercase-global

-- Wait for mk_vehiclekeys to be available (up to 5 seconds)
CreateThread(function()
    local maxAttempts = 50
    local attempt = 0

    while attempt < maxAttempts do
        if GetResourceState('mk_vehiclekeys') == 'started' then
            break
        end
        attempt = attempt + 1
        Wait(100)
    end

    if GetResourceState('mk_vehiclekeys') ~= 'started' then
        local state = GetResourceState('mk_vehiclekeys')
        if state ~= 'missing' then
            print(("^3[rk_propad]^7 mk_vehiclekeys found but not started after 5s. Current state: %s"):format(state))
        end
        return
    end

    print("^2[rk_propad]^7 Loading mk_vehiclekeys server bridge...")

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
        -- Try getting identifier from mk_vehiclekeys export first
        local mkIdentifier = exports["mk_vehiclekeys"]:GetPlayerIdentifier(source)
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

    -- Use mk_vehiclekeys export to transfer ownership
    local transferSuccess = pcall(function()
        exports["mk_vehiclekeys"]:TransferVehicleOwnership(plate, playerIdentifier)
    end)

    if not transferSuccess then
        -- Fallback to direct database operations if export doesn't exist
        if config.DebugVehicleKeys then
            print("^3[rk_propad]^7 mk_vehiclekeys TransferVehicleOwnership export not found, using database fallback")
        end

        -- Try oxmysql first
        if GetResourceState('oxmysql') == 'started' then
            -- First, check if vehicle exists in database
            local existingVehicle = MySQL.query.await(
                'SELECT * FROM owned_vehicles WHERE plate = ?',
                {plate}
            )

            if existingVehicle and #existingVehicle > 0 then
                -- Vehicle exists, get the old owner and vehicle data
                local oldOwner = existingVehicle[1].owner
                local vehicleData = existingVehicle[1].vehicle or '{}'

                if config.DebugVehicleKeys then
                    print(("^3[rk_propad]^7 Found existing vehicle [%s] owned by %s"):format(plate, oldOwner))
                end

                -- Delete old ownership
                MySQL.query.await('DELETE FROM owned_vehicles WHERE plate = ?', {plate})

                -- Insert with new owner
                local insertSuccess = MySQL.insert.await(
                    'INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)',
                    {playerIdentifier, plate, vehicleData}
                )

                if insertSuccess then
                    print(("^2[rk_propad]^7 Vehicle [%s] ownership transferred from %s to %s"):format(plate, oldOwner, playerIdentifier))
                    return true
                else
                    print(("^1[rk_propad]^7 Failed to transfer vehicle [%s] ownership"):format(plate))
                    return false
                end
            else
                -- Vehicle doesn't exist, insert as new
                if config.DebugVehicleKeys then
                    print(("^3[rk_propad]^7 Vehicle [%s] not in database, creating new entry"):format(plate))
                end

                local insertSuccess = MySQL.insert.await(
                    'INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)',
                    {playerIdentifier, plate, '{}'}
                )

                if insertSuccess then
                    print(("^2[rk_propad]^7 Vehicle [%s] added to database with owner %s"):format(plate, playerIdentifier))
                    return true
                else
                    print(("^1[rk_propad]^7 Failed to add vehicle [%s] to database"):format(plate))
                    return false
                end
            end
        else
            print("^1[rk_propad]^7 No database resource found (oxmysql). Cannot transfer ownership.")
            return false
        end
    else
        print(("^2[rk_propad]^7 Vehicle [%s] ownership transferred to %s via mk_vehiclekeys"):format(plate, playerIdentifier))
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

    -- Use mk_vehiclekeys export to remove vehicle
    local deleteSuccess = pcall(function()
        exports["mk_vehiclekeys"]:RemoveVehicleFromDatabase(plate)
    end)

    if not deleteSuccess then
        -- Fallback to direct database operations if export doesn't exist
        if config.DebugVehicleKeys then
            print("^3[rk_propad]^7 mk_vehiclekeys RemoveVehicleFromDatabase export not found, using database fallback")
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
        print(("^2[rk_propad]^7 Vehicle [%s] deleted from database via mk_vehiclekeys"):format(plate))
        return true
    end

    return false
end

    print("^2[rk_propad]^7 mk_vehiclekeys server bridge loaded successfully")
end)
