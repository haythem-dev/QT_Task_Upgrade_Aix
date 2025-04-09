# Qt 5.15.0 Essential Patched Files for AIX with GCC 4.6.3

This archive contains the essential patched files for building Qt 5.15.0 on AIX 7.2 with GCC 4.6.3. These files address key compatibility issues between Qt's C++11 requirements and the limitations of GCC 4.6.3.

## Contents

### Modified Source Files

- `src/corelib/global/qglobal.h`: Added C++11 compatibility layer for GCC 4.6.3
- `src/corelib/tools/qalgorithms.h`: Replaced auto keyword with explicit types
- `src/corelib/thread/qatomic_cxx11.h`: Added atomic operations compatibility

### Platform Configuration

- `mkspecs/aix-g++/qplatformdefs.h`: Updated for AIX compatibility
- `mkspecs/aix-g++/qmake.conf`: Added proper compiler flags for GCC 4.6.3

### Build Scripts

- `configure`: Modified with GCC 4.6.3 detection
- `aix_build.sh`: Custom build script for AIX systems

### Documentation

- `README-PATCHED.md`: Instructions for using the patched Qt version
- `DEVELOPMENT_HISTORY.md`: Development process and design decisions

## Usage

To use these patched files:

1. Download and extract the original Qt 5.15.0 source code
2. Copy these files to their respective locations in the Qt source tree, replacing the original files
3. Follow the build instructions in README-PATCHED.md

## Complete Patched Version

These files are extracted from a complete patched version of Qt 5.15.0. For the full patched source tree, refer to the original project.

For detailed build instructions and troubleshooting information, refer to:
- README-build-steps.md
- troubleshooting_guide.md

## Limitations

This patched version has some limitations compared to standard Qt 5.15.0:
- Some features requiring advanced C++11 support are disabled
- OpenGL and Vulkan support is disabled
- SQLite support is disabled by default
- Some multithreading features may have reduced functionality

These limitations are necessary to maintain compatibility with GCC 4.6.3 on AIX 7.2.