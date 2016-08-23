## Minotaur CMake file

project(MINOTAUR CXX C Fortran)
CMAKE_MINIMUM_REQUIRED(VERSION 2.8 FATAL_ERROR)
cmake_policy(SET CMP0003 NEW)

## Fortran is required for Bqpd, Filter.
## C is required for FortranCInterface.
INCLUDE(CheckIncludeFile)
INCLUDE(CheckIncludeFileCXX)
INCLUDE(CheckFunctionExists)
INCLUDE(CheckLibraryExists)
INCLUDE(FortranCInterface)
INCLUDE(FindSubversion)
INCLUDE(FindPkgConfig OPTIONAL RESULT_VARIABLE MNTR_PKGCON)

include(cmake/Dependencies.cmake)

set (MINOTAUR_VERSION_MAJOR 0)
set (MINOTAUR_VERSION_MINOR 2)

set (MSG_HEAD "Minotaur config: ")  ## must preceed every message.

## Stop if we are compiling in the minotaur-root directory.
if ((EXISTS "${PROJECT_BINARY_DIR}/src/base/Types.h") OR
  ("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}"))
  message(FATAL_ERROR
  ${MSG_HEAD} "In-source builds are not allowed. Please create a build directory and compile there.")
endif()

## Enable compiler warnings
OPTION(COMPILER_WARN "Turn compiler warnings on/off " ON)
if (${COMPILER_WARN})
  set (CMAKE_CXX_FLAGS "-Wall -pedantic -Wmissing-include-dirs -Wunused")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wextra -Wundef -Wshadow")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wredundant-decls")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Woverloaded-virtual")
endif()

###########################################################################
## Don't install in /usr/local
## see http://www.cmake.org/pipermail/cmake/2007-August/015814.html
###########################################################################
set (MNTR_INSTALL_PREFIX "./" CACHE PATH
    "Dir. where Minotaur will be installed. Defaults to current dir.")
set(CMAKE_INSTALL_PREFIX ${MNTR_INSTALL_PREFIX} CACHE INTERNAL
    "Install path prefix, prepended onto install directories.")

###########################################################################
## check if all externals available at one place
###########################################################################
set (ALL_EXTERNS_PATH "" CACHE PATH "Path to the directory where all minotaur external libraries and headers are available (/path/to/third-party)")

###########################################################################
## Shared or static libraries.
###########################################################################
OPTION(BUILD_SHARED_LIBS "Build Minotaur with shared libraries." ON)

###########################################################################
## set runtime-path
###########################################################################
# the RPATH to be used when installing, but only if it's not a system
# directory
if (${BUILD_SHARED_LIBS})
  LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_PREFIX}/lib" isSystemDir)
  if ("${isSystemDir}" STREQUAL "-1")
    if (IS_ABSOLUTE ${CMAKE_INSTALL_PREFIX})
      set(CMAKE_INSTALL_RPATH
        ${CMAKE_INSTALL_RPATH}:${CMAKE_INSTALL_PREFIX}/lib)
    else()
      set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_RPATH}:${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/lib)
    endif()
  endif()
endif()

###########################################################################
## getrusage
###########################################################################
set (MINOTAUR_RUSAGE) ## NULL
CHECK_FUNCTION_EXISTS(getrusage MINOTAUR_RUSAGE)
message (STATUS ${MSG_HEAD} "Is rusage available = ${MINOTAUR_RUSAGE}")

###########################################################################
## svnversion
###########################################################################
set (MINOTAUR_SVN_VERSION "0.0")
get_filename_component(MNTR_ABS_PATH "${PROJECT_SOURCE_DIR}" ABSOLUTE)
message (STATUS ${MSG_HEAD} "checking svn in = ${MNTR_ABS_PATH}")
if (EXISTS "${MNTR_ABS_PATH}/.svn")
  message (STATUS ${MSG_HEAD} "found .svn in ${MNTR_ABS_PATH}")
  FIND_PACKAGE(Subversion)
  if (Subversion_FOUND)
    message (STATUS ${MSG_HEAD} "Package subversion found")
    # extract working copy information for SOURCE_DIR into TMP_SVN_XXX variables
    Subversion_WC_INFO(${MNTR_ABS_PATH} TMP_SVN)
    set (MINOTAUR_SVN_VERSION ${TMP_SVN_WC_REVISION})
  endif()
endif()
message (STATUS ${MSG_HEAD} "svn version = ${MINOTAUR_SVN_VERSION}")


###########################################################################
## pkg-config
###########################################################################
set (MNTR_HAVE_PKGCON 1)
if (("${MNTR_PKGCON}" STREQUAL "NOTFOUND") OR (NOT PKG_CONFIG_FOUND) OR
    (NOT ${USE_PKGCON_BOOL}))
  set (MNTR_HAVE_PKGCON 0)
  message(STATUS ${MSG_HEAD} "pkg-config not called.")
else()
  message(STATUS ${MSG_HEAD} "pkg-config found.")
endif()


###########################################################################
## F77_FUNC
###########################################################################
# save name of fortran compiler in CMAKE_Fortran_COMPILER.
get_filename_component (Fortran_COMPILER_NAME ${CMAKE_Fortran_COMPILER} NAME)
FortranCInterface_HEADER(src/base/MinotaurCFortran.h
                         MACRO_NAMESPACE "F77_"
                         SYMBOL_NAMESPACE "F77_")

###########################################################################
## High verbosity option
###########################################################################
OPTION (SPEW_FLAG "Turn verbosity on/off." OFF)
if (${SPEW_FLAG})
  add_definitions(-DSPEW=1)
else()
  add_definitions(-DSPEW=0)
endif()
message(STATUS ${MSG_HEAD} "SPEW flag is " ${SPEW_FLAG})


###########################################################################
## OPENMP option
###########################################################################
OPTION (USE_OpenMP "Use OpenMP." OFF)
if(${USE_OpenMP})
  FIND_PACKAGE(OpenMP)
  if(OPENMP_FOUND)
    add_definitions(-DUSE_OPENMP=1)
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    message(STATUS ${MSG_HEAD} "OpenMP support detected.")
  else()
    add_definitions(-DUSE_OPENMP=0)
  endif()
else()
  add_definitions(-DUSE_OPENMP=0)
endif()


###########################################################################
## Debug options
###########################################################################
if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  add_definitions(-DDEBUG=1)
else()
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
  set (CMAKE_FORTRAN_FLAGS "${CMAKE_FORTRAN_FLAGS} -O3")
  add_definitions(-DDEBUG=0 -DNDEBUG)
endif()


###########################################################################
## boost
###########################################################################
find_package(Boost REQUIRED)

###########################################################################
## base
###########################################################################
add_subdirectory(src/base)

###########################################################################
## Bqpd
###########################################################################
set (BQPD_LIB_DIR)          ## NULL
set (LINK_BQPD)         ## NULL
message(STATUS ${MSG_HEAD} "Searching for bqpd ...")

set (BQPD_LIB_DIR "" CACHE PATH
  "Full path to libbqpd.a library directory, e.g. /home/path/to/third-party/lib")
set (BQPD_LIB_DIR_F ${BQPD_LIB_DIR})

if (("${BQPD_LIB_DIR_F}" STREQUAL "") AND
  (NOT ("${ALL_EXTERNS_PATH}" STREQUAL "")))
  set (BQPD_LIB_DIR_F ${ALL_EXTERNS_PATH}/lib)
endif()
message(STATUS ${MSG_HEAD} "BQPD_LIB_DIR_F is set to = ${BQPD_LIB_DIR_F}")
if (BQPD_LIB_DIR_F)
  if (EXISTS "${BQPD_LIB_DIR_F}")
    message(STATUS ${MSG_HEAD} "BQPD library directory exists.")
    add_subdirectory(src/engines/Bqpd)
    set (LINK_BQPD 1)
    set (BQPD_LIBS "mntrbqpd" "bqpd")
  else()
    message(FATAL_ERROR " ${MSG_HEAD} BQPD_LIB_DIR_F ${BQPD_LIB_DIR_F} not found.")
  endif()
endif()

if (LINK_BQPD)
  message(STATUS ${MSG_HEAD} "Link BQPD? Yes.")
else()
  set (BQPD_LIB_DIR_F)
  message(STATUS ${MSG_HEAD} "Link BQPD? No.")
endif()


###########################################################################
## Filter-SQP
###########################################################################
set (FILTER_LIB_DIR)          ## NULL
set (LINK_FILTER_SQP)         ## NULL

message(STATUS ${MSG_HEAD} "Searching for Filter-SQP ...")
set (FILTER_LIB_DIR "" CACHE PATH
  "Path to Filter-SQP library. This directory must have a libfilter file.")
set (FILTER_LIB_DIR_F ${FILTER_LIB_DIR})

if (("${FILTER_LIB_DIR_F}" STREQUAL "") AND
    (NOT ("${ALL_EXTERNS_PATH}" STREQUAL "")))
    set (FILTER_LIB_DIR_F ${ALL_EXTERNS_PATH}/lib)
endif()

message(STATUS ${MSG_HEAD} "FILTER_LIB_DIR_F is set to = ${FILTER_LIB_DIR_F}")
if (FILTER_LIB_DIR_F)
  if (EXISTS "${FILTER_LIB_DIR_F}")
    message(STATUS ${MSG_HEAD} "Filter-SQP library directory exists.")
    add_subdirectory(src/engines/FilterSQP)
    set (LINK_FILTER_SQP 1)
    set (FILTER_SQP_LIBS "mntrfiltersqp" "filtersqp")
  else()
    message(FATAL_ERROR " ${MSG_HEAD} FILTER_LIB_DIR_F "
    "${FILTER_LIB_DIR_F} not found.")
  endif()
endif()

if (LINK_FILTER_SQP)
  message(STATUS ${MSG_HEAD} "Link Filter-SQP? Yes.")
else()
  set (FILTER_LIB_DIR_F)
  message(STATUS ${MSG_HEAD} "Link Filter-SQP? No.")
endif()

###########################################################################

set (USE_PKGCON_BOOL TRUE CACHE BOOL
"If true, try to use pkg-config to find library flags.")

###########################################################################
## Ipopt
###########################################################################
# Identify forced include directory
set (IPOPT_INC_DIR "" CACHE PATH
  "Path to Ipopt headers. It must have coin/IpIpoptApplication.hpp file.")
set (IPOPT_INC_DIR_F ${IPOPT_INC_DIR})
if (("${IPOPT_INC_DIR_F}" STREQUAL "") AND
    (NOT ("${ALL_EXTERNS_PATH}" STREQUAL "")))
  set (IPOPT_INC_DIR_F "${ALL_EXTERNS_PATH}/include")
endif()

# Identify forced library directory
set (IPOPT_LIB_DIR "" CACHE PATH
  "Path to Ipopt library. It must have a libipopt file.")
set (IPOPT_LIB_DIR_F ${IPOPT_LIB_DIR})
if (("${IPOPT_LIB_DIR_F}" STREQUAL "") AND
       (NOT ("${ALL_EXTERNS_PATH}" STREQUAL "")))
  set (IPOPT_LIB_DIR_F "${ALL_EXTERNS_PATH}/lib")
endif()

# Attempt to find Ipopt
minotaur_find_dependency(IPOPT NAMES ipopt INC_FILE coin/IpIpoptApplication.hpp INC_DIR ${IPOPT_INC_DIR_F} LIB_NAMES ipopt libipopt LIB_DIR ${IPOPT_LIB_DIR_F})

if(MNTR_DEP_IPOPT_FOUND)
  set(LINK_IPOPT TRUE)
  set(IPOPT_LIBS "mntripopt" ${MNTR_DEP_IPOPT_LIBRARIES})
  add_subdirectory(src/engines/Ipopt)
  message(STATUS ${MSG_HEAD} "Link IPOPT? Yes.")
else()
  set(LINK_IPOPT FALSE)
  set(IPOPT_LIBS "")
  message(STATUS ${MSG_HEAD} "Link IPOPT? No.")
endif()

###########################################################################
## OSI-LP
###########################################################################
# Identify forced include directory
set (OSI_INC_DIR "" CACHE PATH
  "Path to OsiSolver headers. It must have coin/OsiSolverInterface.hpp file.")
set (OSI_INC_DIR_F ${OSI_INC_DIR})
if (("${OSI_INC_DIR_F}" STREQUAL "") AND
    (NOT ("${ALL_EXTERNS_PATH}" STREQUAL "")))
  set (OSI_INC_DIR_F "${ALL_EXTERNS_PATH}/include")
endif()

# Identify forced library directory
set (OSI_LIB_DIR "" CACHE PATH
  "Path to OsiSolver library. It must have libOsi.")
set (OSI_LIB_DIR_F ${OSI_LIB_DIR})
if (("${OSI_LIB_DIR_F}" STREQUAL "") AND
    (NOT ("${ALL_EXTERNS_PATH}" STREQUAL "")))
  set (OSI_LIB_DIR_F "${ALL_EXTERNS_PATH}/lib")
endif()

# Attempt to find OSI-LP
minotaur_find_dependency(OSI NAMES osi INC_FILE coin/OsiSolverInterface.hpp INC_DIR ${OSI_INC_DIR_F} LIB_NAMES Osi libOsi LIB_DIR ${OSI_LIB_DIR_F})

if (MNTR_DEP_OSI_FOUND)
  set(LINK_OSI TRUE)
  set(OSI_LIBS "mntrosilp" ${MNTR_DEP_OSI_LIBRARIES})
  message(STATUS ${MSG_HEAD} "Link OSI? Yes.")
else()
  set(LINK_OSI FALSE)
  set(OSI_LIBS "")
  message(STATUS ${MSG_HEAD} "Link OSI? No.")
endif()

if(LINK_OSI)
  ###########################################################################
  ## CLP
  ###########################################################################

  # Identify forced include directory
  set (CLP_INC_DIR "" CACHE PATH
       "Path to CLP headers. It must have coin/ClpModel.hpp file. Defaults to OSI_INC_DIR")
  if (OSICLP_F)
    set (CLP_INC_DIR_F ${OSI_INC_DIR_F})
  endif()
  if ((NOT ("${CLP_INC_DIR}" STREQUAL "")))
    set (CLP_INC_DIR_F ${CLP_INC_DIR})
  endif()

  # Identify forced library directory
  set (CLP_LIB_DIR "" CACHE PATH
       "Path to CLP libraries. It must have libClp file. Defaults to OSI_LIB_DIR")
  set (CLP_LIB_DIR_F)
  if (OSICLP_F)
    set (CLP_LIB_DIR_F ${OSI_LIB_DIR_F})
  endif()
  if ((NOT ("${CLP_LIB_DIR}" STREQUAL "")))
    set (CLP_LIB_DIR_F ${CLP_LIB_DIR})
  endif()

  # Attempt to find CLP
  minotaur_find_dependency(CLP NAMES osi-clp clp INC_FILE coin/ClpModel.hpp INC_DIR ${CLP_INC_DIR_F} LIB_NAMES OsiClp libOsiClp Clp libClp LIB_DIR ${CLP_LIB_DIR_F})

  if (MNTR_DEP_CLP_FOUND)
    set(LINK_CLP TRUE)
    add_definitions("-DMNTROSICLP=1")
    message(STATUS ${MSG_HEAD} "Link CLP? Yes.")
  else()
    set(LINK_CLP FALSE)
    add_definitions("-DMNTROSICLP=0")
    message(STATUS ${MSG_HEAD} "Link CLP? No.")
  endif()

  ###########################################################################
  ## CPLEX
  ###########################################################################
  set (CPX_INC_DIR "" CACHE PATH
       "Path to Cplex headers. It must have cplex.h file.")

  minotaur_find_dependency(CPX NAMES osi-cplex INC_FILE cplex.h INC_DIR ${CPX_INC_DIR} LIB_NAMES OsiCpx libOsiCpx)

  if (MNTR_DEP_CPX_FOUND)
    set(LINK_CPX TRUE)
    add_definitions("-DMNTROSICPX=1")
    message(STATUS ${MSG_HEAD} "Link Cplex? Yes.")
  else()
    set(LINK_CPX FALSE)
    add_definitions("-DMNTROSICPX=0")
    message(STATUS ${MSG_HEAD} "Link Cplex? No.")
  endif()


  ###########################################################################
  ## Gurobi
  ###########################################################################
  set (GRB_INC_DIR "" CACHE PATH
       "Path to Gurobi headers. It must have gurobi_c.h file.")

  minotaur_find_dependency(GRB NAMES osi-gurobi INC_FILE gurobi_c.h INC_DIR ${GRB_INC_DIR} LIB_NAMES OsiGrb libOsiGrb)

  if (MNTR_DEP_GRB_FOUND)
    set(LINK_GRB TRUE)
    add_definitions("-DMNTROSIGRB=1")
    message(STATUS ${MSG_HEAD} "Link Gurobi? Yes.")
  else()
    set(LINK_GRB FALSE)
    add_definitions("-DMNTROSIGRB=0")
    message(STATUS ${MSG_HEAD} "Link Gurobi? No.")
  endif()

  add_subdirectory(src/engines/OsiLP)
endif()


###########################################################################
## qpOASES
###########################################################################
set (QPOASES_LIB)          ## NULL
set (LINK_QPOASES)         ## NULL

message(STATUS ${MSG_HEAD} "Searching for qpOASES ...")
set (QPOASES_INC_DIR "" CACHE PATH
  "Path to qpOASES headers. It must have subdirectory qpOASES with file QProblem.hpp.")
set (QPOASES_LIB_DIR "" CACHE PATH
  "Path to qpOASES library. It must have a libqpOASES.a file.")
message(STATUS ${MSG_HEAD} "QPOASES_INC_DIR is set to ${QPOASES_INC_DIR}")
message(STATUS ${MSG_HEAD} "QPOASES_LIB_DIR is set to ${QPOASES_LIB_DIR}")

if (QPOASES_INC_DIR)
  if (NOT EXISTS "${QPOASES_INC_DIR}/qpOASES/QProblem.hpp")
    message(FATAL_ERROR " ${MSG_HEAD}"
            "${QPOASES_INC_DIR}/qpOASES/QProblem.hpp not found.")
  endif()
  if (NOT QPOASES_LIB_DIR)
    message(FATAL_ERROR " ${MSG_HEAD}"
            "QPOASES_LIB_DIR must be set along with QPOASES_INC_DIR")
  endif()
  if (EXISTS ${QPOASES_LIB_DIR})
    message(STATUS ${MSG_HEAD} "qpOASES library directory exists.")
    add_subdirectory(src/engines/qpOASES)
    set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_RPATH}:${QPOASES_LIB_DIR})
    set (LINK_QPOASES 1)
  else()
    message(FATAL_ERROR " ${MSG_HEAD} "
            "QPOASES_LIB_DIR ${QPOASES_LIB_DIR} not found.")
  endif()
elseif (QPOASES_INC_DIR)
  if (QPOASES_LIB_DIR)
    message(FATAL_ERROR " ${MSG_HEAD}"
            "QPOASES_INC_DIR must be set along with QPOASES_LIB_DIR")
  endif()
endif()

if (LINK_QPOASES)
  message(STATUS ${MSG_HEAD} "Link qpOASES? Yes.")
else()
  set (QPOASES_INC_DIR)
  set (QPOASES_LIB_DIR)
  message(STATUS ${MSG_HEAD} "Link qpOASES? No.")
endif()

###########################################################################
## Engine Factory
###########################################################################
add_subdirectory(src/engines)


###########################################################################
## ASL
###########################################################################
set(ASL_INC_DIR "" CACHE PATH
  "Path to ASL headers. It must have asl.h")
set(ASL_LIB_DIR "" CACHE PATH
  "Path to ASL library. It must have amplsolver.a")
set (ASL_INC_DIR_F ${ASL_INC_DIR})
set (ASL_LIB_DIR_F ${ASL_LIB_DIR})

if (("${ASL_INC_DIR_F}" STREQUAL "") AND
    (NOT ("${ALL_EXTERNS_PATH}" STREQUAL "")))
  set (ASL_INC_DIR_F "${ALL_EXTERNS_PATH}/include")
  set (ASL_LIB_DIR_F "${ALL_EXTERNS_PATH}/lib")
endif()

minotaur_find_dependency(ASL NAMES asl coinasl INC_FILE coin/asl.hpp INC_DIR ${ASL_INC_DIR_F} LIB_NAMES asl libasl coinasl libcoinasl LIB_DIR ${ASL_LIB_DIR_F})

if (MNTR_DEP_ASL_FOUND)
  set(LINK_ASL TRUE)
  add_subdirectory(src/interfaces/ampl)
  add_subdirectory(src/algorithms)
  message(STATUS ${MSG_HEAD} "Link AMPL-ASL? Yes.")
else()
  set(LINK_ASL FALSE)
  message(STATUS ${MSG_HEAD} "Link AMPL-ASL? No.")
endif()

###########################################################################
## Testing
###########################################################################
set(CPPUNIT_INC_DIR "" CACHE PATH
  "Path to CppUnit headers. It must have cppunit/TestCase.h")
set (CPPUNIT_INC_DIR_F ${CPPUNIT_INC_DIR})
if (("${CPPUNIT_INC_DIR_F}" STREQUAL "") AND
    (NOT ("${ALL_EXTERNS_PATH}" STREQUAL "")))
  set (CPPUNIT_INC_DIR_F "${ALL_EXTERNS_PATH}/include")
endif()


set(CPPUNIT_LIB_DIR "" CACHE PATH
  "Path to CppUnit library. It must have cppunit library file.")
set (CPPUNIT_LIB_DIR_F ${CPPUNIT_LIB_DIR})
if (("${CPPUNIT_LIB_DIR_F}" STREQUAL "") AND
    (NOT ("${ALL_EXTERNS_PATH}" STREQUAL "")))
  set (CPPUNIT_LIB_DIR_F "${ALL_EXTERNS_PATH}/lib")
endif()

minotaur_find_dependency(CPPUNIT NAMES cppunit INC_DIR ${CPPUNIT_INC_DIR_F} INC_FILE cppunit/TestCase.h LIB_DIR ${CPPUNIT_LIB_DIR_F} LIB_NAMES cppunit libcppunit)

if (MNTR_DEP_CPPUNIT_FOUND)
  set(LINK_CPPUNIT TRUE)
  add_definitions("-DCPPUNIT_STD_NEED_ALLOCATOR=0")
  add_subdirectory(src/testing)
  message(STATUS ${MSG_HEAD} "Link CppUnit? Yes.")
  # I don't know what this flag does, but if not set, compiling CPPUNIT gets
  # many warnings. -Ashu
else()
  SET(LINK_CPPUNIT FALSE)
  message(STATUS ${MSG_HEAD} "Link CppUnit? No.")
endif()


## for make test, copy instances, cd to src testing, and run unittest
add_custom_target(utest
  ${CMAKE_COMMAND} -E remove_directory ./src/testing/instances
  COMMAND ${CMAKE_COMMAND} -E copy_directory
  ${PROJECT_SOURCE_DIR}/src/testing/instances ./instances
  COMMAND unittest all
  WORKING_DIRECTORY src/testing)


###########################################################################
## Any other extra libs that user may need to link to
###########################################################################
set(MNTR_EXTRA_LIBS "" CACHE STRING
  "Additional libraries that you may want to link to. e.g. -lbz2 -llapack")

###########################################################################
## Documentation using doxygen will be installed in ./doxygen
###########################################################################
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory doxygen)
add_custom_target(doc
  ${CMAKE_COMMAND} -E remove_directory html
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/doc/doxyfile .
  COMMAND echo "INPUT = ${PROJECT_SOURCE_DIR}/src ${PROJECT_SOURCE_DIR}/doc" >> doxyfile
  COMMAND echo "EXCLUDE = ${PROJECT_SOURCE_DIR}/src/testing" >> doxyfile
  COMMAND echo "HTML_FOOTER = ${PROJECT_SOURCE_DIR}/doc/footer.html" >> doxyfile
  COMMAND doxygen doxyfile
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/doc/logo/small.jpg html
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/doc/logo/tiny.jpg html
  WORKING_DIRECTORY doxygen)

message (STATUS ${MSG_HEAD}
  "rpath for installation is set to ${CMAKE_INSTALL_RPATH}")

###########################################################################
## hide unused options
###########################################################################
set(EXECUTABLE_OUTPUT_PATH "${EXECUTABLE_OUTPUT_PATH}" CACHE INTERNAL "")
set(LIBRARY_OUTPUT_PATH "${LIBRARY_OUTPUT_PATH}" CACHE INTERNAL "")
