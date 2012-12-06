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
        var item = new Ido.SwitchMenuItem ();
        item.active = newitem.property_get_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE) == Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED;
        var label = new Gtk.Label (newitem.property_get (Dbusmenu.MENUITEM_PROP_LABEL));
        label.visible = true;
        item.content_area.add (label);
        newitem.property_changed.connect ((mi, prop, value) =>
        {
            label.label = mi.property_get (Dbusmenu.MENUITEM_PROP_LABEL);
            item.active = mi.property_get_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE) == Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED;
        });
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
                                                           proxy.g_properties_changed.connect (update_icon_cb);
                                                           update_icon_cb ();
                                                       }
                                                       catch (IOError e)
                                                       {
                                                           warning ("Failed to connect to bluetooth service: %s", e.message);
                                                       }
                                                   });
        }
    }    

    private void update_icon_cb ()
    {
        Indicator.image_helper_update (image, proxy.icon_name);
    }
}

[DBus (name = "com.canonical.indicator.bluetooth.service")]
public interface BluetoothService : DBusProxy
{
    public abstract string icon_name { owned get; }
}

public static string get_version ()
{
    return Indicator.VERSION;
}

public static GLib.Type get_type ()
{
    return typeof (BluetoothIndicator);
}
