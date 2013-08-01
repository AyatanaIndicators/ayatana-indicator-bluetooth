
# the indicator bus file
indicatorsdir = $(prefix)/share/unity/indicators
dist_indicators_DATA = com.canonical.indicator.datetime

# the dbus service file
dbus_servicesdir = $(datadir)/dbus-1/services
dbus_services_DATA = indicator-bluetooth.service

%.service: %.service.in
	sed -e "s|\@pkglibexecdir\@|$(pkglibexecdir)|" $< > $@

gsettings_SCHEMAS = com.canonical.indicator.bluetooth.gschema.xml
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

EXTRA_DIST = \
  indicator-bluetooth.service.in \
  com.canonical.indicator.bluetooth.gschema.xml.in

CLEANFILES = \
  $(dbus_services_DATA) \
  $(gsettings_SCHEMAS)
