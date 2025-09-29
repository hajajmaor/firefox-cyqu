#!/bin/bash
# Quick script to check Firefox build status

echo "════════════════════════════════════════════════════════════"
echo "  🔍 Firefox Build Status Checker"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check if build is running
if pgrep -f "mach build" > /dev/null; then
    echo "✅ Build is RUNNING"
    BUILD_PID=$(pgrep -f "mach build" | head -1)
    echo "   PID: $BUILD_PID"
    echo ""
else
    echo "⏹️  No build process found"
    echo ""
fi

# Show last 30 lines of build log
if [ -f /tmp/firefox-build-final.log ]; then
    echo "📋 Last 30 lines of build log:"
    echo "────────────────────────────────────────────────────────────"
    tail -30 /tmp/firefox-build-final.log
    echo "────────────────────────────────────────────────────────────"
    echo ""
    
    # Check for errors
    ERROR_COUNT=$(grep -i "fatal error\|error:" /tmp/firefox-build-final.log | wc -l)
    if [ $ERROR_COUNT -gt 0 ]; then
        echo "⚠️  Found $ERROR_COUNT errors in build log"
        echo ""
        echo "Recent errors:"
        grep -i "fatal error\|error:" /tmp/firefox-build-final.log | tail -5
    else
        echo "✅ No errors detected so far"
    fi
else
    echo "❌ Build log not found: /tmp/firefox-build-final.log"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Commands:"
echo "  Watch live: tail -f /tmp/firefox-build-final.log"
echo "  Stop build: pkill -f 'mach build'"
echo "  Check this: ./CHECK_BUILD_STATUS.sh"
echo ""
