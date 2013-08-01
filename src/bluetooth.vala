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

public class Bluetooth: Object
{
  /***
  ****  Properties
  ***/

  public bool discoverable { get; protected set; default = false; }
  public virtual void try_set_discoverable (bool b) {}

  public bool powered { get; protected set; default = false; }

  public bool blocked { get; protected set; default = true; }
  public virtual void try_set_blocked (bool b) {
    kill_switch.try_set_blocked (b);
  }

  /***
  ****  Killswitch Implementation 
  ***/

  protected KillSwitch kill_switch;

  public Bluetooth (KillSwitch kill_switch)
  {
    this.kill_switch = kill_switch;

    message ("changing blocked to %d", (int)!this.kill_switch.blocked);
    blocked = this.kill_switch.blocked;
    kill_switch.notify["blocked"].connect (() => {
      message ("bluetooth changing blocked to %d", (int)kill_switch.blocked);
      this.blocked = kill_switch.blocked;
    });
  }
}
