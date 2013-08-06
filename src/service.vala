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
 *   Robert Ancell <robert.ancell@canonical.com>
 */

public class Service: Object
{
  private MainLoop loop;
  private SimpleActionGroup actions;
  private HashTable<string,Profile> profiles;

  public Service (Bluetooth bluetooth)
  {
    actions = new SimpleActionGroup ();

    profiles = new HashTable<string,Profile> (str_hash, str_equal);
    profiles.insert ("phone", new Phone (bluetooth, actions));
    profiles.insert ("desktop", new Desktop (bluetooth, actions));
  }

  public int run ()
  {
    if (this.loop != null)
      {
        warning ("service is already running");
        return Posix.EXIT_FAILURE;
      }

    Bus.own_name (BusType.SESSION,
                  "com.canonical.indicator.bluetooth",
                  BusNameOwnerFlags.NONE,
                  this.on_bus_acquired,
                  null,
                  this.on_name_lost);

    this.loop = new MainLoop (null, false);
    this.loop.run ();
    return Posix.EXIT_SUCCESS;
  }

  void on_bus_acquired (DBusConnection connection, string name)
  {
    debug (@"bus acquired: $name");

    var object_path = "/com/canonical/indicator/bluetooth";
    try
      {
        connection.export_action_group (object_path, this.actions);
      }
    catch (Error e)
      {
        critical (@"Unable to export actions on $object_path: $(e.message)");
      }

    this.profiles.for_each ((name,profile) => {
      var path = @"$object_path/$name";
      debug (@"exporting menu '$path'");
      profile.export_menu (connection, path);
    });
  }

  void on_name_lost (DBusConnection connection, string name)
  {
    debug (@"name lost: $name");
    this.loop.quit ();
  }
}
