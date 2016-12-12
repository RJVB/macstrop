cmake_minimum_required(VERSION 2.8.9 FATAL_ERROR)
cmake_policy(SET CMP0002 OLD)
cmake_policy(SET CMP0014 OLD)

project(kdevelop-i18n-@LANGUAGE@)
cmake_minimum_required(VERSION 2.8.12)

find_package(Gettext REQUIRED)
find_package(ECM 0.0.12 REQUIRED)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})

include(KDEInstallDirs)

find_package(KF5DocTools REQUIRED)
find_package(KF5I18n REQUIRED)

if (NOT GETTEXT_MSGMERGE_EXECUTABLE)
   MESSAGE(FATAL_ERROR "Please install the msgmerge binary")
endif (NOT GETTEXT_MSGMERGE_EXECUTABLE)

IF(NOT GETTEXT_MSGFMT_EXECUTABLE)
   MESSAGE(FATAL_ERROR "Please install the msgfmt binary")
endif (NOT GETTEXT_MSGFMT_EXECUTABLE)

set(CURRENT_LANG @LANGUAGE@)

include(ECMPoQmTools)

# Determine if a .po file must be compiled into a .mo or a .qm file
file(GLOB po_files *.po)
set(mo_po_files)
set(qm_po_files)
foreach(po_file ${po_files})
    string(REGEX MATCH "_qt\\.po$" match "${po_file}")
    if(match)
        set(qm_po_files ${qm_po_files} ${po_file})
    else()
        set(mo_po_files ${mo_po_files} ${po_file})
    endif()
endforeach()

if(qm_po_files)
    ecm_process_po_files_as_qm(${CURRENT_LANG} ALL
        INSTALL_DESTINATION ${LOCALE_INSTALL_DIR}
        PO_FILES ${qm_po_files}
    )
endif()

if (mo_po_files)
    gettext_process_po_files(${CURRENT_LANG} ALL
        INSTALL_DESTINATION ${LOCALE_INSTALL_DIR}
        PO_FILES ${mo_po_files}
    )
endif()
