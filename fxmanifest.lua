fx_version 'cerulean'
game 'gta5'

author 'RysingTV'
description 'Tägliche Belohnung: Spieler können alle 24 Stunden ein zufälliges Item oder eine Waffe erhalten.'
version '1.0.1'

server_scripts {
    '@oxmysql/lib/MySQL.lua',  -- unbedingt zuerst für oxmysql
    'config.lua',              -- muss VOR daily_reward.lua geladen werden
    'daily_reward.lua'         -- Hauptcode
}
 
dependency 'es_extended'