
public static int
main (string[] args)
{
  Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
  Intl.setlocale (LocaleCategory.ALL, "");
  Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.GNOMELOCALEDIR);
  Intl.textdomain (Config.GETTEXT_PACKAGE);

  var bluetooth = new Bluez (new KillSwitch ());
  var service = new BluetoothIndicator (bluetooth);
 
  service.run ();

  return Posix.EXIT_SUCCESS;
}
