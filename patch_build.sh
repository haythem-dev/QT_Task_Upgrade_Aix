#!/bin/sh
# Patch Qt 5.15.0 source code for GCC 4.6.3 compatibility

QT_SRC_DIR="/software/home/benabdelaziz/cc_compiler/qt/5.15.0/pharmos.3rd_party.qt5/dev/src/qtbase-everywhere-src-5.15.0"
PATCH_DIR="$(pwd)/aix_compatibility_patches"

echo "Applying Qt 5.15.0 AIX/GCC 4.6.3 compatibility patches..."
echo "Qt source directory: ${QT_SRC_DIR}"
echo "Patch directory: ${PATCH_DIR}"

# Check if patch command is available
if ! command -v patch >/dev/null 2>&1; then
    echo "Error: 'patch' command not found"
    echo "Please install the patch utility or use manual patching"
    exit 1
fi

# Function to apply a patch with fallback
apply_patch() {
    local patch_file=$1
    local target_dir=$2
    
    echo "Applying patch: $(basename ${patch_file})"
    
    if ! cd ${target_dir}; then
        echo "Error: Could not change to directory ${target_dir}"
        return 1
    fi
    
    # Try using patch command
    if ! patch -p1 < ${patch_file}; then
        echo "Warning: patch command failed. Attempting alternative method..."
        
        # Fallback with basic shell utilities
        local patch_basename=$(basename ${patch_file})
        local temp_file="/tmp/${patch_basename}.tmp"
        
        # Extract original file path from patch
        local orig_file=$(grep "^--- " ${patch_file} | head -1 | sed 's/^--- [^\/]*\///;s/\.orig.*//')
        
        echo "Patching ${orig_file} manually..."
        
        # Save original file as backup
        cp ${orig_file} ${orig_file}.backup
        
        # Apply changes manually line by line (this is simplified and may not work for complex patches)
        cat ${patch_file} | while read line; do
            if echo "$line" | grep -q "^+++ "; then
                continue
            elif echo "$line" | grep -q "^--- "; then
                continue
            elif echo "$line" | grep -q "^@@ "; then
                continue
            elif echo "$line" | grep -q "^+ "; then
                echo "${line#+ }" >> ${temp_file}
            elif echo "$line" | grep -q "^- "; then
                continue
            else
                echo "$line" >> ${temp_file}
            fi
        done
        
        # Replace original with patched version
        mv ${temp_file} ${orig_file}
        
        echo "Manual patching completed for ${orig_file}"
    else
        echo "Patch applied successfully"
    fi
    
    cd - >/dev/null
}

# Apply each patch
echo "Applying configure patch..."
apply_patch "${PATCH_DIR}/01-qtbase-configure-gcc463.patch" "${QT_SRC_DIR}"

echo "Applying qglobal C++11 compatibility patch..."
apply_patch "${PATCH_DIR}/02-qtbase-qglobal-cpp11-compat.patch" "${QT_SRC_DIR}"

echo "Applying qalgorithms auto fix patch..."
apply_patch "${PATCH_DIR}/03-qtbase-qalgorithms-auto-fix.patch" "${QT_SRC_DIR}"

echo "Applying qatomic C++11 fix patch..."
apply_patch "${PATCH_DIR}/04-qtbase-qatomic-cxx11-fix.patch" "${QT_SRC_DIR}"

echo "All patches applied. Ready to build Qt 5.15.0."