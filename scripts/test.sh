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
