#!/usr/bin/env python
"""
Qt 5.15.0 Build Planner for AIX 7.2 on PowerPC POWER9
====================================================

This tool helps to:
1. Analyze your AIX environment
2. Determine requirements for building Qt 5.15.0
3. Generate a build plan
4. Create necessary scripts for the build process

Usage:
    python qt_build_planner.py [--analyze] [--generate-scripts] [--check-deps]
"""

import os
import sys
import subprocess
import platform
import re
import json
from datetime import datetime
import argparse

class QtBuildPlanner:
    def __init__(self):
        self.system_info = {}
        self.qt_version = "5.15.0"
        self.qt_source_url = "https://download.qt.io/archive/qt/5.15/5.15.0/single/qt-everywhere-src-5.15.0.tar.xz"
        self.dependencies = {
            "required": [
                "gcc/g++", "make", "perl", "libGL", "libX11", "libXext", 
                "fontconfig", "freetype", "openssl", "zlib", "libjpeg",
                "libpng", "libicu", "glib2", "dbus"
            ],
            "optional": [
                "sqlite", "mysql", "postgresql", "pulseaudio", "alsa",
                "cups", "gstreamer", "libtiff", "libwebp"
            ]
        }
        
        self.aix_specifics = {
            "compiler_versions": ["gcc 8.3+", "xlC 16.1+"],
            "patches_needed": ["AIX shared library handling", "PowerPC qatomic", "AIX platform detection"],
            "build_flags": ["-qpic", "-q64", "-qmaxmem=-1", "-bnoquiet"]
        }
        
    def analyze_environment(self):
        """Analyze the AIX environment and collect system information"""
        print("\n--- Analyzing AIX Environment ---\n")
        
        # Get OS version
        try:
            oslevel = subprocess.check_output(["oslevel", "-s"]).decode().strip()
            self.system_info["os_version"] = oslevel
            print(f"AIX Version: {oslevel}")
        except Exception as e:
            print(f"Error getting OS version: {e}")
            self.system_info["os_version"] = "Unknown"
        
        # Get processor information
        try:
            uname_output = subprocess.check_output(["uname", "-a"]).decode().strip()
            self.system_info["uname"] = uname_output
            print(f"System: {uname_output}")
            
            prtconf = subprocess.Popen(["prtconf"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            prtconf_output, _ = prtconf.communicate()
            prtconf_output = prtconf_output.decode().strip()
            
            processor_type_match = re.search(r"Processor Type: (.+)", prtconf_output)
            if processor_type_match:
                self.system_info["processor_type"] = processor_type_match.group(1)
                print(f"Processor Type: {self.system_info['processor_type']}")
                
            processor_impl_match = re.search(r"Processor Implementation Mode: (.+)", prtconf_output)
            if processor_impl_match:
                self.system_info["processor_impl"] = processor_impl_match.group(1)
                print(f"Processor Implementation: {self.system_info['processor_impl']}")
        except Exception as e:
            print(f"Error getting processor information: {e}")
            self.system_info["processor_type"] = "Unknown"
        
        # Get memory information
        try:
            lparstat = subprocess.Popen(["lparstat", "-i"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            lparstat_output, _ = lparstat.communicate()
            lparstat_output = lparstat_output.decode().strip()
            
            memory_match = re.search(r"Online Memory\s+: (\d+) MB", lparstat_output)
            if memory_match:
                self.system_info["memory"] = f"{memory_match.group(1)} MB"
                print(f"Memory: {self.system_info['memory']}")
                
            vcpu_match = re.search(r"Online Virtual CPUs\s+: (\d+)", lparstat_output)
            if vcpu_match:
                self.system_info["vcpus"] = vcpu_match.group(1)
                print(f"Virtual CPUs: {self.system_info['vcpus']}")
        except Exception as e:
            print(f"Error getting memory information: {e}")
            self.system_info["memory"] = "Unknown"
            
        # Check compilers
        self.check_compiler("xlc_r")
        self.check_compiler("xlC_r")
        self.check_compiler("gcc")
        self.check_compiler("g++")
        
        # Check for important libraries
        self.check_libraries()
        
        return self.system_info
    
    def check_compiler(self, compiler):
        """Check if a compiler is available and get its version"""
        try:
            version_flag = "-qversion" if compiler.startswith("xl") else "--version"
            output = subprocess.check_output([compiler, version_flag], stderr=subprocess.STDOUT).decode().strip()
            version_line = output.split('\n')[0] if '\n' in output else output
            self.system_info[f"{compiler}_version"] = version_line
            print(f"{compiler}: {version_line}")
        except Exception:
            self.system_info[f"{compiler}_version"] = "Not found"
            print(f"{compiler}: Not found")
    
    def check_libraries(self):
        """Check for important libraries required for Qt"""
        libraries = {
            "OpenSSL": {"command": "openssl version", "pattern": r"OpenSSL\s+([\d\.]+[a-z]*)"},
            "X11": {"path": "/usr/include/X11/Xlib.h", "type": "header"},
            "fontconfig": {"path": "/usr/include/fontconfig/fontconfig.h", "type": "header"},
            "freetype": {"path": "/usr/include/freetype2/ft2build.h", "type": "header"},
            "zlib": {"path": "/usr/include/zlib.h", "type": "header"},
            "libpng": {"path": "/usr/include/libpng.h", "type": "header"}
        }
        
        self.system_info["libraries"] = {}
        print("\n--- Checking for Qt dependencies ---")
        
        for lib_name, lib_info in libraries.items():
            if lib_info.get("type") == "header":
                if os.path.exists(lib_info["path"]):
                    self.system_info["libraries"][lib_name] = "Found"
                    print(f"{lib_name}: Found ({lib_info['path']})")
                else:
                    self.system_info["libraries"][lib_name] = "Not found"
                    print(f"{lib_name}: Not found (looking for {lib_info['path']})")
            elif "command" in lib_info:
                try:
                    output = subprocess.check_output(lib_info["command"].split(), stderr=subprocess.STDOUT).decode().strip()
                    if "pattern" in lib_info:
                        match = re.search(lib_info["pattern"], output)
                        if match:
                            version = match.group(1)
                            self.system_info["libraries"][lib_name] = version
                            print(f"{lib_name}: {version}")
                        else:
                            self.system_info["libraries"][lib_name] = "Found (unknown version)"
                            print(f"{lib_name}: Found (unknown version)")
                    else:
                        self.system_info["libraries"][lib_name] = "Found"
                        print(f"{lib_name}: Found")
                except Exception:
                    self.system_info["libraries"][lib_name] = "Not found"
                    print(f"{lib_name}: Not found")
                    
    def generate_build_plan(self):
        """Generate a build plan for Qt 5.15.0 on AIX"""
        print("\n--- Qt 5.15.0 Build Plan for AIX 7.2 ---\n")
        
        # Recommended compiler
        recommended_compiler = "xlC_r" if self.system_info.get("xlC_r_version", "Not found") != "Not found" else "g++"
        
        print(f"1. Recommended compiler: {recommended_compiler}")
        print("   - IBM XL C/C++ provides better optimization for POWER architecture")
        print("   - GCC 8.3+ is also supported and may have better C++17 compliance")
        
        # Configure options
        print("\n2. Recommended Qt configure options:")
        configure_options = [
            "-prefix /opt/qt-5.15.0",
            "-opensource",
            "-confirm-license",
            "-release",
            f"-platform aix-{recommended_compiler.replace('+', 'xx')}-64" if recommended_compiler == "g++" else "-platform aix-xlc-64",
            "-nomake examples",
            "-nomake tests",
            "-no-opengl",  # AIX doesn't support desktop OpenGL well, use -opengl es2 if needed
            "-qt-xcb",
            "-qt-zlib",
            "-qt-libpng",
            "-qt-libjpeg",
            "-qt-freetype",
            "-qt-pcre",
            "-dbus",
            "-openssl",
            "-optimize-size"  # Better for AIX environments
        ]
        
        for option in configure_options:
            print(f"   {option}")
            
        # Pre-build requirements
        print("\n3. Pre-build requirements:")
        missing_libs = []
        for lib, status in self.system_info.get("libraries", {}).items():
            if status == "Not found":
                missing_libs.append(lib)
                
        if missing_libs:
            print("   The following dependencies need to be installed:")
            for lib in missing_libs:
                print(f"   - {lib}")
        else:
            print("   All checked libraries appear to be available.")
            
        print("\n   Additional dependencies to verify:")
        for dep in self.dependencies["required"]:
            if dep not in self.system_info.get("libraries", {}):
                print(f"   - {dep}")
                
        # Patches needed
        print("\n4. Required patches for AIX compatibility:")
        patches = [
            "Fix shared library handling (AIX uses .a files containing shared objects)",
            "Platform-specific atomic operations for PowerPC",
            "AIX-specific filesystem and process handling",
            "Proper RPATH handling for AIX"
        ]
        for patch in patches:
            print(f"   - {patch}")
            
        # Build process outline
        print("\n5. Build process outline:")
        print("   a. Download and extract Qt 5.15.0 source")
        print("   b. Apply AIX-specific patches")
        print("   c. Configure Qt with appropriate options")
        print("   d. Build with make -j4 (based on your 4 vCPUs)")
        print("   e. Install to prefix directory")
        print("   f. Update PATH and environment variables")
        
        # Post-build verification
        print("\n6. Post-build verification:")
        print("   - Check the bin directory for Qt tools (qmake, moc, etc.)")
        print("   - Run a simple Qt application compilation test")
        print("   - Verify dynamic libraries with 'dump -H' command")
        print("   - Test Qt modules functionality")
        
        return {
            "compiler": recommended_compiler,
            "configure_options": configure_options,
            "patches_needed": patches,
            "missing_libraries": missing_libs
        }
        
    def generate_scripts(self):
        """Generate build scripts based on the analysis"""
        build_plan = self.generate_build_plan()
        
        # Create prepare_environment.sh
        with open("scripts/prepare_environment.sh", "w") as f:
            f.write("""#!/bin/sh
# Prepare environment for building Qt 5.15.0 on AIX 7.2
# Generated by Qt Build Planner

# Exit on error
set -e

echo "=== Preparing environment for Qt 5.15.0 build ==="

# Create build directory
mkdir -p qt-build
cd qt-build

# Download Qt source if not present
if [ ! -f qt-everywhere-src-5.15.0.tar.xz ]; then
    echo "Downloading Qt 5.15.0 source..."
    curl -L -o qt-everywhere-src-5.15.0.tar.xz https://download.qt.io/archive/qt/5.15/5.15.0/single/qt-everywhere-src-5.15.0.tar.xz
fi

# Extract source if not already extracted
if [ ! -d qt-everywhere-src-5.15.0 ]; then
    echo "Extracting Qt 5.15.0 source..."
    tar -xf qt-everywhere-src-5.15.0.tar.xz
fi

# Apply patches
echo "Applying AIX-specific patches..."
cd qt-everywhere-src-5.15.0
patch -p1 < ../../patches/qt-5.15.0-aix-fixes.patch

# Return to build directory
cd ..

echo "Environment preparation complete."
echo "Now run build_qt.sh to configure and build Qt."
""")

        # Create build_qt.sh with the recommended configuration
        with open("scripts/build_qt.sh", "w") as f:
            f.write(f"""#!/bin/sh
# Build Qt 5.15.0 on AIX 7.2
# Generated by Qt Build Planner

# Exit on error
set -e

# Number of CPU cores for parallel build
MAKE_JOBS=4

echo "=== Building Qt 5.15.0 for AIX 7.2 ==="

# Go to build directory
cd qt-build

# Enter source directory
cd qt-everywhere-src-5.15.0

# Set up environment for the build
export OBJECT_MODE=64
export QTDIR=$(pwd)
export PATH=$QTDIR/qtbase/bin:$PATH

# Configure Qt with optimal settings for AIX
echo "Configuring Qt 5.15.0..."
./configure \\
    " \\\n    ".join(build_plan['configure_options'])

# Start the build
echo "Building Qt 5.15.0 (this will take several hours)..."
make -j$MAKE_JOBS

# Install Qt to the prefix directory
echo "Installing Qt 5.15.0..."
make install

echo "Build and installation completed!"
echo "Please run verify_build.sh to check the installation."
""")

        # Create verify_build.sh
        with open("scripts/verify_build.sh", "w") as f:
            f.write("""#!/bin/sh
# Verify Qt 5.15.0 build on AIX 7.2
# Generated by Qt Build Planner

# Exit on error
set -e

QT_DIR="/opt/qt-5.15.0"  # Adjust to match your prefix

echo "=== Verifying Qt 5.15.0 installation ==="

# Check for key binaries
echo "Checking for Qt executables..."
for bin in qmake moc rcc uic lrelease lupdate; do
    if [ -x "$QT_DIR/bin/$bin" ]; then
        echo "✓ $bin found"
    else
        echo "✗ $bin missing"
    fi
done

# Check qmake version
echo -e "\nChecking qmake version:"
$QT_DIR/bin/qmake --version

# Create a simple Qt test program
echo -e "\nCreating test Qt application..."
mkdir -p qt-test
cd qt-test

cat > main.cpp << 'EOT'
#include <QApplication>
#include <QLabel>
#include <QDebug>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    
    qDebug() << "Qt version:" << qVersion();
    qDebug() << "Build ABI:" << QSysInfo::buildAbi();
    qDebug() << "Current CPU architecture:" << QSysInfo::currentCpuArchitecture();
    
    QLabel label("Hello Qt on AIX!");
    label.resize(320, 240);
    label.show();
    
    return app.exec();
}
EOT

cat > qt-test.pro << 'EOT'
QT += core gui widgets
TARGET = qt-test
TEMPLATE = app
SOURCES += main.cpp
EOT

# Build the test app
echo "Building test application..."
$QT_DIR/bin/qmake
make

# Check if build was successful
if [ -x "qt-test" ]; then
    echo -e "\n✓ Test application built successfully"
    echo "You can run ./qt-test to test the application"
else
    echo -e "\n✗ Test application build failed"
fi

echo -e "\nVerification completed!"
""")

        # Make scripts executable
        for script in ["scripts/prepare_environment.sh", "scripts/build_qt.sh", "scripts/verify_build.sh"]:
            try:
                os.chmod(script, 0o755)
            except:
                print(f"Could not set executable permission on {script}")
                
        print("\nBuild scripts have been generated in the 'scripts' directory:")
        print("- prepare_environment.sh: Download Qt source and apply patches")
        print("- build_qt.sh: Configure and build Qt with optimal settings")
        print("- verify_build.sh: Verify the Qt installation")

def main():
    # Create directories if they don't exist
    for directory in ["patches", "config", "scripts"]:
        if not os.path.exists(directory):
            os.makedirs(directory)
            
    parser = argparse.ArgumentParser(description='Qt 5.15.0 Build Planner for AIX 7.2')
    parser.add_argument('--analyze', action='store_true', help='Analyze the AIX environment')
    parser.add_argument('--generate-scripts', action='store_true', help='Generate build scripts')
    parser.add_argument('--check-deps', action='store_true', help='Check for Qt dependencies')
    
    args = parser.parse_args()
    
    planner = QtBuildPlanner()
    
    if args.analyze or not any(vars(args).values()):
        planner.analyze_environment()
        
    if args.check_deps or not any(vars(args).values()):
        print("\n=== Qt 5.15.0 Dependencies ===")
        print("\nRequired dependencies:")
        for dep in planner.dependencies["required"]:
            print(f"- {dep}")
        print("\nOptional dependencies:")
        for dep in planner.dependencies["optional"]:
            print(f"- {dep}")
            
    if args.generate_scripts or not any(vars(args).values()):
        planner.generate_scripts()
    
    # Save system info to a file
    with open('system_info.json', 'w') as f:
        json.dump(planner.system_info, f, indent=2)
    
    print(f"\nSystem information saved to system_info.json")
    print("\nTo build Qt 5.15.0 on AIX 7.2:")
    print("1. Review the generated scripts in the 'scripts' directory")
    print("2. Run scripts/prepare_environment.sh to prepare the build environment")
    print("3. Run scripts/build_qt.sh to configure and build Qt")
    print("4. Run scripts/verify_build.sh to verify the installation")

if __name__ == "__main__":
    main()
