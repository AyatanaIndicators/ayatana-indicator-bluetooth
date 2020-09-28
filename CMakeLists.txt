project(ayatana-indicator-bluetooth C CXX)
cmake_minimum_required(VERSION 2.8.9)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" "${CMAKE_MODULE_PATH}")

set(PACKAGE ${CMAKE_PROJECT_NAME})
set(PROJECT_VERSION 0.8.0)
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
)

include_directories(${BLUETOOTHSERVICE_INCLUDE_DIRS})

set(URL_DISPATCHER_REQUIRED_VERSION 0.1)

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
