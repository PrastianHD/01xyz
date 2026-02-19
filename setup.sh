#!/bin/bash

# Berhenti jika ada error
set -e

echo "🚀 Memulai instalasi dan konfigurasi otomatis..."

# 1. Update & Upgrade Sistem
echo "📦 Update dan upgrade apt..."
sudo apt update -y && sudo apt upgrade -y

# 2. Install Git (jika belum ada)
sudo apt install -y git

# 3. Install Docker & Docker Compose (jika belum ada)
if ! command -v docker &> /dev/null; then
    echo "🐳 Menginstal Docker..."
    sudo apt install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "✅ Docker sudah terinstal."
fi

# 4. Clone Repository
REPO_DIR="01xyz"
if [ ! -d "$REPO_DIR" ]; then
    echo "📥 Cloning repository..."
    git clone https://github.com/PrastianHD/01xyz.git
else
    echo "✅ Repository sudah ada, melewati proses clone."
fi

# Masuk ke direktori
cd $REPO_DIR

# 5. Setup .env
echo "⚙️ Setting up .env file..."
cp .env.example .env

# Minta input PRIVATE_KEY dari user
echo -n "🔑 Masukkan PRIVATE_KEY kamu: "
read -s PRIVATE_KEY
echo ""

# Masukkan PRIVATE_KEY ke dalam .env
if grep -q "^PRIVATE_KEY=" .env; then
    sed -i "s/^PRIVATE_KEY=.*/PRIVATE_KEY=$PRIVATE_KEY/" .env
else
    echo "PRIVATE_KEY=$PRIVATE_KEY" >> .env
fi

# 6. Run Docker Compose
echo "🚀 Build dan run Docker container..."
sudo docker compose up -d --build

# 7. Setup Crontab untuk auto-restart tiap 2 jam
echo "⏱️ Mengatur crontab auto-restart tiap 2 jam..."
CRON_JOB="0 */2 * * * cd $(pwd) && sudo docker compose restart"

# Hapus cron job lama untuk repo ini agar tidak duplikat, lalu tambahkan yang baru
(crontab -l 2>/dev/null | grep -v "cd $(pwd) && sudo docker compose restart" ; echo "$CRON_JOB") | crontab -

echo "🎉 Setup selesai! Container sudah berjalan."
echo "📜 Untuk melihat log, gunakan perintah: cd $(pwd) && sudo docker compose logs -f"
