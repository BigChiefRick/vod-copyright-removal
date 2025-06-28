#!/bin/bash
# Main system setup script

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log_info "Setting up VOD Copyright Removal Pipeline..."
log_info "Repository directory: $REPO_DIR"

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "Unknown")
PYTHON_VERSION=$(python3 --version 2>/dev/null | cut -d' ' -f2 | cut -d'.' -f1,2 || echo "Unknown")

log_info "Detected Ubuntu $UBUNTU_VERSION with Python $PYTHON_VERSION"

# Install system dependencies
log_info "Installing system packages..."
apt-get update
apt-get install -y \
    build-essential \
    python3 \
    python3-venv \
    python3-pip \
    python3-dev \
    git \
    ffmpeg \
    nginx \
    redis-server \
    curl \
    wget \
    libsndfile1 \
    libsndfile1-dev \
    pkg-config \
    lsb-release

# Create application user
log_info "Creating application user..."
if ! id -u vodprocessor >/dev/null 2>&1; then
    useradd -m -s /bin/bash vodprocessor
fi

# Create directory structure
log_info "Creating directories..."
mkdir -p /opt/vod-processor/{incoming,processing,processed,logs,config,downloads,archive}
mkdir -p /var/log/vod-processor

# Copy application files
log_info "Installing application files..."
cp "$REPO_DIR/src"/* /opt/vod-processor/
cp "$REPO_DIR/config"/*.yaml /opt/vod-processor/config/ 2>/dev/null || true
cp "$REPO_DIR/web"/* /var/www/html/

# Set up Python environment
log_info "Setting up Python environment..."
cd /opt/vod-processor
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
log_info "Installing Python packages (this may take a while)..."
pip install --upgrade pip setuptools wheel
pip install -r "$REPO_DIR/requirements.txt"

# Try to install Spleeter if Python < 3.12
if python -c "import sys; exit(0 if sys.version_info < (3, 12) else 1)" 2>/dev/null; then
    log_info "Installing Spleeter (Python < 3.12)..."
    pip install spleeter==2.1.0 tensorflow==2.15.0 || log_warn "Spleeter installation failed - will use Demucs only"
else
    log_warn "Python 3.12+ detected - Spleeter not compatible, using Demucs only"
fi

# Copy scripts
log_info "Installing utility scripts..."
cp "$REPO_DIR/scripts/monitor.sh" /opt/vod-processor/
cp "$REPO_DIR/scripts/test.sh" /opt/vod-processor/
chmod +x /opt/vod-processor/*.sh

# Set up services
log_info "Installing system services..."
cp "$REPO_DIR/config/systemd"/*.service /etc/systemd/system/
cp "$REPO_DIR/config/nginx/vod-processor" /etc/nginx/sites-available/

# Enable nginx site
ln -sf /etc/nginx/sites-available/vod-processor /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Create command shortcuts
log_info "Creating command shortcuts..."
cat > /usr/local/bin/vod-processor << 'EOFCMD'
#!/bin/bash
cd /opt/vod-processor && source venv/bin/activate && python vod_processor.py "$@"
EOFCMD

cat > /usr/local/bin/vod-monitor << 'EOFCMD'
#!/bin/bash
/opt/vod-processor/monitor.sh
EOFCMD

cat > /usr/local/bin/vod-test << 'EOFCMD'
#!/bin/bash
/opt/vod-processor/test.sh
EOFCMD

chmod +x /usr/local/bin/vod-*

# Set permissions
log_info "Setting permissions..."
chown -R vodprocessor:vodprocessor /opt/vod-processor
chown -R vodprocessor:vodprocessor /var/log/vod-processor
chown -R www-data:www-data /var/www/html

# Create log files
touch /var/log/vod-processor/{processor.log,processor.error.log,api.log,api.error.log}
chown vodprocessor:vodprocessor /var/log/vod-processor/*.log

# Start services
log_info "Starting services..."
systemctl daemon-reload
systemctl enable vod-processor vod-api nginx redis-server
systemctl restart redis-server nginx
systemctl start vod-processor vod-api

# Check services
sleep 3
systemctl is-active --quiet vod-processor && log_info "VOD Processor: Running" || log_warn "VOD Processor: Check logs"
systemctl is-active --quiet vod-api && log_info "API Server: Running" || log_warn "API Server: Check logs"

log_info "Setup complete!"
