AC_INIT(indicator-bluetooth, 0.0.5)
AM_INIT_AUTOMAKE([1.11 no-dist-gzip dist-xz foreign])
AM_SILENT_RULES([yes])
AM_MAINTAINER_MODE

AM_PROG_VALAC([0.16.0])
AM_PROG_CC_C_O
LT_INIT

GLIB_GSETTINGS

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################

PKG_CHECK_MODULES(INDICATOR_BLUETOOTH_SERVICE, [
  glib-2.0
  gnome-bluetooth-1.0
  indicator3-0.4
  dbusmenu-gtk3-0.4
])

PKG_CHECK_MODULES(INDICATOR_BLUETOOTH, [
  glib-2.0
  gtk+-3.0
  indicator3-0.4
  dbusmenu-gtk3-0.4
  libido3-0.1
])

dnl ###########################################################################
dnl Internationalization
dnl ###########################################################################

IT_PROG_INTLTOOL([0.35.0])
AC_SUBST(GETTEXT_PACKAGE, indicator-bluetooth)

with_localinstall="no"
AC_ARG_ENABLE(localinstall, AS_HELP_STRING([--enable-localinstall], [install all of the files localy instead of system directories (for distcheck)]), with_localinstall=$enableval, with_localinstall=no)

dnl ###########################################################################
dnl Indicator Info
dnl ###########################################################################

AS_IF([test "x$with_localinstall" = "xyes"],
	[
	INDICATORDIR="${libdir}/indicators3/7/"
	],
	[
	INDICATORDIR=`$PKG_CONFIG --variable=indicatordir indicator3-0.4`
	])
AC_SUBST(INDICATORDIR)

dnl ###########################################################################
dnl DBus Service Info
dnl ###########################################################################

if test "x$with_localinstall" = "xyes"; then
	DBUSSERVICEDIR="${datadir}/dbus-1/services/"
else
	DBUSSERVICEDIR=`$PKG_CONFIG --variable=session_bus_services_dir dbus-1`
fi
AC_SUBST(DBUSSERVICEDIR)

dnl ###########################################################################
dnl Files to generate
dnl ###########################################################################

AC_OUTPUT([
Makefile
data/Makefile
po/Makefile.in
src/Makefile
])
