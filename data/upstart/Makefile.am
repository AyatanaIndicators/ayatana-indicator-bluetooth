BUILT_SOURCES =
EXTRA_DIST =
CLEANFILES =

# the upstart version of the xdg autostart job file
# see https://code.launchpad.net/~charlesk/indicator-bluetooth/upstart-job/+merge/198100
upstart_xdg_autostartdir = $(datadir)/upstart/xdg/autostart
upstart_xdg_autostart_DATA = ayatana-indicator-bluetooth.desktop
upstart_xdg_autostart_in = ayatana-indicator-bluetooth.desktop.in
$(upstart_xdg_autostart_DATA): $(upstart_xdg_autostart_in)
	$(AM_V_GEN) $(SED) -e "s|\@pkglibexecdir\@|$(pkglibexecdir)|" $< > $@
BUILT_SOURCES += $(upstart_xdg_autostart_DATA)
EXTRA_DIST += $(upstart_xdg_autostart_in)
CLEANFILES += $(upstart_xdg_autostart_DATA)

EXTRA_DIST += \
  ayatana-indicator-bluetooth.upstart.desktop.in
