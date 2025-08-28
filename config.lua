Config = {}

-- Cooldown in Stunden
Config.CooldownHours = 24

-- Discord Webhooks
Config.Webhooks = {
    dailyReward = "DEIN WEBHOOK LINK",  -- Log
    resetLog = "DEIN WEBHOOK LINK"      -- Log für Reset (z.B. High Team)
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
