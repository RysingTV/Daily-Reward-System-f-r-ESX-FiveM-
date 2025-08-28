Config = {}

-- Cooldown in Stunden
Config.CooldownHours = 24

-- Discord Webhooks
Config.Webhooks = {
    dailyReward = "https://discord.com/api/webhooks/1409935586348896276/3mhfCgbJLgPyKP-P0-5FZhzB-KO9vGER0-DIQmXfGsfcACB53odKqfXXcXPEGLHxjT2a",
    resetLog = "https://discord.com/api/webhooks/1409935586348896276/3mhfCgbJLgPyKP-P0-5FZhzB-KO9vGER0-DIQmXfGsfcACB53odKqfXXcXPEGLHxjT2a"
}

-- Belohnungen mit Gewichtung (je höher die Zahl, desto wahrscheinlicher)
Config.RewardItems = {
    items = {
        {name = "bread", count = 2, weight = 10},       -- häufig
        {name = "water", count = 2, weight = 10},       -- häufig
        {name = "repairkit", count = 1, weight = 5}     -- mittel
    },
    weapons = {
        {name = "weapon_pistol", count = 1, weight = 2}, -- selten
        {name = "weapon_knife", count = 1, weight = 3}   -- etwas häufiger
    }
}