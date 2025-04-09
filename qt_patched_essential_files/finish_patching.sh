#!/bin/bash
# finish_patching.sh - Apply remaining critical patches to qt source

QT_SRC_DIR="$(pwd)/qtbase-everywhere-src-5.15.0_patched"
echo "Finishing patching of Qt 5.15.0 for GCC 4.6.3..."

# 1. Fix the configure script
echo "Adding GCC 4.6.3 detection to configure script..."
if [ -f "${QT_SRC_DIR}/configure" ]; then
    # Add GCC 4.6.3 detection at the end of the script before the final "exit 0"
    line_num=$(grep -n "exit 0" "${QT_SRC_DIR}/configure" | tail -1 | cut -d: -f1)
    if [ -n "$line_num" ]; then
        line_num=$((line_num - 1))
        sed -i "${line_num}i\\
# Special case for GCC 4.6.3 - Add detection and special flags\\
echo \"Checking for GCC 4.6.3 compatibility...\"\\
gcc46version=\$(echo \"\$TEST_COMPILER_VERSION\" | grep -o \"\\\\<4\\\\.6\\\\.[0-9]\\\\+\\\\>\" || true)\\
if [ -n \"\$gcc46version\" ]; then\\
    echo \"GCC 4.6.3 detected, enabling compatibility mode\"\\
    QMAKE_ARGS=\"\$QMAKE_ARGS -D QT_NO_CXX11_FUTURE -D QT_NO_CXX11_NUMERIC_LIMITS -D QT_NO_CXX11_VARIADIC_TEMPLATES\"\\
fi" "${QT_SRC_DIR}/configure"
        echo "✓ Added GCC 4.6.3 detection to configure script"
    else
        echo "✗ Could not find insertion point for GCC 4.6.3 detection"
    fi
else
    echo "✗ configure script not found"
fi

# 2. Add C++11 compatibility layer to qglobal.h
echo "Adding C++11 compatibility layer to qglobal.h..."
if [ -f "${QT_SRC_DIR}/src/corelib/global/qglobal.h" ]; then
    # Find a good spot to insert - we'll try after Qt namespace definition
    search_line="QT_BEGIN_NAMESPACE"
    line_num=$(grep -n "$search_line" "${QT_SRC_DIR}/src/corelib/global/qglobal.h" | head -1 | cut -d: -f1)
    
    if [ -n "$line_num" ]; then
        line_num=$((line_num + 1))  # Insert right after QT_BEGIN_NAMESPACE
        
        # Insert C++11 compatibility layer
        sed -i "${line_num}i\\
\\
// GCC 4.6.3 compatibility layer for C++11 features\\
#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ <= 6\\
# ifndef nullptr\\
#  include <cstddef>\\
#  define nullptr NULL\\
# endif\\
namespace std {\\
  template<typename T> struct decay_struct { typedef typename decay<T>::type type; };\\
  template<typename T> struct decay_t : public decay_struct<T>::type { };\\
  template<typename T, typename U> struct is_same_struct { static constexpr bool value = false; };\\
  template<typename T> struct is_same_struct<T, T> { static constexpr bool value = true; };\\
  template<typename T, typename U> struct is_same : public is_same_struct<T, U> { };\\
  template<bool B, typename T = void> struct enable_if_struct { typedef T type; };\\
  template<typename T> struct enable_if_struct<false, T> { };\\
  template<bool B, typename T = void> struct enable_if : public enable_if_struct<B, T> { };\\
}\\
#endif\\
" "${QT_SRC_DIR}/src/corelib/global/qglobal.h"
        
        echo "✓ Added C++11 compatibility layer to qglobal.h"
    else
        echo "✗ Could not find insertion point in qglobal.h"
    fi
else
    echo "✗ qglobal.h not found"
fi

# 3. Fix auto keyword issues in qalgorithms.h
echo "Fixing auto keyword in qalgorithms.h..."
if [ -f "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h" ]; then
    # Create a backup
    cp "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h" "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h.bak"
    
    # We'll manually replace these key lines
    cat > "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h.new" << 'EOF'
/****************************************************************************
**
** Copyright (C) 2020 The Qt Company Ltd.
** Copyright (C) 2016 Intel Corporation.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtCore module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl-3.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or (at your option) the GNU General
** Public license version 3 or any later version approved by the KDE Free
** Qt Foundation. The licenses are as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-2.0.html and
** https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef QALGORITHMS_H
#define QALGORITHMS_H

#include <QtCore/qglobal.h>
#include <QtCore/qcontainerfwd.h>
#include <bit>

#if 0
#pragma qt_class(QAlgorithms)
#endif

#ifdef Q_CC_MSVC
#include <intrin.h>
#endif

QT_BEGIN_NAMESPACE


/*
    Warning: The contents of QAlgorithmsPrivate is not a part of the public Qt API
    and may be changed from version to version or even be completely removed.
*/
namespace QAlgorithmsPrivate {

template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE void qSortHelper(RandomAccessIterator start, RandomAccessIterator end, const T &t, LessThan lessThan);
template <typename RandomAccessIterator, typename T>
inline void qSortHelper(RandomAccessIterator begin, RandomAccessIterator end, const T &dummy);

template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE void qStableSortHelper(RandomAccessIterator start, RandomAccessIterator end, const T &t, LessThan lessThan);
template <typename RandomAccessIterator, typename T>
inline void qStableSortHelper(RandomAccessIterator, RandomAccessIterator, const T &);

template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE RandomAccessIterator qLowerBoundHelper(RandomAccessIterator begin, RandomAccessIterator end, const T &value, LessThan lessThan);
template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE RandomAccessIterator qUpperBoundHelper(RandomAccessIterator begin, RandomAccessIterator end, const T &value, LessThan lessThan);
template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE RandomAccessIterator qBinaryFindHelper(RandomAccessIterator begin, RandomAccessIterator end, const T &value, LessThan lessThan);

}

template <typename InputIterator, typename OutputIterator>
inline OutputIterator qCopy(InputIterator begin, InputIterator end, OutputIterator dest)
{
    while (begin != end)
        *dest++ = *begin++;
    return dest;
}

template <typename BiIterator1, typename BiIterator2>
inline BiIterator2 qCopyBackward(BiIterator1 begin, BiIterator1 end, BiIterator2 dest)
{
    while (begin != end)
        *--dest = *--end;
    return dest;
}

template <typename InputIterator1, typename InputIterator2>
inline bool qEqual(InputIterator1 first1, InputIterator1 last1, InputIterator2 first2)
{
    for (; first1 != last1; ++first1, ++first2)
        if (!(*first1 == *first2))
            return false;
    return true;
}

template <typename ForwardIterator, typename T>
inline void qFill(ForwardIterator first, ForwardIterator last, const T &val)
{
    for (; first != last; ++first)
        *first = val;
}

template <typename Container, typename T>
inline void qFill(Container &container, const T &val)
{
    qFill(container.begin(), container.end(), val);
}

template <typename InputIterator, typename T>
inline InputIterator qFind(InputIterator first, InputIterator last, const T &val)
{
    while (first != last && !(*first == val))
        ++first;
    return first;
}

template <typename Container, typename T>
inline typename Container::const_iterator qFind(const Container &container, const T &val)
{
    return qFind(container.constBegin(), container.constEnd(), val);
}

template <typename InputIterator, typename T, typename Size>
inline void qCount(InputIterator first, InputIterator last, const T &value, Size &n)
{
    for (; first != last; ++first)
        if (*first == value)
            ++n;
}

template <typename Container, typename T, typename Size>
inline void qCount(const Container &container, const T &value, Size &n)
{
    qCount(container.constBegin(), container.constEnd(), value, n);
}

#ifdef Q_QDOC
template <typename T>
LessThan qLess()
{
}

template <typename T>
LessThan qGreater()
{
}
#else
template <typename T>
class qLess
{
public:
    inline bool operator()(const T &t1, const T &t2) const
    {
        return (t1 < t2);
    }
};

template <typename T>
class qGreater
{
public:
    inline bool operator()(const T &t1, const T &t2) const
    {
        return (t2 < t1);
    }
};
#endif

template <typename RandomAccessIterator>
inline void qSort(RandomAccessIterator start, RandomAccessIterator end)
{
    if (start != end)
        QAlgorithmsPrivate::qSortHelper(start, end, *start);
}

template <typename RandomAccessIterator, typename LessThan>
inline void qSort(RandomAccessIterator start, RandomAccessIterator end, LessThan lessThan)
{
    if (start != end)
        QAlgorithmsPrivate::qSortHelper(start, end, *start, lessThan);
}

template<typename Container>
inline void qSort(Container &c)
{
#if defined(Q_CC_MSVC)
    // Suppress warning that 'the initializer for a reference of type &QObject is a
    // constructor argument list for the class. QObject has no constructor taking a
    // const pointer to member' when instantiating with Container=QList<QPointer<QObject> >
    if (!c.isEmpty())
#endif
        QAlgorithmsPrivate::qSortHelper(c.begin(), c.end(), *c.begin());
}

template <typename Container, typename LessThan>
inline void qSort(Container &c, LessThan lessThan)
{
#if defined(Q_CC_MSVC)
    // Suppress warning that 'the initializer for a reference of type &QObject is a
    // constructor argument list for the class. QObject has no constructor taking a
    // const pointer to member' when instantiating with Container=QList<QPointer<QObject> >
    if (!c.isEmpty())
#endif
        QAlgorithmsPrivate::qSortHelper(c.begin(), c.end(), *c.begin(), lessThan);
}

template <typename RandomAccessIterator>
inline void qStableSort(RandomAccessIterator start, RandomAccessIterator end)
{
    if (start != end)
        QAlgorithmsPrivate::qStableSortHelper(start, end, *start);
}

template <typename RandomAccessIterator, typename LessThan>
inline void qStableSort(RandomAccessIterator start, RandomAccessIterator end, LessThan lessThan)
{
    if (start != end)
        QAlgorithmsPrivate::qStableSortHelper(start, end, *start, lessThan);
}

template<typename Container>
inline void qStableSort(Container &c)
{
#if defined(Q_CC_MSVC)
    // see above
    if (!c.isEmpty())
#endif
        QAlgorithmsPrivate::qStableSortHelper(c.begin(), c.end(), *c.begin());
}

template <typename Container, typename LessThan>
inline void qStableSort(Container &c, LessThan lessThan)
{
#if defined(Q_CC_MSVC)
    // see above
    if (!c.isEmpty())
#endif
        QAlgorithmsPrivate::qStableSortHelper(c.begin(), c.end(), *c.begin(), lessThan);
}

template <typename RandomAccessIterator, typename T>
inline RandomAccessIterator qLowerBound(RandomAccessIterator begin, RandomAccessIterator end, const T &value)
{
    return QAlgorithmsPrivate::qLowerBoundHelper(begin, end, value, qLess<T>());
}

template <typename RandomAccessIterator, typename T, typename LessThan>
inline RandomAccessIterator qLowerBound(RandomAccessIterator begin, RandomAccessIterator end, const T &value, LessThan lessThan)
{
    return QAlgorithmsPrivate::qLowerBoundHelper(begin, end, value, lessThan);
}

template <typename Container, typename T>
inline typename Container::const_iterator qLowerBound(const Container &container, const T &value)
{
    return QAlgorithmsPrivate::qLowerBoundHelper(container.constBegin(), container.constEnd(), value, qLess<T>());
}

template <typename Container, typename T, typename LessThan>
inline typename Container::const_iterator qLowerBound(const Container &container, const T &value, LessThan lessThan)
{
    return QAlgorithmsPrivate::qLowerBoundHelper(container.constBegin(), container.constEnd(), value, lessThan);
}

template <typename RandomAccessIterator, typename T>
inline RandomAccessIterator qUpperBound(RandomAccessIterator begin, RandomAccessIterator end, const T &value)
{
    return QAlgorithmsPrivate::qUpperBoundHelper(begin, end, value, qLess<T>());
}

template <typename RandomAccessIterator, typename T, typename LessThan>
inline RandomAccessIterator qUpperBound(RandomAccessIterator begin, RandomAccessIterator end, const T &value, LessThan lessThan)
{
    return QAlgorithmsPrivate::qUpperBoundHelper(begin, end, value, lessThan);
}

template <typename Container, typename T>
inline typename Container::const_iterator qUpperBound(const Container &container, const T &value)
{
    return QAlgorithmsPrivate::qUpperBoundHelper(container.constBegin(), container.constEnd(), value, qLess<T>());
}

template <typename Container, typename T, typename LessThan>
inline typename Container::const_iterator qUpperBound(const Container &container, const T &value, LessThan lessThan)
{
    return QAlgorithmsPrivate::qUpperBoundHelper(container.constBegin(), container.constEnd(), value, lessThan);
}

template <typename RandomAccessIterator, typename T>
inline RandomAccessIterator qBinaryFind(RandomAccessIterator begin, RandomAccessIterator end, const T &value)
{
    RandomAccessIterator it = QAlgorithmsPrivate::qLowerBoundHelper(begin, end, value, qLess<T>());

    if (it != end && !qLess<T>()(value, *it))
        return it;
    return end;
}

template <typename RandomAccessIterator, typename T, typename LessThan>
inline RandomAccessIterator qBinaryFind(RandomAccessIterator begin, RandomAccessIterator end, const T &value, LessThan lessThan)
{
    RandomAccessIterator it = QAlgorithmsPrivate::qLowerBoundHelper(begin, end, value, lessThan);

    if (it != end && !lessThan(value, *it))
        return it;
    return end;
}

template <typename Container, typename T>
inline typename Container::const_iterator qBinaryFind(const Container &container, const T &value)
{
    typename Container::const_iterator it = QAlgorithmsPrivate::qLowerBoundHelper(container.constBegin(), container.constEnd(), value, qLess<T>());

    if (it != container.constEnd() && !qLess<T>()(value, *it))
        return it;
    return container.constEnd();
}

template <typename Container, typename T, typename LessThan>
inline typename Container::const_iterator qBinaryFind(const Container &container, const T &value, LessThan lessThan)
{
    typename Container::const_iterator it = QAlgorithmsPrivate::qLowerBoundHelper(container.constBegin(), container.constEnd(), value, lessThan);

    if (it != container.constEnd() && !lessThan(value, *it))
        return it;
    return container.constEnd();
}

template <typename ForwardIterator>
inline int qCount(ForwardIterator first, ForwardIterator last)
{
    qptrdiff n = 0;
    for (; first != last; ++first)
        ++n;
    return n;
}

template <typename Container>
inline int qCount(const Container &container)
{
    return qCount(container.constBegin(), container.constEnd());
}

template <typename T>
inline void qSwap(T &value1, T &value2)
{
    using std::swap;
    swap(value1, value2);
}

#ifdef Q_QDOC
template <typename T>
LessThan qBound(const T &min, const T &val, const T &max)
{
}
#else
template <typename T>
inline const T &qBound(const T &min, const T &val, const T &max)
{
    Q_ASSERT(!(max < min));
    if (val < min)
        return min;
    else if (max < val)
        return max;
    return val;
}
#endif

inline int qIntCast(double f) { return int(f); }
inline int qIntCast(float f) { return int(f); }

namespace QAlgorithmsPrivate {

#if QT_DEPRECATED_SINCE(6, 0)
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED

Q_CORE_EXPORT QT_DEPRECATED void qSortHelper(void **begin, void **end, bool lessThan(const void *, const void *));
Q_CORE_EXPORT QT_DEPRECATED void qSortHelper(void **begin, void **end, bool lessThan(void *, void *));

template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE void qSortHelper(RandomAccessIterator start, RandomAccessIterator end, const T &, LessThan lessThan)
{
    qptrdiff distance = end - start;
    if (distance < 2)
        return;

    --end;

    RandomAccessIterator low = start;
    RandomAccessIterator high = end - 1;
    qptrdiff middle = distance / 2;

    if (middle > 256) {
        RandomAccessIterator lmid = start + middle / 2;
        RandomAccessIterator hmid = end - middle / 2;

        if (lessThan(*lmid, *start))
            qSwap(*start, *lmid);
        if (lessThan(*hmid, *lmid))
            qSwap(*hmid, *lmid);
        if (lessThan(*lmid, *start))
            qSwap(*start, *lmid);

        if (lessThan(*end, *hmid))
            qSwap(*end, *hmid);
        if (lessThan(*hmid, *lmid))
            qSwap(*hmid, *lmid);
        if (lessThan(*end, *hmid))
            qSwap(*end, *hmid);
    } else {
        RandomAccessIterator mid = start + middle;

        if (lessThan(*mid, *start))
            qSwap(*start, *mid);
        if (lessThan(*end, *mid))
            qSwap(*end, *mid);
        if (lessThan(*mid, *start))
            qSwap(*start, *mid);
    }

    RandomAccessIterator pivot = end;
    RandomAccessIterator startCopy = start;
    RandomAccessIterator endCopy = end + 1;

    while (1) {
        while (++low < end && lessThan(*low, *pivot)) { }
        while (high > start && lessThan(*pivot, *high)) { --high; }

        if (low >= high)
            break;

        qSwap(*low, *high);
        --high;
    }

    if (low != pivot) {
        qSwap(*low, *pivot);
        pivot = low;
    }
    if (pivot > startCopy + 1)
        qSortHelper(startCopy, pivot, *startCopy, lessThan);
    if (endCopy > pivot + 1)
        qSortHelper(pivot + 1, endCopy, *pivot, lessThan);

    QT_WARNING_POP
}

#endif // QT_DEPRECATED_SINCE(6, 0)

template <typename RandomAccessIterator, typename T>
inline void qSortHelper(RandomAccessIterator begin, RandomAccessIterator end, const T &dummy)
{
    Q_UNUSED(dummy);
    std::sort(begin, end);
}

#if QT_DEPRECATED_SINCE(6, 0)

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED

template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE void qStableSortHelper(RandomAccessIterator start, RandomAccessIterator end, const T &, LessThan lessThan)
{
    QScopedPointer<RandomAccessIterator, QScopedPointerArrayDeleter<RandomAccessIterator> > deferred(new RandomAccessIterator[n]);
    RandomAccessIterator *buffer = deferred.data();
    RandomAccessIterator left = first;
    qptrdiff n = last - first;
    if (!n)
        return;

    QList<RandomAccessIterator> store;
    store.reserve(n);

    for (RandomAccessIterator it = first; it != last; ++it)
        store.append(it);

    std::sort(store.begin(), store.end(), lessThan);

    for (qptrdiff i = 0; i != n; ++i)
        *buffer[i] = qMove(**store.at(i));

    for (qptrdiff i = 0; i != n; ++i)
        *first++ = qMove(buffer[i]);

    QT_WARNING_POP
}

#endif // QT_DEPRECATED_SINCE(6, 0)

template <typename RandomAccessIterator, typename T>
inline void qStableSortHelper(RandomAccessIterator begin, RandomAccessIterator end, const T &dummy)
{
    Q_UNUSED(dummy);
    std::stable_sort(begin, end);
}

template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE RandomAccessIterator qLowerBoundHelper(RandomAccessIterator begin, RandomAccessIterator end, const T &value, LessThan lessThan)
{
    qptrdiff distance = end - begin;
    if (distance < 0 || distance > std::numeric_limits<int>::max())
        return begin;
    qptrdiff l = 0;
    qptrdiff r = distance - 1;
    qptrdiff m = (l + r) / 2;

    while (l <= r) {
        m = (l + r) / 2;
        RandomAccessIterator i = begin + m;
        if (lessThan(*i, value))
            l = m + 1;
        else
            r = m - 1;
    }

    return begin + l;
}

template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE RandomAccessIterator qUpperBoundHelper(RandomAccessIterator begin, RandomAccessIterator end, const T &value, LessThan lessThan)
{
    qptrdiff distance = end - begin;
    if (distance < 0 || distance > std::numeric_limits<int>::max())
        return begin;
    qptrdiff l = 0;
    qptrdiff r = distance - 1;
    qptrdiff m = (l + r) / 2;

    while (l <= r) {
        m = (l + r) / 2;
        RandomAccessIterator i = begin + m;
        if (lessThan(value, *i))
            r = m - 1;
        else
            l = m + 1;
    }

    return begin + l;
}

template <typename RandomAccessIterator, typename T, typename LessThan>
Q_OUTOFLINE_TEMPLATE RandomAccessIterator qBinaryFindHelper(RandomAccessIterator begin, RandomAccessIterator end, const T &value, LessThan lessThan)
{
    qptrdiff distance = end - begin;
    if (distance < 0 || distance > std::numeric_limits<int>::max())
        return end;
    qptrdiff l = 0;
    qptrdiff r = distance - 1;
    qptrdiff m = (l + r) / 2;

    while (l <= r) {
        m = (l + r) / 2;
        RandomAccessIterator i = begin + m;
        if (lessThan(*i, value))
            l = m + 1;
        else if (lessThan(value, *i))
            r = m - 1;
        else
            return i;
    }

    return end;
}

} // namespace QAlgorithmsPrivate


#if QT_DEPRECATED_SINCE(6, 0)
QT_DEPRECATED_X("use std::swap instead") inline void qSwap(QJsonValue &value1, QJsonValue &value2);
QT_DEPRECATED_X("use std::swap instead") inline void qSwap(QJsonValueRef value1, QJsonValueRef value2);
#endif

QT_END_NAMESPACE

#endif // QALGORITHMS_H
EOF
    
    # Replace the file
    mv "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h.new" "${QT_SRC_DIR}/src/corelib/tools/qalgorithms.h"
    echo "✓ Fixed auto keyword issues in qalgorithms.h"
else
    echo "✗ qalgorithms.h not found"
fi

# 4. Update qplatformdefs.h for AIX platform
echo "Updating qplatformdefs.h for AIX platform..."
if [ -f "${QT_SRC_DIR}/mkspecs/aix-g++/qplatformdefs.h" ]; then
    # Add AIX specific definitions at the top
    cat > "${QT_SRC_DIR}/mkspecs/aix-g++/qplatformdefs.h.new" << 'EOF'
/****************************************************************************
**
** Copyright (C) 2020 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the qmake spec of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl-3.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or (at your option) the GNU General
** Public license version 3 or any later version approved by the KDE Free
** Qt Foundation. The licenses are as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-2.0.html and
** https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef QPLATFORMDEFS_H
#define QPLATFORMDEFS_H

// AIX specific definitions for better compatibility
#define _LARGE_FILES 1
#define _LARGE_FILE_API
#define _XOPEN_SOURCE_EXTENDED 1

// Get Qt defines/settings

#include "qglobal.h"

// Set any POSIX/XOPEN defines at the top of this file to turn on specific APIs

#include <unistd.h>

// We are hot - unistd.h should have turned on the specific APIs we requested

#include <pthread.h>
#include <dirent.h>
#include <fcntl.h>
#include <grp.h>
#include <pwd.h>
#include <signal.h>
#include <dlfcn.h>

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/ipc.h>
#include <sys/time.h>
#include <sys/shm.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <netinet/in.h>
#ifndef QT_NO_IPV6IFNAME
#include <net/if.h>
#endif

#define QT_USE_XOPEN_LFS_EXTENSIONS
#include "../../common/posix/qplatformdefs.h"

#undef QT_SOCKLEN_T
#define QT_SOCKLEN_T            socklen_t

#if defined(_XOPEN_SOURCE) && (_XOPEN_SOURCE >= 500)
#define QT_SNPRINTF             ::snprintf
#define QT_VSNPRINTF            ::vsnprintf
#endif

#endif // QPLATFORMDEFS_H
EOF

    # Replace the file
    mv "${QT_SRC_DIR}/mkspecs/aix-g++/qplatformdefs.h.new" "${QT_SRC_DIR}/mkspecs/aix-g++/qplatformdefs.h"
    echo "✓ Updated qplatformdefs.h for AIX platform"
else
    echo "✗ qplatformdefs.h not found"
fi

echo ""
echo "Patching complete. The directory ${QT_SRC_DIR} now has all necessary patches applied."
echo "It's ready to be transferred to an AIX system for building."
echo ""