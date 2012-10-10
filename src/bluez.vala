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

[DBus (name = "org.bluez.Manager")]
public interface BluezManager : Object
{
    public abstract string default_adapter () throws IOError;
}

[DBus (name = "org.bluez.Adapter")]
public interface BluezAdapter : Object
{
    public abstract string[] list_devices () throws IOError;
    public abstract HashTable<string, Variant> get_properties () throws IOError;
    public abstract void set_property (string name, Variant value) throws IOError;
}

[DBus (name = "org.bluez.Device")]
public interface BluezDevice : Object
{
    public abstract HashTable<string, Variant> get_properties () throws IOError;
}

[DBus (name = "org.bluez.Audio")]
public interface BluezAudio : Object
{
    public abstract void connect () throws IOError;
}

[DBus (name = "org.bluez.Input")]
public interface BluezInput : Object
{
    public abstract void connect () throws IOError;
}
