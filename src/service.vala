/*
 * Copyright 2013 Canonical Ltd.
 * Copyright 2025 Robert Tari
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *   Charles Kerr <charles.kerr@canonical.com>
 *   Robert Ancell <robert.ancell@canonical.com>
 *   Robert Tari <robert@tari.in>
 */

/**
 * Boilerplate class to own the name on the bus,
 * to create the profiles, and to export them on the bus.
 */
public class Service: Object
{
  private MainLoop loop;
  private SimpleActionGroup actions;
  private HashTable<string,Profile> profiles;
  private Bluetooth bluetooth;
  private Agent agent;
  private DBusConnection connection;
  private uint exported_action_id;

  private uint exported_agent_action_id;
  private uint exported_agent_menu_id;

  private const string OBJECT_PATH = "/org/ayatana/indicator/bluetooth";
  private const string AGENT_OBJECT_PATH = "/org/ayatana/indicator/bluetooth/agent";

  private void unexport ()
  {
    if (connection != null)
      {
        profiles.for_each ((name, profile)
          => profile.unexport_menu (connection));

        if (exported_action_id != 0)
          {
            debug (@"unexporting action group '$(OBJECT_PATH)'");
            connection.unexport_action_group (exported_action_id);
            exported_action_id = 0;
          }

        if (exported_agent_menu_id != 0)
          {
            connection.unexport_menu_model (exported_agent_menu_id);
            exported_agent_menu_id = 0;
          }

        if (exported_agent_action_id != 0)
          {
            connection.unexport_action_group (exported_agent_action_id);
            exported_agent_action_id = 0;
          }
      }
  }

  public Service (Bluetooth bluetooth_service)
  {
    actions = new SimpleActionGroup ();
    bluetooth = bluetooth_service;
    agent = new Agent (bluetooth);
    agent.actions_path = AGENT_OBJECT_PATH;
    agent.menu_path = AGENT_OBJECT_PATH;

    profiles = new HashTable<string,Profile> (str_hash, str_equal);
    profiles.insert ("phone", new Phone (bluetooth, actions));
    profiles.insert ("desktop", new Desktop (bluetooth, actions));
    profiles.insert ("greeter", new Greeter (bluetooth, actions));
  }

  public int run ()
  {
    if (loop != null)
      {
        warning ("service is already running");
        return Posix.EXIT_FAILURE;
      }

    var own_name_id = Bus.own_name (BusType.SESSION,
                                    "org.ayatana.indicator.bluetooth",
                                    BusNameOwnerFlags.NONE,
                                    on_bus_acquired,
                                    null,
                                    on_name_lost);

    var system_name_id = Bus.own_name (BusType.SYSTEM,
                                       "org.ayatana.indicator.bluetooth",
                                       BusNameOwnerFlags.NONE,
                                       on_system_bus_acquired,
                                       null,
                                       null);

    bluetooth.agent_manager_ready.connect (() => {
        bluetooth.add_agent (AGENT_OBJECT_PATH);
    });

    loop = new MainLoop (null, false);
    loop.run ();

    // cleanup
    unexport ();
    Bus.unown_name (own_name_id);
    Bus.unown_name (system_name_id);
    return Posix.EXIT_SUCCESS;
  }

  void on_system_bus_acquired (DBusConnection connection, string name)
  {
    try
    {
        connection.register_object (AGENT_OBJECT_PATH, agent);
    }
    catch (GLib.IOError pError)
    {
        warning ("Panic: Failed registering pairing agent: %s", pError.message);
    }
  }

  void on_bus_acquired (DBusConnection connection, string name)
  {
    debug (@"bus acquired: $name");
    this.connection = connection;

    try
      {
        debug (@"exporting action group '$(OBJECT_PATH)'");
        exported_action_id = connection.export_action_group (OBJECT_PATH,
                                                             actions);

        exported_agent_action_id = connection.export_action_group (AGENT_OBJECT_PATH,
                                                                   agent.actions);
        exported_agent_menu_id = connection.export_menu_model (AGENT_OBJECT_PATH,
                                                               agent.menu);
      }
    catch (Error e)
      {
        critical (@"Unable to export actions on $OBJECT_PATH: $(e.message)");
      }

    profiles.for_each ((name, profile)
        => profile.export_menu (connection, @"$OBJECT_PATH/$name"));
  }

  void on_name_lost (DBusConnection connection, string name)
  {
    debug (@"name lost: $name");
    loop.quit ();
  }
}
