# Qt 5.15.0 Build for AIX 7.x with GCC 4.6.3

This repository contains scripts and patches to build Qt 5.15.0 on AIX 7.x systems with the older GCC 4.6.3 compiler.

## Prerequisites

- AIX 7.x operating system
- GCC 4.6.3 compiler
- X11 development headers
- OpenSSL development headers
- Sufficient disk space (at least 10GB)
- Sufficient memory (at least 4GB)

## Build Steps

1. Transfer the following files to your AIX system:
   - `build-qt515-aix-gcc463.sh`
   - All patch files from the `patches` directory

2. Make the build script executable:
   ```
   chmod +x build-qt515-aix-gcc463.sh
   ```

3. Run the build script from the directory containing `qtbase-everywhere-src-5.15.0`:
   ```
   ./build-qt515-aix-gcc463.sh
   ```

4. Monitor the build process for errors.

## Common Issues and Solutions

### If configure fails to find:

- Make sure the configure script is executable:
  ```
  chmod +x qtbase-everywhere-src-5.15.0/configure
  ```

### If compilation fails with C++11 feature errors:

These errors are expected because GCC 4.6.3 lacks full C++11 support. Apply the patches from the `patches` directory:

```
patch -p1 < /path/to/patches/01-qtbase-aix-gcc463-compatibility.patch
patch -p1 < /path/to/patches/02-qtbase-gcc463-cpp11-compat.patch
patch -p1 < /path/to/patches/03-qtbase-gcc463-modern-syntax.patch
```

If you encounter additional C++11 compatibility issues:

1. Note the file and line number from the error
2. Create a targeted patch for that specific file
3. Apply the patch and restart the build

## Testing the Build

Once built, you can test Qt with a simple application:

```cpp
// test.cpp
#include <QCoreApplication>
#include <QDebug>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    qDebug() << "Qt version:" << QT_VERSION_STR;
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