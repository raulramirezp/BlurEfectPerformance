cmake_minimum_required(VERSION 2.8)
project( blur-effect )
include(FindOpenMP)
if(OPENMP_FOUND)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
endif()
find_package( OpenCV REQUIRED )
include_directories( ${OpenCV_INCLUDE_DIRS} )
add_compile_options(-fopenmp)
add_executable( blur-effect blur-effect.cpp )
target_link_libraries( blur-effect ${OpenCV_LIBS} )
target_link_libraries( blur-effect ${CMAKE_THREAD_LIBS_INIT} )
