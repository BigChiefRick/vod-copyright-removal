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
