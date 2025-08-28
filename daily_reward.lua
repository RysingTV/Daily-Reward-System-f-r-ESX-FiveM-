---------------------------------------
-- DAILY REWARD SYSTEM
-- Version: Optimized & Documented
-- Autor: RysingTV twitch.tv/RysingTV
---------------------------------------

-- Initialisiert Zufallsgenerator basierend auf Game-Timer (für nicht wiederholbare Seeds)
math.randomseed(GetGameTimer() + math.random(999999))

-- ESX Objekt laden (erforderlich für Spieler-Interaktionen)
ESX = exports["es_extended"]:getSharedObject()

-- Cooldown-Sperre pro Spieler während Datenbank-Operationen (verhindert Mehrfachausführung)
local cooldownLock = {}

---------------------------------------
-- Datenbank Setup
-- Erstellt Tabelle für Daily Rewards, falls sie nicht existiert
---------------------------------------
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS daily_rewards (
            identifier VARCHAR(60) PRIMARY KEY, -- Eindeutige Spielerkennung
            last_claim INT(11)                  -- Unix Timestamp des letzten Rewards
        )
    ]])
end)

---------------------------------------
-- Utility Funktion: Benachrichtigung
-- Schickt Nachricht an Spieler oder Konsole
---------------------------------------
local function notify(src, msg)
    if src ~= 0 then 
        TriggerClientEvent('esx:showNotification', src, msg)
    else 
        print(msg)
    end
end

---------------------------------------
-- Discord Logging
-- Sendet Informationen über Rewards oder Admin-Aktionen an einen Discord-Webhook
---------------------------------------
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

---------------------------------------
-- Funktion: Zufällige Belohnung wählen
-- Wählt zufällig Item oder Waffe aus der Config
---------------------------------------
local function getRandomReward()
    -- Prüfen ob die Config korrekt geladen wurde
    if not Config or not Config.RewardItems or not Config.RewardItems.items or not Config.RewardItems.weapons then
        print("[FEHLER] Config.RewardItems fehlt oder ist leer!")
        return nil
    end

    -- Zufällige Entscheidung: Item oder Waffe
    local rewardType = math.random(1, 2) == 1 and "item" or "weapon"
    local rewardList = (rewardType == "item") and Config.RewardItems.items or Config.RewardItems.weapons

    -- Falls gewählte Liste leer → andere Liste verwenden
    if #rewardList == 0 then
        rewardType = (rewardType == "item") and "weapon" or "item"
        rewardList = (rewardType == "item") and Config.RewardItems.items or Config.RewardItems.weapons
    end

    -- Zufällige Belohnung auswählen
    local reward = rewardList[math.random(1, #rewardList)]
    reward.type = rewardType
    return reward
end

---------------------------------------
-- Befehl: /daily
-- Spieler kann alle X Stunden (Config.CooldownHours) eine Belohnung abholen
---------------------------------------
RegisterCommand("daily", function(source)
    if source == 0 then print("Dieser Befehl ist nur für Spieler!") return end

    -- Cooldown-Schutz aktivieren
    if cooldownLock[source] then 
        notify(source, "⏳ Bitte warte, Anfrage läuft...")
        return 
    end
    cooldownLock[source] = true

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then 
        cooldownLock[source] = nil 
        return 
    end

    local identifier = xPlayer.getIdentifier()
    MySQL.Async.fetchScalar("SELECT last_claim FROM daily_rewards WHERE identifier=@identifier", {['@identifier']=identifier}, function(lastClaim)
        local now = os.time()
        local cooldown = (Config.CooldownHours or 24) * 3600 -- Stunden in Sekunden

        -- Prüfen ob Spieler Anspruch hat
        if not lastClaim or os.difftime(now, lastClaim) >= cooldown then
            local reward = getRandomReward()
            if not reward then 
                notify(source, "⚠️ Keine Belohnung verfügbar.")
                cooldownLock[source] = nil 
                return 
            end

            -- Belohnung vergeben
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

            -- Zeitstempel in DB speichern
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

---------------------------------------
-- Admin Befehl: /resetdaily [id]
-- Setzt den Cooldown für einen Spieler zurück
---------------------------------------
RegisterCommand("resetdaily", function(source,args)
    if source ~= 0 and not IsPlayerAceAllowed(source,"command.resetdaily") then 
        notify(source,"❌ Keine Berechtigung.") 
        return 
    end

    local targetId = tonumber(args[1])
    if not targetId then 
        notify(source,"❌ Ungültige Spieler-ID.") 
        return 
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then 
        notify(source,"❌ Spieler nicht gefunden.") 
        return 
    end

    -- Cooldown aus der DB löschen
    MySQL.Async.execute("DELETE FROM daily_rewards WHERE identifier=@identifier", {
        ['@identifier']=xTarget.getIdentifier()
    }, function()
        sendToDiscord("🔁 Daily Reset", ("%s hat %s zurückgesetzt."):format(
            source==0 and "CONSOLE" or GetPlayerName(source), xTarget.getName()), 16753920, Config.Webhooks.resetLog)
        notify(source,"✅ Cooldown zurückgesetzt.")
    end)
end)

---------------------------------------
-- Admin Befehl: /setdaily [id] [stunden]
-- Setzt den Cooldown für einen Spieler auf eine bestimmte Zeit in der Vergangenheit
---------------------------------------
RegisterCommand("setdaily", function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, "command.setdaily") then
        notify(source, "❌ Keine Berechtigung.")
        return
    end

    local targetId = tonumber(args[1])
    local hoursAgo = tonumber(args[2])
    if not targetId or not hoursAgo then
        notify(source, "❌ Nutzung: /setdaily [Spieler-ID] [Stunden]")
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        notify(source, "❌ Spieler nicht gefunden.")
        return
    end

    local identifier = xTarget.getIdentifier()
    local timestamp = os.time() - (hoursAgo * 3600)

    -- Cooldown in der DB hinzufügen
    MySQL.Async.execute("REPLACE INTO daily_rewards (identifier, last_claim) VALUES (@identifier, @time)", {
        ['@identifier'] = identifier,
        ['@time'] = timestamp
    }, function()
        sendToDiscord("⏱️ Daily Cooldown gesetzt", ("%s hat den Cooldown für %s auf vor %d Stunden gesetzt."):format(
            source == 0 and "CONSOLE" or GetPlayerName(source), xTarget.getName(), hoursAgo), 16776960, Config.Webhooks.resetLog)
        notify(source, ("✅ Cooldown für %s wurde gesetzt."):format(xTarget.getName()))
    end)
end)
