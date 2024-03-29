set_property(GLOBAL PROPERTY USE_FOLDERS On)
CMAKE_MINIMUM_REQUIRED(VERSION 3.4.0)
cmake_policy(SET CMP0022 NEW)
PROJECT(NebulaToolkit)

include(CMakeDependentOption)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${NebulaToolkit_SOURCE_DIR}/cmake ${NebulaToolkit_SOURCE_DIR}/nebula-trifid/libs/cmake)
INCLUDE(NebulaHelpers)

add_subdirectory(nebula-trifid)

SET(N_QT4 OFF)
SET(N_QT5 OFF)
SET(DEFQT "N_QT4")
SET(N_QT ${DEFQT} CACHE STRING "Qt Version")
SET_PROPERTY(CACHE N_QT PROPERTY STRINGS "N_QT4" "N_QT5")
SET(${N_QT} ON)

IF(N_QT5)
	ADD_DEFINITIONS(-D__USE_QT5)
ELSE()
	ADD_DEFINITIONS(-D__USE_QT4)
ENDIF()
CMAKE_DEPENDENT_OPTION(N_QT5_STATIC "Use static linking for Qt5" ON "N_QT5" OFF)

IF(N_QT4)
	FIND_PACKAGE(Qt4 REQUIRED QtCore QtGui QtXml QtNetwork)
	INCLUDE(${QT_USE_FILE})
	ADD_DEFINITIONS(${QT_DEFINITIONS})
ELSE()
	FIND_PACKAGE(Qt5Core REQUIRED)
	FIND_PACKAGE(Qt5Widgets REQUIRED)
	FIND_PACKAGE(Qt5Network REQUIRED)
ENDIF()
IF(N_QT_NEB_SUPPORT)
	ADD_DEFINITIONS(-D_QT_NEB_SUPPORT)		
ENDIF()

INCLUDE(ToolkitHelpers)
SET(CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE ON)
IF(MSVC)
	SET(PROJECTBINDIR ${NebulaToolkit_SOURCE_DIR}/bin/win32)
ELSE()
	SET(PROJECTBINDIR ${NebulaToolkit_SOURCE_DIR}/bin/posix)
ENDIF()
add_subdirectory(extlibs)
add_subdirectory(code)