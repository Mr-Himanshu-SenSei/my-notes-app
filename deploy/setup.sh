#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  Notes App — EC2 Server Setup Script
#  Run this on a fresh Ubuntu 22.04 / 24.04 EC2 instance
#  Usage:  chmod +x setup.sh && sudo ./setup.sh
# ══════════════════════════════════════════════════════════════
set -euo pipefail

APP_DIR="/home/ubuntu/my-notes-app"
APP_USER="ubuntu"
DB_NAME="notesdb"
DB_USER="notesuser"
DB_PASS="CHANGE_ME_TO_A_STRONG_PASSWORD"

echo "══════════════════════════════════════════════════"
echo "  1. Updating system packages"
echo "══════════════════════════════════════════════════"
apt update && apt upgrade -y

echo "══════════════════════════════════════════════════"
echo "  2. Installing Python, PostgreSQL, Nginx, Git"
echo "══════════════════════════════════════════════════"
apt install -y python3 python3-pip python3-venv \
    postgresql postgresql-contrib \
    nginx git curl

echo "══════════════════════════════════════════════════"
echo "  3. Setting up PostgreSQL"
echo "══════════════════════════════════════════════════"
systemctl enable postgresql
systemctl start postgresql

# Create database user and database
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_catalog.pg_database WHERE datname='${DB_NAME}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"

echo "══════════════════════════════════════════════════"
echo "  4. Cloning the repository"
echo "══════════════════════════════════════════════════"
if [ -d "$APP_DIR" ]; then
    echo "Directory exists. Pulling latest changes..."
    cd "$APP_DIR" && sudo -u "$APP_USER" git pull
else
    sudo -u "$APP_USER" git clone https://github.com/Mr-Himanshu-SenSei/my-notes-app.git "$APP_DIR"
fi

echo "══════════════════════════════════════════════════"
echo "  5. Setting up Python virtual environment"
echo "══════════════════════════════════════════════════"
cd "$APP_DIR"
sudo -u "$APP_USER" python3 -m venv venv
sudo -u "$APP_USER" ./venv/bin/pip install --upgrade pip
sudo -u "$APP_USER" ./venv/bin/pip install -r requirements.txt

echo "══════════════════════════════════════════════════"
echo "  6. Creating .env file"
echo "══════════════════════════════════════════════════"
SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")
cat > "$APP_DIR/.env" << EOF
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}
SECRET_KEY=${SECRET}
ACCESS_TOKEN_EXPIRE_MINUTES=60
EOF
chown "$APP_USER:$APP_USER" "$APP_DIR/.env"
chmod 600 "$APP_DIR/.env"

echo "══════════════════════════════════════════════════"
echo "  7. Setting up log directory"
echo "══════════════════════════════════════════════════"
mkdir -p /var/log/notesapp
chown "$APP_USER:$APP_USER" /var/log/notesapp

echo "══════════════════════════════════════════════════"
echo "  8. Installing systemd service"
echo "══════════════════════════════════════════════════"
cp "$APP_DIR/deploy/notesapp.service" /etc/systemd/system/notesapp.service
systemctl daemon-reload
systemctl enable notesapp
systemctl start notesapp

echo "══════════════════════════════════════════════════"
echo "  9. Configuring Nginx"
echo "══════════════════════════════════════════════════"
cp "$APP_DIR/deploy/nginx.conf" /etc/nginx/sites-available/notesapp
ln -sf /etc/nginx/sites-available/notesapp /etc/nginx/sites-enabled/notesapp
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
systemctl enable nginx

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✅  SETUP COMPLETE!"
echo "══════════════════════════════════════════════════"
echo ""
echo "  App running at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo '<YOUR-EC2-PUBLIC-IP>')"
echo ""
echo "  Useful commands:"
echo "    sudo systemctl status notesapp    # Check app status"
echo "    sudo systemctl restart notesapp   # Restart app"
echo "    sudo journalctl -u notesapp -f    # View live logs"
echo "    tail -f /var/log/notesapp/*.log   # View app logs"
echo ""
echo "  ⚠️  IMPORTANT: Change DB_PASS in this script before running!"
echo "  ⚠️  IMPORTANT: Update server_name in /etc/nginx/sites-available/notesapp"
echo "     with your domain name once you have one."
echo ""
