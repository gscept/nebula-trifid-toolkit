#-------------------------------------------------------------------------------
# posteffectcontroller
#-------------------------------------------------------------------------------

PROJECT(posteffectcontroller)

FILE(GLOB SRC "code/*.cc") 
FILE(GLOB HEAD "code/*.h")
FILE(GLOB FORMS "ui/*.ui")
SOURCE_GROUP("posteffectcontroller" FILES ${SRC} ${HEAD})
LIST(APPEND CODE ${SRC} ${HEAD})

SET(QTMOCFILES "code/posteffectcontroller.h")
PCH_QT_WRAP_CPP(posteffectcontroller_HEADERS_MOC ${QTMOCFILES})
N_QT_WRAP_UI(posteffectcontroller_FORMS_HEADERS ${FORMS})

SET(PCH_files	
    ../../stdneb.cc
)
SOURCE_GROUP("Precompiled" FILES ${PCH_files})


LIST(APPEND ALLSRCS ${CODE} ${PCH_files} ${posteffectcontroller_HEADERS_MOC} ${posteffectcontroller_FORMS_HEADERS})
ADD_LIBRARY(posteffectcontroller STATIC ${ALLSRCS})
TARGET_INCLUDE_DIRECTORIES(posteffectcontroller PUBLIC ${NebulaToolkit_SOURCE_DIR}/code/qttoolkit/qtaddons/posteffectcontroller/code PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
TARGET_LINK_LIBRARIES(posteffectcontroller PUBLIC application toolkitutil globalprobecontroller qttools qtsupport)
SET_TARGET_PROPERTIES(posteffectcontroller PROPERTIES FOLDER "N3SDK/QtAddons")
N_SET_COMPILER_DEFAULTS(posteffectcontroller)		

