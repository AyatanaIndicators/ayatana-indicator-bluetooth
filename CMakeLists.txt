cmake_minimum_required(VERSION 3.13)
project (ayatana-indicator-bluetooth VERSION 24.5.0 LANGUAGES C CXX)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    SET(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "..." FORCE)
endif(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" "${CMAKE_MODULE_PATH}")

# Options

option(ENABLE_WERROR "Treat all build warnings as errors" OFF)
set (CMAKE_BUILD_TYPE "Release")

if(ENABLE_WERROR)
    add_definitions("-Werror")
endif()

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    add_definitions("-Weverything")
else()
    add_definitions("-Wall")
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

find_package(Vala 0.20)
find_package(GObjectIntrospection 0.9.12)

include_directories(${SOURCE_DIR})
include_directories(${SOURCE_BINARY_DIR})

configure_file(
  "config.h.in"
  "${CMAKE_CURRENT_BINARY_DIR}/config.h"
)

add_subdirectory(data)
add_subdirectory(src)
add_subdirectory(po)

# Display config info

message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "Build with -Werror: ${ENABLE_WERROR}")
