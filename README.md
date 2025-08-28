📦 Daily Reward System für ESX (FiveM)
Ein einfaches, konfigurierbares Belohnungssystem für ESX-basierte FiveM-Server. Spieler können einmal alle 24 Stunden ein zufälliges Item oder eine Waffe erhalten. Die Belohnungen werden in einer MySQL-Datenbank gespeichert, und Aktionen werden optional per Discord Webhook geloggt.

✨ Funktionen
Tägliche Belohnung via /daily
Zufällige Auswahl aus Items und Waffen
Gewichtung für häufige und seltene Belohnungen
Speicherung in MySQL (daily_rewards)
Discord Logging für Belohnungen und Admin-Aktionen
Admin-Befehle zum Zurücksetzen und Setzen von Cooldowns

📂 Dateien
daily_reward.lua – Hauptscript mit Logik und Befehlen
config.lua – Konfiguration der Belohnungen, Webhooks und Cooldown
fxmanifest.lua – Manifest zur Einbindung ins FiveM-Resource-System

⚙️ Installation
Dateien hinzufügen
Lege daily_reward.lua, config.lua und fxmanifest.lua in ein neues Verzeichnis, z. B. resources/[local]/daily_bonus.

Datenbank vorbereiten
Das Script erstellt automatisch die Tabelle daily_rewards, wenn sie nicht existiert.

Webhook konfigurieren
Trage deine Discord Webhooks in config.lua ein:


Belohnungen definieren
Passe die Items und Waffen in config.lua an. Beispiel:


fxmanifest.lua eintragen Stelle sicher, dass config.lua vor daily_reward.lua geladen wird:


Berechtigungen setzen (optional)
Für den Admin-Befehl /resetdaily muss der Spieler die ACE-Berechtigung command.resetdaily besitzen.

🛠️ Befehle
Befehl	                    Beschreibung
/daily	                    Fordert die tägliche Belohnung an
/resetdaily [id]	        Setzt den Cooldown für einen Spieler zurück (Admin)
/setdaily [id] [stunden]	Setzt den Cooldown manuell auf eine Zeit in der Vergangenheit (Admin)


🧠 Hinweise
Die Belohnungsauswahl berücksichtigt die Gewichtung (weight) – je höher, desto wahrscheinlicher.
Waffen erhalten standardmäßig 30 Munition, falls count nicht gesetzt ist.
Das Script ist kompatibel mit es_extended und oxmysql.

🔒 ACE-Berechtigungen
Füge folgende Zeilen in deine server.cfg ein, um Admins Zugriff auf die Befehle zu geben:

    add_ace group.admin command.resetdaily allow
    add_ace group.admin command.setdaily allow
