/*
 * Copyright (C) 2012-2013 Canonical Ltd.
 * Author: Robert Ancell <robert.ancell@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, version 3 of the License.
 * See http://www.gnu.org/copyleft/gpl.html the full text of the license.
 */

public class BluetoothIndicator
{
    private DBusConnection bus;
    private Indicator.Service indicator_service;
    private Dbusmenu.Server menu_server;
    private BluetoothService bluetooth_service;
    private GnomeBluetooth.Client client;
    private GnomeBluetooth.Killswitch killswitch;
    private bool updating_killswitch = false;
    private Dbusmenu.Menuitem enable_item;
    private Dbusmenu.Menuitem visible_item;
    private bool updating_visible = false;
    private Dbusmenu.Menuitem devices_separator;
    private List<BluetoothMenuItem> device_items;
    private Dbusmenu.Menuitem menu;

    public BluetoothIndicator () throws Error
    {
        bus = Bus.get_sync (BusType.SESSION);

        indicator_service = new Indicator.Service ("com.canonical.indicator.bluetooth");
        menu_server = new Dbusmenu.Server ("/com/canonical/indicator/bluetooth/menu");

        bluetooth_service = new BluetoothService ();
        bus.register_object ("/com/canonical/indicator/bluetooth/service", bluetooth_service);

        killswitch = new GnomeBluetooth.Killswitch ();
        killswitch.state_changed.connect (killswitch_state_changed_cb);

        client = new GnomeBluetooth.Client ();

        menu = new Dbusmenu.Menuitem ();
        menu_server.set_root (menu);

        enable_item = new Dbusmenu.Menuitem ();
        enable_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Bluetooth"));
        enable_item.property_set (Dbusmenu.MENUITEM_PROP_TYPE, "x-canonical-switch");
        enable_item.item_activated.connect (() =>
        {
            if (updating_killswitch)
                return;
            if (killswitch.state == GnomeBluetooth.KillswitchState.UNBLOCKED)
                killswitch.state = GnomeBluetooth.KillswitchState.SOFT_BLOCKED;
            else
                killswitch.state = GnomeBluetooth.KillswitchState.UNBLOCKED;
        });
        menu.child_append (enable_item);

        visible_item = new Dbusmenu.Menuitem ();
        visible_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Visible"));
        visible_item.property_set (Dbusmenu.MENUITEM_PROP_TYPE, "x-canonical-switch");
        bool discoverable;
        client.get ("default-adapter-discoverable", out discoverable);
        visible_item.property_set_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE, discoverable ? Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED : Dbusmenu.MENUITEM_TOGGLE_STATE_UNCHECKED);
        client.notify["default-adapter-discoverable"].connect (() =>
        {
            updating_visible = true;
            bool is_discoverable;
            client.get ("default-adapter-discoverable", out is_discoverable);
            visible_item.property_set_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE, is_discoverable ? Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED : Dbusmenu.MENUITEM_TOGGLE_STATE_UNCHECKED);
            updating_visible = false;
        });
        visible_item.item_activated.connect (() =>
        {
            if (updating_visible)
                return;
            client.set ("default-adapter-discoverable", visible_item.property_get_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE) != Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED);
        });
        menu.child_append (visible_item);

        devices_separator = new Dbusmenu.Menuitem ();
        devices_separator.property_set (Dbusmenu.MENUITEM_PROP_TYPE, Dbusmenu.CLIENT_TYPES_SEPARATOR);
        menu.child_append (devices_separator);

        device_items = new List<BluetoothMenuItem> ();

        client.model.row_inserted.connect (device_changed_cb);
        client.model.row_changed.connect (device_changed_cb);
        client.model.row_deleted.connect (device_removed_cb);
        Gtk.TreeIter iter;
        var have_iter = client.model.get_iter_first (out iter);
        while (have_iter)
        {
            Gtk.TreeIter child_iter;
            var have_child_iter = client.model.iter_children (out child_iter, iter);
            while (have_child_iter)
            {
                device_changed_cb (null, child_iter);
                have_child_iter = client.model.iter_next (ref child_iter);
            }
            have_iter = client.model.iter_next (ref iter);
        }

        var sep = new Dbusmenu.Menuitem ();
        sep.property_set (Dbusmenu.MENUITEM_PROP_TYPE, Dbusmenu.CLIENT_TYPES_SEPARATOR);
        menu.child_append (sep);

        var item = new Dbusmenu.Menuitem ();
        item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Set Up New Device…"));
        item.item_activated.connect (() => { set_up_new_device (); });
        menu.child_append (item);

        item = new Dbusmenu.Menuitem ();
        item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Bluetooth Settings…"));
        item.item_activated.connect (() => { show_control_center ("bluetooth"); });
        menu.child_append (item);

        killswitch_state_changed_cb (killswitch.state);
    }

    private BluetoothMenuItem? find_menu_item (string address)
    {
        foreach (var item in device_items)
            if (item.address == address)
                return item;

        return null;
    }

    private void device_changed_cb (Gtk.TreePath? path, Gtk.TreeIter iter)
    {
        /* Ignore adapters */
        Gtk.TreeIter parent_iter;
        if (!client.model.iter_parent (out parent_iter, iter))
            return;

        DBusProxy proxy;
        string address;
        string alias;
        GnomeBluetooth.Type type;
        string icon;
        bool connected;
        HashTable services;
        string[] uuids;
        client.model.get (iter,
                          GnomeBluetooth.Column.PROXY, out proxy,
                          GnomeBluetooth.Column.ADDRESS, out address,
                          GnomeBluetooth.Column.ALIAS, out alias,
                          GnomeBluetooth.Column.TYPE, out type,
                          GnomeBluetooth.Column.ICON, out icon,
                          GnomeBluetooth.Column.CONNECTED, out connected,
                          GnomeBluetooth.Column.SERVICES, out services,
                          GnomeBluetooth.Column.UUIDS, out uuids);

        /* Skip if haven't actually got any information yet */
        if (proxy == null)
            return;

        /* Find or create menu item */
        var item = find_menu_item (address);
        if (item == null)
        {
            item = new BluetoothMenuItem (client, address);
            item.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, killswitch.state == GnomeBluetooth.KillswitchState.UNBLOCKED);
            var last_item = devices_separator as Dbusmenu.Menuitem;
            if (device_items != null)
                last_item = device_items.last ().data;
            device_items.append (item);
            menu.child_add_position (item, last_item.get_position (menu) + 1);
        }

        item.update (type, proxy, alias, icon, connected, services, uuids);
    }

    private void device_removed_cb (Gtk.TreePath path)
    {
        Gtk.TreeIter iter;
        if (!client.model.get_iter (out iter, path))
            return;

        string address;
        client.model.get (iter, GnomeBluetooth.Column.ADDRESS, out address);

        var item = find_menu_item (address);
        if (item == null)
            return;

        device_items.remove (item);
        menu.child_delete (item);
    }

    private void killswitch_state_changed_cb (GnomeBluetooth.KillswitchState state)
    {
        updating_killswitch = true;

        var enabled = state == GnomeBluetooth.KillswitchState.UNBLOCKED;

        bluetooth_service._icon_name = enabled ? "bluetooth-active" : "bluetooth-disabled";
        bluetooth_service._accessible_description = enabled ? _("Bluetooth: On") : _("Bluetooth: Off");

        var builder = new VariantBuilder (VariantType.ARRAY);
        builder.add ("{sv}", "IconName", new Variant.string (bluetooth_service._icon_name));
        builder.add ("{sv}", "AccessibleDescription", new Variant.string (bluetooth_service._accessible_description));
        try
        {
            var properties = new Variant ("(sa{sv}as)", "com.canonical.indicator.bluetooth.service", builder, null);
            bus.emit_signal (null,
                             "/com/canonical/indicator/bluetooth/service",
                             "org.freedesktop.DBus.Properties",
                             "PropertiesChanged",
                             properties);
        }
        catch (Error e)
        {
            warning ("Failed to emit signal: %s", e.message);
        }

        enable_item.property_set_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE, enabled ? Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED : Dbusmenu.MENUITEM_TOGGLE_STATE_UNCHECKED);

        /* Disable devices when locked */
        visible_item.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, enabled);
        devices_separator.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, enabled);
        foreach (var item in device_items)
            item.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, enabled && item.get_children () != null);

        updating_killswitch = false;
    }
}

private class BluetoothMenuItem : Dbusmenu.Menuitem
{
    private GnomeBluetooth.Client client;
    public string address;
    private Dbusmenu.Menuitem? connect_item = null;
    private bool make_submenu = false;

    public BluetoothMenuItem (GnomeBluetooth.Client client, string address)
    {
        this.client = client;
        this.address = address;
    }

    public void update (GnomeBluetooth.Type type, DBusProxy proxy, string alias, string icon, bool connected, HashTable? services, string[] uuids)
    {
        property_set (Dbusmenu.MENUITEM_PROP_LABEL, alias);
        property_set (Dbusmenu.MENUITEM_PROP_ICON_NAME, icon);
        if (connect_item != null)
            connect_item.property_set_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE, connected ? Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED : Dbusmenu.MENUITEM_TOGGLE_STATE_UNCHECKED);

        /* FIXME: Not sure if the GUI elements below can change over time */
        if (make_submenu)
            return;
        make_submenu = true;

        if (services != null)
        {
            connect_item = new Dbusmenu.Menuitem ();
            connect_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Connection"));
            connect_item.property_set (Dbusmenu.MENUITEM_PROP_TYPE, "x-canonical-switch");
            connect_item.property_set_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE, connected ? Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED : Dbusmenu.MENUITEM_TOGGLE_STATE_UNCHECKED);
            connect_item.item_activated.connect (() => { connect_service (proxy.get_object_path (), connect_item.property_get_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE) != Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED); });
            child_append (connect_item);
        }

        var can_send = false;
        var can_browse = false;
        if (uuids != null)
        {
            for (var i = 0; uuids[i] != null; i++)
            {
                if (uuids[i] == "OBEXObjectPush")
                    can_send = true;
                if (uuids[i] == "OBEXFileTransfer")
                    can_browse = true;
            }
        }

        if (can_send)
        {
            var send_item = new Dbusmenu.Menuitem ();
            send_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Send files…"));
            send_item.item_activated.connect (() => { GnomeBluetooth.send_to_address (address, alias); });
            child_append (send_item);
        }

        if (can_browse)
        {
            var browse_item = new Dbusmenu.Menuitem ();
            browse_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Browse files…"));
            browse_item.item_activated.connect (() => { GnomeBluetooth.browse_address (null, address, Gdk.CURRENT_TIME, null); });
            child_append (browse_item);
        }

        switch (type)
        {
        case GnomeBluetooth.Type.KEYBOARD:
            var keyboard_item = new Dbusmenu.Menuitem ();
            keyboard_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Keyboard Settings…"));
            keyboard_item.item_activated.connect (() => { show_control_center ("keyboard"); });
            child_append (keyboard_item);
            break;

        case GnomeBluetooth.Type.MOUSE:
        case GnomeBluetooth.Type.TABLET:
            var mouse_item = new Dbusmenu.Menuitem ();
            mouse_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Mouse and Touchpad Settings…"));
            mouse_item.item_activated.connect (() => { show_control_center ("mouse"); });
            child_append (mouse_item);
            break;

        case GnomeBluetooth.Type.HEADSET:
        case GnomeBluetooth.Type.HEADPHONES:
        case GnomeBluetooth.Type.OTHER_AUDIO:
            var sound_item = new Dbusmenu.Menuitem ();
            sound_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Sound Settings…"));
            sound_item.item_activated.connect (() => { show_control_center ("sound"); });
            child_append (sound_item);
            break;
        }

        property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, get_children () != null);
    }

    private void connect_service (string device, bool connect)
    {
        client.connect_service.begin (device, connect, null, (object, result) =>
        {
            var connected = false;
            try
            {
                connected = client.connect_service.end (result);
            }
            catch (Error e)
            {
                warning ("Failed to connect service: %s", e.message);
            }
        });
    }
}

private void set_up_new_device ()
{
    try
    {
        Process.spawn_command_line_async ("bluetooth-wizard");
    }
    catch (GLib.SpawnError e)
    {
        warning ("Failed to open bluetooth-wizard: %s", e.message);
    }
}

private void show_control_center (string panel)
{
    try
    {
        Process.spawn_command_line_async ("gnome-control-center %s".printf (panel));
    }
    catch (GLib.SpawnError e)
    {
        warning ("Failed to open control center: %s", e.message);
    }
}

public static int main (string[] args)
{
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALE_DIR);
    Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (GETTEXT_PACKAGE);

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
    // FIXMEindicator.shutdown.connect (() => { loop.quit (); });

    loop.run ();

    indicator = null;

    return Posix.EXIT_SUCCESS;
}

[DBus (name = "com.canonical.indicator.bluetooth.service")]
private class BluetoothService : Object
{
    internal string _icon_name = "bluetooth-active";
    public string icon_name
    {
        get { return _icon_name; }
    }
    internal string _accessible_description = _("Bluetooth");
    public string accessible_description
    {
        get { return _accessible_description; }
    }
}
