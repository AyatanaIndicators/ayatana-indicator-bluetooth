/*
 * Copyright (C) 2012-2013 Canonical Ltd.
 * Author: Robert Ancell <robert.ancell@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, version 3 of the License.
 * See http://www.gnu.org/copyleft/gpl.html the full text of the license.
 */

public class Service: Object
{
    private MainLoop loop;
    private SimpleActionGroup actions;
    private HashTable<string,Profile> profiles;

    public Service (Bluetooth bluetooth)
    {
      profiles = new HashTable<string,Profile> (str_hash, str_equal);
      profiles.insert ("phone", new Phone (bluetooth));
      profiles.insert ("desktop", new Desktop (bluetooth));

      actions = new SimpleActionGroup ();
      foreach (Profile profile in profiles.get_values())
        profile.add_actions_to_group (actions);
    }

    public int run ()
    {
      if (this.loop != null)
        {
          warning ("service is already running");
          return 1;
        }

      Bus.own_name (BusType.SESSION,
                    "com.canonical.indicator.bluetooth",
                    BusNameOwnerFlags.NONE,
                    this.on_bus_acquired,
                    null,
                    this.on_name_lost);

      this.loop = new MainLoop (null, false);
      this.loop.run ();
      return 0;
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
        var path = @"/com/canonical/indicator/bluetooth/$name";
        message (@"exporting menu '$path'");
        profile.export_menu (connection, path);
      });
    }

    void on_name_lost (DBusConnection connection, string name)
    {
      debug (@"name lost: $name");
      this.loop.quit ();
    }
}
