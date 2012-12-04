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

public class BluetoothIndicator : AppIndicator.Indicator
{
    private GnomeBluetooth.Client client;
    private RFKillManager rfkill;
    private Gtk.MenuItem status_item;
    private Gtk.MenuItem enable_item;
    private bool enable_value = false;
    private Gtk.CheckMenuItem visible_item;
    private Gtk.SeparatorMenuItem devices_separator;
    private Gtk.MenuItem devices_item;
    private List<BluetoothMenuItem> device_items;
    private Gtk.MenuItem settings_item;
    private Gtk.Menu menu;

    public BluetoothIndicator ()
    {
        Object (id: "indicator-bluetooth", icon_name: "bluetooth-active", category: "Hardware");

        /* Monitor killswitch status */
        rfkill = new RFKillManager ();
        rfkill.open ();
        rfkill.device_added.connect (update_rfkill);
        rfkill.device_changed.connect (update_rfkill);
        rfkill.device_deleted.connect (update_rfkill);

        client = new GnomeBluetooth.Client ();

        set_status (AppIndicator.IndicatorStatus.ACTIVE);

        menu = new Gtk.Menu ();
        set_menu (menu);

        status_item = new Gtk.MenuItem ();
        status_item.sensitive = false;
        status_item.visible = true;
        menu.append (status_item);

        enable_item = new Gtk.MenuItem ();
        enable_item.activate.connect (toggle_enabled);
        menu.append (enable_item);

        visible_item = new Gtk.CheckMenuItem.with_label (_("Visible"));
        bool discoverable;
        client.get ("default-adapter-discoverable", out discoverable);
        visible_item.active = discoverable;
        client.notify["default-adapter-discoverable"].connect (() =>
        {
            bool is_discoverable;
            client.get ("default-adapter-discoverable", out is_discoverable);
            visible_item.active = is_discoverable;
        });
        visible_item.activate.connect (() => { client.set ("default-adapter-discoverable", visible_item.active); });
        menu.append (visible_item);
    
        devices_separator = new Gtk.SeparatorMenuItem ();
        menu.append (devices_separator);

        devices_item = new Gtk.MenuItem.with_label (_("Devices"));
        devices_item.sensitive = false;
        devices_item.visible = true;
        menu.append (devices_item);

        device_items = new List<BluetoothMenuItem> ();

        client.model.row_inserted.connect (device_changed_cb);
        client.model.row_changed.connect (device_changed_cb);
        client.model.row_deleted.connect (device_removed_cb);
        Gtk.TreeIter iter;
        if (client.model.get_iter_first (out iter))
        {
            do
            {
                device_changed_cb (null, iter);
            } while (client.model.iter_next (ref iter));
        }

        var sep = new Gtk.SeparatorMenuItem ();
        sep.visible = true;
        menu.append (sep);

        settings_item = new Gtk.MenuItem.with_label (_("Bluetooth Settings..."));
        settings_item.activate.connect (() => { show_control_center ("bluetooth"); });
        settings_item.visible = true;
        menu.append (settings_item);

        update_rfkill ();
    }

    private BluetoothMenuItem? find_menu_item (DBusProxy proxy)
    {
        foreach (var item in device_items)
            if (item.proxy == proxy)
                return item;

        return null;
    }

    private void device_changed_cb (Gtk.TreePath? path, Gtk.TreeIter iter)
    {
        DBusProxy proxy;
        string address;
        string alias;
        string name;
        GnomeBluetooth.Type type;
        string[] uuids;
        client.model.get (iter,
                          GnomeBluetooth.Column.PROXY, out proxy,
                          GnomeBluetooth.Column.ADDRESS, out address,
                          GnomeBluetooth.Column.ALIAS, out alias,
                          GnomeBluetooth.Column.NAME, out name,
                          GnomeBluetooth.Column.TYPE, out type,
                          GnomeBluetooth.Column.UUIDS, out uuids);

        /* Skip if haven't actually got any information yet */
        if (proxy == null)
            return;

        /* Find or create menu item */
        var item = find_menu_item (proxy);
        if (item == null)
        {
            item = new BluetoothMenuItem (proxy);
            item.visible = true;
            var last_item = devices_item;
            if (device_items != null)
                last_item = device_items.last ().data;
            device_items.append (item);
            menu.insert (item, menu.get_children ().index (last_item) + 1);
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

        item.label = name;
        item.alias = alias;
        item.address = address;
        item.send_item.visible = can_send;
        item.browse_item.visible = can_browse;
        item.keyboard_item.visible = type == GnomeBluetooth.Type.KEYBOARD;
        item.mouse_item.visible = type == GnomeBluetooth.Type.MOUSE || type == GnomeBluetooth.Type.TABLET;
        item.sound_item.visible = type == GnomeBluetooth.Type.HEADSET || type == GnomeBluetooth.Type.HEADPHONES || type == GnomeBluetooth.Type.OTHER_AUDIO;
    }

    private void device_removed_cb (Gtk.TreePath path)
    {
        Gtk.TreeIter iter;
        if (!client.model.get_iter (out iter, path))
            return;

        DBusProxy proxy;
        client.model.get (iter, GnomeBluetooth.Column.PROXY, out proxy);

        var item = find_menu_item (proxy);
        if (item == null)
            return;

        device_items.remove (item);
        menu.remove (item);
    }

    private void update_rfkill ()
    {
        var have_lock = false;
        var software_locked = false;
        var hardware_locked = false;

        foreach (var device in rfkill.get_devices ())
        {
            if (device.device_type != RFKillDeviceType.BLUETOOTH)
                continue;

            have_lock = true;
            if (device.software_lock)
                software_locked = true;
            if (device.hardware_lock)
                hardware_locked = true;
        }
        var locked = hardware_locked || software_locked;

        if (hardware_locked)
        {
            status_item.label = _("Bluetooth: Disabled");
            enable_item.visible = false;
        }
        else if (software_locked)
        {
            status_item.label = _("Bluetooth: Off");
            enable_item.label = _("Turn on Bluetooth");
            enable_item.visible = true;
            enable_value = false;
        }
        else
        {
            status_item.label = _("Bluetooth: On");
            enable_item.label = _("Turn off Bluetooth");
            enable_item.visible = true;
            enable_value = true;
        }

        /* Disable devices when locked */
        visible_item.visible = !locked;
        devices_separator.visible = !locked;
        devices_item.visible = !locked;
        foreach (var item in device_items)
            item.visible = !locked;
    }

    private void toggle_enabled ()
    {
        rfkill.set_software_lock (RFKillDeviceType.BLUETOOTH, enable_value);
    }
}

private class BluetoothMenuItem : Gtk.MenuItem
{
    public DBusProxy proxy;
    public string alias;
    public string address;
    public Gtk.MenuItem send_item;
    public Gtk.MenuItem browse_item;
    public Gtk.MenuItem keyboard_item;
    public Gtk.MenuItem mouse_item;
    public Gtk.MenuItem sound_item;

    public BluetoothMenuItem (DBusProxy proxy)
    {
        this.proxy = proxy;
        submenu = new Gtk.Menu ();
        submenu.visible = true;

        send_item = new Gtk.MenuItem.with_label (_("Send files..."));
        send_item.visible = true;
        send_item.activate.connect (() => { GnomeBluetooth.send_to_address (address, alias); });
        submenu.append (send_item);

        browse_item = new Gtk.MenuItem.with_label (_("Browse files..."));
        browse_item.activate.connect (() => { GnomeBluetooth.browse_address (null, address, Gdk.CURRENT_TIME, null); });
        submenu.append (browse_item);

        keyboard_item = new Gtk.MenuItem.with_label (_("Keyboard Settings..."));
        keyboard_item.activate.connect (() => { show_control_center ("keyboard"); });
        submenu.append (keyboard_item);

        mouse_item = new Gtk.MenuItem.with_label (_("Mouse and Touchpad Settings..."));
        mouse_item.activate.connect (() => { show_control_center ("mouse"); });
        submenu.append (mouse_item);

        sound_item = new Gtk.MenuItem.with_label (_("Sound Settings..."));
        sound_item.activate.connect (() => { show_control_center ("sound"); });
        submenu.append (sound_item);
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

    Gtk.init (ref args);

    var indicator = new BluetoothIndicator ();
    
    Gtk.main ();
    
    indicator = null;

    return Posix.EXIT_SUCCESS;
}
