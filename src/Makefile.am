pkglibexec_PROGRAMS = indicator-bluetooth-service
indicatordir = ${libdir}/indicators3/7
indicator_LTLIBRARIES = libbluetooth.la

indicator_bluetooth_service_SOURCES = 	\
	config.vapi \
	indicator3-0.4.vapi \
	gnome-bluetooth-1.0.vapi \
	indicator-bluetooth-service.vala

indicator_bluetooth_service_VALAFLAGS = \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gtk+-3.0 \
	--pkg Dbusmenu-0.4

indicator_bluetooth_service_CFLAGS = \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DLOCALE_DIR=\"$(datadir)/locale\" \
	$(INDICATOR_BLUETOOTH_SERVICE_CFLAGS)

indicator_bluetooth_service_LDADD = \
	$(INDICATOR_BLUETOOTH_SERVICE_LIBS)

libbluetooth_la_SOURCES = 	\
	config.vapi \
	indicator3-0.4.vapi \
	indicator-bluetooth.vala \
	libido3-0.1.vapi

libbluetooth_la_VALAFLAGS = \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gtk+-3.0 \
	--pkg Dbusmenu-0.4 \
	--pkg DbusmenuGtk3-0.4

libbluetooth_la_CFLAGS = \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	$(INDICATOR_BLUETOOTH_CFLAGS)

libbluetooth_la_LIBADD = \
	$(INDICATOR_BLUETOOTH_LIBS)

libbluetooth_la_LDFLAGS = \
	-module -avoid-version

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	*_vala.stamp
