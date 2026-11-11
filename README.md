# Minecraft-Server auf ESXi-VM

Java Edition, Paper, Whitelist aktiv, tägliches Backup (7 Tage aufbewahrt).

## 1. VM in ESXi anlegen

| Einstellung | Wert |
|---|---|
| Gastbetriebssystem | Linux, Ubuntu (64-Bit) |
| vCPU | 2–4 |
| RAM | 6 GB (4 GB für Minecraft, Rest fürs System) |
| Disk | 30 GB, Thin Provisioning |
| Netzwerk | VM Network, Adapter VMXNET3 |
| CD/DVD | Ubuntu-Server-LTS-ISO aus dem Datastore |

## 2. Ubuntu installieren

- Im Schritt «Network configuration» fixe IP setzen (Edit IPv4 → Manual) oder auf DHCP lassen und im Router reservieren.
- «Install OpenSSH server» anhaken.
- Keine zusätzlichen Snaps auswählen (auch nicht Docker, das macht das Skript).

## 3. Dateien auf die VM kopieren und Skript starten

Vom PC aus (IP und Benutzer anpassen):

```bash
scp compose.yaml setup.sh benutzer@192.168.1.50:~
ssh benutzer@192.168.1.50
sudo bash setup.sh
```

Das Skript installiert Docker, legt alles unter `/opt/minecraft` an, erzeugt die `.env` mit einem zufälligen RCON-Passwort, öffnet Port 25565 in der Firewall und startet den Server.

## 4. Spieler eintragen

Die Whitelist ist aktiv, ohne Eintrag kommt niemand rein.

```bash
sudo nano /opt/minecraft/.env      # MC_WHITELIST=Name1,Name2 und MC_OPS=Name1
cd /opt/minecraft && sudo docker compose up -d
```

## 5. Zugriff von aussen

Im Router TCP-Port 25565 auf die IP der VM weiterleiten. Deine Kollegen verbinden sich dann mit deiner öffentlichen IP (oder einem DynDNS-Namen). ESXi-Verwaltung und SSH nicht weiterleiten.

## Nützliche Befehle

Alle in `/opt/minecraft` ausführen:

| Zweck | Befehl |
|---|---|
| Logs | `sudo docker compose logs -f mc` |
| Konsole | `sudo docker exec -i minecraft rcon-cli` |
| Neustart | `sudo docker compose restart mc` |
| Update | `sudo docker compose pull && sudo docker compose up -d` |
| Stoppen | `sudo docker compose down` |

## Daten

- Welt und Konfiguration: `/opt/minecraft/data`
- Backups: `/opt/minecraft/backups` (täglich, 7 Tage). Für echten Schutz zusätzlich auf ein anderes Gerät kopieren oder die VM mit Veeam sichern.
