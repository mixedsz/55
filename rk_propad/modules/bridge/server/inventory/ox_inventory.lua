-- Ox Inventory Bridge
-- This file handles inventory operations for ox_inventory

if GetResourceState('ox_inventory') ~= 'started' then 
    return 
end

-- The inventory functions are already being used via exports in the callbacks
-- This file just ensures the resource is loaded
print("^2[rk_propad]^7 Using ox_inventory for inventory management")