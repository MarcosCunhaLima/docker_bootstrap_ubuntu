# 🐳 docker_bootstrap_ubuntu

Script de bootstrap para preparar um Ubuntu (ou WSL2 com Ubuntu) com **Docker Engine**, **Docker Compose** e **Node.js LTS**.

Destinado a máquinas novas — instala dependências, habilita o serviço do Docker e coloca o usuário atual no grupo `docker`.

---

## 🚀 Uso rápido (última versão do branch `main`)

```bash
curl -fsSL https://raw.githubusercontent.com/<sua-org>/docker_bootstrap_ubuntu/main/bootstrap-ubuntu-docker.sh | bash
