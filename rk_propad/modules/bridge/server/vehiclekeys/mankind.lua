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

    -- First, check what identifier type the existing vehicle uses (if it exists)
    local identifierType = nil
    local existingVehicleCheck = nil

    if GetResourceState('oxmysql') == 'started' then
        existingVehicleCheck = MySQL.query.await(
            'SELECT owner FROM owned_vehicles WHERE plate = ?',
            {plate}
        )

        if existingVehicleCheck and #existingVehicleCheck > 0 then
            local oldOwner = existingVehicleCheck[1].owner
            -- Determine identifier type from old owner (char1:, license:, steam:, etc.)
            if string.match(oldOwner, "^char%d+:") then
                identifierType = "char"
            elseif string.match(oldOwner, "^license:") then
                identifierType = "license"
            elseif string.match(oldOwner, "^steam:") then
                identifierType = "steam"
            end

            if config.DebugVehicleKeys then
                print(("^5[rk_propad]^7 Detected identifier type from old owner: %s"):format(identifierType or "unknown"))
            end
        end
    end

    -- Get player identifier matching the type used in database
    local playerIdentifier = nil
    local playerIdentifiers = GetPlayerIdentifiers(source)

    -- If we detected char identifier type, search for char identifier FIRST
    if identifierType == "char" then
        -- Search player identifiers directly for char pattern
        for _, id in ipairs(playerIdentifiers) do
            if string.match(id, "^char%d+:") then
                playerIdentifier = id
                if config.DebugVehicleKeys then
                    print(("^5[rk_propad]^7 Found char identifier: %s"):format(playerIdentifier))
                end
                break
            end
        end

        -- If not found, try ESX export as fallback
        if not playerIdentifier and ESX then
            local success, xPlayer = pcall(function()
                return ESX.GetPlayerFromId(source)
            end)
            if success and xPlayer and xPlayer.identifier then
                playerIdentifier = xPlayer.identifier
                if config.DebugVehicleKeys then
                    print(("^5[rk_propad]^7 Got char ID from ESX: %s"):format(playerIdentifier))
                end
            end
        end
    elseif identifierType then
        -- Look for the specific identifier type
        for _, id in ipairs(playerIdentifiers) do
            if string.match(id, "^" .. identifierType .. ":") then
                playerIdentifier = id
                break
            end
        end
    end

    -- Fallback ONLY if no identifier found yet
    if not playerIdentifier then
        if config.DebugVehicleKeys then
            print("^3[rk_propad]^7 Identifier type mismatch or not found, using fallback")
        end
        -- Try char first (for ESX)
        for _, id in ipairs(playerIdentifiers) do
            if string.match(id, "^char%d+:") then
                playerIdentifier = id
                break
            end
        end
    end

    if not playerIdentifier then
        -- Then try license
        for _, id in ipairs(playerIdentifiers) do
            if string.match(id, "^license:") then
                playerIdentifier = id
                break
            end
        end
    end

    if not playerIdentifier then
        -- Finally try steam
        for _, id in ipairs(playerIdentifiers) do
            if string.match(id, "^steam:") then
                playerIdentifier = id
                break
            end
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
    local usedChangeOwner = false
    if vehicleEntity and DoesEntityExist(vehicleEntity) then
        local changeOwnerSuccess, changeOwnerError = pcall(function()
            exports["mk_vehiclekeys"]:ChangeOwner(vehicleEntity, source)
        end)

        if changeOwnerSuccess then
            print(("^2[rk_propad]^7 Vehicle [%s] ownership changed via mk_vehiclekeys ChangeOwner"):format(plate))
            usedChangeOwner = true
            -- DON'T return here - continue to database update!
        else
            if config.DebugVehicleKeys then
                print(("^3[rk_propad]^7 mk_vehiclekeys ChangeOwner failed: %s"):format(tostring(changeOwnerError)))
            end
        end
    end

    -- Fallback: Use mk_vehiclekeys AddKey export if ChangeOwner wasn't used
    if vehicleEntity and DoesEntityExist(vehicleEntity) and not usedChangeOwner then
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

    -- Database operations (ALWAYS run these!)
    local transferSuccess = false
    print(("^5[rk_propad]^7 Starting database operations for vehicle [%s]"):format(plate))

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
