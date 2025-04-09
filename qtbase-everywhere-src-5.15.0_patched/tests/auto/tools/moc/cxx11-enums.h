/****************************************************************************
**
** Copyright (C) 2011 Olivier Goffart.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the test suite of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:GPL-EXCEPT$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 as published by the Free Software
** Foundation with exceptions as appearing in the file LICENSE.GPL3-EXCEPT
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef CXX11_ENUMS_H
#define CXX11_ENUMS_H
#include <QtCore/QObject>

class CXX11Enums
{
    Q_GADGET
public:
    enum class EnumClass { A0, A1, A2, A3 };
    enum TypedEnum : char { B0, B1 , B2, B3 };
    enum class TypedEnumClass : char { C0, C1, C2, C3 };
    enum NormalEnum { D2 = 2, D3, D0 =0 , D1 };
    enum class ClassFlag { F0 = 1, F1 = 2, F2 = 4, F3 = 8};

    enum struct EnumStruct { G0, G1, G2, G3 };
    enum struct TypedEnumStruct : char { H0, H1, H2, H3 };
    enum struct StructFlag { I0 = 1, I1 = 2, I2 = 4, I3 = 8};

    Q_DECLARE_FLAGS(ClassFlags, ClassFlag)
    Q_DECLARE_FLAGS(StructFlags, StructFlag)

    Q_ENUM(EnumClass)
    Q_ENUM(TypedEnum)
    Q_ENUM(TypedEnumClass)
    Q_ENUM(NormalEnum)
    Q_ENUM(EnumStruct)
    Q_ENUM(TypedEnumStruct)
    Q_FLAG(ClassFlags)
    Q_FLAG(StructFlags)
};

// Also test the Q_ENUMS macro
class CXX11Enums2
{
    Q_GADGET
public:
    enum class EnumClass { A0, A1, A2, A3 };
    enum TypedEnum : char { B0, B1 , B2, B3 };
    enum class TypedEnumClass : char { C0, C1, C2, C3 };
    enum NormalEnum { D2 = 2, D3, D0 =0 , D1 };
    enum class ClassFlag { F0 = 1, F1 = 2, F2 = 4, F3 = 8 };
    Q_DECLARE_FLAGS(ClassFlags, ClassFlag)
    Q_ENUMS(EnumClass TypedEnum TypedEnumClass NormalEnum)
    Q_FLAGS(ClassFlags)
};

#endif // CXX11_ENUMS_H
