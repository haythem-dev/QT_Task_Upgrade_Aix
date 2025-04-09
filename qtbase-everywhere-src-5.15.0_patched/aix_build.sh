#!/bin/sh
# Quick build script for Qt 5.15.0 on AIX with GCC 4.6.3
# This is a pre-patched version with all compatibility fixes applied

export OBJECT_MODE=64
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export LIBPATH=$LIBPATH:/usr/lib:/lib:/usr/X11R6/lib

# Make configure executable
chmod +x ./configure

# Configure Qt with reduced feature set
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
