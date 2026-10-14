cmake_minimum_required(VERSION 3.10)
project(TrustLens CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

include_directories(include)

add_executable(trustlens src/main.cpp)
add_executable(generate_data src/generate_data.cpp)

# SQLite is optional for the data pipeline. Without it, the program writes a
# .sql script instead of creating a live database.
find_package(SQLite3 QUIET)
if(SQLite3_FOUND)
  target_compile_definitions(trustlens PRIVATE USE_SQLITE)
  target_include_directories(trustlens PRIVATE ${SQLite3_INCLUDE_DIRS})
  target_link_libraries(trustlens PRIVATE ${SQLite3_LIBRARIES})

  # The website backend reads the generated database and therefore requires
  # SQLite. It is intentionally omitted in script-only mode.
  find_package(Threads REQUIRED)
  add_executable(trustlens_server src/server.cpp)
  target_include_directories(trustlens_server PRIVATE ${SQLite3_INCLUDE_DIRS})
  target_link_libraries(trustlens_server PRIVATE ${SQLite3_LIBRARIES} Threads::Threads)
  message(STATUS "SQLite found - live database mode")
else()
  message(STATUS "SQLite not found - script-only mode")
endif()
