/*
 * Copyright (C) 2012 Canonical Ltd.
 * Author: Robert Ancell <robert.ancell@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class BluetoothIndicator : Indicator.Object
{
    private Indicator.ServiceManager service;
    private Gtk.Image image;
    private DbusmenuGtk.Menu menu;
    private BluetoothService proxy;
    private string accessible_description = "Bluetooth: On";

    construct
    {
        service = new Indicator.ServiceManager ("com.canonical.indicator.bluetooth");
        service.connection_change.connect (connection_change_cb);
        menu = new DbusmenuGtk.Menu ("com.canonical.indicator.bluetooth", "/com/canonical/indicator/bluetooth/menu");
        image = Indicator.image_helper ("bluetooth-active");
        image.visible = true;

        var menu_client = menu.get_client ();
        menu_client.add_type_handler_full ("x-canonical-switch", new_switch_cb);
    }

    private bool new_switch_cb (Dbusmenu.Menuitem newitem, Dbusmenu.Menuitem parent, Dbusmenu.Client client)
    {
        var item = new Switch (newitem);
        (client as DbusmenuGtk.Client).newitem_base (newitem, item, parent);
        return true;
    }

    public override unowned Gtk.Image get_image ()
    {
        return image;
    }

    public override unowned Gtk.Menu get_menu ()
    {
        return menu;
    }

    public override unowned string get_accessible_desc ()
    {
        return accessible_description;
    }

    private void connection_change_cb (bool connected)
    {
        if (!connected)
            return;

        // FIXME: Set proxy to null on disconnect?
        // FIXME: Use Cancellable to cancel existing connection
        if (proxy == null)
        {
            Bus.get_proxy.begin<BluetoothService> (BusType.SESSION,
                                                   "com.canonical.indicator.bluetooth",
                                                   "/com/canonical/indicator/bluetooth/service",
                                                   DBusProxyFlags.NONE, null, (object, result) =>
                                                   {
                                                       try
                                                       {
                                                           proxy = Bus.get_proxy.end (result);
                                                           proxy.g_properties_changed.connect (server_properties_changed_cb);
                                                           server_properties_changed_cb ();
                                                       }
                                                       catch (IOError e)
                                                       {
                                                           warning ("Failed to connect to bluetooth service: %s", e.message);
                                                       }
                                                   });
        }
    }    

    private void server_properties_changed_cb ()
    {
        Indicator.image_helper_update (image, proxy.icon_name);
        accessible_description = proxy.accessible_description;
    }
}

public class Switch : Ido.SwitchMenuItem
{
    public Dbusmenu.Menuitem menuitem;
    public new Gtk.Label label;
    private bool updating_switch = false;
    
    public Switch (Dbusmenu.Menuitem menuitem)
    {
        this.menuitem = menuitem;
        label = new Gtk.Label ("");
        label.visible = true;
        content_area.add (label);

        /* Be the first listener to the activate signal so we can stop it
         * emitting when we change the state. Without this you get feedback loops */
        activate.connect (() => 
        {
            if (updating_switch)
                Signal.stop_emission_by_name (this, "activate");
        });

        menuitem.property_changed.connect ((mi, prop, value) => { update (); });
        update ();
    }

    private void update ()
    {
        updating_switch = true;
        label.label = menuitem.property_get (Dbusmenu.MENUITEM_PROP_LABEL);
        active = menuitem.property_get_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE) == Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED;
        updating_switch = false;
    }
}

[DBus (name = "com.canonical.indicator.bluetooth.service")]
public interface BluetoothService : DBusProxy
{
    public abstract string icon_name { owned get; }
    public abstract string accessible_description { owned get; }
}

public static string get_version ()
{
    return Indicator.VERSION;
}

public static GLib.Type get_type ()
{
    return typeof (BluetoothIndicator);
}
