# Qt 5.15.0 AIX Build Scripts

These scripts are designed to fix common build issues when building Qt 5.15.0 on AIX with GCC 4.6.3.

## The Issue

The error you encountered (`./configure: not found`) is likely caused by one of these issues:
1. The configure script doesn't exist in the expected location
2. The configure script exists but isn't executable
3. The script is trying to run configure from the wrong path

## Included Scripts

### 1. aix_build_fix.sh

This is an improved version of the original aix_build.sh script that:
- Detects the current directory
- Verifies the configure script exists
- Makes the configure script executable
- Uses the full path to the configure script

**Usage:**
```bash
# Run from inside the qtbase-everywhere-src-5.15.0_patched directory
cd /software/home/benabdelaziz/cc_compiler/qt/5.15.0/pharmos.3rd_party.qt5/dev/src/qtbase-everywhere-src-5.15.0_patched
chmod +x aix_build_fix.sh
./aix_build_fix.sh
```

### 2. simple_aix_build.sh

This script uses a hardcoded absolute path to the configure script, which you should modify to match your environment. This approach is more robust when the script is run from a different directory.

**Before using:**
1. Edit the script to update the `QT_SRC_DIR` variable to match your environment
2. Save the changes

**Usage:**
```bash
# Can be run from any directory
chmod +x simple_aix_build.sh
./simple_aix_build.sh
```

## Troubleshooting Common Issues

If you still encounter issues:

1. **Check file permissions:**
   ```bash
   ls -la /path/to/qtbase-everywhere-src-5.15.0_patched/configure
   chmod +x /path/to/qtbase-everywhere-src-5.15.0_patched/configure
   ```

2. **Check if the file exists:**
   ```bash
   find /software/home/benabdelaziz/cc_compiler/qt/5.15.0 -name configure
   ```

3. **Check line endings:**
   AIX can be sensitive to non-Unix line endings. You may need to convert Windows-style (CRLF) line endings to Unix-style (LF):
   ```bash
   dos2unix /path/to/aix_build.sh
   dos2unix /path/to/configure
   ```

4. **Execute configure directly:**
   Try running the configure script directly to see if it works:
   ```bash
   cd /software/home/benabdelaziz/cc_compiler/qt/5.15.0/pharmos.3rd_party.qt5/dev/src/qtbase-everywhere-src-5.15.0_patched
   ./configure -help
   ```

## Additional Notes

- Your AIX build environment might require specific environment variables beyond what's set in these scripts
- The troubleshooting_guide.md file includes more detailed solutions for other common build issues
- If you get other errors during the build process, please refer to the troubleshooting guide