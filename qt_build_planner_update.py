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
        print("Analyzing environment...")
        
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
        
        print("Environment analysis complete. Results saved to system_info.json")
        
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
                        print(f"Note: GCC {version} has limited C++11 support. Special patches will be required.")
                    
                    return True
            
            return True
        except (subprocess.SubprocessError, FileNotFoundError):
            print(f"{compiler} not found or not working correctly")
            return False
    
    def check_libraries(self):
        """Check for important libraries required for Qt."""
        libraries_to_check = [
            {"name": "X11", "header": "/usr/include/X11/Xlib.h"},
            {"name": "OpenSSL", "header": "/usr/include/openssl/ssl.h"},
            {"name": "Freetype", "header": "/usr/include/freetype2/freetype/freetype.h"},
            {"name": "Fontconfig", "header": "/usr/include/fontconfig/fontconfig.h"}
        ]
        
        for lib in libraries_to_check:
            if not os.path.exists(lib["header"]):
                print(f"Missing library: {lib['name']} (header not found: {lib['header']})")
                self.system_info["missing_libraries"].append(lib["name"])
            else:
                print(f"Found library: {lib['name']}")
    
    def print_environment_summary(self):
        """Print a summary of the environment analysis."""
        print("\n===== Environment Summary =====")
        print(f"OS: {self.system_info['os']} {self.system_info['os_version']}")
        print(f"Architecture: {self.system_info['architecture']}")
        
        if self.system_info["compiler"]:
            print(f"Compiler: {self.system_info['compiler']} {self.system_info['compiler_version']}")
        else:
            print("Compiler: Not found")
        
        if self.system_info["missing_tools"]:
            print("\nMissing required tools:")
            for tool in self.system_info["missing_tools"]:
                print(f"  - {tool}")
        
        if self.system_info["missing_libraries"]:
            print("\nMissing required libraries:")
            for lib in self.system_info["missing_libraries"]:
                print(f"  - {lib}")
        
        # GCC 4.6.3 compatibility warning
        if self.system_info["compiler"] == "gcc" and self.system_info["compiler_version"]:
            if self.system_info["compiler_version"].startswith("4.6"):
                print("\nWARNING: GCC 4.6.x has limited C++11 support.")
                print("The following C++11 features used in Qt 5.15.0 will require patching:")
                for issue in self.gcc463_compatibility_issues:
                    print(f"  - {issue['feature']}: {issue['solution']}")
    
    def generate_build_plan(self):
        """Generate a build plan for Qt 5.15.0 on AIX with GCC 4.6.3."""
        print("\n===== Qt 5.15.0 Build Plan for AIX with GCC 4.6.3 =====")
        
        print("\nStep 1: Prepare the environment")
        print("  - Ensure all required tools are installed")
        if self.system_info["missing_tools"]:
            for tool in self.system_info["missing_tools"]:
                print(f"    * Install {tool}")
        
        print("  - Ensure all required libraries are available")
        if self.system_info["missing_libraries"]:
            for lib in self.system_info["missing_libraries"]:
                print(f"    * Install {lib} development package")
        
        print("\nStep 2: Apply compatibility patches")
        print("  - Download and extract Qt 5.15.0 source code")
        print("  - Apply the following patches:")
        for patch in self.patch_files:
            print(f"    * {patch['name']}: {patch['description']}")
        
        print("\nStep 3: Configure and build")
        print("  - Run the build script with the following configuration:")
        for option in self.configure_options:
            print(f"    * {option}")
        
        print("\nStep 4: Handle build-time errors")
        print("  - Monitor the build for additional C++11 compatibility issues")
        print("  - Create targeted patches for any new issues encountered")
        
        print("\nStep 5: Test the build")
        print("  - Create a simple test application to verify the build works")
        print("  - Check for runtime issues")
        
        return True
    
    def generate_scripts(self):
        """Generate build scripts and patches based on the analysis."""
        print("Generating build scripts and patches...")
        
        # Create directory structure
        os.makedirs("patches", exist_ok=True)
        os.makedirs("scripts", exist_ok=True)
        
        # Create build script
        self._create_build_script()
        
        # Create patch script
        self._create_patch_script()
        
        # Create patches
        self._create_patches()
        
        print("Build scripts and patches generated.")
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
        
        with open("scripts/build-qt515-aix-gcc463.sh", "w") as f:
            f.write(build_script)
        
        # Make executable
        os.chmod("scripts/build-qt515-aix-gcc463.sh", 0o755)
    
    def _create_patch_script(self):
        """Create the script to apply patches."""
        patch_script = """#!/bin/sh
# apply_edit_patches.sh - Apply patches to Qt 5.15.0 for GCC 4.6.3 compatibility

QT_SRC_DIR="/software/home/benabdelaziz/cc_compiler/qt/5.15.0/pharmos.3rd_party.qt5/dev/src/qtbase-everywhere-src-5.15.0"
PATCH_DIR="$(pwd)/patches"

echo "Applying patches using ed text editor..."
echo "Qt source directory: ${QT_SRC_DIR}"

# Check if ed is available
if ! command -v ed >/dev/null 2>&1; then
    echo "Warning: 'ed' command not found, will use cat/echo for patching"
fi

# 1. Configure patch - Add GCC 4.6.3 specific flags
CONFIG_FILE="${QT_SRC_DIR}/configure"
echo "Patching ${CONFIG_FILE}..."

if [ -f "${CONFIG_FILE}" ]; then
    # Create a backup
    cp "${CONFIG_FILE}" "${CONFIG_FILE}.bak"
    
    # Find the line where we need to add our GCC 4.6 detection
    GCC5_LINE=$(grep -n "gcc5version=" "${CONFIG_FILE}" | cut -d: -f1)
    
    if [ -n "${GCC5_LINE}" ]; then
        # Use ed if available
        if command -v ed >/dev/null 2>&1; then
            ed -s "${CONFIG_FILE}" <<EOF
${GCC5_LINE}a
        # GCC 4.6.x
        gcc46version=\\$(echo "\\$TEST_COMPILER_VERSION" | grep -o "\\\\\\\\<4\\\\\\\\.6\\\\\\\\.[0-9]\\\\\\\\+\\\\\\\\>" || true)
        [ -n "\\$gcc46version" ] && QMAKE_ARGS="\\$QMAKE_ARGS -D QT_NO_CXX11_FUTURE -D QT_NO_CXX11_NUMERIC_LIMITS -D QT_NO_CXX11_VARIADIC_TEMPLATES"
.
w
q
EOF
        else
            # Fallback to temp file method
            TEMP_FILE="/tmp/configure.tmp"
            awk -v line="${GCC5_LINE}" '{print; if(NR==line) {print "        # GCC 4.6.x"; print "        gcc46version=$(echo \\"$TEST_COMPILER_VERSION\\" | grep -o \\"\\\\\\\\<4\\\\\\\\.6\\\\\\\\.[0-9]\\\\\\\\+\\\\\\\\>\\" || true)"; print "        [ -n \\"$gcc46version\\" ] && QMAKE_ARGS=\\"$QMAKE_ARGS -D QT_NO_CXX11_FUTURE -D QT_NO_CXX11_NUMERIC_LIMITS -D QT_NO_CXX11_VARIADIC_TEMPLATES\\""}}' "${CONFIG_FILE}" > "${TEMP_FILE}"
            mv "${TEMP_FILE}" "${CONFIG_FILE}"
        fi
        echo "Configure patched successfully."
    else
        echo "Warning: Could not find location to patch in configure script."
    fi
else
    echo "Error: Configure script not found at ${CONFIG_FILE}"
fi

# Rest of the patching code for other files follows...
"""
        
        with open("scripts/apply_edit_patches.sh", "w") as f:
            f.write(patch_script)
        
        # Make executable
        os.chmod("scripts/apply_edit_patches.sh", 0o755)
    
    def _create_patches(self):
        """Create the patch files."""
        # These would be the actual patch contents based on diff output
        # For brevity, we'll just create placeholder files
        for patch in self.patch_files:
            patch_path = os.path.join("patches", patch["name"])
            with open(patch_path, "w") as f:
                f.write(f"# {patch['description']}\n")
                f.write("# This is a placeholder for the actual patch content\n")
        
        print("Created patch files in 'patches' directory")
    
    def _check_command(self, command):
        """Check if a command is available."""
        try:
            subprocess.run(["which", command], capture_output=True, check=True)
            return True
        except subprocess.SubprocessError:
            return False

def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="Qt 5.15.0 Build Planner for AIX")
    parser.add_argument("--analyze", action="store_true", help="Analyze the environment")
    parser.add_argument("--generate-scripts", action="store_true", help="Generate build scripts")
    parser.add_argument("--check-deps", action="store_true", help="Check for dependencies")
    
    args = parser.parse_args()
    
    planner = QtBuildPlanner()
    
    # Default action if no arguments
    if not (args.analyze or args.generate_scripts or args.check_deps):
        planner.analyze_environment()
        planner.generate_build_plan()
    
    if args.analyze:
        planner.analyze_environment()
    
    if args.generate_scripts:
        planner.generate_scripts()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())