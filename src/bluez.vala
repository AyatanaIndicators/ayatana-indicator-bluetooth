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
 * Bluetooth implementaion which uses bluez over dbus 
 */
public class Bluez: Bluetooth
{
  private org.bluez.Manager manager;
  private org.bluez.Adapter default_adapter;

  public Bluez (KillSwitch killswitch)
  {
    string default_adapter_object_path = null;

    base (killswitch);

    try
      {
        manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.bluez", "/");

        manager.default_adapter_changed.connect ((object_path) => on_default_adapter_changed (object_path));
        default_adapter_object_path = manager.default_adapter ();
      }
    catch (Error e)
     {
       critical ("%s", e.message);
     }

    on_default_adapter_changed (default_adapter_object_path);
  }

  private void on_default_adapter_changed (string? object_path)
  {
    if (object_path != null) try
      {
        message ("using default adapter at %s", object_path);
        this.default_adapter = Bus.get_proxy_sync (BusType.SYSTEM, "org.bluez", object_path);
        this.default_adapter.property_changed.connect(() => this.on_default_adapter_properties_changed());
      }
    catch (Error e)
      {
       critical ("%s", e.message);
      }

    this.on_default_adapter_properties_changed ();
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
       critical ("%s", e.message);
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
        critical ("%s", e.message);
      }
  }
}
