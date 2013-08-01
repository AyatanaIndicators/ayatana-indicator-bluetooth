
public static int
main (string[] args)
{
  Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
  Intl.setlocale (LocaleCategory.ALL, "");
  Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.GNOMELOCALEDIR);
  Intl.textdomain (Config.GETTEXT_PACKAGE);

  var loop = new MainLoop ();

  BluetoothIndicator indicator;
  try
    {
      indicator = new BluetoothIndicator ();
    }
  catch (Error e)
    {
      warning ("Failed to start bluetooth indicator service: %s", e.message);
      return Posix.EXIT_FAILURE;
    }

  loop.run ();
  return Posix.EXIT_SUCCESS;
}
  //var service = new IndicatorSound.Service ();
  //return service.run ();
