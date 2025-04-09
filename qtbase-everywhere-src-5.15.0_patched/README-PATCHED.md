# Qt 5.15.0 Patched for AIX 7.2 with GCC 4.6.3

This is a patched version of Qt 5.15.0 specifically designed to build on AIX 7.2 using the GCC 4.6.3 compiler. The original Qt 5.15.0 source requires C++11 features that are not fully supported by GCC 4.6.3, so this patched version includes several compatibility fixes to work around these limitations.

## Applied Patches

The following patches have been applied to this source tree:

1. **GCC 4.6.3 compiler detection** in `configure`
   - Adds detection of GCC 4.6.3 compiler versions
   - Automatically enables compatibility flags when the compiler is detected

2. **C++11 compatibility layer** in `src/corelib/global/qglobal.h`
   - Provides implementations for missing C++11 features:
     - `std::decay_t`
     - `std::is_same`
     - `std::enable_if`
     - `nullptr` compatibility

3. **Auto keyword replacement** in `src/corelib/tools/qalgorithms.h`
   - Replaces `auto` keyword with explicit types
   - Uses `qptrdiff` and other explicit types instead of type deduction

4. **Atomic operations compatibility** in `src/corelib/thread/qatomic_cxx11.h`
   - Provides GCC 4.6.3 compatible atomic operations
   - Adds missing memory ordering implementations

5. **AIX platform optimizations** in `mkspecs/aix-g++/qplatformdefs.h`
   - Adds large file support
   - Improves 64-bit compatibility

6. **AIX build configuration** in `mkspecs/aix-g++/qmake.conf`
   - Sets correct compiler and linker flags for AIX
   - Disables unsupported C++11 features:
     - Rvalue references
     - Explicit conversions
     - constexpr
     - C++11 atomics
     - std::future
     - Variadic templates

## Building Qt

An AIX-specific build script `aix_build.sh` is included in this directory. This script will configure and build Qt with the appropriate options for AIX 7.2 with GCC 4.6.3.

To build Qt:

1. Transfer this entire directory to your AIX system.
2. Make sure GCC 4.6.3 is installed and in your PATH.
3. Set up the environment:
   ```
   export OBJECT_MODE=64
   export PATH=/usr/bin:/bin:/usr/sbin:/sbin
   export LIBPATH=$LIBPATH:/usr/lib:/lib:/usr/X11R6/lib
   ```
4. Run the build script:
   ```
   ./aix_build.sh
   ```

The script will configure Qt with a reduced feature set appropriate for GCC 4.6.3 and build it. This may take several hours depending on your system's performance.

## Installation

After a successful build, install Qt to the configured prefix location with:
```
make install
```

By default, Qt will be installed to `/opt/qt-5.15.0`. This path can be changed by editing the `-prefix` option in the `aix_build.sh` script before building.

## Additional Resources

For more details on the patches and troubleshooting information, refer to the main project documentation:

- `README-build-steps.md`: Step-by-step build instructions
- `troubleshooting_guide.md`: Solutions for common issues
- `PROJECT_SUMMARY.md`: Overview of the patches and compatibility work

## Limitations

This patched version of Qt has some limitations compared to the standard Qt 5.15.0:

- Some features requiring advanced C++11 support are disabled
- OpenGL and Vulkan support is disabled
- SQLite support is disabled by default
- Some multithreading features may have reduced functionality

These limitations are necessary to maintain compatibility with GCC 4.6.3 on AIX 7.2.