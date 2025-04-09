#!/bin/sh
# apply_edit_patches.sh - Apply patches to Qt 5.15.0 for GCC 4.6.3 compatibility

QT_SRC_DIR="/software/home/benabdelaziz/cc_compiler/qt/5.15.0/pharmos.3rd_party.qt5/dev/src/qtbase-everywhere-src-5.15.0"
PATCH_DIR="$(pwd)/aix_compatibility_patches"

echo "Applying patches using ed text editor..."
echo "Qt source directory: ${QT_SRC_DIR}"
echo "Patch directory: ${PATCH_DIR}"

# Check if ed is available
if ! command -v ed >/dev/null 2>&1; then
    echo "Warning: 'ed' command not found, will use sed for patching"
    USE_SED=1
else
    USE_SED=0
fi

# Apply patches function
apply_patch() {
    local patch_file="$1"
    local target_dir="$2"
    
    echo "Applying patch: $patch_file"
    
    # Check if patch file exists
    if [ ! -f "$patch_file" ]; then
        echo "Error: Patch file not found: $patch_file"
        return 1
    fi
    
    # Extract target file from patch
    local target_file=$(grep "^+++ " "$patch_file" | head -1 | sed 's|^+++ ./||' | sed 's|^+++ b/||')
    if [ -z "$target_file" ]; then
        echo "Error: Could not determine target file from patch"
        return 1
    fi
    
    local full_target_path="${target_dir}/${target_file}"
    echo "Target file: $full_target_path"
    
    # Check if target file exists
    if [ ! -f "$full_target_path" ]; then
        echo "Error: Target file not found: $full_target_path"
        return 1
    fi
    
    # Create backup
    cp "$full_target_path" "${full_target_path}.bak"
    
    # Apply the patch
    if [ $USE_SED -eq 1 ]; then
        # Using sed for patching
        # This is a simplified approach and may not work for complex patches
        # Extract hunks and apply them one by one
        csplit -f "$patch_file.hunk." "$patch_file" '/^@@/' '{*}' > /dev/null
        
        for hunk_file in "$patch_file.hunk."*; do
            if [ -f "$hunk_file" ]; then
                # Extract line number
                line_info=$(grep "^@@" "$hunk_file" | head -1)
                start_line=$(echo "$line_info" | grep -o -- "-[0-9]*" | head -1 | cut -c2-)
                
                if [ -n "$start_line" ]; then
                    # Extract content to add (lines starting with +)
                    add_content=$(grep "^+" "$hunk_file" | sed 's/^+//' | grep -v "^+++ ")
                    
                    # Extract content to remove (lines starting with -)
                    remove_content=$(grep "^-" "$hunk_file" | sed 's/^-//' | grep -v "^--- ")
                    
                    # Remove lines first
                    for line in $remove_content; do
                        sed -i.tmp "${start_line}s|${line}||g" "$full_target_path"
                        rm -f "${full_target_path}.tmp"
                    done
                    
                    # Then add new lines
                    if [ -n "$add_content" ]; then
                        sed -i.tmp "${start_line}a\\
${add_content}" "$full_target_path"
                        rm -f "${full_target_path}.tmp"
                    fi
                fi
                
                rm -f "$hunk_file"
            fi
        done
    else
        # Using patch command
        (cd "$target_dir" && patch -p1 < "$patch_file")
    fi
    
    echo "Patch applied to $target_file"
    return 0
}

# Apply all patches
for patch_file in "${PATCH_DIR}"/*.patch; do
    if [ -f "$patch_file" ]; then
        apply_patch "$patch_file" "$QT_SRC_DIR"
        if [ $? -ne 0 ]; then
            echo "Failed to apply patch: $patch_file"
            exit 1
        fi
    fi
done

echo "All patches applied successfully!"
exit 0