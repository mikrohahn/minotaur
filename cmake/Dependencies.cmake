include(CMakeParseArguments)
find_package(PkgConfig)

function(minotaur_find_dependency prefix)
  cmake_parse_arguments(DEP "" "INC_FILE;INC_DIR;LIB_DIR" "NAMES;LIB_NAMES" ${ARGN})

  # By default, act as if the dependency was not found
  set(MNTR_DEP_${prefix}_FOUND FALSE PARENT_SCOPE)

  # Try finding the dependency using pkg-config
  if((PKG_CONFIG_FOUND) AND (DEP_NAMES))
    if(${prefix}_LIB_DIR)
      set(ENV{PKG_CONFIG_DIR} "${${prefix}_LIB_DIR}/pkgconfig:$ENV{PKG_CONFIG_DIR}")
    endif()
    pkg_search_module(MNTR_DEP_${prefix} ${DEP_NAMES})
  endif()

  # Try finding the dependency manually
  if(NOT MNTR_DEP_${prefix}_FOUND)
    find_path(MNTR_DEP_${prefix}_INCLUDE_DIRS ${DEP_INC_FILE} HINTS ${DEP_INC_DIR})
    if(NOT MNTR_DEP_${prefix}_INCLUDE_DIRS)
      return()
    endif()

    find_library(MNTR_DEP_${prefix}_LIBRARIES NAMES ${DEP_LIB_NAMES})
    if(NOT MNTR_DEP_${prefix}_LIBRARIES)
      return()
    endif()

    get_filename_component(MNTR_DEP_${prefix}_LIBRARY_DIRS ${MNTR_DEP_${prefix}_LIBRARIES} PATH)
  endif()

  # Transfer variables to parent scope if found
  set(MNTR_DEP_${prefix}_FOUND TRUE PARENT_SCOPE)
  set(MNTR_DEP_${prefix}_INCLUDE_DIRS ${MNTR_DEP_${prefix}_INCLUDE_DIRS} PARENT_SCOPE)
  set(MNTR_DEP_${prefix}_LIBRARY_DIRS ${MNTR_DEP_${prefix}_LIBRARY_DIRS} PARENT_SCOPE)
  set(MNTR_DEP_${prefix}_LIBRARIES ${MNTR_DEP_${prefix}_LIBRARIES} PARENT_SCOPE)
endfunction(minotaur_find_dependency)
