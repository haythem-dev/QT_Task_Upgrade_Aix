# Troubleshooting Guide for Qt 5.15.0 on AIX with GCC 4.6.3

This guide covers common issues encountered when building Qt 5.15.0 on AIX 7.2 using GCC 4.6.3, with specific focus on C++11 compatibility problems and their solutions.

## Configure Phase Issues

### Problem: Configure script fails to detect compiler
**Error message:** "No compiler can be deduced for AIX"

**Solution:**
- Ensure GCC 4.6.3 is in your PATH: `which gcc`
- Set OBJECT_MODE=64 environment variable:
  ```
  export OBJECT_MODE=64
  ```
- Check if compiler executable has correct permissions:
  ```
  chmod +x $(which gcc)
  chmod +x $(which g++)
  ```

### Problem: Configure script cannot find X11
**Error message:** "X11/Xlib.h: No such file or directory"

**Solution:**
- Install X11 development package:
  ```
  installp -acXgd . X11.adt.include
  ```
- Specify X11 include path manually:
  ```
  ./configure -I/usr/include/X11
  ```

### Problem: Configure detects wrong compiler version
**Error message:** "Detected unsupported GCC" or no GCC 4.6.3 specific options

**Solution:**
- Apply the 01-qtbase-configure-gcc463.patch to add explicit detection
- If still not detecting, add manual compiler detection to configure script:
  ```
  gcc46version=$(echo "$TEST_COMPILER_VERSION" | grep -o "\\<4\\.6\\.[0-9]\\+\\>" || true)
  [ -n "$gcc46version" ] && QMAKE_ARGS="$QMAKE_ARGS -D QT_NO_CXX11_FUTURE -D QT_NO_CXX11_NUMERIC_LIMITS -D QT_NO_CXX11_VARIADIC_TEMPLATES"
  ```

## Compilation Issues

### Problem: C++11 'auto' keyword errors
**Error message:** "error: 'auto' does not name a type" or "error: unable to deduce 'auto' type"

**Affected files:**
- qalgorithms.h
- qstringlist.h
- various template implementations

**Solution:**
- Apply the 03-qtbase-qalgorithms-auto-fix.patch 
- For files not covered by existing patches, manually replace auto with explicit types:
  ```diff
  - auto distance = end - begin;
  + qptrdiff distance = end - begin;  // or another appropriate type
  ```
- For more complex cases, analyze the context to determine the correct type

### Problem: Template alias ('using') errors
**Error message:** "error: template aliases are not allowed in C++98 mode" or "'using' cannot name a type in C++98"

**Affected files:**
- qglobal.h 
- various template implementation files

**Solution:**
- Apply the 02-qtbase-qglobal-cpp11-compat.patch to add compatibility layer
- For new instances, add typedef equivalents:
  ```diff
  - template<typename T> using decay_t = typename decay<T>::type;
  + template<typename T> struct decay_struct { typedef typename decay<T>::type type; };
  + template<typename T> struct decay_t : public decay_struct<T>::type { };
  ```

### Problem: Memory ordering in atomics
**Error message:** "error: 'memory_order_relaxed' is not a member of 'std'" or "error: no member named 'atomic_..._explicit'"

**Affected files:**
- qatomic_cxx11.h
- concurrent threading code

**Solution:**
- Apply the 04-qtbase-qatomic-cxx11-fix.patch
- For additional atomic issues, add compatibility macros:
  ```c++
  #if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6
  #define atomic_load_explicit(ptr, order) atomic_load(ptr)
  // (additional macros as needed)
  #endif
  ```

### Problem: nullptr issues
**Error message:** "error: 'nullptr' was not declared in this scope"

**Solution:**
- Apply the 02-qtbase-qglobal-cpp11-compat.patch which includes:
  ```c++
  #if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6
  # ifndef nullptr
  #  include <cstddef>
  #  define nullptr NULL
  # endif
  #endif
  ```
- If still encountering issues, replace `nullptr` with `NULL` or `0` in specific contexts

### Problem: Lambda expression errors
**Error message:** "error: lambda expressions are not allowed in C++98 mode" or errors with capture clauses

**Solution:**
- For simple lambdas, convert to traditional function objects or functors
- For lambdas that capture variables, create a proper functor class

## Linking Issues

### Problem: Missing template instantiations
**Error message:** "undefined reference to [template function]"

**Solution:**
- Add explicit template instantiations in .cpp files
- Use the -fno-implicit-templates compiler flag with caution (may increase code size)

### Problem: Symbol visibility issues
**Error message:** "undefined symbol" or "symbol not found"

**Solution:**
- Remove -fvisibility-inlines-hidden flag (done in 02-qtbase-qglobal-cpp11-compat.patch)
- Add visibility attributes explicitly where needed
- Check -maix64 flag is properly set

### Problem: Library path issues
**Error message:** "cannot find -lX11" or other -l linking errors

**Solution:**
- Add explicit library paths to build-qt515-aix-gcc463.sh:
  ```
  export LIBPATH=$LIBPATH:/usr/lib:/lib:/usr/X11R6/lib
  ```
- Verify that all dependencies are properly installed

## Runtime Issues

### Problem: Symbol resolution errors on application startup
**Error message:** "Symbol resolution failed for ..." or "Could not load shared library"

**Solution:**
- Check LIBPATH environment variable
- Ensure binary compatibility (32-bit vs 64-bit)
- Set OBJECT_MODE=64 before running the application
- Use `dump -H` to examine binary dependencies

### Problem: Crashes in atomic operations
**Error message:** "Program terminated with signal SIGSEGV" in atomic code

**Solution:**
- Ensure 04-qtbase-qatomic-cxx11-fix.patch is applied
- Add memory barriers explicitly for AIX:
  ```c++
  asm volatile("" ::: "memory");    // Lightweight barrier
  ```
- For severe issues, consider disabling thread support during configure

## Advanced Troubleshooting

### Analyzing Build Failures

1. Save the full build log:
   ```
   ./build-qt515-aix-gcc463.sh > build.log 2>&1
   ```

2. Search for specific error patterns:
   ```
   grep -A 5 "error:" build.log
   ```

3. Identify common C++11 features causing problems:
   ```
   grep -n "auto\|nullptr\|using.*=\|atomic_\|constexpr\|noexcept\|decltype" build.log
   ```

4. Create targeted patches based on the error pattern and existing patches

### Memory-Limited Environments

If your AIX system has limited memory:

1. Reduce parallel build jobs:
   ```
   make -j1
   ```

2. Build only essential modules:
   ```
   ./configure -submodules=qtbase
   ```

3. Use minimal debug information:
   ```
   QMAKE_CXXFLAGS += -g1
   ```

4. Consider applying patches in smaller batches to avoid memory-intensive processes

### Extracting Diagnostic Information

For persistent issues, gather this information:

1. System details:
   ```
   oslevel -s
   lparstat -i
   ```

2. Compiler details:
   ```
   gcc -v
   g++ -v
   ```

3. Library information:
   ```
   dump -H /path/to/problematic/library.so
   ```

4. Core dump analysis (if available):
   ```
   dbx -a core.file
   ```

This detailed information will help pinpoint compatibility issues specific to your environment.