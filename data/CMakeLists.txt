
find_package(GSettings)

###########################
# Indicator service
###########################

set(
  INDICATOR_DIR
  "${CMAKE_INSTALL_FULL_DATADIR}/ayatana/indicators"
  CACHE FILEPATH "Ayatana Indicators Directory"
)

install(
  FILES "org.ayatana.indicator.bluetooth"
  DESTINATION "${INDICATOR_DIR}"
)

###########################
# Systemd Job
###########################

pkg_check_modules(SYSTEMD systemd)
if (${SYSTEMD_FOUND})

  # where to install
  pkg_get_variable(SYSTEMD_USER_DIR systemd systemduserunitdir)
  message (STATUS "${SYSTEMD_USER_DIR} is the systemd user unit file install dir")

  set (SYSTEMD_USER_NAME "${CMAKE_PROJECT_NAME}.service")
  set (SYSTEMD_USER_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SYSTEMD_USER_NAME}")
  set (SYSTEMD_USER_FILE_IN "${CMAKE_CURRENT_SOURCE_DIR}/${SYSTEMD_USER_NAME}.in")

  # build it
  configure_file ("${SYSTEMD_USER_FILE_IN}" "${SYSTEMD_USER_FILE}")

  # install it
  install (FILES "${SYSTEMD_USER_FILE}"
           DESTINATION "${SYSTEMD_USER_DIR}")
endif()

###########################
# XDG Autostart
###########################

set(
  INDICATOR_BLUETOOTH_XDG_AUTOSTART
  "${CMAKE_CURRENT_BINARY_DIR}/ayatana-indicator-bluetooth.desktop"
)

configure_file(
  "ayatana-indicator-bluetooth.desktop.in"
  ${INDICATOR_BLUETOOTH_XDG_AUTOSTART}
  @ONLY
)

install(
  FILES "${INDICATOR_BLUETOOTH_XDG_AUTOSTART}"
  DESTINATION "/etc/xdg/autostart"
)

###########################
# GSettings
###########################

add_schema ("org.ayatana.indicator.bluetooth.gschema.xml")
