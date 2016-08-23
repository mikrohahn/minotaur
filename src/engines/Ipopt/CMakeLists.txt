add_definitions(-DUSE_IPOPT)
include_directories("${PROJECT_BINARY_DIR}/src/base")
include_directories("${PROJECT_SOURCE_DIR}/src/base")
include_directories(${MNTR_DEP_IPOPT_INCLUDE_DIRS})
link_directories(${MNTR_DEP_IPOPT_LIBRARY_DIRS})

set (IPOPT_SOURCES
  IpoptDummy.f
  IpoptEngine.cpp
)
set (IPOPT_HEADERS
  IpoptEngine.h
  IpoptEngineTnlp.h
)

set(MNTR_ENGINE_IPOPT_INCLUDE_DIRS "${MNTR_DEP_IPOPT_INCLUDE_DIRS};${PROJECT_SOURCE_DIR}/src/engines/Ipopt" PARENT_SCOPE)
set(MNTR_ENGINE_IPOPT_LIBRARY_DIRS "${MNTR_DEP_IPOPT_LIBRARY_DIRS}" PARENT_SCOPE)
set(MNTR_ENGINE_IPOPT_LIBRARIES "mntripopt" ${MNTR_DEP_IPOPT_LIBRARIES} PARENT_SCOPE)

add_library(mntripopt ${IPOPT_SOURCES})
target_link_libraries(mntripopt ${MNTR_DEP_IPOPT_LIBS})

if (BUILD_SHARED_LIBS)
install(TARGETS mntripopt LIBRARY DESTINATION lib)
else (BUILD_SHARED_LIBS)
install(TARGETS mntripopt ARCHIVE DESTINATION lib)
endif (BUILD_SHARED_LIBS)

install(FILES ${IPOPT_HEADERS} DESTINATION include/minotaur)
