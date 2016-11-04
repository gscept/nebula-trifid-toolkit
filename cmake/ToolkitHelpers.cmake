
#------------------------------------------------------------------------------
# macro for qt projects
#------------------------------------------------------------------------------

MACRO(N_SET_QT_PROPERTIES inTarget inFolder)
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES FOLDER ${inFolder})
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES DEBUG_POSTFIX ".debug")
        
        IF(NOT N_BUILD_PUBLIC_AS_RELEASE)
                SET_TARGET_PROPERTIES(${inTarget} PROPERTIES RELEASE_POSTFIX ".public")
        ENDIF()
        
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${PROJECTBINDIR})
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${PROJECTBINDIR})
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ${PROJECTBINDIR})
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${PROJECTBINDIR})
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL ${PROJECTBINDIR})
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES PDB_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/pdb)
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES PDB_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/pdb)
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES PDB_OUTPUT_DIRECTORY_RELWITHDEBINFO ${CMAKE_BINARY_DIR}/pdb)
        SET_TARGET_PROPERTIES(${inTarget} PROPERTIES PDB_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/pdb)
ENDMACRO()

IF(WIN32)
	IF(N_QT4)
		MACRO (PCH_QT_WRAP_CPP outfiles )
			# get include dirs
			QT4_GET_MOC_FLAGS(moc_flags)
			QT4_EXTRACT_OPTIONS(moc_files moc_options moc_target ${ARGN})

			FOREACH (it ${moc_files})
				GET_FILENAME_COMPONENT(it ${it} ABSOLUTE)
				QT4_MAKE_OUTPUT_FILE(${it} moc_ cxx outfile)
				set (moc_flags_append "-fstdneb.h" "-f${it}") # pch hack.
				QT4_CREATE_MOC_COMMAND(${it} ${outfile} "${moc_flags};${moc_flags_append}" "${moc_options}" "${moc_target}")
				SET(${outfiles} ${${outfiles}} ${outfile})
			ENDFOREACH(it)
		ENDMACRO (PCH_QT_WRAP_CPP)
	ELSE()
		function(PCH_QT_WRAP_CPP outfiles )
			# get include dirs
			qt5_get_moc_flags(moc_flags)

			set(options)
			set(oneValueArgs TARGET)
			set(multiValueArgs OPTIONS DEPENDS)

			cmake_parse_arguments(_WRAP_CPP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

			set(moc_files ${_WRAP_CPP_UNPARSED_ARGUMENTS})
			set(moc_options ${_WRAP_CPP_OPTIONS})
			set(moc_target ${_WRAP_CPP_TARGET})
			set(moc_depends ${_WRAP_CPP_DEPENDS})

			if (moc_target AND CMAKE_VERSION VERSION_LESS 2.8.12)
				message(FATAL_ERROR "The TARGET parameter to qt5_wrap_cpp is only available when using CMake 2.8.12 or later.")
			endif()
			foreach(it ${moc_files})
				get_filename_component(it ${it} ABSOLUTE)
				qt5_make_output_file(${it} moc_ cpp outfile)
				set (moc_flags_append "-fstdneb.h" "-f${it}") # pch hack.
				qt5_create_moc_command(${it} ${outfile} "${moc_flags};${moc_flags_append}" "${moc_options}" "${moc_target}" "${moc_depends}")
				list(APPEND ${outfiles} ${outfile})
			endforeach()
			set(${outfiles} ${${outfiles}} PARENT_SCOPE)
		endfunction()
	ENDIF()
	
	IF(N_QT4)
		MACRO(N_QT_WRAP_UI)
			QT4_WRAP_UI(${ARGV})
		ENDMACRO()
	ELSE()
		MACRO(N_QT_WRAP_UI)
			QT5_WRAP_UI(${ARGV})
		ENDMACRO()
	ENDIF()
	
	IF(N_QT4)
		macro (NONPCH_QT_ADD_RESOURCES outfiles )
			QT4_EXTRACT_OPTIONS(rcc_files rcc_options rcc_target ${ARGN})

			foreach (it ${rcc_files})
			get_filename_component(outfilename ${it} NAME_WE)
			get_filename_component(infile ${it} ABSOLUTE)
			get_filename_component(rc_path ${infile} PATH)
			set(outfile ${CMAKE_CURRENT_BINARY_DIR}/qrc_${outfilename}.cxx)

			set(_RC_DEPENDS)
			if(EXISTS "${infile}")
			  #  parse file for dependencies
			  #  all files are absolute paths or relative to the location of the qrc file
			  file(READ "${infile}" _RC_FILE_CONTENTS)
			  string(REGEX MATCHALL "<file[^<]+" _RC_FILES "${_RC_FILE_CONTENTS}")
			  foreach(_RC_FILE ${_RC_FILES})
				string(REGEX REPLACE "^<file[^>]*>" "" _RC_FILE "${_RC_FILE}")
				if(NOT IS_ABSOLUTE "${_RC_FILE}")
				  set(_RC_FILE "${rc_path}/${_RC_FILE}")
				endif()
				set(_RC_DEPENDS ${_RC_DEPENDS} "${_RC_FILE}")
			  endforeach()
			  unset(_RC_FILES)
			  unset(_RC_FILE_CONTENTS)
			  # Since this cmake macro is doing the dependency scanning for these files,
			  # let's make a configured file and add it as a dependency so cmake is run
			  # again when dependencies need to be recomputed.
			  QT4_MAKE_OUTPUT_FILE("${infile}" "" "qrc.depends" out_depends)
			  configure_file("${infile}" "${out_depends}" COPYONLY)
			else()
			  # The .qrc file does not exist (yet). Let's add a dependency and hope
			  # that it will be generated later
			  set(out_depends)
			endif()	
			add_custom_command(OUTPUT ${outfile}
			  COMMAND ${QT_RCC_EXECUTABLE}
			  ARGS ${rcc_options} -name ${outfilename} -o ${outfile} ${infile}
			  MAIN_DEPENDENCY ${infile}
			  DEPENDS ${_RC_DEPENDS} "${out_depends}" VERBATIM)
			set(${outfiles} ${${outfiles}} ${outfile})
			if(MSVC)
				SET_SOURCE_FILES_PROPERTIES(${outfile} PROPERTIES COMPILE_FLAGS /Y-)
			endif()
		  endforeach ()	
		endmacro ()
	ELSE()
		macro (NONPCH_QT_ADD_RESOURCES outfiles )
			set(options)
			set(oneValueArgs)
			set(multiValueArgs OPTIONS)

			cmake_parse_arguments(_RCC "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

			set(rcc_files ${_RCC_UNPARSED_ARGUMENTS})
			set(rcc_options ${_RCC_OPTIONS})

			if("${rcc_options}" MATCHES "-binary")
				message(WARNING "Use qt5_add_binary_resources for binary option")
			endif()

			foreach(it ${rcc_files})
				get_filename_component(outfilename ${it} NAME_WE)
				get_filename_component(infile ${it} ABSOLUTE)
				set(outfile ${CMAKE_CURRENT_BINARY_DIR}/qrc_${outfilename}.cpp)

				_QT5_PARSE_QRC_FILE(${infile} _out_depends _rc_depends)

				add_custom_command(OUTPUT ${outfile}
								   COMMAND ${Qt5Core_RCC_EXECUTABLE}
								   ARGS ${rcc_options} --name ${outfilename} --output ${outfile} ${infile}
								   MAIN_DEPENDENCY ${infile}
								   DEPENDS ${_rc_depends} "${out_depends}" VERBATIM)
				list(APPEND ${outfiles} ${outfile})
				if(MSVC)
					SET_SOURCE_FILES_PROPERTIES(${outfile} PROPERTIES COMPILE_FLAGS /Y-)
				endif()
			endforeach()
			set(${outfiles} ${${outfiles}} PARENT_SCOPE)
		endmacro ()
	ENDIF()
ELSEIF(UNIX)
	macro (PCH_QT4_WRAP_CPP outfiles )
		# get include dirs
		QT4_GET_MOC_FLAGS(moc_flags)
		QT4_EXTRACT_OPTIONS(moc_files moc_options moc_target ${ARGN})

		foreach (it ${moc_files})
			get_filename_component(it ${it} ABSOLUTE)
			QT4_MAKE_OUTPUT_FILE(${it} moc_ cxx outfile)
			set (moc_flags_append "-fstdneb.h" "-f${it}") # pch hack.
			QT4_CREATE_MOC_COMMAND(${it} ${outfile} "${moc_flags}" "${moc_options};${moc_flags_append}" "${moc_target}")
			set(${outfiles} ${${outfiles}} ${outfile})
		endforeach()
	endmacro ()
	
	MACRO (NONPCH_QT4_ADD_RESOURCES outfiles )
		QT4_EXTRACT_OPTIONS(rcc_files rcc_options rcc_target ${ARGN})

		foreach (it ${rcc_files})
		get_filename_component(outfilename ${it} NAME_WE)
		get_filename_component(infile ${it} ABSOLUTE)
		get_filename_component(rc_path ${infile} PATH)
		set(outfile ${CMAKE_CURRENT_BINARY_DIR}/qrc_${outfilename}.cxx)

		set(_RC_DEPENDS)
		if(EXISTS "${infile}")
		  #  parse file for dependencies
		  #  all files are absolute paths or relative to the location of the qrc file
		  file(READ "${infile}" _RC_FILE_CONTENTS)
		  string(REGEX MATCHALL "<file[^<]+" _RC_FILES "${_RC_FILE_CONTENTS}")
		  foreach(_RC_FILE ${_RC_FILES})
			string(REGEX REPLACE "^<file[^>]*>" "" _RC_FILE "${_RC_FILE}")
			if(NOT IS_ABSOLUTE "${_RC_FILE}")
			  set(_RC_FILE "${rc_path}/${_RC_FILE}")
			endif()
			set(_RC_DEPENDS ${_RC_DEPENDS} "${_RC_FILE}")
		  endforeach()
		  unset(_RC_FILES)
		  unset(_RC_FILE_CONTENTS)
		  # Since this cmake macro is doing the dependency scanning for these files,
		  # let's make a configured file and add it as a dependency so cmake is run
		  # again when dependencies need to be recomputed.
		  QT4_MAKE_OUTPUT_FILE("${infile}" "" "qrc.depends" out_depends)
		  configure_file("${infile}" "${out_depends}" COPYONLY)
		else()
		  # The .qrc file does not exist (yet). Let's add a dependency and hope
		  # that it will be generated later
		  set(out_depends)
		endif()

		add_custom_command(OUTPUT ${outfile}
		  COMMAND ${QT_RCC_EXECUTABLE}
		  ARGS ${rcc_options} -name ${outfilename} -o ${outfile} ${infile}
		  MAIN_DEPENDENCY ${infile}
		  DEPENDS ${_RC_DEPENDS} "${out_depends}" VERBATIM)
		set(${outfiles} ${${outfiles}} ${outfile})
	  endforeach ()
	endmacro (NONPCH_QT4_ADD_RESOURCES)
	SET(QT_LIBS "")
	#SET(QT_QMAKE_EXECUTABLE /usr/bin/qmake)
	#SET(QT_MOC_EXECUTABLE /usr/bin/moc)
	#SET(QT_RCC_EXECUTABLE /usr/bin/rcc)
	#SET(QT_UIC_EXECUTABLE /usr/bin/uic)
        
ENDIF()


# qt linking and flags

ADD_LIBRARY(qtsupport INTERFACE)
TARGET_COMPILE_OPTIONS(qtsupport INTERFACE $<$<C_COMPILER_ID:MSVC>:/EHsc>)
TARGET_LINK_LIBRARIES(qtsupport INTERFACE 
	$<$<BOOL:${N_QT5}>:Qt5::Widgets Qt5::Core Qt5::Network Imm32.lib winmm.lib>	
	$<$<BOOL:${N_QT4}>:Qt4::QtGui Qt4::QtCore Qt4::QtNetwork Imm32.lib>
	)

IF(N_STATIC_BUILD)
	IF(N_QT5_STATIC)
		# find additional qt5 libs for static linking
		FIND_PACKAGE(Qt5Core REQUIRED)
		get_target_property(qtlocation Qt5::Core LOCATION)
		get_filename_component(qtfolder ${qtlocation} DIRECTORY)
		find_library(pcre NAMES qtpcred PATHS ${qtfolder})
		find_library(qtharf NAMES qtharfbuzzngd PATHS ${qtfolder})
		find_library(qtplatform NAMES qt5platformsupportd PATHS ${qtfolder})
		find_library(qwindows NAMES qwindowsd PATHS ${qtfolder}/../plugins/platforms)
		TARGET_LINK_LIBRARIES(qtsupport INTERFACE ${pcre} ${qtharf} ${qtplatform} ${qwindows})

		# static qt from http://www.npcglib.org/~stathis/blog/precompiled-qt4-qt5/ is built with ssl
		SET(OPENSSL_USE_STATIC_LIBS TRUE)
		SET(OPENSSL_MSVC_STATIC_RT TRUE)		
		SET(OPENSSL_ROOT_DIR "" CACHE PATH "OpenSSL Root folder")
		FIND_PACKAGE(OpenSSL REQUIRED)
		TARGET_LINK_LIBRARIES(qtsupport INTERFACE $<$<CONFIG:Release>:${LIB_EAY_RELEASE} ${SSL_EAY_RELEASE}> $<$<CONFIG:Debug>:${LIB_EAY_DEBUG} ${SSL_EAY_DEBUG}> $<$<C_COMPILER_ID:MSVC>:Crypt32.lib>)
	ENDIF()
ENDIF()