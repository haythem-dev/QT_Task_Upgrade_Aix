#!/usr/bin/env python3
"""
Qt 5.15.0 Build Planner for AIX 7.2 on PowerPC POWER9
====================================================

This tool helps to:
1. Analyze your AIX environment
2. Determine requirements for building Qt 5.15.0 with GCC 4.6.3
3. Generate a build plan
4. Create necessary scripts and patches for the build process

Usage:
    python qt_build_planner.py [--analyze] [--generate-scripts] [--check-deps]
"""

import os
import sys
import argparse
import platform
import subprocess
import json
from pathlib import Path

def bold(text):
    """Return text in bold ANSI formatting."""
    return f"\033[1m{text}\033[0m"

def red(text):
    """Return text in red ANSI formatting."""
    return f"\033[91m{text}\033[0m"

def green(text):
    """Return text in green ANSI formatting."""
    return f"\033[92m{text}\033[0m"

def yellow(text):
    """Return text in yellow ANSI formatting."""
    return f"\033[93m{text}\033[0m"

class QtBuildPlanner:
    def __init__(self):
        """Initialize the build planner."""
        self.system_info = {
            "os": platform.system(),
            "os_version": platform.version(),
            "architecture": platform.machine(),
            "compiler": None,
            "compiler_version": None,
            "missing_libraries": [],
            "missing_tools": []
        }
        
        # AIX specific configuration
        self.aix_platform_config = {
            "qmake_conf_path": "mkspecs/aix-g++/qmake.conf",
            "qplatformdefs_path": "mkspecs/aix-g++/qplatformdefs.h"
        }
        
        # Build paths
        self.build_paths = {
            "source_dir": "/software/home/benabdelaziz/cc_compiler/qt/5.15.0/pharmos.3rd_party.qt5/dev/src/qtbase-everywhere-src-5.15.0",
            "install_dir": "/opt/qt-5.15.0"
        }
        
        # GCC 4.6.3 compatibility issues
        self.gcc463_compatibility_issues = [
            {"feature": "auto keyword", 
             "example": "const auto n = last - first;", 
             "solution": "Replace with explicit type: const qptrdiff n = last - first;"},
            {"feature": "template aliases", 
             "example": "template<typename T> using decay_t = typename decay<T>::type;", 
             "solution": "Add compatibility layer in std namespace for missing template aliases"},
            {"feature": "atomic operations", 
             "example": "std::atomic_load_explicit(ptr, order)", 
             "solution": "Provide simpler versions using #define macros"},
            {"feature": "lambda expressions", 
             "example": "[]() { return 0; }", 
             "solution": "Refactor to use traditional functors where needed"},
            {"feature": "nullptr keyword", 
             "example": "return nullptr;", 
             "solution": "Replace with NULL or 0 where compatibility is an issue"}
        ]
        
        self.patch_files = [
            {"name": "01-qtbase-configure-gcc463.patch", 
             "description": "Adds GCC 4.6.3 detection to the configure script"},
            {"name": "02-qtbase-qglobal-cpp11-compat.patch", 
             "description": "Adds C++11 compatibility layer to qglobal.h"},
            {"name": "03-qtbase-qalgorithms-auto-fix.patch", 
             "description": "Replaces auto keyword usage in qalgorithms.h"},
            {"name": "04-qtbase-qatomic-cxx11-fix.patch", 
             "description": "Fixes atomic operations for GCC 4.6.3"}
        ]
        
        # Configure options optimized for AIX with GCC 4.6.3
        self.configure_options = [
            "-prefix /opt/qt-5.15.0",
            "-platform aix-g++",
            "-release",
            "-opensource",
            "-confirm-license",
            "-no-feature-c++14",
            "-no-feature-c++17",
            "-no-feature-thread_local",
            "-no-feature-renameat2",
            "-no-feature-getentropy",
            "-no-feature-clock-gettime",
            "-no-feature-ffmpeg",
            "-no-feature-glib",
            "-no-feature-sse2",
            "-no-feature-system-doubleconversion",
            "-no-opengl",
            "-no-vulkan",
            "-no-sql-sqlite",
            "-no-dbus",
            "-no-glib",
            "-qt-zlib",
            "-qt-libpng",
            "-qt-libjpeg",
            "-qt-freetype",
            "-qt-harfbuzz",
            "-qt-pcre",
            "-no-fontconfig",
            "-nomake examples",
            "-nomake tests",
            "-verbose"
        ]
        
    def analyze_environment(self):
        """Analyze the AIX environment and collect system information."""
        print(bold("Analyzing environment..."))
        
        # Check compiler
        self.check_compiler("gcc")
        self.check_compiler("g++")
        
        # Check for important tools
        for tool in ["make", "grep", "sed", "patch", "perl"]:
            if not self._check_command(tool):
                self.system_info["missing_tools"].append(tool)
        
        # Check libraries
        self.check_libraries()
        
        # Save system info to file
        with open("system_info.json", "w") as f:
            json.dump(self.system_info, f, indent=2)
        
        print(bold("Environment analysis complete. Results saved to system_info.json"))
        
        # Print summary
        self.print_environment_summary()
        
        return self.system_info
    
    def check_compiler(self, compiler):
        """Check if a compiler is available and get its version."""
        print(f"Checking for {compiler}...")
        
        try:
            result = subprocess.run([compiler, "--version"], 
                                     capture_output=True, text=True, check=True)
            output = result.stdout.strip()
            
            # Extract version from output
            # GCC version output typically contains version in first line
            first_line = output.split('\n')[0]
            
            if compiler == "gcc":
                self.system_info["compiler"] = "gcc"
                
                # Try to extract version number
                import re
                version_match = re.search(r'(\d+\.\d+\.\d+)', first_line)
                if version_match:
                    version = version_match.group(1)
                    self.system_info["compiler_version"] = version
                    print(f"Found {compiler} version {version}")
                    
                    # Warn specifically about GCC 4.6.3 compatibility
                    if version.startswith("4.6"):
                        print(yellow(f"Note: GCC {version} has limited C++11 support. Special patches will be required."))
                    
                    return True
            
            return True
        except (subprocess.SubprocessError, FileNotFoundError):
            print(red(f"{compiler} not found or not working correctly"))
            return False
    
    def check_libraries(self):
        """Check for important libraries required for Qt."""
        print(bold("Checking for required libraries..."))
        
        libraries_to_check = [
            {"name": "X11", "header": "/usr/include/X11/Xlib.h"},
            {"name": "OpenSSL", "header": "/usr/include/openssl/ssl.h"},
            {"name": "Freetype", "header": "/usr/include/freetype2/freetype/freetype.h"},
            {"name": "Fontconfig", "header": "/usr/include/fontconfig/fontconfig.h"}
        ]
        
        for lib in libraries_to_check:
            if not os.path.exists(lib["header"]):
                print(red(f"Missing library: {lib['name']} (header not found: {lib['header']})"))
                self.system_info["missing_libraries"].append(lib["name"])
            else:
                print(green(f"Found library: {lib['name']}"))
    
    def print_environment_summary(self):
        """Print a summary of the environment analysis."""
        print(bold("\n===== Environment Summary ====="))
        print(f"OS: {self.system_info['os']} {self.system_info['os_version']}")
        print(f"Architecture: {self.system_info['architecture']}")
        
        if self.system_info["compiler"]:
            print(f"Compiler: {self.system_info['compiler']} {self.system_info['compiler_version']}")
        else:
            print(red("Compiler: Not found"))
        
        if self.system_info["missing_tools"]:
            print(red("\nMissing required tools:"))
            for tool in self.system_info["missing_tools"]:
                print(f"  - {tool}")
        else:
            print(green("\nAll required tools are available."))
        
        if self.system_info["missing_libraries"]:
            print(red("\nMissing required libraries:"))
            for lib in self.system_info["missing_libraries"]:
                print(f"  - {lib}")
        else:
            print(green("\nAll required libraries are available."))
        
        # GCC 4.6.3 compatibility warning
        if self.system_info["compiler"] == "gcc" and self.system_info["compiler_version"]:
            if self.system_info["compiler_version"].startswith("4.6"):
                print(yellow("\nWARNING: GCC 4.6.x has limited C++11 support."))
                print("The following C++11 features used in Qt 5.15.0 will require patching:")
                for issue in self.gcc463_compatibility_issues:
                    print(f"  - {issue['feature']}: {issue['solution']}")
    
    def generate_build_plan(self):
        """Generate a build plan for Qt 5.15.0 on AIX with GCC 4.6.3."""
        print(bold("\n===== Qt 5.15.0 Build Plan for AIX with GCC 4.6.3 ====="))
        
        print(bold("\nStep 1: Prepare the environment"))
        print("  - Ensure all required tools are installed")
        if self.system_info["missing_tools"]:
            for tool in self.system_info["missing_tools"]:
                print(red(f"    * Install {tool}"))
        
        print("  - Ensure all required libraries are available")
        if self.system_info["missing_libraries"]:
            for lib in self.system_info["missing_libraries"]:
                print(red(f"    * Install {lib} development package"))
        
        print(bold("\nStep 2: Apply compatibility patches"))
        print("  - Download and extract Qt 5.15.0 source code")
        print("  - Apply the following patches:")
        for patch in self.patch_files:
            print(f"    * {patch['name']}: {patch['description']}")
        
        print(bold("\nStep 3: Configure and build"))
        print("  - Run the build script with the following configuration:")
        for option in self.configure_options:
            print(f"    * {option}")
        
        print(bold("\nStep 4: Handle build-time errors"))
        print("  - Monitor the build for additional C++11 compatibility issues")
        print("  - Create targeted patches for any new issues encountered")
        
        print(bold("\nStep 5: Test the build"))
        print("  - Create a simple test application to verify the build works")
        print("  - Check for runtime issues")
        
        return True
    
    def generate_scripts(self):
        """Generate build scripts and patches based on the analysis."""
        print(bold("Generating build scripts and patches..."))
        
        # Create directory structure
        os.makedirs("patches", exist_ok=True)
        os.makedirs("scripts", exist_ok=True)
        
        # Create build script
        self._create_build_script()
        
        # Create patch script
        self._create_patch_script()
        
        # Create patches
        self._create_patches()
        
        print(green("Build scripts and patches generated."))
        return True
    
    def _create_build_script(self):
        """Create the main build script."""
        build_script = """#!/bin/sh
# build-qt515-aix-gcc463.sh - Build Qt 5.15.0 for AIX with GCC 4.6.3

# Exit on error
set -e

# Base directory paths
BASE_DIR="/software/home/benabdelaziz/cc_compiler/qt/5.15.0/pharmos.3rd_party.qt5/dev/src"
QT_SRC_DIR="${BASE_DIR}/qtbase-everywhere-src-5.15.0"
CONFIGURE_PATH="${QT_SRC_DIR}/configure"

echo "Starting Qt 5.15.0 build process..."
echo "Base directory: ${BASE_DIR}"
echo "Qt source directory: ${QT_SRC_DIR}"
echo "Configure path: ${CONFIGURE_PATH}"

# Configure environment
export OBJECT_MODE=64
export PATH=${QT_SRC_DIR}/bin:$PATH

# Create install directory
mkdir -p /opt/qt-5.15.0

echo "Configuring qtbase with reduced features..."
cd "${QT_SRC_DIR}"

# Explicitly check for the configure script
if [ ! -f "${CONFIGURE_PATH}" ]; then
    echo "Error: configure script not found at ${CONFIGURE_PATH}"
    echo "Contents of Qt source directory:"
    ls -la "${QT_SRC_DIR}"
    exit 1
fi

# Make sure configure is executable
chmod +x "${CONFIGURE_PATH}"

# Run configure with full path
"${CONFIGURE_PATH}" \\
"""
        
        # Add configure options
        for option in self.configure_options:
            build_script += f"    {option} \\\n"
        
        # Remove trailing backslash and newline
        build_script = build_script.rstrip("\\\n")
        
        # Add build commands
        build_script += """

# If configure succeeds, attempt to build
echo "Building qtbase..."
make -j2

echo "Qt 5.15.0 build process completed. Check for any errors in the output."
"""
        
        with open("build-qt515-aix-gcc463.sh", "w") as f:
            f.write(build_script)
        
        # Make executable
        os.chmod("build-qt515-aix-gcc463.sh", 0o755)
        
        print(green("Created build-qt515-aix-gcc463.sh"))
    
    def _create_patch_script(self):
        """Create the script to apply patches."""
        patch_script = """#!/bin/sh
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
exit 0"""
        
        with open("apply_edit_patches.sh", "w") as f:
            f.write(patch_script)
        
        # Make executable
        os.chmod("apply_edit_patches.sh", 0o755)
        
        print(green("Created apply_edit_patches.sh"))
    
    def _create_patches(self):
        """Create the patch files."""
        # These would be the actual patch contents based on diff output
        # For brevity, we'll just create placeholder files
        os.makedirs("aix_compatibility_patches", exist_ok=True)
        
        for patch in self.patch_files:
            patch_path = os.path.join("aix_compatibility_patches", patch["name"])
            with open(patch_path, "w") as f:
                f.write(f"# {patch['description']}\n")
                f.write("# This is a placeholder for the actual patch content\n")
        
        print(green("Created patch files in 'aix_compatibility_patches' directory"))
    
    def _check_command(self, command):
        """Check if a command is available."""
        try:
            subprocess.run(["which", command], capture_output=True, check=True)
            print(green(f"Found required tool: {command}"))
            return True
        except subprocess.SubprocessError:
            print(red(f"Missing required tool: {command}"))
            return False
    
    def display_help(self):
        """Display help information."""
        print(bold("Qt 5.15.0 Build Planner for AIX 7.2 with GCC 4.6.3"))
        print("This tool helps prepare your environment for building Qt 5.15.0 on AIX.")
        print("\nAvailable commands:")
        print("  --analyze         Analyze your environment for compatibility")
        print("  --generate-scripts Generate build scripts and patches")
        print("  --check-deps      Check for dependencies")
        print("\nExample usage:")
        print("  python3 qt_build_planner.py --analyze")

def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="Qt 5.15.0 Build Planner for AIX")
    parser.add_argument("--analyze", action="store_true", help="Analyze the environment")
    parser.add_argument("--generate-scripts", action="store_true", help="Generate build scripts")
    parser.add_argument("--check-deps", action="store_true", help="Check for dependencies")
    
    args = parser.parse_args()
    
    planner = QtBuildPlanner()
    
    if len(sys.argv) == 1:
        # No arguments, show welcome message and help
        print(bold("Qt 5.15.0 Build Planner for AIX 7.2 with GCC 4.6.3"))
        print("This tool helps you prepare for building Qt 5.15.0 on AIX systems.")
        print("Use --analyze to start environment analysis.")
        planner.display_help()
        return 0
    
    if args.analyze:
        planner.analyze_environment()
        planner.generate_build_plan()
    
    if args.generate_scripts:
        planner.generate_scripts()
    
    if args.check_deps:
        planner.check_compiler("gcc")
        planner.check_libraries()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())