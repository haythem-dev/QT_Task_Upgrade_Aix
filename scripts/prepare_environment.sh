#!/bin/sh
# Prepare environment for building Qt 5.15.0 on AIX 7.2
# Generated by Qt Build Planner

# Exit on error
set -e

echo "=== Preparing environment for Qt 5.15.0 build ==="

# Create build directory
mkdir -p qt-build
cd qt-build

# Download Qt source if not present
if [ ! -f qt-everywhere-src-5.15.0.tar.xz ]; then
    echo "Downloading Qt 5.15.0 source..."
    curl -L -o qt-everywhere-src-5.15.0.tar.xz https://download.qt.io/archive/qt/5.15/5.15.0/single/qt-everywhere-src-5.15.0.tar.xz
fi

# Extract source if not already extracted
if [ ! -d qt-everywhere-src-5.15.0 ]; then
    echo "Extracting Qt 5.15.0 source..."
    tar -xf qt-everywhere-src-5.15.0.tar.xz
fi

# Apply patches
echo "Applying AIX-specific patches..."
cd qt-everywhere-src-5.15.0
patch -p1 < ../../patches/qt-5.15.0-aix-fixes.patch

# Return to build directory
cd ..

echo "Environment preparation complete."
echo "Now run build_qt.sh to configure and build Qt."
