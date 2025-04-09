#!/bin/sh
# Alternative method to apply patches using ed (text editor) scripts
# This is useful if the 'patch' command fails or isn't available

QT_SRC_DIR="/software/home/benabdelaziz/cc_compiler/qt/5.15.0/pharmos.3rd_party.qt5/dev/src/qtbase-everywhere-src-5.15.0"

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
        gcc46version=\$(echo "\$TEST_COMPILER_VERSION" | grep -o "\\\\<4\\\\.6\\\\.[0-9]\\\\+\\\\>" || true)
        [ -n "\$gcc46version" ] && QMAKE_ARGS="\$QMAKE_ARGS -D QT_NO_CXX11_FUTURE -D QT_NO_CXX11_NUMERIC_LIMITS -D QT_NO_CXX11_VARIADIC_TEMPLATES"
.
w
q
EOF
        else
            # Fallback to temp file method
            TEMP_FILE="/tmp/configure.tmp"
            awk -v line="${GCC5_LINE}" '{print; if(NR==line) {print "        # GCC 4.6.x"; print "        gcc46version=$(echo \"$TEST_COMPILER_VERSION\" | grep -o \"\\\\<4\\\\.6\\\\.[0-9]\\\\+\\\\>\" || true)"; print "        [ -n \"$gcc46version\" ] && QMAKE_ARGS=\"$QMAKE_ARGS -D QT_NO_CXX11_FUTURE -D QT_NO_CXX11_NUMERIC_LIMITS -D QT_NO_CXX11_VARIADIC_TEMPLATES\""}}' "${CONFIG_FILE}" > "${TEMP_FILE}"
            mv "${TEMP_FILE}" "${CONFIG_FILE}"
        fi
        echo "Configure patched successfully."
    else
        echo "Warning: Could not find location to patch in configure script."
    fi
else
    echo "Error: Configure script not found at ${CONFIG_FILE}"
fi

# 2. qglobal.h patch - Add C++11 compatibility layer
QGLOBAL_FILE="${QT_SRC_DIR}/src/corelib/global/qglobal.h"
echo "Patching ${QGLOBAL_FILE}..."

if [ -f "${QGLOBAL_FILE}" ]; then
    # Create a backup
    cp "${QGLOBAL_FILE}" "${QGLOBAL_FILE}.bak"
    
    # Find the line where we need to add our compatibility layer
    INCLUDE_LINE=$(grep -n "#endif" "${QGLOBAL_FILE}" | grep -A1 "defined(__MINGW64_VERSION_MAJOR)" | head -1 | cut -d: -f1)
    
    if [ -n "${INCLUDE_LINE}" ]; then
        # Use ed if available
        if command -v ed >/dev/null 2>&1; then
            ed -s "${QGLOBAL_FILE}" <<EOF
${INCLUDE_LINE}a

// GCC 4.6.3 compatibility - define missing C++11 features
#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6
namespace std {
    template<typename T> using decay_t = typename decay<T>::type;
    template<bool B, typename T = void> using enable_if_t = typename enable_if<B, T>::type;
    template<typename T> using remove_cv_t = typename remove_cv<T>::type;
    template<typename T> using remove_reference_t = typename remove_reference<T>::type;
    template<typename T> using add_const_t = typename add_const<T>::type;
    template<typename T> using add_volatile_t = typename add_volatile<T>::type;
    template<typename T> using add_cv_t = typename add_cv<T>::type;
}
#endif
.
w
q
EOF
        else
            # Fallback to temp file method
            TEMP_FILE="/tmp/qglobal.tmp"
            awk -v line="${INCLUDE_LINE}" '{print; if(NR==line) {print "\n// GCC 4.6.3 compatibility - define missing C++11 features"; print "#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6"; print "namespace std {"; print "    template<typename T> using decay_t = typename decay<T>::type;"; print "    template<bool B, typename T = void> using enable_if_t = typename enable_if<B, T>::type;"; print "    template<typename T> using remove_cv_t = typename remove_cv<T>::type;"; print "    template<typename T> using remove_reference_t = typename remove_reference<T>::type;"; print "    template<typename T> using add_const_t = typename add_const<T>::type;"; print "    template<typename T> using add_volatile_t = typename add_volatile<T>::type;"; print "    template<typename T> using add_cv_t = typename add_cv<T>::type;"; print "}"; print "#endif"}}' "${QGLOBAL_FILE}" > "${TEMP_FILE}"
            mv "${TEMP_FILE}" "${QGLOBAL_FILE}"
        fi
        echo "qglobal.h patched successfully."
    else
        echo "Warning: Could not find location to patch in qglobal.h."
    fi
else
    echo "Error: qglobal.h not found at ${QGLOBAL_FILE}"
fi

# 3. qalgorithms.h patch - Fix 'auto' usage
QALGORITHMS_FILE="${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h"
echo "Patching ${QALGORITHMS_FILE}..."

if [ -f "${QALGORITHMS_FILE}" ]; then
    # Create a backup
    cp "${QALGORITHMS_FILE}" "${QALGORITHMS_FILE}.bak"
    
    # Replace 'const auto n = last - first;' with conditional version
    sed -i.bak 's/const auto n = last - first;/#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6\n    const qptrdiff n = last - first;\n#else\n    const auto n = last - first;\n#endif/' "${QALGORITHMS_FILE}"
    
    echo "qalgorithms.h patched successfully."
else
    echo "Error: qalgorithms.h not found at ${QALGORITHMS_FILE}"
fi

# 4. qatomic_cxx11.h patch - Fix C++11 atomics
QATOMIC_FILE="${QT_SRC_DIR}/src/corelib/thread/qatomic_cxx11.h"
echo "Patching ${QATOMIC_FILE}..."

if [ -f "${QATOMIC_FILE}" ]; then
    # Create a backup
    cp "${QATOMIC_FILE}" "${QATOMIC_FILE}.bak"
    
    # Add compatibility definitions for std::atomic operations
    INCLUDE_LINE=$(grep -n "#include <cstddef>" "${QATOMIC_FILE}" | cut -d: -f1)
    
    if [ -n "${INCLUDE_LINE}" ]; then
        # Use ed if available
        if command -v ed >/dev/null 2>&1; then
            ed -s "${QATOMIC_FILE}" <<EOF
${INCLUDE_LINE}a

// GCC 4.6.3 compatibility - older GCC doesn't have std::atomic_*_explicit
#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6
#define QT_ATOMIC_STORE(type, ptr, val, order) std::atomic_store(ptr, val)
#define QT_ATOMIC_LOAD(type, ptr, order) std::atomic_load(ptr)
#define QT_ATOMIC_FETCH_OP(op, type, ptr, val, order) std::atomic_fetch_##op(ptr, val)
#else
.
w
q
EOF
        else
            # Fallback to temp file method
            TEMP_FILE="/tmp/qatomic.tmp"
            awk -v line="${INCLUDE_LINE}" '{print; if(NR==line) {print "\n// GCC 4.6.3 compatibility - older GCC doesn\'t have std::atomic_*_explicit"; print "#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6"; print "#define QT_ATOMIC_STORE(type, ptr, val, order) std::atomic_store(ptr, val)"; print "#define QT_ATOMIC_LOAD(type, ptr, order) std::atomic_load(ptr)"; print "#define QT_ATOMIC_FETCH_OP(op, type, ptr, val, order) std::atomic_fetch_##op(ptr, val)"; print "#else"}}' "${QATOMIC_FILE}" > "${TEMP_FILE}"
            mv "${TEMP_FILE}" "${QATOMIC_FILE}"
        fi
        
        # Add endif after QT_ATOMIC_FETCH_OP definition
        ENDIF_LINE=$(grep -n "QT_ATOMIC_FETCH_OP" "${QATOMIC_FILE}" | grep -v "defined" | cut -d: -f1)
        if [ -n "${ENDIF_LINE}" ]; then
            ENDIF_LINE=$((ENDIF_LINE + 1))
            ed -s "${QATOMIC_FILE}" <<EOF
${ENDIF_LINE}a
#endif
.
w
q
EOF
        fi
        
        # Fix operator=
        OPERATOR_LINE=$(grep -n "Type operator=" "${QATOMIC_FILE}" | head -1 | cut -d: -f1)
        STORE_LINE=$(grep -n "store(desired);" "${QATOMIC_FILE}" | head -1 | cut -d: -f1)
        
        if [ -n "${OPERATOR_LINE}" ] && [ -n "${STORE_LINE}" ]; then
            STORE_LINE=$((STORE_LINE - 1))
            ed -s "${QATOMIC_FILE}" <<EOF
${STORE_LINE}c
#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6
            // Simple assignment for GCC 4.6.3
            a = desired;
            return desired;
#else
.
w
q
EOF
            RETURN_LINE=$(grep -n "return desired;" "${QATOMIC_FILE}" | head -1 | cut -d: -f1)
            if [ -n "${RETURN_LINE}" ]; then
                RETURN_LINE=$((RETURN_LINE + 1))
                ed -s "${QATOMIC_FILE}" <<EOF
${RETURN_LINE}a
#endif
.
w
q
EOF
            fi
        fi
        
        echo "qatomic_cxx11.h patched successfully."
    else
        echo "Warning: Could not find location to patch in qatomic_cxx11.h."
    fi
else
    echo "Error: qatomic_cxx11.h not found at ${QATOMIC_FILE}"
fi

echo "All patches applied. Ready to build Qt 5.15.0."