# Qt 5.15.0 Build for AIX 7.2 with GCC 4.6.3

This project provides a comprehensive solution for building Qt 5.15.0 on AIX 7.2 systems using the older GCC 4.6.3 compiler, which lacks full C++11 support.

## Overview

Qt 5.15.0 requires C++11 features that are not fully supported by GCC 4.6.3. This project addresses this compatibility gap by:

1. Providing specialized patches for key C++11 features
2. Automating the build process with customized scripts
3. Including analysis and diagnostic tools to understand build issues
4. Offering clear documentation on the build steps and troubleshooting

## Key Components

- **Build Environment Analysis**: `qt_build_planner.py` analyzes your environment for compatibility
- **Compatibility Patches**: Located in `aix_compatibility_patches/` and `patches/`
- **Build Automation**: Scripts for applying patches and initiating the build process
- **Mock Testing**: `mock_build_test.py` simulates build issues and verifies patches

## Prerequisites

- AIX 7.2 operating system (POWER9 architecture)
- GCC 4.6.3 compiler 
- Required development headers:
  - X11
  - OpenSSL
  - Freetype
  - Fontconfig
- Sufficient disk space (at least 10GB)
- Sufficient memory (at least 4GB)

## C++11 Compatibility Issues Addressed

| Feature | Issue with GCC 4.6.3 | Our Solution |
|---------|----------------------|--------------|
| auto keyword | Limited support for type deduction | Replace with explicit types (e.g., `qptrdiff`) |
| template aliases | No support for `using` declarations | Add compatibility layer in std namespace |
| atomic operations | Missing C++11 memory ordering | Implement compatible versions with inline assembly |
| nullptr | Limited support | Provide ifdef-based compatibility workarounds |
| lambda expressions | Limited capture support | Alternative approaches where needed |

## Build Process

1. **Prepare Source and Patches**:
   - Extract the Qt 5.15.0 source
   - Apply all patches from `aix_compatibility_patches/`
   ```
   ./apply_edit_patches.sh
   ```

2. **Configure and Build**:
   - Run the build script with customized options:
   ```
   ./build-qt515-aix-gcc463.sh
   ```

3. **Testing**:
   - Create a minimal test application to verify functionality
   - Check for any runtime issues

## Patch Details

1. **01-qtbase-configure-gcc463.patch**:
   - Detects GCC 4.6.3 and disables incompatible C++11 features
   - Adds flags to disable C++11 features that cannot be patched

2. **02-qtbase-qglobal-cpp11-compat.patch**:
   - Adds compatibility layer for template aliases
   - Provides implementations for missing C++11 standard library features
   - Adds nullptr compatibility definitions

3. **03-qtbase-qalgorithms-auto-fix.patch**:
   - Replaces auto keyword usage with explicit types
   - Focuses on algorithm implementations in qalgorithms.h

4. **04-qtbase-qatomic-cxx11-fix.patch**:
   - Provides compatibility for atomic operations
   - Uses inline assembly for memory barriers where needed

## Troubleshooting

If compilation fails with C++11 feature errors not covered by existing patches:

1. Identify the file and line number from the error message
2. Check for:
   - `auto` keyword usage
   - Template aliases with `using` declarations
   - Complex lambda expressions
   - Atomic operations with explicit memory ordering
3. Create a targeted patch using the patterns in existing patches
4. Apply the new patch and restart the build

For detailed build logs and additional troubleshooting, see `troubleshooting_guide.md`.

## Testing the Build

Once built, verify with a simple application:

```cpp
// test.cpp
#include <QCoreApplication>
#include <QDebug>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    qDebug() << "Qt version:" << QT_VERSION_STR;
    qDebug() << "Built with compiler: " << QT_COMPILER_VERSION_STR;
    qDebug() << "Build succeeded!";
    return 0;
}
```

Compile and run:
```
/opt/qt-5.15.0/bin/qmake test.cpp -o Makefile
make
./test
```

## Limitations

- This build disables certain Qt features that require C++11/14 functionality
- Some modules may not work due to compiler limitations
- Limited graphics support (no OpenGL or Vulkan)
- Focus is on core functionality for embedded applications