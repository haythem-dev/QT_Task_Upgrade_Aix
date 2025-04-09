# Building Qt 5.15.0 on AIX with GCC 4.6.3

This guide provides step-by-step instructions to build Qt 5.15.0 on AIX 7.x with the GCC 4.6.3 compiler.

## Step 1: Prepare the Build Environment

Transfer these files to your AIX system in the same directory as qtbase-everywhere-src-5.15.0:

1. `build-qt515-aix-gcc463.sh` - Main build script
2. `apply_edit_patches.sh` - Script to apply patches using text editor commands
3. `patch_build.sh` - Alternative patch script using the patch command
4. `aix_compatibility_patches/` - Directory with all patch files

Make scripts executable:
```bash
chmod +x build-qt515-aix-gcc463.sh
chmod +x apply_edit_patches.sh
chmod +x patch_build.sh
```

## Step 2: Apply Compatibility Patches

The GCC 4.6.3 compiler lacks full C++11 support required by Qt 5.15.0. You need to apply patches to make Qt compatible.

Choose one of these patching methods:

### Option A: Using the standard patch command
```bash
./patch_build.sh
```

### Option B: Using text editor (ed) commands (more reliable on AIX)
```bash
./apply_edit_patches.sh
```

If both methods fail, you can manually modify these files:

1. **qtbase-everywhere-src-5.15.0/configure**
   - Add GCC 4.6.x detection around line 1030 (after the GCC 5.0 detection)
   - Add flags to disable C++11 features not supported by GCC 4.6.3

2. **qtbase-everywhere-src-5.15.0/src/corelib/global/qglobal.h**
   - Add compatibility layer for C++11 template alias features

3. **qtbase-everywhere-src-5.15.0/src/corelib/tools/qalgorithms.h**
   - Replace `const auto n = last - first;` with explicit type

4. **qtbase-everywhere-src-5.15.0/src/corelib/thread/qatomic_cxx11.h**
   - Add compatibility definitions for std::atomic operations

## Step 3: Run the Build

After applying patches, start the build process:

```bash
./build-qt515-aix-gcc463.sh
```

The build script:
1. Sets up the environment (OBJECT_MODE=64)
2. Configures Qt with reduced features
3. Builds Qt with reasonable parallelism (-j2)

## Step 4: Handling Build Errors

If you encounter build errors:

1. Check the error message to identify the file and problem
2. If it's a C++11 compatibility issue, create a targeted patch
3. Apply the patch and restart the build

Common errors include:
- Auto type deduction
- Lambda expressions
- Move semantics
- Variadic templates
- C++11 standard library features

## Step 5: Testing the Build

After a successful build, verify the installation:

```bash
cd /tmp
mkdir test-qt
cd test-qt

cat > test.cpp << 'EOT'
#include <QCoreApplication>
#include <QDebug>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    qDebug() << "Qt version:" << QT_VERSION_STR;
    qDebug() << "Build succeeded!";
    return 0;
}
EOT

/opt/qt-5.15.0/bin/qmake -project
/opt/qt-5.15.0/bin/qmake
make
./test
```