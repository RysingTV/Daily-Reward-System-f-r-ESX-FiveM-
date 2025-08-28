📦 Daily Reward System für ESX (FiveM)
Ein einfaches, konfigurierbares Belohnungssystem für ESX-basierte FiveM-Server. Spieler können einmal alle 24 Stunden ein zufälliges Item oder eine Waffe erhalten. Die Belohnungen werden in einer MySQL-Datenbank gespeichert, und Aktionen werden optional per Discord Webhook geloggt.

🔧 Funktionen
🎁 Zufällige tägliche Belohnung (Item oder Waffe)
⏳ Cooldown-System (standardmäßig 24 Stunden)
📦 Gewichtung der Belohnungen (häufige vs. seltene Items/Waffen)
📊 Speicherung in MySQL (daily_rewards)
📢 Discord Logging für Belohnungen und Resets
🔒 Admin-Befehl zum Zurücksetzen des Cooldowns
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

📜 Befehle
Befehl	Beschreibung
/daily	Fordert die tägliche Belohnung an
/resetdaily [id]	Setzt den Cooldown für einen Spieler zurück (Admin)
🧠 Hinweise
Die Belohnungsauswahl berücksichtigt die Gewichtung (weight) – je höher, desto wahrscheinlicher.
Waffen erhalten standardmäßig 30 Munition, falls count nicht gesetzt ist.
Das Script ist kompatibel mit es_extended und oxmysql.
