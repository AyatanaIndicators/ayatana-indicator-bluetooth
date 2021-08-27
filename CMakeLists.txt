project(ayatana-indicator-bluetooth C CXX)
cmake_minimum_required(VERSION 3.13)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    SET(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "..." FORCE)
endif(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" "${CMAKE_MODULE_PATH}")

set(PACKAGE ${CMAKE_PROJECT_NAME})
set(PROJECT_VERSION 0.8.2)

# Options

option(ENABLE_TESTS "Enable all tests and checks" OFF)
option(ENABLE_COVERAGE "Enable coverage reports (includes enabling all tests and checks)" OFF)
option(ENABLE_WERROR "Treat all build warnings as errors" OFF)

if(ENABLE_COVERAGE)
    set(ENABLE_TESTS ON)
    set(CMAKE_BUILD_TYPE "Coverage")
else()
    set(CMAKE_BUILD_TYPE "Release")
endif()

if(ENABLE_WERROR)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
endif()

find_package(PkgConfig REQUIRED)
include(GNUInstallDirs)
include(UseVala)

set(GETTEXT_PACKAGE "ayatana-indicator-bluetooth")
set(LOCALEDIR "${CMAKE_INSTALL_FULL_DATADIR}/locale")
add_definitions( -DGETTEXT_PACKAGE="${GETTEXT_PACKAGE}" )

set(SOURCE_DIR "${CMAKE_SOURCE_DIR}/src")
set(SOURCE_BINARY_DIR "${CMAKE_BINARY_DIR}/src")

set(GLIB_2_0_REQUIRED_VERSION 2.32)
set(GIO_2_0_REQUIRED_VERSION 2.25.13)

pkg_check_modules(
    BLUETOOTHSERVICE REQUIRED
    glib-2.0>=${GLIB_2_0_REQUIRED_VERSION}
    gio-unix-2.0>=${GIO_2_0_REQUIRED_VERSION}
    libayatana-common>=0.9.3
)

include_directories(${BLUETOOTHSERVICE_INCLUDE_DIRS})

set(URL_DISPATCHER_REQUIRED_VERSION 0)

pkg_check_modules(
  URLDISPATCHER
  lomiri-url-dispatcher>=${URL_DISPATCHER_REQUIRED_VERSION}
)
include_directories(${URLDISPATCHER_INCLUDE_DIRS})

find_package(Vala 0.20)

find_package(GObjectIntrospection 0.9.12)

include_directories(${SOURCE_DIR})
include_directories(${SOURCE_BINARY_DIR})

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c11")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

add_definitions(
  -Wall
)

configure_file(
  "config.h.in"
  "${CMAKE_CURRENT_BINARY_DIR}/config.h"
)

add_subdirectory(data)
add_subdirectory(src)
add_subdirectory(po)

# testing & coverage

if (ENABLE_TESTS)

    include(CTest)
    enable_testing()

    if (ENABLE_COVERAGE)

        find_package(CoverageReport)

    endif()

endif()

# Display config info

message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "Unit tests: ${ENABLE_TESTS}")
message(STATUS "Build with -Werror: ${ENABLE_WERROR}")
