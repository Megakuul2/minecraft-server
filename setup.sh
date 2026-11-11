#!/usr/bin/env bash
# Richtet den Minecraft-Server auf einer frischen Ubuntu- oder Debian-VM ein.
# Aufruf:  sudo bash setup.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Bitte mit sudo ausfuehren: sudo bash setup.sh" >&2
  exit 1
fi

SRC="$(cd "$(dirname "$0")" && pwd)"
DIR=/opt/minecraft

echo "==> System aktualisieren"
apt-get update -y
apt-get install -y curl ca-certificates openssl

echo "==> Docker installieren (falls noetig)"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker

echo "==> Verzeichnis $DIR anlegen"
mkdir -p "$DIR/data" "$DIR/backups"
cp "$SRC/compose.yaml" "$DIR/compose.yaml"

if [ ! -f "$DIR/.env" ]; then
  echo "==> .env mit zufaelligem RCON-Passwort erzeugen"
  cat > "$DIR/.env" <<EOF
# Spielernamen mit Komma trennen, z. B. MC_WHITELIST=Steve,Alex
MC_WHITELIST=
# Admins (duerfen Befehle ausfuehren)
MC_OPS=
MC_MEMORY=4G
MC_VERSION=LATEST
MC_MOTD=Minecraft Server
MC_DIFFICULTY=normal
MC_MAX_PLAYERS=10
RCON_PASSWORD=$(openssl rand -hex 16)
EOF
  chmod 600 "$DIR/.env"
else
  echo "==> .env existiert bereits, wird nicht ueberschrieben"
fi

if command -v ufw >/dev/null 2>&1; then
  echo "==> Firewall: SSH und Minecraft erlauben"
  ufw allow OpenSSH
  ufw allow 25565/tcp
  ufw --force enable
fi

echo "==> Server starten"
cd "$DIR"
docker compose pull
docker compose up -d

IP="$(hostname -I | awk '{print $1}')"
cat <<EOF

Fertig. Der Server startet jetzt (erster Start dauert ein paar Minuten).

  Adresse im LAN:   $IP:25565
  Logs ansehen:     cd $DIR && docker compose logs -f mc
  Spieler eintragen: $DIR/.env bearbeiten (MC_WHITELIST, MC_OPS),
                     danach: cd $DIR && docker compose up -d
EOF
