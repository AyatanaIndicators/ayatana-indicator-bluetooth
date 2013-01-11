dbus_servicesdir = $(DBUSSERVICEDIR)
dbus_services_DATA = indicator-bluetooth.service

%.service: %.service.in
	sed -e "s|\@libexecdir\@|$(libexecdir)|" $< > $@

EXTRA_DIST = indicator-bluetooth.service.in

CLEANFILES = \
  $(dbus_services_DATA)
