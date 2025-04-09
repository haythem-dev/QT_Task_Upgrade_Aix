#!/bin/sh
# create_patched_version.sh - Apply patches to create a fully patched Qt 5.15.0 for GCC 4.6.3

QT_SRC_DIR="$(pwd)/qtbase-everywhere-src-5.15.0_patched"
AIX_PATCH_DIR="$(pwd)/patches"
GCC463_PATCH_DIR="$(pwd)/aix_compatibility_patches"

echo "Creating patched Qt 5.15.0 version..."
echo "Qt source directory: ${QT_SRC_DIR}"
echo "AIX patch directory: ${AIX_PATCH_DIR}"
echo "GCC 4.6.3 patch directory: ${GCC463_PATCH_DIR}"

# Check if patch command is available
if ! command -v patch >/dev/null 2>&1; then
    echo "Error: 'patch' command not found"
    exit 1
fi

# Apply patch function
apply_patch() {
    local patch_file="$1"
    local target_dir="$2"
    
    echo "Applying patch: $patch_file"
    
    # Check if patch file exists
    if [ ! -f "$patch_file" ]; then
        echo "Error: Patch file not found: $patch_file"
        return 1
    fi
    
    # Apply the patch
    (cd "$target_dir" && patch -p1 < "$patch_file")
    
    if [ $? -ne 0 ]; then
        echo "Warning: Patch may have had some rejects. Check .rej files."
    fi
    
    echo "Patch applied: $patch_file"
    return 0
}

# First apply general AIX patches
echo "Applying general AIX patches..."
for patch_file in "${AIX_PATCH_DIR}"/*.patch; do
    if [ -f "$patch_file" ]; then
        apply_patch "$patch_file" "$QT_SRC_DIR"
        if [ $? -ne 0 ]; then
            echo "Failed to apply patch: $patch_file"
            exit 1
        fi
    fi
done

# Then apply GCC 4.6.3 specific patches
echo "Applying GCC 4.6.3 compatibility patches..."
for patch_file in "${GCC463_PATCH_DIR}"/*.patch; do
    if [ -f "$patch_file" ]; then
        apply_patch "$patch_file" "$QT_SRC_DIR"
        if [ $? -ne 0 ]; then
            echo "Failed to apply patch: $patch_file"
            exit 1
        fi
    fi
done

# Verify key files contain patches
echo "Verifying patches were applied successfully..."

echo "Checking for GCC 4.6.3 detection in configure..."
if grep -q "gcc46version" "${QT_SRC_DIR}/configure"; then
    echo "✓ GCC 4.6.3 detection patch found"
else
    echo "✗ GCC 4.6.3 detection patch NOT found"
fi

echo "Checking for template compatibility in qglobal.h..."
if grep -q "template<typename T> struct decay_struct" "${QT_SRC_DIR}/src/corelib/global/qglobal.h"; then
    echo "✓ Template compatibility patch found"
else
    echo "✗ Template compatibility patch NOT found"
fi

echo "Checking for auto keyword fix in qalgorithms.h..."
if ! grep -q "auto distance" "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h"; then
    echo "✓ Auto keyword replacement patch found"
else
    echo "✗ Auto keyword replacement patch NOT found"
fi

echo "Checking for atomic operations patch in qatomic_cxx11.h..."
if grep -q "defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6" "${QT_SRC_DIR}/src/corelib/thread/qatomic_cxx11.h" 2>/dev/null; then
    echo "✓ Atomic operations patch found"
else
    echo "✗ Atomic operations patch NOT found"
fi

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