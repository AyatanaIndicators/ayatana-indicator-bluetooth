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

public class BluezManager : Object
{
    public BluezAdapter default_adapter;

    public BluezManager ()
    {
    }

    public void start () throws IOError
    {
        proxy = Bus.get_proxy_sync<BluezManagerInterface> (BusType.SYSTEM, "org.bluez", "/");
        proxy.default_adapter_changed.connect (default_adapter_changed_cb);
        default_adapter_changed_cb (proxy.default_adapter ());
    }

    private BluezManagerInterface proxy;

    private void default_adapter_changed_cb (string path)
    {
        default_adapter = new BluezAdapter (path);
    }
}

public class BluezAdapter : Object
{
    public List<BluezDevice> get_devices ()
    {
        var devices = new List<BluezDevice> ();
        foreach (var device in _devices)
            devices.append (device);
        return devices;
    }

    private bool _discoverable = false;
    public bool discoverable
    {
        get { return _discoverable; }
        set
        {
            _discoverable = value;
            proxy.set_property ("Discoverable", new Variant.boolean (value));
        }
    }

    internal string path;
    private List<BluezDevice> _devices;
    private BluezAdapterInterface proxy;

    internal BluezAdapter (string path)
    {
        this.path = path;
        _devices = new List<BluezDevice> ();
        proxy = Bus.get_proxy_sync<BluezAdapterInterface> (BusType.SYSTEM, "org.bluez", path);

        proxy.property_changed.connect (property_changed_cb);
        var properties = proxy.get_properties ();
        var iter = HashTableIter<string, Variant> (properties);
        string name;
        Variant value;
        while (iter.next (out name, out value))
            property_changed_cb (name, value);

        proxy.device_created.connect (device_created_cb);
        foreach (var device_path in proxy.list_devices ())
            device_created_cb (device_path);
    }

    private void property_changed_cb (string name, Variant value)
    {
        stderr.printf ("%s %s=%s\n", path, name, value.print (false));
        if (name == "Discoverable" && value.is_of_type (VariantType.BOOLEAN))
        {
            _discoverable = value.get_boolean ();
            notify_property ("discoverable");
        }
    }

    private void device_created_cb (string path)
    {
        foreach (var device in _devices)
            if (device.path == path)
                return;

        var device = new BluezDevice (path);
        _devices.append (device);
    }
}

public class BluezDevice : Object
{
    private string _name = null;
    public string name { get { return _name; } }

    private uint32 _class = 0;
    public uint32 class { get { return _class; } }

    internal string path;
    private BluezDeviceInterface proxy;

    internal BluezDevice (string path)
    {
        this.path = path;
        proxy = Bus.get_proxy_sync<BluezDeviceInterface> (BusType.SYSTEM, "org.bluez", path);

        proxy.property_changed.connect (property_changed_cb);
        var properties = proxy.get_properties ();
        var iter = HashTableIter<string, Variant> (properties);
        string name;
        Variant value;
        while (iter.next (out name, out value))
            property_changed_cb (name, value);

        //var input_device = Bus.get_proxy_sync<BluezInputInterface> (BusType.SYSTEM, "org.bluez", path);
        //input_device.property_changed.connect (input_property_changed_cb);
    }

    private void property_changed_cb (string name, Variant value)
    {
        stderr.printf ("%s %s=%s\n", path, name, value.print (false));
        if (name == "Name" && value.is_of_type (VariantType.STRING))
            _name = value.get_string ();
        if (name == "Class" && value.is_of_type (VariantType.UINT32))
            _class = value.get_uint32 ();
    }

    private void input_property_changed_cb (string name, Variant value)
    {
        stderr.printf ("%s i %s=%s\n", path, name, value.print (false));
    }
}

[DBus (name = "org.bluez.Manager")]
private interface BluezManagerInterface : Object
{
    public abstract string default_adapter () throws IOError;
    public signal void default_adapter_changed (string path);
}

[DBus (name = "org.bluez.Adapter")]
private interface BluezAdapterInterface : Object
{
    public abstract string[] list_devices () throws IOError;
    public abstract HashTable<string, Variant> get_properties () throws IOError;
    public abstract void set_property (string name, Variant value) throws IOError;
    public signal void property_changed (string name, Variant value);
    public signal void device_created (string path);
}

[DBus (name = "org.bluez.Device")]
private interface BluezDeviceInterface : Object
{
    public abstract HashTable<string, Variant> get_properties () throws IOError;
    public signal void property_changed (string name, Variant value);
}

[DBus (name = "org.bluez.Audio")]
private interface BluezAudioInterface : Object
{
    public abstract void connect () throws IOError;
}

[DBus (name = "org.bluez.Input")]
private interface BluezInputInterface : Object
{
    public abstract void connect () throws IOError;
    public abstract void disconnect () throws IOError;
    public abstract HashTable<string, Variant> get_properties () throws IOError;
    public signal void property_changed (string name, Variant value);
}
