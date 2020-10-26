BUILT_SOURCES =
EXTRA_DIST =
CLEANFILES =

# the indicator bus file
indicatorsdir = $(datadir)/ayatana/indicators
dist_indicators_DATA = org.ayatana.indicator.bluetooth

# the systemd unit file
systemddir = $(SYSTEMD_USERDIR)
systemd_DATA = ayatana-indicator-bluetooth.service
systemd_in = $(systemd_DATA:.service=.service.in)
$(systemd_DATA): $(systemd_in)
	$(AM_V_GEN) $(SED) -e "s|\@pkglibexecdir\@|$(pkglibexecdir)|" $< > $@
BUILT_SOURCES += $(systemd_DATA)
EXTRA_DIST += $(systemd_in)
CLEANFILES += $(systemd_DATA)

# the xdg autostart job file
xdg_autostartdir = /etc/xdg/autostart
xdg_autostart_DATA = ayatana-indicator-bluetooth.desktop
xdg_autostart_in = $(xdg_autostart_DATA:.desktop=.desktop.in)
$(xdg_autostart_DATA): $(xdg_autostart_in)
	$(AM_V_GEN) $(SED) -e "s|\@pkglibexecdir\@|$(pkglibexecdir)|" $< > $@
BUILT_SOURCES += $(xdg_autostart_DATA)
EXTRA_DIST += $(xdg_autostart_in)
CLEANFILES += $(xdg_autostart_DATA)

# the gsettings schema
gsettings_SCHEMAS = org.ayatana.indicator.bluetooth.gschema.xml
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

EXTRA_DIST += \
  org.ayatana.indicator.bluetooth.gschema.xml.in \
  ayatana-indicator-bluetooth.desktop.in

CLEANFILES += \
  $(dbus_services_DATA) \
  $(gsettings_SCHEMAS)
