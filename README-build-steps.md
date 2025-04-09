# Step-by-Step Build Guide for Qt 5.15.0 on AIX 7.2 with GCC 4.6.3

This document provides detailed instructions for building Qt 5.15.0 on AIX 7.2 systems using GCC 4.6.3. Follow these steps carefully to navigate the build process and avoid common issues.

## Prerequisites

Before starting, ensure you have:

- AIX 7.2 operating system
- GCC 4.6.3 compiler installed and in your PATH
- At least 10GB of free disk space
- At least 4GB of RAM
- Required development packages:
  - X11 development headers
  - OpenSSL development headers
  - Freetype development headers
  - Fontconfig development headers

## Step 1: Preparation

1. Create a dedicated build directory:
   ```bash
   mkdir -p /software/home/yourusername/qt-build
   cd /software/home/yourusername/qt-build
   ```

2. Download and extract Qt 5.15.0 source:
   ```bash
   wget https://download.qt.io/archive/qt/5.15/5.15.0/single/qt-everywhere-src-5.15.0.tar.xz
   tar -xf qt-everywhere-src-5.15.0.tar.xz
   ```

3. Set up the environment:
   ```bash
   export OBJECT_MODE=64
   export PATH=/software/home/yourusername/qt-build/qtbase-everywhere-src-5.15.0/bin:$PATH
   export LIBPATH=$LIBPATH:/usr/lib:/lib:/usr/X11R6/lib
   ```

## Step 2: Apply Compatibility Patches

1. Copy all patch files from the `aix_compatibility_patches` directory to your build environment.

2. Apply the patches using the script:
   ```bash
   chmod +x apply_edit_patches.sh
   ./apply_edit_patches.sh
   ```

   This will apply the following critical patches:
   - 01-qtbase-configure-gcc463.patch - Adds compiler detection
   - 02-qtbase-qglobal-cpp11-compat.patch - Adds C++11 compatibility layer
   - 03-qtbase-qalgorithms-auto-fix.patch - Fixes auto keyword issues
   - 04-qtbase-qatomic-cxx11-fix.patch - Provides atomic operation compatibility

3. Verify that patches were applied successfully:
   ```bash
   cd qtbase-everywhere-src-5.15.0
   grep -n "gcc46version" configure
   grep -n "template<typename T> struct decay" src/corelib/global/qglobal.h
   ```

## Step 3: Configure Qt

1. Make the configure script executable:
   ```bash
   chmod +x configure
   ```

2. Run configure with reduced feature set:
   ```bash
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
   ```

3. Review the configure output carefully:
   - Verify that GCC 4.6.3 was detected correctly
   - Check that all required libraries were found
   - Note any warnings or errors for troubleshooting

## Step 4: Build Qt

1. Start the build process with limited parallelism to avoid memory issues:
   ```bash
   make -j2
   ```

2. Monitor the build process for errors:
   ```bash
   make > build.log 2>&1
   ```

3. If errors occur, check `troubleshooting_guide.md` for common issues and solutions.

4. For serious memory constraints, build with single thread:
   ```bash
   make -j1
   ```

## Step 5: Install Qt

1. Install to the configured prefix directory:
   ```bash
   make install
   ```

2. Set up environment variables for using the built Qt:
   ```bash
   export PATH=/opt/qt-5.15.0/bin:$PATH
   export LIBPATH=$LIBPATH:/opt/qt-5.15.0/lib
   ```

## Step 6: Verify the Build

1. Create a simple test application:
   ```bash
   mkdir -p ~/qt-test
   cd ~/qt-test
   ```

2. Create a test file (test.cpp):
   ```cpp
   #include <QCoreApplication>
   #include <QDebug>
   
   int main(int argc, char *argv[])
   {
       QCoreApplication app(argc, argv);
       qDebug() << "Qt version:" << QT_VERSION_STR;
       qDebug() << "Built with compiler:" << QT_COMPILER_VERSION_STR;
       qDebug() << "Build succeeded!";
       return 0;
   }
   ```

3. Create a project file (test.pro):
   ```
   QT = core
   TARGET = qttest
   SOURCES = test.cpp
   ```

4. Build and run the test:
   ```bash
   /opt/qt-5.15.0/bin/qmake
   make
   export LIBPATH=$LIBPATH:/opt/qt-5.15.0/lib
   ./qttest
   ```

5. If the test runs successfully, your Qt build is working!

## Troubleshooting Common Build Issues

### If compilation fails with C++11 feature errors:

1. Check if the feature is related to already patched issues:
   - Auto keyword usage
   - Template aliases
   - Atomic operations
   - nullptr keyword

2. Look at the error message and file name to determine which patch might be missing or incomplete.

3. Apply additional targeted patches as needed.

### If linking fails with missing symbols:

1. Check if the library path is set correctly:
   ```bash
   echo $LIBPATH
   ```

2. Verify all dependencies were detected during configure:
   ```bash
   grep -n "Checking for.*\.\.\. yes" config.log
   ```

3. If specific modules are missing, consider rebuilding with a more limited set:
   ```
   ./configure -submodules=qtbase
   ```

### If the build runs out of memory:

1. Clear any temporary files:
   ```bash
   make clean
   ```

2. Restart the build with minimal parallel jobs:
   ```bash
   make -j1
   ```

3. Disable debug information if needed:
   ```bash
   QMAKE_CXXFLAGS+="-g0" make -j1
   ```

## Next Steps

After a successful build:

1. Document the specific features and modules that were built successfully
2. Test with more complex applications to verify functionality
3. Consider creating a distribution package for your AIX environment

For further assistance, refer to `troubleshooting_guide.md` for detailed solutions to common issues.