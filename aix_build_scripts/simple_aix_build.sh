#!/bin/sh
# Simple build script for Qt 5.15.0 on AIX with GCC 4.6.3
# This directly references the configure script by full path

# Set the directory where the configure script is located
# Update this path to match your setup
QT_SRC_DIR="/software/home/benabdelaziz/cc_compiler/qt/5.15.0/pharmos.3rd_party.qt5/dev/src/qtbase-everywhere-src-5.15.0_patched"

export OBJECT_MODE=64
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export LIBPATH=$LIBPATH:/usr/lib:/lib:/usr/X11R6/lib

# Check if the configure script exists
if [ ! -f "$QT_SRC_DIR/configure" ]; then
    echo "Error: configure script not found at $QT_SRC_DIR/configure"
    echo "Please update the QT_SRC_DIR variable in this script to point to the correct location"
    exit 1
fi

# Make configure executable
chmod +x "$QT_SRC_DIR/configure"

echo "Using configure script at: $QT_SRC_DIR/configure"

# Change to the Qt source directory
cd "$QT_SRC_DIR" || { echo "Error: Could not change to directory $QT_SRC_DIR"; exit 1; }

# Configure Qt with reduced feature set
"$QT_SRC_DIR/configure" \
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

# Verify configuration succeeded
if [ $? -ne 0 ]; then
    echo "Configuration failed!"
    exit 1
fi

# Build with limited parallelism
echo "Starting build with make -j2..."
make -j2

# Install if build successful
if [ $? -eq 0 ]; then
    echo "Build successful! Run 'make install' to install."
else
    echo "Build failed! Check error messages above."
fi