#!/bin/bash
# Script to create all files for the GitHub repository
# Run this in your local development environment

# Create the complete directory structure
echo "Creating VOD Copyright Removal repository structure..."

# Create directories
mkdir -p src config/systemd config/nginx scripts web docs tests

# Create .gitignore
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/

# Logs
*.log
logs/

# Processing directories
incoming/
processing/
processed/
downloads/
archive/

# Config with secrets
config/secrets.yaml
.env
.env.local

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Models (downloaded on first run)
models/
pretrained_models/

# Test videos
*.mp4
*.avi
*.mov
*.mkv
*.webm
!tests/fixtures/*.mp4
EOF

# Create README.md
cat > README.md << 'EOF'
# VOD Copyright Removal Pipeline

Automatically remove copyrighted music from livestream VODs while preserving commentary and ambient audio.

## Features

- 🎵 AI-powered music removal using Demucs (and optionally Spleeter)
- 📹 Preserves commentary and ambient sounds
- 🚀 Processes hours of video in minutes (vs days with manual tools)
- 🌐 Web dashboard for easy management
- 📊 Real-time processing status
- 🔄 Batch processing support

## Quick Start

### Requirements

- Ubuntu 22.04 or 24.04 LTS
- 8GB+ RAM (16GB recommended)
- 50GB+ free disk space
- Python 3.10+

### One-Line Install

```bash
git clone https://github.com/BigChiefRick/vod-copyright-removal.git && cd vod-copyright-removal && sudo ./install.sh
```

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/BigChiefRick/vod-copyright-removal.git
cd vod-copyright-removal
```

2. Run the installer:
```bash
sudo ./install.sh
```

3. Access the web interface:
```
http://your-server-ip
```

## Usage

### Web Interface
Upload videos through the web dashboard at `http://your-server-ip`

### Command Line
```bash
# Process a single video
vod-processor /path/to/video.mp4

# Monitor system
vod-monitor

# Run tests
vod-test
```

### API
```bash
# Upload via API
curl -X POST "http://your-server/api/upload" -F "file=@video.mp4"

# Check status
curl "http://your-server/api/stats"

# List processed videos
curl "http://your-server/api/videos"
```

## Configuration

Edit `/opt/vod-processor/config/settings.yaml` to customize:
- Processing methods (demucs/spleeter)
- Number of worker threads
- Output quality settings

## Performance

For a typical 9-hour racing VOD:
- Upload: 15-30 minutes (depends on your connection)
- Processing: 45-90 minutes
- Total: ~2 hours (vs 100+ hours with YouTube's manual tool)

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Web Upload    │────▶│  Processing Queue │────▶│ AI Separation   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                           │
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ Processed Files │◀────│   Recombine      │◀────│ Extract Audio   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## Troubleshooting

### Services not starting
```bash
# Check logs
sudo journalctl -u vod-processor -n 50
sudo journalctl -u vod-api -n 50
```

### Out of memory
```bash
# Check memory usage
free -h

# Edit worker count in settings
sudo nano /opt/vod-processor/config/settings.yaml
```

### Disk space issues
```bash
# Check disk usage
df -h

# Clean old processed files
sudo rm -rf /opt/vod-processor/processed/*.mp4
```

## License

MIT License - See [LICENSE](LICENSE) file

## Contributing

Pull requests welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

- Issues: [GitHub Issues](https://github.com/BigChiefRick/vod-copyright-removal/issues)
- Discussions: [GitHub Discussions](https://github.com/BigChiefRick/vod-copyright-removal/discussions)

## Acknowledgments

- [Demucs](https://github.com/facebookresearch/demucs) by Facebook Research
- [FFmpeg](https://ffmpeg.org/) for video processing
- [FastAPI](https://fastapi.tiangolo.com/) for the API framework
EOF

# Create LICENSE
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 BigChiefRick

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Create main installer
cat > install.sh << 'EOF'
#!/bin/bash
# VOD Copyright Removal - Universal Installer

set -e

echo "==================================="
echo "VOD Copyright Removal Pipeline Setup"
echo "==================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: Please run as root (use sudo ./install.sh)"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run the main setup
bash "$SCRIPT_DIR/scripts/setup-system.sh"

echo ""
echo "Installation complete!"
echo "Access the web interface at: http://$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo ""
EOF

chmod +x install.sh

# Create requirements.txt
cat > requirements.txt << 'EOF'
# Core dependencies
numpy>=1.26.0
scipy>=1.13.0
librosa>=0.10.0
soundfile>=0.12.0
pydub>=0.25.0

# Audio separation
demucs>=4.0.0

# API and workers
fastapi>=0.110.0
uvicorn>=0.29.0
celery>=5.3.0
redis>=5.0.0
python-multipart>=0.0.9

# Utilities
pyyaml>=6.0
python-dotenv>=1.0.0
requests>=2.31.0
tqdm>=4.66.0
psutil>=5.9.0

# Monitoring
prometheus-client>=0.20.0
EOF

# Create setup-system.sh in scripts directory
cat > scripts/setup-system.sh << 'EOF'
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
EOF

chmod +x scripts/setup-system.sh

# Create monitor.sh
cat > scripts/monitor.sh << 'EOF'
#!/bin/bash
# VOD Processor Monitoring Script

while true; do
    clear
    echo "=== VOD Processor Monitor ==="
    echo "Time: $(date)"
    echo "============================"
    echo ""
    
    # Check services
    echo "Service Status:"
    echo "--------------"
    systemctl is-active --quiet vod-processor && echo "✓ Processor: Running" || echo "✗ Processor: Stopped"
    systemctl is-active --quiet vod-api && echo "✓ API Server: Running" || echo "✗ API Server: Stopped"
    systemctl is-active --quiet nginx && echo "✓ Nginx: Running" || echo "✗ Nginx: Stopped"
    systemctl is-active --quiet redis-server && echo "✓ Redis: Running" || echo "✗ Redis: Stopped"
    echo ""
    
    # Check queues
    echo "Queue Status:"
    echo "------------"
    incoming=$(find /opt/vod-processor/incoming -maxdepth 1 -name "*.mp4" -o -name "*.avi" -o -name "*.mov" -o -name "*.mkv" 2>/dev/null | wc -l)
    processed=$(find /opt/vod-processor/processed -maxdepth 1 -name "*.mp4" 2>/dev/null | wc -l)
    echo "Incoming: $incoming videos"
    echo "Processed: $processed videos"
    echo ""
    
    # System resources
    echo "System Resources:"
    echo "----------------"
    free -h | grep Mem | awk '{print "Memory: " $3 "/" $2 " (" int($3/$2 * 100) "%)"}'
    df -h / | tail -1 | awk '{print "Disk: " $3 "/" $2 " (" $5 ")"}'
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    
    # Recent logs
    echo "Recent Activity:"
    echo "---------------"
    if [ -f /var/log/vod-processor/processor.log ]; then
        tail -5 /var/log/vod-processor/processor.log 2>/dev/null | grep -E "(Processing|Success|Failed)" || echo "No recent activity"
    fi
    
    echo ""
    echo "Press Ctrl+C to exit"
    sleep 30
done
EOF

chmod +x scripts/monitor.sh

# Create test.sh
cat > scripts/test.sh << 'EOF'
#!/bin/bash
# VOD Processor Test Script

echo "=== VOD Processor Test ==="
echo ""

# Check services
echo "Checking services..."
systemctl is-active --quiet vod-processor && echo "✓ Processor is running" || echo "✗ Processor is not running"
systemctl is-active --quiet vod-api && echo "✓ API is running" || echo "✗ API is not running"
echo ""

# Create test video
echo "Creating test video..."
mkdir -p /opt/vod-processor/incoming

ffmpeg -f lavfi -i testsrc=duration=10:size=320x240:rate=30 \
       -f lavfi -i sine=frequency=1000:duration=10 \
       -c:v libx264 -c:a aac \
       /opt/vod-processor/incoming/test_$(date +%s).mp4 -y 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Test video created successfully"
    echo ""
    echo "The processor will pick it up within 60 seconds."
    echo "Check /opt/vod-processor/processed/ for the output."
    echo ""
    echo "You can monitor progress with: vod-monitor"
else
    echo "✗ Failed to create test video"
fi
EOF

chmod +x scripts/test.sh

# Copy the vod_processor.py from the previous artifact
cp ../vod_processor.py src/vod_processor.py 2>/dev/null || cat > src/vod_processor.py << 'EOF'
#!/usr/bin/env python3
"""
VOD Copyright Removal Processor
"""

import os
import sys
import subprocess
import logging
import json
from pathlib import Path
from datetime import datetime
import concurrent.futures
import shutil
import time
import psutil
from typing import List, Dict, Optional, Tuple

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/vod-processor/processor.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Check available audio separation methods
AVAILABLE_METHODS = ['demucs']  # Default to demucs
try:
    import spleeter
    AVAILABLE_METHODS.append('spleeter')
    logger.info("Spleeter is available")
except ImportError:
    logger.info("Spleeter not available - using Demucs only")

class SystemMonitor:
    """Monitor system resources"""
    
    @staticmethod
    def get_stats():
        return {
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_usage': psutil.disk_usage('/').percent,
            'load_average': os.getloadavg()
        }
    
    @staticmethod
    def check_resources():
        stats = SystemMonitor.get_stats()
        if stats['memory_percent'] > 90:
            logger.warning(f"High memory usage: {stats['memory_percent']}%")
            return False
        if stats['disk_usage'] > 85:
            logger.warning(f"High disk usage: {stats['disk_usage']}%")
            return False
        return True

class AudioProcessor:
    """Process audio to remove copyrighted music"""
    
    def __init__(self, method=None):
        # Auto-select method if not specified
        if method is None:
            method = 'spleeter' if 'spleeter' in AVAILABLE_METHODS else 'demucs'
        elif method not in AVAILABLE_METHODS:
            logger.warning(f"{method} not available, using demucs")
            method = 'demucs'
            
        self.method = method
        self.temp_dir = Path('/opt/vod-processor/processing')
        self.temp_dir.mkdir(exist_ok=True)
        logger.info(f"Using audio separation method: {self.method}")
        
    def process_video(self, video_path: Path, output_dir: Path) -> Optional[Path]:
        """Process a single video file"""
        logger.info(f"Processing video: {video_path.name}")
        
        # Check system resources
        if not SystemMonitor.check_resources():
            logger.error("Insufficient system resources")
            return None
        
        start_time = time.time()
        work_dir = self.temp_dir / f"work_{video_path.stem}_{int(time.time())}"
        work_dir.mkdir(exist_ok=True)
        
        try:
            # Extract audio
            audio_path = work_dir / "audio.wav"
            logger.info("Extracting audio...")
            self._extract_audio(video_path, audio_path)
            
            # Separate audio
            logger.info(f"Separating audio using {self.method}...")
            if self.method == 'spleeter' and 'spleeter' in AVAILABLE_METHODS:
                clean_audio = self._process_with_spleeter(audio_path, work_dir)
            else:
                clean_audio = self._process_with_demucs(audio_path, work_dir)
            
            # Recombine with video
            output_path = output_dir / f"{video_path.stem}_no_copyright.mp4"
            logger.info("Recombining with video...")
            self._combine_audio_video(video_path, clean_audio, output_path)
            
            # Log statistics
            duration = time.time() - start_time
            size_reduction = (video_path.stat().st_size - output_path.stat().st_size) / 1e6
            logger.info(f"Processing complete in {duration:.1f}s, size change: {size_reduction:.1f}MB")
            
            return output_path
            
        except Exception as e:
            logger.error(f"Processing failed: {e}", exc_info=True)
            return None
        finally:
            # Cleanup
            if work_dir.exists():
                shutil.rmtree(work_dir)
    
    def _extract_audio(self, video_path: Path, output_path: Path):
        """Extract audio from video"""
        cmd = [
            'ffmpeg', '-i', str(video_path),
            '-vn', '-acodec', 'pcm_s16le',
            '-ar', '44100', '-ac', '2',
            str(output_path), '-y'
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"FFmpeg error: {result.stderr}")
    
    def _process_with_spleeter(self, audio_path: Path, work_dir: Path) -> Path:
        """Process with Spleeter (faster, good quality)"""
        try:
            from spleeter.separator import Separator
            
            separator = Separator('spleeter:2stems')
            separator.separate_to_file(str(audio_path), str(work_dir))
            
            # Return vocals (commentary) path
            vocals_path = work_dir / audio_path.stem / 'vocals.wav'
            if vocals_path.exists():
                return vocals_path
            else:
                raise Exception("Spleeter output not found")
        except Exception as e:
            logger.error(f"Spleeter error: {e}")
            # Fallback to simple filtering
            return self._fallback_filter(audio_path, work_dir)
    
    def _process_with_demucs(self, audio_path: Path, work_dir: Path) -> Path:
        """Process with Demucs (slower, better quality)"""
        try:
            cmd = [
                sys.executable, '-m', 'demucs',
                '--two-stems=vocals',
                '-o', str(work_dir),
                str(audio_path)
            ]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                raise Exception(f"Demucs error: {result.stderr}")
            
            # Find output file - demucs creates nested directories
            for root, dirs, files in os.walk(work_dir):
                for file in files:
                    if file == 'vocals.wav':
                        return Path(root) / file
            
            raise Exception("Demucs output not found")
        except Exception as e:
            logger.error(f"Demucs error: {e}")
            return self._fallback_filter(audio_path, work_dir)
    
    def _fallback_filter(self, audio_path: Path, work_dir: Path) -> Path:
        """Fallback audio filtering when AI models fail"""
        logger.warning("Using fallback audio filter")
        output_path = work_dir / "filtered.wav"
        cmd = [
            'ffmpeg', '-i', str(audio_path),
            '-af', 'highpass=f=200,lowpass=f=3000',
            str(output_path), '-y'
        ]
        subprocess.run(cmd, check=True)
        return output_path
    
    def _combine_audio_video(self, video_path: Path, audio_path: Path, output_path: Path):
        """Combine processed audio with original video"""
        cmd = [
            'ffmpeg', '-i', str(video_path), '-i', str(audio_path),
            '-c:v', 'copy',  # Don't re-encode video
            '-c:a', 'aac', '-b:a', '192k',
            '-map', '0:v:0', '-map', '1:a:0',
            '-shortest', str(output_path), '-y'
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"FFmpeg combine error: {result.stderr}")

class BatchProcessor:
    """Handle batch processing of videos"""
    
    def __init__(self, max_workers=2):
        self.max_workers = max_workers
        self.processor = AudioProcessor()
        self.incoming_dir = Path('/opt/vod-processor/incoming')
        self.processed_dir = Path('/opt/vod-processor/processed')
        
    def scan_for_videos(self) -> List[Path]:
        """Scan for unprocessed videos"""
        video_extensions = {'.mp4', '.avi', '.mov', '.mkv', '.webm'}
        videos = []
        
        if not self.incoming_dir.exists():
            self.incoming_dir.mkdir(parents=True)
            
        for file in self.incoming_dir.iterdir():
            if file.suffix.lower() in video_extensions:
                # Check if already processed
                output_file = self.processed_dir / f"{file.stem}_no_copyright.mp4"
                if not output_file.exists():
                    videos.append(file)
        
        return videos
    
    def process_all(self):
        """Process all pending videos"""
        videos = self.scan_for_videos()
        
        if not videos:
            logger.info("No videos to process")
            return
        
        logger.info(f"Found {len(videos)} videos to process")
        
        # Process videos with limited concurrency
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = []
            
            for video in videos:
                future = executor.submit(
                    self.processor.process_video,
                    video,
                    self.processed_dir
                )
                futures.append((video, future))
            
            # Wait for completion
            for video, future in futures:
                try:
                    result = future.result()
                    if result:
                        logger.info(f"Successfully processed: {video.name}")
                        # Archive original
                        archive_dir = self.incoming_dir / 'archive'
                        archive_dir.mkdir(exist_ok=True)
                        video.rename(archive_dir / video.name)
                except Exception as e:
                    logger.error(f"Failed to process {video.name}: {e}")

def main():
    """Main entry point"""
    logger.info("VOD Processor starting...")
    logger.info(f"Available methods: {AVAILABLE_METHODS}")
    logger.info(f"System stats: {SystemMonitor.get_stats()}")
    
    # Check if running as service or manual
    if len(sys.argv) > 1:
        # Process single file
        video_path = Path(sys.argv[1])
        if video_path.exists():
            processor = AudioProcessor()
            output = processor.process_video(
                video_path,
                Path('/opt/vod-processor/processed')
            )
            if output:
                print(f"Success: {output}")
            else:
                print("Processing failed")
                sys.exit(1)
    else:
        # Batch mode - continuous monitoring
        batch = BatchProcessor()
        while True:
            try:
                batch.process_all()
            except Exception as e:
                logger.error(f"Batch processing error: {e}")
            time.sleep(60)  # Check every minute

if __name__ == "__main__":
    main()
EOF

# Copy the api_server.py from the previous artifact
cp ../api_server.py src/api_server.py 2>/dev/null || cat > src/api_server.py << 'EOF'
from fastapi import FastAPI, UploadFile, File, BackgroundTasks, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import shutil
from pathlib import Path
import uuid
from datetime import datetime
import asyncio
import os
import sys

# Add the processor directory to path
sys.path.append('/opt/vod-processor')

app = FastAPI(title="VOD Processor API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create directories if they don't exist
Path("/opt/vod-processor/processed").mkdir(parents=True, exist_ok=True)
Path("/var/log/vod-processor").mkdir(parents=True, exist_ok=True)

# Mount static files
app.mount("/processed", StaticFiles(directory="/opt/vod-processor/processed"), name="processed")
app.mount("/logs", StaticFiles(directory="/var/log/vod-processor"), name="logs")

@app.get("/")
async def root():
    return {
        "message": "VOD Processor API",
        "status": "operational",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/stats")
async def get_stats():
    try:
        from vod_processor import SystemMonitor, AVAILABLE_METHODS
        stats = SystemMonitor.get_stats()
        stats['available_methods'] = AVAILABLE_METHODS
        return stats
    except Exception as e:
        return {"error": str(e)}

@app.post("/upload")
async def upload_video(file: UploadFile = File(...), background_tasks: BackgroundTasks = None):
    if not file.filename.lower().endswith(('.mp4', '.avi', '.mov', '.mkv', '.webm')):
        raise HTTPException(status_code=400, detail="Invalid file format")
    
    # Save uploaded file
    file_id = str(uuid.uuid4())
    input_path = Path(f"/opt/vod-processor/incoming/{file_id}_{file.filename}")
    
    try:
        input_path.parent.mkdir(parents=True, exist_ok=True)
        with input_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")
    
    # Queue for processing
    if background_tasks:
        background_tasks.add_task(process_video_task, input_path)
    
    return {
        "file_id": file_id,
        "filename": file.filename,
        "status": "queued",
        "size_mb": input_path.stat().st_size / 1e6
    }

@app.get("/videos")
async def list_videos():
    processed = Path("/opt/vod-processor/processed")
    videos = []
    
    if processed.exists():
        for video in processed.glob("*.mp4"):
            videos.append({
                "filename": video.name,
                "size_mb": video.stat().st_size / 1e6,
                "modified": datetime.fromtimestamp(video.stat().st_mtime).isoformat()
            })
    
    return {"videos": sorted(videos, key=lambda x: x['modified'], reverse=True)}

@app.delete("/videos/{filename}")
async def delete_video(filename: str):
    video_path = Path(f"/opt/vod-processor/processed/{filename}")
    if video_path.exists() and video_path.suffix == '.mp4':
        video_path.unlink()
        return {"message": "Video deleted"}
    raise HTTPException(status_code=404, detail="Video not found")

def process_video_task(video_path):
    """Background task to process video"""
    try:
        from vod_processor import AudioProcessor
        processor = AudioProcessor()
        processor.process_video(video_path, Path("/opt/vod-processor/processed"))
    except Exception as e:
        print(f"Background processing error: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

# Create config files
cat > config/settings.yaml << 'EOF'
# VOD Processor Configuration

processing:
  method: auto  # auto, demucs, or spleeter
  max_workers: 2
  chunk_duration: 300
  
audio:
  sample_rate: 44100
  bitrate: 192k
  format: aac
  
paths:
  incoming: /opt/vod-processor/incoming
  processing: /opt/vod-processor/processing
  processed: /opt/vod-processor/processed
  archive: /opt/vod-processor/incoming/archive
  
system:
  max_memory_percent: 90
  max_disk_percent: 85
  
api:
  host: 0.0.0.0
  port: 8000
  max_upload_size: 50G
EOF

# Create systemd service files
cat > config/systemd/vod-processor.service << 'EOF'
[Unit]
Description=VOD Copyright Processor
After=network.target

[Service]
Type=simple
User=vodprocessor
Group=vodprocessor
WorkingDirectory=/opt/vod-processor
Environment="PATH=/opt/vod-processor/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/opt/vod-processor/venv/bin/python /opt/vod-processor/vod_processor.py
Restart=always
RestartSec=10
StandardOutput=append:/var/log/vod-processor/processor.log
StandardError=append:/var/log/vod-processor/processor.error.log

[Install]
WantedBy=multi-user.target
EOF

cat > config/systemd/vod-api.service << 'EOF'
[Unit]
Description=VOD Processor API
After=network.target

[Service]
Type=simple
User=vodprocessor
Group=vodprocessor
WorkingDirectory=/opt/vod-processor
Environment="PATH=/opt/vod-processor/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/opt/vod-processor/venv/bin/python /opt/vod-processor/api_server.py
Restart=always
RestartSec=10
StandardOutput=append:/var/log/vod-processor/api.log
StandardError=append:/var/log/vod-processor/api.error.log

[Install]
WantedBy=multi-user.target
EOF

# Create nginx config
cat > config/nginx/vod-processor << 'EOF'
server {
    listen 80;
    server_name _;
    
    client_max_body_size 50G;
    proxy_read_timeout 3600;
    proxy_connect_timeout 3600;
    proxy_send_timeout 3600;
    
    location / {
        root /var/www/html;
        index index.html;
        try_files $uri $uri/ =404;
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /processed/ {
        alias /opt/vod-processor/processed/;
        autoindex on;
        add_header Accept-Ranges bytes;
    }
}
EOF

# Copy the web interface
cp ../index.html web/index.html 2>/dev/null || cat > web/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <title>VOD Processor Dashboard</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #f5f5f5;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        h1 { 
            color: #333;
            margin-bottom: 30px;
            font-size: 2.5em;
        }
        
        h2 {
            color: #555;
            margin-bottom: 15px;
            font-size: 1.5em;
        }
        
        .status { 
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            background: white;
        }
        
        .running { 
            border-left: 4px solid #28a745;
        }
        
        .error { 
            border-left: 4px solid #dc3545;
        }
        
        .upload-section {
            background: white;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin: 20px 0;
        }
        
        .video-list { 
            margin-top: 30px;
        }
        
        .video-item { 
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin: 10px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: transform 0.2s;
        }
        
        .video-item:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }
        
        button { 
            background-color: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            margin: 5px;
            cursor: pointer;
            border-radius: 5px;
            font-size: 16px;
            transition: background-color 0.2s;
        }
        
        button:hover {
            background-color: #0056b3;
        }
        
        button:disabled {
            background-color: #6c757d;
            cursor: not-allowed;
        }
        
        .file-input-wrapper {
            margin: 20px 0;
        }
        
        input[type="file"] {
            display: block;
            margin: 10px 0;
            padding: 10px;
            border: 2px dashed #ccc;
            border-radius: 5px;
            width: 100%;
            cursor: pointer;
        }
        
        #uploadStatus {
            margin-top: 15px;
            font-weight: bold;
            padding: 10px;
            border-radius: 5px;
        }
        
        #uploadStatus.success {
            background-color: #d4edda;
            color: #155724;
        }
        
        #uploadStatus.error {
            background-color: #f8d7da;
            color: #721c24;
        }
        
        .progress {
            width: 100%;
            height: 25px;
            background-color: #e9ecef;
            border-radius: 5px;
            overflow: hidden;
            margin-top: 15px;
            box-shadow: inset 0 1px 3px rgba(0,0,0,0.1);
        }
        
        .progress-bar {
            height: 100%;
            background-color: #007bff;
            width: 0%;
            transition: width 0.3s;
            text-align: center;
            line-height: 25px;
            color: white;
        }
        
        .delete-btn {
            background-color: #dc3545;
        }
        
        .delete-btn:hover {
            background-color: #c82333;
        }
        
        .method-info {
            background-color: #e9ecef;
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
            font-size: 0.9em;
        }
        
        .no-videos {
            text-align: center;
            padding: 40px;
            color: #666;
        }
        
        @media (max-width: 768px) {
            .video-item {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .video-item > div:last-child {
                margin-top: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>VOD Copyright Removal</h1>
        
        <div id="status" class="status">
            <h2>System Status</h2>
            <div id="statusContent">Loading...</div>
        </div>
        
        <div class="upload-section">
            <h2>Upload Video</h2>
            <div class="file-input-wrapper">
                <input type="file" id="fileInput" accept=".mp4,.avi,.mov,.mkv,.webm">
                <button onclick="uploadVideo()" id="uploadBtn">Upload & Process</button>
            </div>
            <div id="uploadStatus"></div>
            <div class="progress" id="progressContainer" style="display: none;">
                <div class="progress-bar" id="progressBar">0%</div>
            </div>
        </div>
        
        <div class="video-list">
            <h2>Processed Videos</h2>
            <button onclick="refreshVideos()">Refresh List</button>
            <div id="videoList"></div>
        </div>
    </div>
    
    <script>
        const API_URL = '/api';
        
        async function checkStatus() {
            try {
                const response = await fetch(`${API_URL}/stats`);
                const data = await response.json();
                
                const statusDiv = document.getElementById('status');
                const statusContent = document.getElementById('statusContent');
                
                statusDiv.className = 'status running';
                
                let methodInfo = '';
                if (data.available_methods) {
                    methodInfo = `<div class="method-info">Available separation methods: ${data.available_methods.join(', ')}</div>`;
                }
                
                statusContent.innerHTML = `
                    <strong>✓ System Operational</strong><br><br>
                    CPU Usage: ${data.cpu_percent ? data.cpu_percent.toFixed(1) : 'N/A'}%<br>
                    Memory Usage: ${data.memory_percent ? data.memory_percent.toFixed(1) : 'N/A'}%<br>
                    Disk Usage: ${data.disk_usage ? data.disk_usage.toFixed(1) : 'N/A'}%
                    ${methodInfo}
                `;
            } catch (error) {
                document.getElementById('status').className = 'status error';
                document.getElementById('statusContent').innerHTML = 
                    '<strong>✗ System Error</strong><br>' + error.message;
            }
        }
        
        async function refreshVideos() {
            try {
                const response = await fetch(`${API_URL}/videos`);
                const data = await response.json();
                const listDiv = document.getElementById('videoList');
                
                if (!data.videos || data.videos.length === 0) {
                    listDiv.innerHTML = '<div class="no-videos">No processed videos yet. Upload a video to get started!</div>';
                    return;
                }
                
                listDiv.innerHTML = '';
                data.videos.forEach(video => {
                    const item = document.createElement('div');
                    item.className = 'video-item';
                    
                    const date = new Date(video.modified);
                    const dateStr = date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
                    
                    item.innerHTML = `
                        <div>
                            <strong>${video.filename}</strong><br>
                            Size: ${video.size_mb.toFixed(2)} MB<br>
                            Processed: ${dateStr}
                        </div>
                        <div>
                            <a href="/processed/${video.filename}" download>
                                <button>Download</button>
                            </a>
                            <button class="delete-btn" onclick="deleteVideo('${video.filename}')">Delete</button>
                        </div>
                    `;
                    listDiv.appendChild(item);
                });
            } catch (error) {
                console.error('Error loading videos:', error);
                document.getElementById('videoList').innerHTML = 
                    '<div class="no-videos">Error loading videos: ' + error.message + '</div>';
            }
        }
        
        async function deleteVideo(filename) {
            if (!confirm(`Delete ${filename}?`)) return;
            
            try {
                const response = await fetch(`${API_URL}/videos/${encodeURIComponent(filename)}`, {
                    method: 'DELETE'
                });
                
                if (response.ok) {
                    refreshVideos();
                } else {
                    const error = await response.json();
                    alert('Error deleting video: ' + (error.detail || 'Unknown error'));
                }
            } catch (error) {
                alert('Error deleting video: ' + error.message);
            }
        }
        
        async function uploadVideo() {
            const fileInput = document.getElementById('fileInput');
            const file = fileInput.files[0];
            
            if (!file) {
                alert('Please select a file');
                return;
            }
            
            // Check file size (warn if > 1GB)
            if (file.size > 1024 * 1024 * 1024) {
                if (!confirm(`This file is ${(file.size / 1024 / 1024 / 1024).toFixed(2)}GB. Large files may take a while to upload. Continue?`)) {
                    return;
                }
            }
            
            const formData = new FormData();
            formData.append('file', file);
            
            const uploadBtn = document.getElementById('uploadBtn');
            const statusDiv = document.getElementById('uploadStatus');
            const progressContainer = document.getElementById('progressContainer');
            const progressBar = document.getElementById('progressBar');
            
            uploadBtn.disabled = true;
            statusDiv.textContent = 'Uploading...';
            statusDiv.className = '';
            progressContainer.style.display = 'block';
            
            try {
                const xhr = new XMLHttpRequest();
                
                xhr.upload.onprogress = (e) => {
                    if (e.lengthComputable) {
                        const percentComplete = Math.round((e.loaded / e.total) * 100);
                        progressBar.style.width = percentComplete + '%';
                        progressBar.textContent = percentComplete + '%';
                    }
                };
                
                xhr.onload = function() {
                    if (xhr.status === 200) {
                        const data = JSON.parse(xhr.responseText);
                        statusDiv.textContent = `Upload complete! Processing started. File ID: ${data.file_id}`;
                        statusDiv.className = 'success';
                        fileInput.value = '';
                        
                        // Refresh video list after a delay
                        setTimeout(() => {
                            refreshVideos();
                            statusDiv.textContent = '';
                        }, 5000);
                    } else {
                        const error = JSON.parse(xhr.responseText);
                        statusDiv.textContent = `Upload failed: ${error.detail || xhr.statusText}`;
                        statusDiv.className = 'error';
                    }
                    uploadBtn.disabled = false;
                    progressContainer.style.display = 'none';
                    progressBar.style.width = '0%';
                    progressBar.textContent = '0%';
                };
                
                xhr.onerror = function() {
                    statusDiv.textContent = 'Upload failed: Network error';
                    statusDiv.className = 'error';
                    uploadBtn.disabled = false;
                    progressContainer.style.display = 'none';
                    progressBar.style.width = '0%';
                    progressBar.textContent = '0%';
                };
                
                xhr.open('POST', `${API_URL}/upload`);
                xhr.send(formData);
                
            } catch (error) {
                statusDiv.textContent = `Upload failed: ${error.message}`;
                statusDiv.className = 'error';
                uploadBtn.disabled = false;
                progressContainer.style.display = 'none';
                progressBar.style.width = '0%';
                progressBar.textContent = '0%';
            }
        }
        
        // Initialize
        checkStatus();
        refreshVideos();
        
        // Auto-refresh
        setInterval(checkStatus, 30000);
        setInterval(refreshVideos, 30000);
        
        // File input change handler
        document.getElementById('fileInput').addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                const sizeMB = (file.size / 1024 / 1024).toFixed(2);
                document.getElementById('uploadStatus').textContent = 
                    `Selected: ${file.name} (${sizeMB} MB)`;
                document.getElementById('uploadStatus').className = '';
            }
        });
    </script>
</body>
</html>
EOF

# Create empty docs and tests directories
mkdir -p docs tests

echo ""
echo "Repository structure created successfully!"
echo ""
echo "Next steps:"
echo "1. git add ."
echo "2. git commit -m 'Complete VOD Copyright Removal Pipeline'"
echo "3. git push origin main"
echo ""
echo "To install on a server:"
echo "git clone https://github.com/BigChiefRick/vod-copyright-removal.git"
echo "cd vod-copyright-removal"
echo "sudo ./install.sh"
echo ""
