dbus_servicesdir = $(DBUSSERVICEDIR)
dist_dbus_services_DATA = indicator-bluetooth.service

%.service: %.service.in
	sed -e "s|\@libexecdir\@|$(libexecdir)|" $< > $@

CLEANFILES = \
  $(dbus_services_DATA)
  