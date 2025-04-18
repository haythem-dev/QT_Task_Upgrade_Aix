#!/bin/sh
# Build Qt 5.15.0 on AIX 7.2
# Generated by Qt Build Planner

# Exit on error
set -e

# Number of CPU cores for parallel build
MAKE_JOBS=4

echo "=== Building Qt 5.15.0 for AIX 7.2 ==="

# Go to build directory
cd qt-build

# Enter source directory
cd qt-everywhere-src-5.15.0

# Set up environment for the build
export OBJECT_MODE=64
export QTDIR=$(pwd)
export PATH=$QTDIR/qtbase/bin:$PATH

# Configure Qt with optimal settings for AIX
echo "Configuring Qt 5.15.0..."
./configure \
    " \
    ".join(build_plan['configure_options'])

# Start the build
echo "Building Qt 5.15.0 (this will take several hours)..."
make -j$MAKE_JOBS

# Install Qt to the prefix directory
echo "Installing Qt 5.15.0..."
make install

echo "Build and installation completed!"
echo "Please run verify_build.sh to check the installation."
