-- Add these items to your ox_inventory/data/items.lua file

['propad'] = {
    label = 'PROPAD Device',
    weight = 500,
    stack = false,
    close = true,
    description = 'Professional vehicle programming device',
    client = {
        export = 'rk_propad.usePropad'
    }
},

['usb_device'] = {
    label = 'USB Device',
    weight = 50,
    stack = true,
    close = true,
    description = 'USB device for data transfer'
},

['empty_keyfob'] = {
    label = 'Empty Key Fob',
    weight = 25,
    stack = true,
    close = true,
    description = 'Blank programmable key fob'
},