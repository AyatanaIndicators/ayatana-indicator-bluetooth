/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *   Charles Kerr <charles.kerr@canonical.com>
 */

/**
 * Bluetooth implementaion which uses org.bluez on DBus 
 */
public class Bluez: KillswitchBluetooth
{
  private org.bluez.Manager manager;
  private org.bluez.Adapter default_adapter;
  private HashTable<string,org.bluez.Device> path_to_proxy;
  private HashTable<string,uint> path_to_id;
  private HashTable<uint,string> id_to_path;
  private HashTable<uint,Device> id_to_device;
  private uint next_device_id = 1;

  public Bluez (KillSwitch killswitch)
  {
    base (killswitch);

    string adapter_path = null;

    id_to_path    = new HashTable<uint,string> (direct_hash, direct_equal);
    id_to_device  = new HashTable<uint,Device> (direct_hash, direct_equal);
    path_to_id    = new HashTable<string,uint> (str_hash, str_equal);
    path_to_proxy = new HashTable<string,org.bluez.Device> (str_hash, str_equal);

    try
      {
        manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.bluez", "/");
        manager.default_adapter_changed.connect ((object_path) => on_default_adapter_changed (object_path));
        adapter_path = manager.default_adapter ();
      }
    catch (Error e)
      {
        critical (@"$(e.message)");
      }

    on_default_adapter_changed (adapter_path);
  }

  private void on_default_adapter_changed (string? object_path)
  {
    if (object_path != null) try
      {
        message (@"using default adapter at $object_path");
        default_adapter = Bus.get_proxy_sync (BusType.SYSTEM, "org.bluez", object_path);
        default_adapter.property_changed.connect(() => on_default_adapter_properties_changed());

        default_adapter.device_removed.connect((adapter, path) => {
          var id = path_to_id.lookup (path);
          path_to_id.remove (path);
          id_to_path.remove (id);
          id_to_device.remove (id);
          devices_changed ();
        });

        default_adapter.device_created.connect((adapter, path) => add_device (path));
        foreach (string device_path in default_adapter.list_devices())
          add_device (device_path);
      }
    catch (Error e)
     {
       critical (@"$(e.message)");
     }

    this.on_default_adapter_properties_changed ();
  }

  private static uint16 get_uuid16_from_uuid_string (string uuid)
  {
    uint16 uuid16;

    string[] tokens = uuid.split ("-", 1);
    if (tokens.length > 0)
      uuid16 = (uint16) uint64.parse ("0x"+tokens[0]);
    else
      uuid16 = 0;

    return uuid16;
  }

  /* A device supports file transfer if OBEXObjectPush is in its uuid list */
  private bool device_supports_file_transfer (uint16[] uuids)
  {
    foreach (uint16 uuid16 in uuids)
      if (uuid16 == 0x1105) // OBEXObjectPush
        return true;

    return false;
  }

  /* A device supports browsing if OBEXFileTransfer is in its uuid list */
  private bool device_supports_browsing (uint16[] uuids)
  {
    foreach (uint16 uuid16 in uuids)
      if (uuid16 == 0x1106) // OBEXFileTransfer
        return true;

    return false;
  }

  /* headsets, audio sinks, and input devices are connectable.
   *
   * TODO: this duplicates the behavior of the indicator from when it used
   * gnome-bluetooth as a backend. Are there other interfaces we care about? */
  private DBusInterfaceInfo[] get_connectable_interfaces (DBusProxy device)
  {
    DBusInterfaceInfo[] connectable_interfaces = {};

    try
      {
        var iname = "org.freedesktop.DBus.Introspectable.Introspect";
        var intro = device.call_sync (iname, null, DBusCallFlags.NONE, -1);

        if ((intro != null) && (intro.n_children() > 0))
          {
            string xml = intro.get_child_value(0).get_string();
            var info = new DBusNodeInfo.for_xml (xml);
            if (info != null)
              {
                foreach (DBusInterfaceInfo i in info.interfaces)
                  {
                    if ((i.name == "org.bluez.AudioSink") ||
                        (i.name == "org.bluez.Headset") ||
                        (i.name == "org.bluez.Input"))
                      {
                        connectable_interfaces += i;
                      }
                  }
              }
          }
      }
    catch (Error e)
      {
       critical (@"$(e.message)");
      }

    return connectable_interfaces;
  }

  private bool device_is_connectable (DBusProxy device)
  {
    var connectable_interfaces = get_connectable_interfaces (device);
    return connectable_interfaces.length > 0;
  }

  private void device_connect (DBusProxy proxy)
  {
    var connection = proxy.get_connection ();
    var object_path = proxy.get_object_path ();

    foreach (var i in get_connectable_interfaces (proxy))
      {
        try
          {
            debug (@"trying to connect to $object_path: $(i.name)");
            connection.call_sync ("org.bluez",
                                  object_path,
                                  i.name,
                                  "Connect",
                                  null,
                                  null,
                                  DBusCallFlags.NONE,
                                  -1);
          }
        catch (Error e)
          {
            debug (@"Unable to call $(i.name).Connect() on $(proxy.get_object_path()): $(e.message)");
          }
      }
  }

  private void add_device (string object_path)
  {
    if (!path_to_proxy.contains (object_path))
      {
        try
          {
            org.bluez.Device device = Bus.get_proxy_sync (BusType.SYSTEM, "org.bluez", object_path);
            path_to_proxy.insert (object_path, device);
            device.property_changed.connect(() => update_device (device)); 
            update_device (device);
          }
        catch (Error e)
          {
            critical (@"$(e.message)");
          }
      }
  }

  private void update_device (org.bluez.Device device_proxy)
  {
    HashTable<string, GLib.Variant> properties;

    try {
      properties = device_proxy.get_properties ();
    } catch (Error e) {
      critical (@"$(e.message)");
      return;
    }

    // look up our id for this device.
    // if we don't have one yet, create one.
    var object_path = (device_proxy as DBusProxy).get_object_path();
    var id = path_to_id.lookup (object_path);
    if (id == 0)
      {
        id = next_device_id ++;
        id_to_path.insert (id, object_path);
        path_to_id.insert (object_path, id);
      }

    // look up the device's type
    Device.Type type;
    var v = properties.lookup ("Class");
    if (v == null)
      type = Device.Type.OTHER;
    else 
      type = Device.class_to_device_type (v.get_uint32());

    // look up the device's human-readable name
    v = properties.lookup ("Alias");
    if (v == null)
      v = properties.lookup ("Name");
    string name = v == null ? _("Unknown") : v.get_string ();

    // look up the device's bus address
    v = properties.lookup ("Address");
    string address = v.get_string ();

    // look up the device's bus address
    Icon icon;
    v = properties.lookup ("Icon");
    if (v == null)
      icon = new ThemedIcon ("unknown");
    else
      icon = new ThemedIcon (v.get_string());

    // derive a Connectable flag for this device
    var is_connectable = device_is_connectable (device_proxy as DBusProxy);

    // look up the device's Connected flag
    v = properties.lookup ("Connected");
    bool is_connected = (v != null) && v.get_boolean ();

    // derive the uuid-related attributes we care about
    v = properties.lookup ("UUIDs");
    string[] uuid_strings = v.dup_strv ();
    uint16[] uuids = {};
    foreach (string s in uuid_strings)
      uuids += get_uuid16_from_uuid_string (s);
    var supports_browsing = device_supports_browsing (uuids);
    var supports_file_transfer = device_supports_file_transfer (uuids);

    // update our lookup table with these new attributes
    id_to_device.insert (id, new Device (id,
                                         type,
                                         name,
                                         address,
                                         icon,
                                         is_connectable,
                                         is_connected,
                                         supports_browsing,
                                         supports_file_transfer));

    devices_changed ();
  }

  public override void set_device_connected (uint id, bool connected)
  {
    var device = id_to_device.lookup (id);
    var object_path = id_to_path.lookup (id);
    var proxy = (object_path != null) ? path_to_proxy.lookup (object_path) : null;

    if ((proxy != null) && (device != null) && (device.is_connected != connected))
      {
        if (connected)
          {
            device_connect (proxy as DBusProxy);
          }
        else // disconnect
          {
            try
              {
                proxy.disconnect ();
              }
            catch (Error e)
              {
                critical (@"Unable to disconnect $object_path: $(e.message)");
              }
          }
      }
  }

  private void on_default_adapter_properties_changed ()
  {
    bool is_discoverable = false;
    bool is_powered = false;

    if (this.default_adapter != null) try
      {
        var properties = this.default_adapter.get_properties();

        var v = properties.lookup("Discoverable");
        is_discoverable = (v != null) && v.get_boolean ();

        v = properties.lookup("Powered");
        is_powered = (v != null) && v.get_boolean ();
      }
    catch (Error e) 
     {
       critical (@"$(e.message)");
     }

    this.powered = is_powered;
    this.discoverable = is_discoverable;
  }

  public override void try_set_discoverable (bool b)
  {
    if (discoverable != b) try
      {
        this.default_adapter.set_property ("Discoverable", new Variant.boolean(b));
      }
    catch (Error e)
      {
        critical (@"$(e.message)");
      }
  }

  public override List<unowned Device> get_devices ()
  {
    return id_to_device.get_values();
  }
}
