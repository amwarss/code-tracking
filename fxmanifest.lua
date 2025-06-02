fx_version 'cerulean'
game 'gta5'

author 'codescripts'
description 'codescripts'
version '1.0.0'

lua54 'yes'
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'

}

client_scripts {
    'client/client.lua',
}

ui_page 'web/new.html'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/ComboZone.lua',

}

files {
    'web/*.*'
}
dependencies {
    'qb-core',
    'ox_lib',
    
}
