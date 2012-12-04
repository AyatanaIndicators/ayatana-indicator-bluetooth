bin_PROGRAMS = indicator-bluetooth

indicator_bluetooth_SOURCES = 	\
	config.vapi \
	gnome-bluetooth-1.0.vapi \
	indicator-bluetooth.vala

indicator_bluetooth_VALAFLAGS = \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gtk+-3.0 \
	--pkg appindicator3-0.1

indicator_bluetooth_CFLAGS = \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DLOCALE_DIR=\"$(datadir)/locale\" \
	$(INDICATOR_BLUETOOTH_CFLAGS)

indicator_bluetooth_LDADD = \
	$(INDICATOR_BLUETOOTH_LIBS)

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	*_vala.stamp
