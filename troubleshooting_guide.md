# Troubleshooting Guide: Building Qt 5.15.0 on AIX with GCC 4.6.3

This guide provides solutions for common issues you might encounter when building Qt 5.15.0 on AIX with GCC 4.6.3.

## Configure Script Issues

### Problem: "configure: not found"
```
./build-qt515-aix-gcc463.sh[30]: ./configure: not found.
```

**Solution:**
1. Check if the configure script exists:
   ```
   ls -la qtbase-everywhere-src-5.15.0/configure
   ```

2. If it exists but isn't executable:
   ```
   chmod +x qtbase-everywhere-src-5.15.0/configure
   ```

3. If it doesn't exist, you may need to extract the Qt source again.

## Compilation Errors

### Problem: C++11 Features Not Supported

When you see errors like:
```
error: 'auto' does not name a type
```

**Solution:**
Create a patch that replaces `auto` with explicit types:

```cpp
// Original code
const auto n = last - first;

// Replace with:
const qptrdiff n = last - first;  // or appropriate type
```

### Problem: Lambda Expressions

When you see errors related to lambda expressions:

**Solution:**
Replace lambdas with traditional functors:

```cpp
// Original code with lambda
std::sort(begin, end, [](const Item& a, const Item& b) {
    return a.key < b.key;
});

// Replace with functor
struct ItemComparator {
    bool operator()(const Item& a, const Item& b) const {
        return a.key < b.key;
    }
};
std::sort(begin, end, ItemComparator());
```

### Problem: Template Errors

When you see errors about C++11 template features:

**Solution:**
Add compatibility code to provide equivalent functionality:

```cpp
// Add to a header file (like in qglobal.h):
#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6
namespace std {
    template<typename T> using decay_t = typename decay<T>::type;
    template<bool B, typename T = void> using enable_if_t = typename enable_if<B, T>::type;
    template<typename T> using remove_cv_t = typename remove_cv<T>::type;
}
#endif
```

## Build System Issues

### Problem: Memory Errors

If you see memory-related errors:

**Solution:**
1. Reduce parallel jobs:
   ```
   make -j1
   ```

2. Increase AIX paging space if possible.

### Problem: Linker Errors

With errors about undefined symbols:

**Solution:**
Check library paths and add any missing dependencies:

```
export LIBPATH=/opt/freeware/lib:/usr/lib:$LIBPATH
```

## Qt-Specific Issues

### Problem: Platform Detection Errors

If Qt fails to recognize AIX properly:

**Solution:**
Check and update platform detection in:
- qtbase-everywhere-src-5.15.0/mkspecs/aix-g++/qmake.conf
- qtbase-everywhere-src-5.15.0/mkspecs/aix-g++/qplatformdefs.h

## Creating Emergency Patches

If all else fails, and you need to skip problematic code:

### For non-essential features:

```cpp
// Original code
QSomeClass::complexFeature() {
    // Complex C++11 code
}

// Patch to disable feature
QSomeClass::complexFeature() {
    qWarning() << "Feature not available with GCC 4.6.3";
    return; // or appropriate fallback value
}
```

## Debugging Build Failures

For hard-to-diagnose failures:
```bash
# Add verbose output
make VERBOSE=1

# Inspect preprocessor output for a specific file
g++ -E src/file.cpp -o file.preprocessed
```