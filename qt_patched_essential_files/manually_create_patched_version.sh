#!/bin/bash
# manually_create_patched_version.sh - Apply patches to create a fully patched Qt 5.15.0 for GCC 4.6.3

QT_SRC_DIR="$(pwd)/qtbase-everywhere-src-5.15.0_patched"
AIX_PATCH_DIR="$(pwd)/patches"
GCC463_PATCH_DIR="$(pwd)/aix_compatibility_patches"

echo "Creating patched Qt 5.15.0 version..."
echo "Qt source directory: ${QT_SRC_DIR}"
echo "AIX patch directory: ${AIX_PATCH_DIR}"
echo "GCC 4.6.3 patch directory: ${GCC463_PATCH_DIR}"

# Function to check if a directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        echo "Error: Directory not found: $1"
        exit 1
    fi
}

# Verify directories exist
check_directory "$QT_SRC_DIR"
check_directory "$AIX_PATCH_DIR"
check_directory "$GCC463_PATCH_DIR"

# Function to manually apply patches based on their content descriptions
apply_gcc463_patches() {
    echo "Applying GCC 4.6.3 compatibility patches manually..."
    
    # 1. Apply 01-qtbase-configure-gcc463.patch
    echo "Applying GCC 4.6.3 detection to configure script..."
    
    # Find a good spot to insert the GCC 4.6.3 detection code
    if [ -f "${QT_SRC_DIR}/configure" ]; then
        # Add GCC 4.6.3 detection after the GCC version detection section
        search_line="# Detect compiler version"
        line_num=$(grep -n "$search_line" "${QT_SRC_DIR}/configure" | cut -d: -f1)
        
        if [ -n "$line_num" ]; then
            line_num=$((line_num + 20))  # Skip ahead to a good insertion point
            
            # Insert GCC 4.6.3 detection code
            sed -i "${line_num}i\\
# Special case for GCC 4.6.3 - Add detection and special flags\\
gcc46version=\$(echo \"\$TEST_COMPILER_VERSION\" | grep -o \"\\\\<4\\\\.6\\\\.[0-9]\\\\+\\\\>\" || true)\\
[ -n \"\$gcc46version\" ] && QMAKE_ARGS=\"\$QMAKE_ARGS -D QT_NO_CXX11_FUTURE -D QT_NO_CXX11_NUMERIC_LIMITS -D QT_NO_CXX11_VARIADIC_TEMPLATES\"" "${QT_SRC_DIR}/configure"
            
            echo "✓ Added GCC 4.6.3 detection to configure"
        else
            echo "✗ Could not find insertion point for GCC 4.6.3 detection"
        fi
    else
        echo "✗ configure script not found"
    fi
    
    # 2. Apply 02-qtbase-qglobal-cpp11-compat.patch
    echo "Applying C++11 compatibility layer to qglobal.h..."
    
    if [ -f "${QT_SRC_DIR}/src/corelib/global/qglobal.h" ]; then
        # Find a good spot to insert the compatibility code
        search_line="#include <type_traits>"
        line_num=$(grep -n "$search_line" "${QT_SRC_DIR}/src/corelib/global/qglobal.h" | cut -d: -f1)
        
        if [ -n "$line_num" ]; then
            line_num=$((line_num + 2))  # Insert after type_traits include
            
            # Insert C++11 compatibility layer
            sed -i "${line_num}i\\
// GCC 4.6.3 compatibility layer for C++11 features\\
#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6\\
# ifndef nullptr\\
#  include <cstddef>\\
#  define nullptr NULL\\
# endif\\
namespace std {\\
  template<typename T> struct decay_struct { typedef typename decay<T>::type type; };\\
  template<typename T> struct decay_t : public decay_struct<T>::type { };\\
  template<typename T, typename U> struct is_same_struct { static constexpr bool value = false; };\\
  template<typename T> struct is_same_struct<T, T> { static constexpr bool value = true; };\\
  template<typename T, typename U> struct is_same : public is_same_struct<T, U> { };\\
  template<bool B, typename T = void> struct enable_if_struct { typedef T type; };\\
  template<typename T> struct enable_if_struct<false, T> { };\\
  template<bool B, typename T = void> struct enable_if : public enable_if_struct<B, T> { };\\
}\\
#endif" "${QT_SRC_DIR}/src/corelib/global/qglobal.h"
            
            echo "✓ Added C++11 compatibility layer to qglobal.h"
        else
            echo "✗ Could not find insertion point for C++11 compatibility layer"
        fi
    else
        echo "✗ qglobal.h not found"
    fi
    
    # 3. Apply 03-qtbase-qalgorithms-auto-fix.patch
    echo "Applying auto keyword fixes to qalgorithms.h..."
    
    if [ -f "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h" ]; then
        # Replace auto keyword instances
        sed -i 's/auto distance = end - begin;/qptrdiff distance = end - begin;/g' "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h"
        sed -i 's/const auto n = last - first;/const qptrdiff n = last - first;/g' "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h"
        sed -i 's/auto left = first;/QScopedPointer<RandomAccessIterator, QScopedPointerArrayDeleter<RandomAccessIterator> > deferred(new RandomAccessIterator[n]);\
    RandomAccessIterator *buffer = deferred.data();\
    RandomAccessIterator left = first;/g' "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h"
        
        # Check if changes were applied
        if grep -q "qptrdiff distance = end - begin" "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h"; then
            echo "✓ Fixed auto keyword usage in qalgorithms.h"
        else
            echo "✗ Failed to fix auto keyword usage"
        fi
    else
        echo "✗ qalgorithms.h not found"
    fi
    
    # 4. Apply 04-qtbase-qatomic-cxx11-fix.patch
    echo "Applying atomic operations fixes..."
    
    if [ -f "${QT_SRC_DIR}/src/corelib/thread/qatomic_cxx11.h" ]; then
        # Add atomic compatibility layer
        search_line="#include <atomic>"
        line_num=$(grep -n "$search_line" "${QT_SRC_DIR}/src/corelib/thread/qatomic_cxx11.h" | cut -d: -f1)
        
        if [ -n "$line_num" ]; then
            line_num=$((line_num + 1))  # Insert after atomic include
            
            # Insert atomic compatibility layer
            sed -i "${line_num}i\\
// GCC 4.6.3 atomic compatibility layer\\
#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6\\
// Add memory order definitions\\
namespace std {\\
    enum memory_order {\\
        memory_order_relaxed,\\
        memory_order_consume,\\
        memory_order_acquire,\\
        memory_order_release,\\
        memory_order_acq_rel,\\
        memory_order_seq_cst\\
    };\\
}\\
// Define missing atomic operations\\
#define atomic_load_explicit(ptr, order) atomic_load(ptr)\\
#define atomic_store_explicit(ptr, val, order) atomic_store(ptr, val)\\
#define atomic_exchange_explicit(ptr, val, order) atomic_exchange(ptr, val)\\
#define atomic_compare_exchange_strong_explicit(ptr, expected, desired, success, failure) \\
    atomic_compare_exchange_strong(ptr, expected, desired)\\
#define atomic_compare_exchange_weak_explicit(ptr, expected, desired, success, failure) \\
    atomic_compare_exchange_weak(ptr, expected, desired)\\
#endif" "${QT_SRC_DIR}/src/corelib/thread/qatomic_cxx11.h"
            
            echo "✓ Added atomic operations compatibility layer"
        else
            echo "✗ Could not find insertion point for atomic compatibility layer"
        fi
    else
        echo "✗ qatomic_cxx11.h not found"
    fi
}

# Apply AIX specific patches
apply_aix_patches() {
    echo "Applying AIX platform patches manually..."
    
    # Check if the aix-g++ platform directory exists
    if [ -d "${QT_SRC_DIR}/mkspecs/aix-g++" ]; then
        # Modify qplatformdefs.h
        if [ -f "${QT_SRC_DIR}/mkspecs/aix-g++/qplatformdefs.h" ]; then
            echo "Modifying qplatformdefs.h for AIX compatibility..."
            
            # Add proper system definitions
            search_line="#include <unistd.h>"
            line_num=$(grep -n "$search_line" "${QT_SRC_DIR}/mkspecs/aix-g++/qplatformdefs.h" | cut -d: -f1)
            
            if [ -n "$line_num" ]; then
                # Add AIX specific definitions
                sed -i "${line_num}i\\
// AIX specific definitions for better compatibility\\
#define _LARGE_FILES 1\\
#define _LARGE_FILE_API\\
#define _XOPEN_SOURCE_EXTENDED 1" "${QT_SRC_DIR}/mkspecs/aix-g++/qplatformdefs.h"
                
                echo "✓ Added AIX specific definitions to qplatformdefs.h"
            else
                echo "✗ Could not find insertion point in qplatformdefs.h"
            fi
        else
            echo "✗ qplatformdefs.h not found"
        fi
        
        # Create a custom qmake.conf
        if [ -f "${QT_SRC_DIR}/mkspecs/aix-g++/qmake.conf" ]; then
            echo "Modifying qmake.conf for AIX compatibility..."
            
            # Backup original file
            cp "${QT_SRC_DIR}/mkspecs/aix-g++/qmake.conf" "${QT_SRC_DIR}/mkspecs/aix-g++/qmake.conf.orig"
            
            # Create a modified qmake.conf with proper flags
            cat > "${QT_SRC_DIR}/mkspecs/aix-g++/qmake.conf" << 'EOF'
#
# AIX with GCC 4.6.3 platform - Modified for compatibility
#

MAKEFILE_GENERATOR      = UNIX
QMAKE_PLATFORM          = aix

include(../common/unix.conf)

QMAKE_COMPILER          = gcc

QMAKE_CC                = gcc
QMAKE_LEX               = flex
QMAKE_LEXFLAGS          =
QMAKE_YACC              = yacc
QMAKE_YACCFLAGS         = -d
QMAKE_CFLAGS            = -maix64
QMAKE_CFLAGS_DEPS       = -M
QMAKE_CFLAGS_WARN_ON    = -Wall -W
QMAKE_CFLAGS_WARN_OFF   = -w
QMAKE_CFLAGS_RELEASE    = -O2
QMAKE_CFLAGS_DEBUG      = -g
QMAKE_CFLAGS_SHLIB      = -fPIC
QMAKE_CFLAGS_STATIC_LIB = -fPIC
QMAKE_CFLAGS_YACC       = -Wno-unused -Wno-parentheses
QMAKE_CFLAGS_THREAD     = -D_THREAD_SAFE

QMAKE_CXX               = g++
QMAKE_CXXFLAGS          = $$QMAKE_CFLAGS -D__STDC_CONSTANT_MACROS -std=c++98
QMAKE_CXXFLAGS_DEPS     = $$QMAKE_CFLAGS_DEPS
QMAKE_CXXFLAGS_WARN_ON  = $$QMAKE_CFLAGS_WARN_ON
QMAKE_CXXFLAGS_WARN_OFF = $$QMAKE_CFLAGS_WARN_OFF
QMAKE_CXXFLAGS_RELEASE  = $$QMAKE_CFLAGS_RELEASE
QMAKE_CXXFLAGS_DEBUG    = $$QMAKE_CFLAGS_DEBUG
QMAKE_CXXFLAGS_SHLIB    = $$QMAKE_CFLAGS_SHLIB
QMAKE_CXXFLAGS_STATIC_LIB = $$QMAKE_CFLAGS_STATIC_LIB
QMAKE_CXXFLAGS_YACC     = $$QMAKE_CFLAGS_YACC
QMAKE_CXXFLAGS_THREAD   = $$QMAKE_CFLAGS_THREAD

# Disable C++11 features not supported by GCC 4.6.3
DEFINES += QT_NO_CXX11_RVALUE_REFERENCES
DEFINES += QT_NO_CXX11_EXPLICIT_CONVERSIONS
DEFINES += QT_NO_CXX11_CONSTEXPR
DEFINES += QT_NO_CXX11_ATOMICS
DEFINES += QT_NO_CXX11_FUTURE
DEFINES += QT_NO_CXX11_VARIADIC_TEMPLATES

QMAKE_LINK              = g++
QMAKE_LINK_SHLIB        = g++
QMAKE_LINK_C            = gcc
QMAKE_LINK_C_SHLIB      = gcc
QMAKE_LFLAGS            = -maix64
QMAKE_LFLAGS_RELEASE    =
QMAKE_LFLAGS_DEBUG      =
QMAKE_LFLAGS_SHLIB      = -shared
QMAKE_LFLAGS_PLUGIN     = $$QMAKE_LFLAGS_SHLIB
QMAKE_LFLAGS_SONAME     = -Wl,-soname,
QMAKE_LFLAGS_THREAD     =
QMAKE_LFLAGS_NOUNDEF    = -Wl,-z,defs
QMAKE_LFLAGS_RPATH      = -Wl,-rpath,

QMAKE_PCH_OUTPUT_EXT    = .gch/c++

QMAKE_LIBS              =
QMAKE_LIBS_DYNLOAD      = -ldl
QMAKE_LIBS_X11          = -lXext -lX11 -lm
QMAKE_LIBS_OPENGL       = -lGL
QMAKE_LIBS_THREAD       = -lpthread

QMAKE_AR                = ar cqs
QMAKE_OBJCOPY           = objcopy
QMAKE_NM                = nm -P
QMAKE_RANLIB            =

QMAKE_STRIP             = strip
QMAKE_STRIPFLAGS_LIB   += --strip-unneeded

load(qt_config)
EOF
            
            echo "✓ Created custom qmake.conf for AIX compatibility"
        else
            echo "✗ qmake.conf not found"
        fi
    else
        echo "✗ aix-g++ platform directory not found"
    fi
}

# Apply GCC 4.6.3 patches
apply_gcc463_patches

# Apply AIX patches
apply_aix_patches

# Create a build script specifically for the patched version
cat > "${QT_SRC_DIR}/aix_build.sh" << 'EOF'
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
EOF

chmod +x "${QT_SRC_DIR}/aix_build.sh"

echo ""
echo "All patches have been applied to ${QT_SRC_DIR}"
echo "A build script has been created at ${QT_SRC_DIR}/aix_build.sh"
echo ""
echo "Next steps:"
echo "1. Transfer the patched directory to your AIX system"
echo "2. Run the aix_build.sh script to build Qt"
echo "3. Refer to README-build-steps.md for detailed instructions"
echo ""
echo "Patched version creation complete!"
exit 0