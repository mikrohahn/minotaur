add_definitions(-DUSE_OSILP)
include_directories("${PROJECT_BINARY_DIR}/src/base")
include_directories("${PROJECT_SOURCE_DIR}/src/base")

set(OSI_LINK_LIBS)
set(OSI_INC_DIRS)
if (LINK_OSI)
  include_directories(${MNTR_DEP_OSI_INCLUDE_DIRS})
  link_directories(${MNTR_DEP_OSI_LIBRARY_DIRS})
  list(APPEND OSI_LINK_LIBS "${MNTR_DEP_OSI_LIBRARIES}")
  list(APPEND OSI_INC_DIRS "${MNTR_DEP_OSI_INCLUDE_DIRS}")
endif()

if (LINK_CLP)
  include_directories(${MNTR_DEP_CLP_INCLUDE_DIRS})
  link_directories(${MNTR_DEP_CLP_LIBRARY_DIRS})
  list(APPEND OSI_LINK_LIBS "${MNTR_DEP_CLP_LIBRARIES}")
  list(APPEND OSI_INC_DIRS "${MNTR_DEP_CLP_INCLUDE_DIRS}")
endif()

if (LINK_CPX)
  include_directories(${MNTR_DEP_CPX_INCLUDE_DIRS})
  link_directories(${MNTR_DEP_CPX_LIBRARY_DIRS})
  list(APPEND OSI_LINK_LIBS "${MNTR_DEP_CPX_LIBRARIES}")
  list(APPEND OSI_INC_DIRS "${MNTR_DEP_CPX_INCLUDE_DIRS}")
endif()

if (LINK_GRB)
  include_directories(${MNTR_DEP_GRB_INCLUDE_DIRS})
  link_directories(${MNTR_DEP_GRB_LIBRARY_DIRS})
  list(APPEND OSI_LINK_LIBS "${MNTR_DEP_GRB_LIBRARIES}")
  list(APPEND OSI_INC_DIRS "${MNTR_DEP_GRB_INCLUDE_DIRS}")
endif()

add_definitions(-DCOIN_BIG_INDEX=0) ## avoid warnings
set (OSILP_SOURCES
  OsiLPEngine.cpp
)
set (OSILP_HEADERS
  OsiLPEngine.h
)

set(MNTR_ENGINE_OSI_INCLUDE_DIRS "${OSI_INC_DIRS};${PROJECT_SOURCE_DIR}/src/engines/OsiLP" PARENT_SCOPE)
set(MNTR_ENGINE_OSI_LIBRARY_DIRS "${MNTR_DEP_OSI_LIBRARY_DIRS}" PARENT_SCOPE)
set(MNTR_ENGINE_OSI_LIBRARIES "mntrosilp" ${MNTR_DEP_OSI_LIBRARIES} PARENT_SCOPE)

add_library(mntrosilp ${OSILP_SOURCES})
target_link_libraries(mntrosilp ${OSI_LINK_LIBS})

if (BUILD_SHARED_LIBS)
install(TARGETS mntrosilp LIBRARY DESTINATION lib)
else (BUILD_SHARED_LIBS)
install(TARGETS mntrosilp ARCHIVE DESTINATION lib)
endif (BUILD_SHARED_LIBS)

install(FILES ${OSILP_HEADERS} DESTINATION include/minotaur)
