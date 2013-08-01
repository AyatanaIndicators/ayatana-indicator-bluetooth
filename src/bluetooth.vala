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
 * Base class for the bluetooth backend.
 */
public class Bluetooth: Object
{
  /* whether or not our system can be seen by other bluetooth devices */
  public bool discoverable { get; protected set; default = false; }
  public virtual void try_set_discoverable (bool b) {}

  /* whether or not there are any bluetooth adapters powered up on the system */
  public bool powered { get; protected set; default = false; }

  /* whether or not bluetooth's been disabled,
     either by a software setting or physical hardware switch */
  public bool blocked { get; protected set; default = true; }
  public virtual void try_set_blocked (bool b) {
    killswitch.try_set_blocked (b);
  }

  /***
  ****  Killswitch Implementation 
  ***/

  private KillSwitch killswitch;

  public Bluetooth (KillSwitch killswitch)
  {
    this.killswitch = killswitch;
    blocked = killswitch.blocked;
    killswitch.notify["blocked"].connect (() => blocked = killswitch.blocked );
  }
}
