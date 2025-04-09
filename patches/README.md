# Qt 5.15.0 AIX Patches

This directory contains patches required to build Qt 5.15.0 on AIX 7.2 with PowerPC POWER9 architecture.

## Included Patches

The `qt-5.15.0-aix-fixes.patch` file addresses several AIX-specific issues:

1. **Shared Library Handling**
   - AIX uses .a archive files containing shared objects
   - Fixes build system to properly create and link shared libraries on AIX

2. **PowerPC Atomic Operations**
   - Optimizes atomic operations for PowerPC POWER9
   - Ensures proper memory ordering on AIX systems

3. **Platform-specific File System Handling**
   - Implements AIX-specific file system and process handling
   - Fixes path normalization and file permission issues

4. **RPATH and Dynamic Loading**
   - Corrects RPATH handling for AIX dynamic libraries
   - Fixes dynamic loader issues specific to AIX

## Applying Patches

The patches are automatically applied by the `prepare_environment.sh` script. If you need to apply them manually:

```bash
cd qt-everywhere-src-5.15.0
patch -p1 < /path/to/patches/qt-5.15.0-aix-fixes.patch
