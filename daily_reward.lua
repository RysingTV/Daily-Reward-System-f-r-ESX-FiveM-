-- Seed für Zufallsgenerator, damit Rewards nicht immer gleich sind
math.randomseed(GetGameTimer() + math.random(999999))

-- ESX Objekt laden
ESX = exports["es_extended"]:getSharedObject()

-- Cooldown-Sperre pro Spieler (Verhindert Spam während MySQL-Abfrage)
local cooldownLock = {}

-- MySQL Tabelle anlegen (falls noch nicht vorhanden)
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS daily_rewards (
            identifier VARCHAR(60) PRIMARY KEY,
            last_claim INT(11)
        )
    ]])
end)

-- Funktion für Benachrichtigungen an Spieler oder Konsole
local function notify(src, msg)
    if src ~= 0 then 
        TriggerClientEvent('esx:showNotification', src, msg) 
    else 
        print(msg) 
    end
end

-- Discord Logging Funktion
-- Sendet Logs mit Titel, Nachricht, Farbe und Webhook
local function sendToDiscord(title, message, color, webhook)
    if not webhook or webhook == "" then 
        print("[WARNUNG] Kein Discord Webhook gesetzt!") 
        return 
    end
    local embed = {{
        title = title,
        description = message,
        color = color,
        footer = { text = os.date("%d.%m.%Y - %H:%M:%S") }
    }}
    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        username = "Daily Reward Log",
        embeds = embed
    }), {['Content-Type']='application/json'})
end

-- Zufällige Belohnung auswählen
-- Es wird entweder ein Item oder eine Waffe aus der Config gewählt
local function getRandomReward()
    -- Prüfen ob Config korrekt geladen ist
    if not Config or not Config.RewardItems or not Config.RewardItems.items or not Config.RewardItems.weapons then
        print("[FEHLER] Config.RewardItems fehlt oder ist leer!")
        return nil
    end

    -- Zufällig entscheiden: Item oder Waffe
    local rewardType = math.random(1, 2) == 1 and "item" or "weapon"
    local rewardList = (rewardType == "item") and Config.RewardItems.items or Config.RewardItems.weapons

    -- Falls die gewählte Liste leer ist → andere Liste nehmen
    if #rewardList == 0 then
        rewardType = (rewardType == "item") and "weapon" or "item"
        rewardList = (rewardType == "item") and Config.RewardItems.items or Config.RewardItems.weapons
    end

    -- Zufälliges Element aus der Liste wählen
    local reward = rewardList[math.random(1, #rewardList)]
    reward.type = rewardType
    return reward
end

-- Hauptbefehl: /daily
-- Spieler kann täglich eine Belohnung abholen
RegisterCommand("daily", function(source)
    if source == 0 then print("Dieser Befehl ist nur für Spieler!") return end

    -- Prüfen ob der Spieler aktuell im Cooldown-Lock ist
    if cooldownLock[source] then notify(source, "Bitte warte...") return end
    cooldownLock[source] = true

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cooldownLock[source] = nil return end

    local identifier = xPlayer.getIdentifier()
    MySQL.Async.fetchScalar("SELECT last_claim FROM daily_rewards WHERE identifier=@identifier", {['@identifier']=identifier}, function(lastClaim)
        local now = os.time()
        local cooldown = (Config.CooldownHours or 24) * 3600 -- Stunden in Sekunden umrechnen

        -- Prüfen ob Spieler Anspruch hat (entweder neu oder Cooldown abgelaufen)
        if not lastClaim or os.difftime(now, lastClaim) >= cooldown then
            local reward = getRandomReward()
            if not reward then 
                notify(source, "⚠️ Keine Belohnung verfügbar.") 
                cooldownLock[source] = nil 
                return 
            end

            -- Belohnung geben (Item oder Waffe)
            if reward.type == "item" then
                xPlayer.addInventoryItem(reward.name, reward.count or 1)
                notify(source, ("🎁 Du hast erhalten: %s x%d"):format(reward.name, reward.count or 1))
            else
                xPlayer.addWeapon(reward.name, reward.count or 30)
                notify(source, ("🎁 Du hast eine Waffe erhalten: %s"):format(reward.name))
            end

            -- Discord Log erstellen
            local rewardText = (reward.type == "item") 
                and ("Item: %s x%d"):format(reward.name, reward.count or 1) 
                or ("Waffe: %s"):format(reward.name)
            sendToDiscord("🎁 Daily Reward", ("%s hat erhalten: %s"):format(xPlayer.getName(), rewardText), 65280, Config.Webhooks.dailyReward)

            -- Neuen Zeitstempel in DB speichern
            MySQL.Async.execute("REPLACE INTO daily_rewards (identifier,last_claim) VALUES (@identifier,@time)", {
                ['@identifier']=identifier,
                ['@time']=now
            })

            notify(source, "✅ Du hast dein tägliches Geschenk erhalten!")
        else
            -- Zeit bis zur nächsten Belohnung berechnen
            local remaining = cooldown - os.difftime(now, lastClaim)
            notify(source, ("⏳ Bitte warte noch %d Stunden und %d Minuten."):format(math.floor(remaining/3600), math.floor((remaining%3600)/60)))
        end
        cooldownLock[source] = nil
    end)
end, false)

-- Admin Befehl: /resetdaily [id]
-- Setzt den Daily-Reward-Cooldown für einen Spieler zurück
RegisterCommand("resetdaily", function(source,args)
    if source ~= 0 and not IsPlayerAceAllowed(source,"command.resetdaily") then 
        notify(source,"❌ Keine Berechtigung.") 
        return 
    end

    local targetId = tonumber(args[1])
    if not targetId then notify(source,"❌ Ungültige Spieler-ID.") return end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then notify(source,"❌ Spieler nicht gefunden.") return end

    -- Cooldown aus der DB entfernen
    MySQL.Async.execute("DELETE FROM daily_rewards WHERE identifier=@identifier", {
        ['@identifier']=xTarget.getIdentifier()
    }, function()
        sendToDiscord("🔁 Daily Reset", ("%s hat %s zurückgesetzt."):format(
            source==0 and "CONSOLE" or GetPlayerName(source), xTarget.getName()), 16753920, Config.Webhooks.resetLog)
        notify(source,"✅ Cooldown zurückgesetzt.")
    end)
end)

    local timestamp = os.time() - (hoursAgo * 3600)

    MySQL.Async.execute("REPLACE INTO daily_rewards (identifier, last_claim) VALUES (@identifier, @time)", {
        ['@identifier'] = identifier,
        ['@time'] = timestamp
    }, function()
        local adminName = source == 0 and "CONSOLE" or GetPlayerName(source)
        local targetName = xTarget.getName()

        sendToDiscord("⏱️ Daily Cooldown gesetzt", ("%s hat den Cooldown für %s auf vor %d Stunden gesetzt."):format(adminName, targetName, hoursAgo), 16776960, Config.Webhooks.resetLog)
        notify(source, ("✅ Cooldown für %s wurde gesetzt."):format(targetName))
    end)
end)
