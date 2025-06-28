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
