AC_INIT(indicator-bluetooth, 0.0.6)
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

dnl ###########################################################################
dnl Files to generate
dnl ###########################################################################

AC_OUTPUT([
Makefile
data/Makefile
po/Makefile.in
src/Makefile
])
