include_directories("${PROJECT_BINARY_DIR}/src/base")
include_directories("${PROJECT_SOURCE_DIR}/src/base")
include_directories("${PROJECT_SOURCE_DIR}/src/engines")
include_directories(${MNTR_DEP_CPPUNIT_INCLUDE_DIRS})

set (MINOTAUR_SOURCES
     unittest.cpp
     CGraphUT.cpp
     #CoverCutGeneratorUT.cpp # Serdar added.
     EnvironmentUT.cpp
     FunctionUT.cpp
     ProblemUT.cpp
     JacobianUT.cpp
     HessianOfLagUT.cpp
     #KnapsackListUT.cpp # Serdar added.
     LapackUT.cpp
     LinearFunctionUT.cpp
     LoggerUT.cpp
     ObjectiveUT.cpp
     OperationsUT.cpp
     PolyUT.cpp
     QuadraticFunctionUT.cpp
     TimerUT.cpp
)

## define where to search for external libraries. This path must be defined
## before add_executable is called.
link_directories(${MNTR_DEP_CPPUNIT_LIBRARY_DIRS})

if (LINK_BQPD)
  add_definitions(-DUSE_BQPD)
  include_directories("${PROJECT_SOURCE_DIR}/src/engines/Bqpd")
  link_directories(${BQPD_LIB_DIR_F})
endif()
if (LINK_FILTER_SQP)
  add_definitions(-DUSE_FilterSQP)
  include_directories("${PROJECT_SOURCE_DIR}/src/engines/FilterSQP")
  link_directories(${FILTER_LIB_DIR_F})
endif()

if (LINK_IPOPT)
  add_definitions(-DUSE_IPOPT)
  include_directories(${MNTR_ENGINE_IPOPT_INCLUDE_DIRS})
  set (MINOTAUR_SOURCES  ${MINOTAUR_SOURCES} NLPBnbUT.cpp IpoptEngineUT.cpp)
  link_directories(${MNTR_ENGINE_IPOPT_LIBRARY_DIRS})
endif()

if (LINK_OSI)
  add_definitions(-DUSE_OSILP)
  include_directories(${MNTR_ENGINE_OSI_INCLUDE_DIRS})
  link_directories(${MNTR_ENGINE_OSI_LIBRARY_DIRS})
endif()

if (LINK_ASL)
  add_definitions(-DUSE_MINOTAUR_AMPL_INTERFACE)
  set (MINOTAUR_SOURCES  ${MINOTAUR_SOURCES} AMPLInstanceUT.cpp
	                                     AMPLCGraphUT.cpp
					     PolySolverUT.cpp
				             TransformerUT.cpp)
  include_directories("${PROJECT_SOURCE_DIR}/src/interfaces/ampl" ${ASL_INC_DIR_F})
  if (LINK_BQPD)
    set (MINOTAUR_SOURCES  ${MINOTAUR_SOURCES} AMPLBqpdUT.cpp)
  endif()
  if (LINK_FILTER_SQP)
    set (MINOTAUR_SOURCES  ${MINOTAUR_SOURCES} AMPLFilterSQPUT)
  endif()
  if (LINK_IPOPT)
    set (MINOTAUR_SOURCES  ${MINOTAUR_SOURCES} AMPLIpoptUT.cpp)
  endif()
  if (LINK_OSI)
    set (MINOTAUR_SOURCES  ${MINOTAUR_SOURCES} AMPLOsiUT.cpp)
  endif()
endif()

add_executable(unittest EXCLUDE_FROM_ALL ${MINOTAUR_SOURCES})
target_link_libraries(unittest cppunit mntrengfac)

if (LINK_BQPD)
  target_link_libraries(unittest mntrbqpd ${BQPD_LIBS})
  if (Fortran_COMPILER_NAME STREQUAL "gfortran")
    target_link_libraries(unittest gfortran)
  endif()
endif()
if (LINK_FILTER_SQP)
  target_link_libraries(unittest mntrfiltersqp ${FILTER_SQP_LIBS})
  if (Fortran_COMPILER_NAME STREQUAL "gfortran")
    target_link_libraries(unittest gfortran)
  endif()
endif()
if (LINK_IPOPT)
  target_link_libraries(unittest ${MNTR_ENGINE_IPOPT_LIBRARIES})
  if (Fortran_COMPILER_NAME STREQUAL "gfortran")
    target_link_libraries(unittest gfortran)
  endif()
  message(STATUS ${MSG_HEAD} "fortran compiler = ${Fortran_COMPILER_NAME}")
endif()
if (LINK_OSI)
  target_link_libraries(unittest ${MNTR_ENGINE_OSI_LIBRARIES})
endif()
if (LINK_ASL)
  target_link_libraries(unittest mntrampl ${MNTR_DEP_AMPL_LIBRARIES})
endif()

#add_custom_target(Name test unittest all)
target_link_libraries(unittest minotaur lapack blas dl)
target_link_libraries(unittest ${MNTR_EXTRA_LIBS})
