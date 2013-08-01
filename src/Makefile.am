pkglibexec_PROGRAMS = indicator-bluetooth-service

indicator_bluetooth_service_SOURCES = 	\
	indicator3-0.4.vapi \
	org-bluez.vala \
	bluetooth.vala \
	bluez.vala \
	desktop.vala \
	main.vala \
	menu.vala \
	phone.vala \
	killswitch.vala \
	service.vala

indicator_bluetooth_service_VALAFLAGS = \
	--ccode \
	--vapidir=$(top_srcdir)/vapi/ \
	--vapidir=./ \
	--pkg gnome-bluetooth-1.0 \
	--pkg config \
	--pkg rfkill \
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

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	*_vala.stamp
