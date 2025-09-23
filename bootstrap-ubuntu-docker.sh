#!/usr/bin/env bash
# bootstrap-ubuntu-docker.sh
set -Eeuo pipefail

LOGFILE="/var/log/bootstrap-docker.log"
exec > >(sudo tee -a "$LOGFILE") 2>&1

ts() { date +"%Y-%m-%d %H:%M:%S"; }
log() { echo "[$(ts)] [INFO] $*"; }
warn() { echo "[$(ts)] [WARN] $*" >&2; }
err() {
  echo "[$(ts)] [ERR ] Linha ${BASH_LINENO[0]}: comando '${BASH_COMMAND}' falhou."
  exit 1
}
trap err ERR

run() {
  log "executando: $*"
  eval "$@"
}

log "Iniciando bootstrap. Logs em: $LOGFILE"
export DEBIAN_FRONTEND=noninteractive

# Aviso para WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
  warn "WSL detectado. Habilite systemd em /etc/wsl.conf e reinicie a distro caso use Docker Engine."
fi

# 1) Atualizações
run "sudo apt-get update -y"
run "sudo apt-get upgrade -y"

# 2) Pré-requisitos gerais
run "sudo apt-get install -y ca-certificates curl gnupg lsb-release git"

# 3) Node.js LTS (20.x) via NodeSource
# remove Node do repositório padrão se existir
if dpkg -s nodejs >/dev/null 2>&1; then
  log "Removendo nodejs do repo padrão (se instalado) para evitar conflito..."
  run "sudo apt-get remove -y nodejs || true"
fi
run "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
run "sudo apt-get install -y nodejs"
run "sudo apt-get install -y jq" # necessario para instalacao automatica depois
run "node -v && npm -v"

# 4) Repositório oficial do Docker
run "sudo install -m 0755 -d /etc/apt/keyrings"
#if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
run "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg"
#else
#  log "docker.gpg já existe, seguindo."
#fi
run "sudo chmod a+r /etc/apt/keyrings/docker.gpg"
run "echo \
'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' \
| sudo tee /etc/apt/sources.list.d/docker.list >/dev/null"

run "sudo apt-get update -y"

# 5) Docker Engine + CLI + containerd + buildx + compose
run 'sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin'

# 6) Habilitar e iniciar serviço do Docker (se systemd disponível)
if command -v systemctl >/dev/null 2>&1; then
  run "sudo systemctl enable --now docker"
  run "sudo systemctl start docker"
else
  warn "systemctl não encontrado; tentando iniciar via 'service docker start'"
  run "sudo service docker start || true"
fi

# 7) Permitir uso do docker sem sudo
if groups "$USER" | grep -q '\bdocker\b'; then
  log "Usuário '$USER' já está no grupo docker."
else
  run "sudo usermod -aG docker $USER"
  run "newgrp docker"
  #warn "Saia e entre novamente na sessão (ou 'newgrp docker') para aplicar o grupo 'docker'."
fi

#8) Smoke tests
if command -v docker >/dev/null 2>&1; then
  run "docker version || true"
  run "docker info | head -n 20 || true"
else
  warn "'docker' não está no PATH desta sessão. Após relogar, execute: 'docker version'."
fi

# log "Bootstrap finalizado com sucesso. Logs: $LOGFILE"
