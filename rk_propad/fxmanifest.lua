fx_version 'cerulean'
game 'gta5'

author 'RK x AnnoyingTV'
description 'Windy City Propad - Advanced Vehicle Theft'
version '1.0.4'

ui_page 'build/index.html'

files {
    'build/**',
    'build/assets/**',
    'locales/json/**',
}

shared_scripts {
    '@ox_lib/init.lua',
    'init.lua',
    'locales/LocaleManager.lua',
    'shared/main.lua',
    'shared/vehicles.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/bridge/server/vehiclekeys/*.lua',
    'modules/server.lua',
}

client_scripts {
    -- Load bridge files FIRST before anything else
    'modules/bridge/client/vehiclekeys/*.lua',
    'modules/nui/client.lua',
    'modules/vehicle/client.lua',
    'modules/client.lua',
}

-- Exports for inventory integration
client_exports {
    'usePropad'
}

dependencies {
    'ox_lib',
    '/optional:mk_vehiclekeys',
}

lua54 'yes'