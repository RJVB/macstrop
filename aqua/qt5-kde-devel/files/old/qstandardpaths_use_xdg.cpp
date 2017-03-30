/****************************************************************************
**
** Copyright (C) 2015 RJV Bertin
** More appropriate legalese here.
**
** This file is part of the QtCore module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL21$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Digia. For licensing terms and
** conditions see http://qt.digia.com/licensing. For further information
** use the contact form at http://qt.digia.com/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 or version 3 as published by the Free
** Software Foundation and appearing in the file LICENSE.LGPLv21 and
** LICENSE.LGPLv3 included in the packaging of this file. Please review the
** following information to ensure the GNU Lesser General Public License
** requirements will be met: https://www.gnu.org/licenses/lgpl.html and
** http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Digia gives you certain additional
** rights. These rights are described in the Digia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include <QtCore/QtGlobal>
#if defined(Q_OS_OSX)

#include "qstandardpaths_p.h"

#ifndef QT_NO_STANDARDPATHS

const QString qspUsesXDGLocationsTag("$Id: @(#) " __FILE__ " - " __DATE__ " $");

// defining a static instance works for now, but see
// https://wiki.qt.io/Coding_Conventions#Compiler.2FPlatform_specific_issues
static QStandardPathsConfiguration qspUsesXDGLocations(true);

bool setXDGLocationsEnabled(bool useXDGLocations)
{
    QStandardPathsConfiguration dummy(useXDGLocations);
    // this should force even clever linkers to preserve qspUsesXDGLocations
    return qspUsesXDGLocations.usesXDGLocations() != useXDGLocations;
}

#endif //Q_NO_STANDARDPATHS
#endif //Q_OS_OSX