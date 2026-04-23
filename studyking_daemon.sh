#!/bin/bash

# StudyKing Continuous Operation Daemon
# This script keeps the StudyKing development process running
# and monitors progress

echo "[$(date '+%Y-%m-%d %H:%M:%S')] StudyKing daemon started"

# Set working directory
cd /home/tomi/Documents

# Ensure we have flutter available
export PATH="$HOME/flutter/bin:$PATH"

# Function to log status
log_status() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$1" >> /tmp/studyking_status.log
}

# Function to check if project is valid
check_project() {
    if [ -f "pubspec.yaml" ]; then
        log_status "✓ Project exists"
        return 0
    else
        log_status "✗ Project not found"
        return 1
    fi
}

# Function to check project health
check_health() {
    log_status "Checking project health..."
    
    # Check key files exist
    local missing=0
    for file in lib/main.dart lib/core/data/data.dart project_statement.md; do
        if [ ! -f "$file" ]; then
            log_status "✗ Missing: $file"
            missing=1
        fi
    done
    
    if [ $missing -eq 0 ]; then
        log_status "✓ All core files present"
    fi
    
    return $missing
}

# Main loop
while true; do
    log_status "StudyKing monitoring cycle"
    
    check_project
    check_health
    
    # Wait 20 minutes before next cycle
    log_status "Next check in 20 minutes"
    sleep 1200
    
done
