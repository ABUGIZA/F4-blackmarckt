fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'F4 Black Market'
description 'Black market NUI with QB/QBX support and persistent history'
author 'F4'
version '1.0.0'

ui_page 'ui/build/index.html'

files {
    'ui/build/**/*',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
