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
TransferVehicleOwnership = function(source, plate, vehicleEntity)
    if not config.DeleteAndAdd then
        if config.DebugVehicleKeys then
            print("^3[rk_propad]^7 DeleteAndAdd is disabled, skipping ownership transfer")
        end
        return false
    end

    -- Get player identifier from FiveM identifiers
    local playerIdentifier = nil
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.match(id, "license:") then
            playerIdentifier = id
            break
        end
    end

    if not playerIdentifier then
        print("^1[rk_propad]^7 No valid identifier found for player: " .. source)
        return false
    end

    if config.DebugVehicleKeys then
        print(("^5[rk_propad]^7 Player identifier: %s"):format(playerIdentifier))
    end

    -- Use mk_vehiclekeys ChangeOwner export if vehicle entity is provided
    if vehicleEntity and DoesEntityExist(vehicleEntity) then
        local changeOwnerSuccess, changeOwnerError = pcall(function()
            exports["mk_vehiclekeys"]:ChangeOwner(vehicleEntity, source)
        end)

        if changeOwnerSuccess then
            print(("^2[rk_propad]^7 Vehicle [%s] ownership changed via mk_vehiclekeys ChangeOwner"):format(plate))
            return true
        else
            if config.DebugVehicleKeys then
                print(("^3[rk_propad]^7 mk_vehiclekeys ChangeOwner failed: %s"):format(tostring(changeOwnerError)))
            end
        end
    end

    -- Fallback: Use mk_vehiclekeys AddKey export to give ownership
    if vehicleEntity and DoesEntityExist(vehicleEntity) then
        local addKeySuccess, addKeyError = pcall(function()
            exports["mk_vehiclekeys"]:AddKey(vehicleEntity, source)
        end)

        if addKeySuccess then
            print(("^2[rk_propad]^7 Vehicle [%s] keys given to player %s via mk_vehiclekeys"):format(plate, source))
            -- Continue to database update
        else
            if config.DebugVehicleKeys then
                print(("^3[rk_propad]^7 mk_vehiclekeys AddKey failed: %s"):format(tostring(addKeyError)))
            end
        end
    end

    -- Database fallback
    local transferSuccess = false

    -- Database operations
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
                    print(("^2[rk_propad]^7 Database: Vehicle [%s] ownership transferred from %s to %s"):format(plate, oldOwner, playerIdentifier))
                    transferSuccess = true
                else
                    print(("^1[rk_propad]^7 Failed to transfer vehicle [%s] ownership in database"):format(plate))
                    transferSuccess = false
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
                    print(("^2[rk_propad]^7 Database: Vehicle [%s] added with owner %s"):format(plate, playerIdentifier))
                    transferSuccess = true
                else
                    print(("^1[rk_propad]^7 Failed to add vehicle [%s] to database"):format(plate))
                    transferSuccess = false
                end
            end
    else
        print("^1[rk_propad]^7 No database resource found (oxmysql). Cannot transfer ownership.")
        transferSuccess = false
    end

    return transferSuccess
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
