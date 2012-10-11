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
    private RFKillManager rfkill;
    private Gtk.MenuItem status_item;
    private Gtk.MenuItem enable_item;
    private bool enable_value = false;
    private Gtk.CheckMenuItem visible_item;
    private Gtk.SeparatorMenuItem devices_separator;
    private Gtk.MenuItem devices_item;
    private List<Gtk.MenuItem> device_items;
    private Gtk.MenuItem settings_item;

    public BluetoothIndicator ()
    {
        Object (id: "indicator-bluetooth", icon_name: "bluetooth-active", category: "Hardware");

        /* Monitor killswitch status */
        rfkill = new RFKillManager ();
        rfkill.open ();
        rfkill.device_added.connect (update_rfkill);
        rfkill.device_changed.connect (update_rfkill);
        rfkill.device_deleted.connect (update_rfkill);

        /* Get/control bluetooth status from Bluez */
        var bluez = new BluezManager ();
        bluez.start ();

        set_status (AppIndicator.IndicatorStatus.ACTIVE);

        var menu = new Gtk.Menu ();
        set_menu (menu);

        status_item = new Gtk.MenuItem ();
        status_item.sensitive = false;
        status_item.visible = true;
        menu.append (status_item);

        enable_item = new Gtk.MenuItem ();
        enable_item.activate.connect (toggle_enabled);
        menu.append (enable_item);

        visible_item = new Gtk.CheckMenuItem.with_label (_("Visible"));
        visible_item.active = bluez.default_adapter.discoverable;
        bluez.default_adapter.notify["discoverable"].connect (() => { visible_item.active = bluez.default_adapter.discoverable; });
        visible_item.activate.connect (() => { bluez.default_adapter.discoverable = visible_item.active; });
        menu.append (visible_item);
    
        devices_separator = new Gtk.SeparatorMenuItem ();
        menu.append (devices_separator);

        devices_item = new Gtk.MenuItem.with_label (_("Devices"));
        devices_item.sensitive = false;
        devices_item.visible = true;
        menu.append (devices_item);

        device_items = new List<Gtk.MenuItem> ();

        var devices = bluez.default_adapter.get_devices ();
        foreach (var device in devices)
        {
            var item = new Gtk.MenuItem.with_label (device.name);
            device_items.append (item);
            menu.append (item);

            item.submenu = new Gtk.Menu ();

            /* Scan class mask to determine what type of device it is */
            var is_keyboard = false;
            var is_pointer = false;
            var is_audio = false;
            switch ((device.class & 0x1f00) >> 8)
            {
            case 0x04:
                switch ((device.class & 0xfc) >> 2)
                {
                case 0x0b:
                case 0x0c:
                case 0x0d:
                    /* (video devices) */
                    break;
                default:
                    is_audio = true;
                    break;
                }
                break;
            case 0x05:
                switch ((device.class & 0xc0) >> 6)
                {
                case 0x00:
                    /* (joypads) */
                    break;
                case 0x01:
                    is_keyboard = true;
                    break;
                case 0x02:
                    is_pointer = true;
                    break;
                }
                break;
            }

            // FIXME: Check by looking at the UUIDs
            var can_receive_files = true;
            var can_browse_files = true;

            if (can_receive_files)
            {
                var i = new Gtk.MenuItem.with_label (_("Send files..."));
                i.visible = true;
                i.activate.connect (() => { Process.spawn_command_line_async ("bluetooth-sendto --device=DEVICE --name=NAME"); }); // FIXME
                item.submenu.append (i);
            }
            if (can_browse_files)
            {
                var i = new Gtk.MenuItem.with_label (_("Browse files..."));
                i.visible = true;
                i.activate.connect (() => { Process.spawn_command_line_async ("gnome-open obex://[%s]/"); }); // FIXME
                item.submenu.append (i);
            }

            if (is_keyboard)
            {
                var i = new Gtk.MenuItem.with_label (_("Keyboard Settings..."));
                i.visible = true;
                i.activate.connect (() => { Process.spawn_command_line_async ("gnome-control-center keyboard"); });
                item.submenu.append (i);
            }

            if (is_pointer)
            {
                var i = new Gtk.MenuItem.with_label (_("Mouse and Touchpad Settings..."));
                i.visible = true;
                i.activate.connect (() => { Process.spawn_command_line_async ("gnome-control-center mouse"); });
                item.submenu.append (i);
            }

            if (is_audio)
            {
                var i = new Gtk.MenuItem.with_label (_("Sound Settings..."));
                i.visible = true;
                i.activate.connect (() => { Process.spawn_command_line_async ("gnome-control-center sound"); });
                item.submenu.append (i);
            }
        }

        var sep = new Gtk.SeparatorMenuItem ();
        sep.visible = true;
        menu.append (sep);

        settings_item = new Gtk.MenuItem.with_label (_("Bluetooth Settings..."));
        settings_item.activate.connect (() => { Process.spawn_command_line_async ("gnome-control-center bluetooth"); });
        settings_item.visible = true;
        menu.append (settings_item);

        update_rfkill ();
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
