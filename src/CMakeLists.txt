###########################
# Vala Generation
###########################

set(HEADER_PATH "${CMAKE_CURRENT_BINARY_DIR}/ayatana-indicator-bluetooth-service.h")
set(SYMBOLS_PATH "${CMAKE_CURRENT_BINARY_DIR}/ayatana-indicator-bluetooth-service.def")
set(VAPI_PATH "${CMAKE_CURRENT_BINARY_DIR}/ayatana-indicator-bluetooth-service.vapi")

vala_init(ayatana-indicator-bluetooth-service
  DEPENDS
  PACKAGES
    config
    rfkill
    posix
    gio-2.0
    gio-unix-2.0
    AyatanaCommon
  OPTIONS
    --ccode
    --target-glib=${GLIB_2_0_REQUIRED_VERSION}
    --vapidir=${CMAKE_SOURCE_DIR}/vapi/
    --vapidir=.
)

vala_add(ayatana-indicator-bluetooth-service
main.vala
    DEPENDS
    service
    bluetooth
    device
    bluez
    killswitch
)

vala_add(ayatana-indicator-bluetooth-service
    bluetooth.vala
        DEPENDS
        device
)

vala_add(ayatana-indicator-bluetooth-service
    bluez.vala
        DEPENDS
        bluetooth
        killswitch
        device
)

vala_add(ayatana-indicator-bluetooth-service
    desktop.vala
        DEPENDS
        profile
        bluetooth
        device
)

vala_add(ayatana-indicator-bluetooth-service
    greeter.vala
        DEPENDS
        profile
        bluetooth
        device
)

vala_add(ayatana-indicator-bluetooth-service
    device.vala
)

vala_add(ayatana-indicator-bluetooth-service
  killswitch.vala
)

vala_add(ayatana-indicator-bluetooth-service
    phone.vala
        DEPENDS
        profile
        bluetooth
        device
)

vala_add(ayatana-indicator-bluetooth-service
    profile.vala
        DEPENDS
        bluetooth
        device
)

vala_add(ayatana-indicator-bluetooth-service
    service.vala
        DEPENDS
        bluetooth
        profile
        device
        phone
        desktop
        greeter
)

vala_finish(ayatana-indicator-bluetooth-service
  SOURCES
    project_VALA_SOURCES
  OUTPUTS
    project_VALA_C
  GENERATE_HEADER
    ${HEADER_PATH}
  GENERATE_SYMBOLS
    ${SYMBOLS_PATH}
  GENERATE_VAPI
    ${VAPI_PATH}
)

set_source_files_properties(
  ${project_VALA_SOURCES}
  PROPERTIES
  HEADER_FILE_ONLY TRUE
)

set(
  INDICATOR_BLUETOOTH_SOURCES
  ${project_VALA_SOURCES}
  ${project_VALA_C}
  ${SYMBOLS_PATH}
)

###########################
# Lib
###########################

add_definitions(
  -w
  -DG_LOG_DOMAIN="ayatana-indicator-bluetooth"
)

add_library(
    ayatana-indicator-bluetooth-service-lib STATIC
    ${INDICATOR_BLUETOOTH_SOURCES}
)

target_link_libraries(
  ayatana-indicator-bluetooth-service-lib
  ${BLUETOOTHSERVICE_LIBRARIES}
  -lm
)

###########################
# Executable
###########################

include_directories(${CMAKE_BINARY_DIR})

add_executable(
  ayatana-indicator-bluetooth-service-bin
  ${project_VALA_C}
)

set_target_properties(
  ayatana-indicator-bluetooth-service-bin
  PROPERTIES
  OUTPUT_NAME "ayatana-indicator-bluetooth-service"
)

target_link_libraries(
  ayatana-indicator-bluetooth-service-bin
  ayatana-indicator-bluetooth-service-lib
)

###########################
# Installation
###########################

install(
  TARGETS ayatana-indicator-bluetooth-service-bin
  RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_LIBEXECDIR}/ayatana-indicator-bluetooth/
)

# coverage reporting
set(COVERAGE_TARGETS
  ${COVERAGE_TARGETS}
  ayatana-indicator-bluetooth-service-lib
  ayatana-indicator-bluetooth-service-bin
  PARENT_SCOPE
)
