#!/bin/sh
# build-qt515-aix-gcc463.sh - Build Qt 5.15.0 for AIX with GCC 4.6.3

# Exit on error
set -e

# We'll run this from the src directory where qtbase-everywhere-src-5.15.0 exists
echo "Starting Qt 5.15.0 build process..."
echo "Current directory: $(pwd)"

# Configure environment
export OBJECT_MODE=64
export PATH=$(pwd)/qtbase-everywhere-src-5.15.0/bin:$PATH

# Create install directory
mkdir -p /opt/qt-5.15.0

echo "Configuring qtbase with reduced features..."
cd qtbase-everywhere-src-5.15.0

# Explicitly check for the configure script
if [ ! -f "./configure" ]; then
    echo "Error: configure script not found in $(pwd)"
    echo "Contents of current directory:"
    ls -la
    exit 1
fi

# Make sure configure is executable
chmod +x ./configure

./configure \
    -prefix /opt/qt-5.15.0 \
    -platform aix-g++ \
    -release \
    -opensource \
    -confirm-license \
    -no-feature-c++14 \
    -no-feature-c++17 \
    -no-feature-thread_local \
    -no-feature-renameat2 \
    -no-feature-getentropy \
    -no-feature-clock-gettime \
    -no-feature-ffmpeg \
    -no-feature-glib \
    -no-feature-sse2 \
    -no-feature-system-doubleconversion \
    -no-opengl \
    -no-vulkan \
    -no-sql-sqlite \
    -no-dbus \
    -no-glib \
    -qt-zlib \
    -qt-libpng \
    -qt-libjpeg \
    -qt-freetype \
    -qt-harfbuzz \
    -qt-pcre \
    -no-fontconfig \
    -nomake examples \
    -nomake tests \
    -verbose

# If configure succeeds, attempt to build
echo "Building qtbase..."
make -j2

echo "Qt 5.15.0 build process completed. Check for any errors in the output."