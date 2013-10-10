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
 * Abstract interface for the Bluetooth backend.
 */
public interface Bluetooth: Object
{
  /* True if there are any bluetooth adapters on this system.
     This work as a proxy for "does this hardware support bluetooth?" */
  public abstract bool supported { get; protected set; }

  /* True if there are any bluetooth adapters powered up on the system.
     In short, whether or not this system's bluetooth is "on". */
  public abstract bool powered { get; protected set; }

  /* True if our system can be seen by other bluetooth devices */
  public abstract bool discoverable { get; protected set; }
  public abstract void try_set_discoverable (bool discoverable);

  /* True if bluetooth's blocked. This can be soft-blocked by software and
   * hard-blocked physically, eg by a laptop's network killswitch */
  public abstract bool blocked { get; protected set; }

  /* Try to block/unblock bluetooth. This can fail if it's overridden
     by the system, eg by a laptop's network killswitch */
  public abstract void try_set_blocked (bool b);

  /* Get a list of the Device structs that we know about */
  public abstract List<unowned Device> get_devices ();

  /* Emitted when one or more of the devices is added, removed, or changed */
  public signal void devices_changed ();

  /* Try to connect/disconnect a particular device.
     The device_key argument comes from the Device struct */
  public abstract void set_device_connected (uint device_key, bool connected);
}



/**
 * Base class for Bluetooth objects that use a killswitch to implement
 * the 'discoverable' property.
 */
public abstract class KillswitchBluetooth: Object, Bluetooth
{
  private KillSwitch killswitch;

  public KillswitchBluetooth (KillSwitch killswitch)
  {
    // always sync our 'blocked' property with the one in killswitch
    this.killswitch = killswitch;
    blocked = killswitch.blocked;
    killswitch.notify["blocked"].connect (() => blocked = killswitch.blocked );
  }

  public bool supported { get; protected set; default = false; }
  public bool powered { get; protected set; default = false; }
  public bool discoverable { get; protected set; default = false; }
  public bool blocked { get; protected set; default = true; }
  public void try_set_blocked (bool b) { killswitch.try_set_blocked (b); }

  // empty implementations
  public abstract void try_set_discoverable (bool b);
  public abstract List<unowned Device> get_devices ();
  public abstract void set_device_connected (uint device_key, bool connected);
}
