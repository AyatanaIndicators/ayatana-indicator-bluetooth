[DBus (name = "org.bluez.Manager")]
interface BluezManager : Object
{
    public abstract string default_adapter () throws IOError;
}

[DBus (name = "org.bluez.Adapter")]
interface BluezAdapter : Object
{
    public abstract string[] list_devices () throws IOError;
    public abstract HashTable<string, Variant> get_properties () throws IOError;
    public abstract void set_property (string name, Variant value) throws IOError;
}

[DBus (name = "org.bluez.Device")]
interface BluezDevice : Object
{
    public abstract HashTable<string, Variant> get_properties () throws IOError;
}

[DBus (name = "org.bluez.Audio")]
interface BluezAudio : Object
{
    public abstract void connect () throws IOError;
}

[DBus (name = "org.bluez.Input")]
interface BluezInput : Object
{
    public abstract void connect () throws IOError;
}

int main (string[] args)
{
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALE_DIR);
    Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (GETTEXT_PACKAGE);

    Gtk.init (ref args);

    BluezAdapter adapter;
    try
    {
        var manager = Bus.get_proxy_sync<BluezManager> (BusType.SYSTEM, "org.bluez", "/");
        var path = manager.default_adapter ();
        adapter = Bus.get_proxy_sync<BluezAdapter> (BusType.SYSTEM, "org.bluez", path);
    }
    catch (IOError e)
    {
        return Posix.EXIT_FAILURE;
    }

    var indicator = new AppIndicator.Indicator ("indicator-bluetooth", "bluetooth-active", AppIndicator.IndicatorCategory.HARDWARE);
    indicator.set_status (AppIndicator.IndicatorStatus.ACTIVE);

    var menu = new Gtk.Menu ();
    indicator.set_menu (menu);

    var item = new Gtk.MenuItem.with_label ("Bluetooth: On");
    item.sensitive = false;
    item.show ();
    menu.append (item);

    item = new Gtk.MenuItem.with_label ("Turn off Bluetooth");
    item.show ();
    menu.append (item);

    item = new Gtk.CheckMenuItem.with_label (_("Visible"));
    item.activate.connect (() => { adapter.set_property ("Discoverable", new Variant.boolean (true)); });
    item.show ();
    menu.append (item);
    
    var sep = new Gtk.SeparatorMenuItem ();
    sep.show ();
    menu.append (sep);

    item = new Gtk.MenuItem.with_label (_("Devices"));
    item.sensitive = false;
    item.show ();
    menu.append (item);

    try
    {
        var devices = adapter.list_devices ();
        foreach (var path in devices)
        {
            var device = Bus.get_proxy_sync<BluezDevice> (BusType.SYSTEM, "org.bluez", path);
            var properties = device.get_properties ();
            var iter = HashTableIter<string, Variant> (properties);
            string name;
            Variant value;
            //stderr.printf ("%s\n", path);
            while (iter.next (out name, out value))
            {
                //stderr.printf ("  %s=%s\n", name, value.print (false));
                if (name == "Name" && value.is_of_type (VariantType.STRING))
                {
                    item = new Gtk.MenuItem.with_label (value.get_string ());
                    item.show ();
                    menu.append (item);

                    item.submenu = new Gtk.Menu ();
                    var i = new Gtk.MenuItem.with_label (_("Send files..."));
                    i.show ();
                    i.activate.connect (() => { Process.spawn_command_line_async ("bluetooth-sendto --device=DEVICE --name=NAME"); });
                    item.submenu.append (i);

                    //var i = new Gtk.MenuItem.with_label (_("Keyboard Settings..."));
                    //i.activate.connect (() => { Process.spawn_command_line_async ("gnome-control-center keyboard"); });
                    //var i = new Gtk.MenuItem.with_label (_("Mouse and Touchpad Settings..."));
                    //i.activate.connect (() => { Process.spawn_command_line_async ("gnome-control-center mouse"); });
                    //var i = new Gtk.MenuItem.with_label (_("Sound Settings..."));
                    //i.activate.connect (() => { Process.spawn_command_line_async ("gnome-control-center sound"); });
                }
            }
        }
    }
    catch (IOError e)
    {
        stderr.printf ("%s\n", e.message);
        return Posix.EXIT_FAILURE;
    }

    sep = new Gtk.SeparatorMenuItem ();
    sep.show ();
    menu.append (sep);

    item = new Gtk.MenuItem.with_label (_("Bluetooth Settings..."));
    item.activate.connect (() => { Process.spawn_command_line_async ("gnome-control-center bluetooth"); });
    item.show ();
    menu.append (item);

    Gtk.main ();

    return 0;
}
