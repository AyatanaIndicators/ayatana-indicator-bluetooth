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

class Desktop: Profile
{
  private uint idle_rebuild_id = 0;
  private Settings settings;
  private Bluetooth bluetooth;

  private SimpleAction root_action;
  private Action[] all_actions;
  private Menu device_section;
  private HashTable<uint,SimpleAction> connect_actions;

  public override void add_actions_to_group (SimpleActionGroup group)
  {
    for (var i=0; i<all_actions.length; i++)
      group.insert (all_actions[i]);
  }

  protected override void dispose ()
  {
    if (idle_rebuild_id != 0)
      {
        Source.remove (idle_rebuild_id); 
        idle_rebuild_id = 0;
      }

    base.dispose ();
  }

  public Desktop (Bluetooth bluetooth)
  {
    base ("desktop");

    this.bluetooth = bluetooth;

    connect_actions = new HashTable<uint,SimpleAction>(direct_hash, direct_equal);

    settings = new Settings ("com.canonical.indicator.bluetooth");

    root_action = create_root_action ();

    all_actions = {};
    all_actions += root_action;
    all_actions += create_enabled_action (bluetooth);
    all_actions += create_discoverable_action (bluetooth);
    all_actions += create_wizard_action ();
    all_actions += create_browse_files_action ();
    all_actions += create_send_file_action ();
    all_actions += create_show_settings_action ();

    build_menu ();

    settings.changed["visible"].connect (()=> update_root_action_state());
    bluetooth.notify.connect (() => update_root_action_state());
    bluetooth.devices_changed.connect (()=> {
      if (idle_rebuild_id == 0)
        idle_rebuild_id = Idle.add (() => {
          rebuild_device_section();
          idle_rebuild_id = 0;
          return false;
        });
    });
  }

  ///
  ///  MenuItems
  ///

  MenuItem create_device_connection_menuitem (Device device)
  {
    var action_name = @"desktop-device-$(device.id)-connected";

    var item = new MenuItem (_("Connection"), "indicator."+action_name);
    item.set_attribute ("x-canonical-type", "s", "com.canonical.indicator.switch");

    // if this doesn't already have an action, create one
    if (!connect_actions.contains (device.id))
      {
        debug (@"creating action for $action_name");
        var action = new SimpleAction.stateful (action_name, null, device.is_connected);
        action.activate.connect (() => action.set_state (!action.get_state().get_boolean()));
        action.notify["state"].connect (() => bluetooth.set_device_connected (device.id, action.get_state().get_boolean()));
        connect_actions.insert (device.id, action);
        all_actions += action;
      }
    else
      {
        debug (@"updating action $(device.id) state to $(device.is_connected)");
        var action = connect_actions.lookup (device.id);
        action.set_state (device.is_connected);
      }

    return item;
  }

  void rebuild_device_section ()
  {
    device_section.remove_all ();

    foreach (var device in bluetooth.get_devices())
      {
        Menu submenu = new Menu ();
        MenuItem item;

        if (device.is_connectable)
          submenu.append_item (create_device_connection_menuitem (device));

        if (device.supports_browsing)
          submenu.append (_("Browse files…"), @"indicator.desktop-browse-files::$(device.address)");

        if (device.supports_file_transfer)
          submenu.append (_("Send files…"), @"indicator.desktop-send-file::$(device.address)");

        switch (device.device_type)
          {
            case Device.Type.KEYBOARD:
              submenu.append (_("Keyboard Settings…"), "indicator.desktop-show-settings::keyboard");
              break;

            case Device.Type.MOUSE:
            case Device.Type.TABLET:
              submenu.append (_("Mouse and Touchpad Settings…"), "indicator.desktop-show-settings::mouse");
              break;

            case Device.Type.HEADSET:
            case Device.Type.HEADPHONES:
            case Device.Type.OTHER_AUDIO:
              submenu.append (_("Sound Settings…"), "indicator.desktop-show-settings::sound");
              break;
          }

        /* only show the device if it's got actions that we can perform on it */
        if (submenu.get_n_items () > 0)
          {
            item = new MenuItem (device.name, null);
            item.set_attribute_value ("icon", device.icon.serialize());
            item.set_submenu (submenu);
            device_section.append_item (item);
          }
      }
  }

  void build_menu ()
  {
    Menu section;
    MenuItem item;

    // quick toggles section
    section = new Menu ();
    item = new MenuItem ("Bluetooth", "indicator.desktop-enabled");
    item.set_attribute ("x-canonical-type", "s", "com.canonical.indicator.switch");
    section.append_item (item);
    item = new MenuItem ("Visible", "indicator.desktop-discoverable");
    item.set_attribute ("x-canonical-type", "s", "com.canonical.indicator.switch");
    section.append_item (item);
    menu.append_section (null, section);

    // devices section
    device_section = new Menu ();
    rebuild_device_section ();
    menu.append_section (null, device_section);

    // settings section
    section = new Menu ();
    section.append (_("Set Up New Device…"), "indicator.desktop-wizard");
    section.append (_("Bluetooth Settings…"), "indicator.desktop-show-settings::bluetooth");
    menu.append_section (null, section);
  }

  ///
  ///  Action Helpers
  ///

  void spawn_command_line_async (string command)
  {
    try {
      Process.spawn_command_line_async (command);
    } catch (Error e) {
      warning ("unable to launch '$command': $(e.message)");
    }
  }

  void show_control_center (string panel)
  {
    spawn_command_line_async ("gnome-control-center " + panel);
  }

  ///
  ///  Actions
  ///

  Action create_enabled_action (Bluetooth bluetooth)
  {
    var action = new SimpleAction.stateful ("desktop-enabled", null, !bluetooth.blocked);
    action.activate.connect (() => action.set_state (!action.get_state().get_boolean()));
    action.notify["state"].connect (() => bluetooth.try_set_blocked (!action.get_state().get_boolean()));
    bluetooth.notify["blocked"].connect (() => action.set_state (!bluetooth.blocked));
    return action;
  }

  Action create_discoverable_action (Bluetooth bluetooth)
  {
    var action = new SimpleAction.stateful ("desktop-discoverable", null, bluetooth.discoverable);
    action.set_enabled (bluetooth.powered);
    action.activate.connect (() => action.set_state (!action.get_state().get_boolean()));
    action.notify["state"].connect (() => bluetooth.try_set_discoverable (action.get_state().get_boolean()));
    bluetooth.notify["discoverable"].connect (() => action.set_state (bluetooth.discoverable));
    bluetooth.notify["powered"].connect (() => action.set_enabled (bluetooth.powered));
    return action;
  }

  Action create_wizard_action ()
  {
    var action = new SimpleAction ("desktop-wizard", null);
    action.activate.connect (() => spawn_command_line_async ("bluetooth-wizard"));
    return action;
  }

  Action create_browse_files_action ()
  {
    var action = new SimpleAction ("desktop-browse-files", VariantType.STRING);
    action.activate.connect ((action, address) => {
      var uri = @"obex://[$(address.get_string())]/";
      var file = File.new_for_uri (uri);
      file.mount_enclosing_volume.begin (MountMountFlags.NONE, null, null, (obj, res) => {
        try {
          AppInfo.launch_default_for_uri (uri, null);
        } catch (Error e) {
          warning ("unable to launch '$uri': $(e.message)");
        }
      });
    });
    return action;
  }

  Action create_send_file_action ()
  {
    var action = new SimpleAction ("desktop-send-file", VariantType.STRING);
    action.activate.connect ((action, address) => {
      spawn_command_line_async ("bluetooth-sendto --device=$(address.get_string())");
    });
    return action;
  }

  Action create_show_settings_action ()
  {
    var action = new SimpleAction ("desktop-show-settings", VariantType.STRING);
    action.activate.connect ((action, panel) => show_control_center (panel.get_string()));
    return action;
  }

  protected Variant action_state_for_root ()
  {
    bool blocked = bluetooth.blocked;
    bool powered = bluetooth.powered;

    settings.changed["visible"].connect (()=> update_root_action_state());

    bool visible = powered && settings.get_boolean("visible");

    string a11y;
    string icon_name;
    if (powered && !blocked)
      {
        a11y = "Bluetooth (on)";
        icon_name = "bluetooth-active";
      }
    else
      {
        a11y = "Bluetooth (off)";
        icon_name = "bluetooth-disabled";
      }

    var icon = new ThemedIcon.with_default_fallbacks (icon_name);

    var builder = new VariantBuilder (new VariantType ("a{sv}"));
    builder.add ("{sv}", "visible", new Variant ("b", visible));
    builder.add ("{sv}", "accessible-desc", new Variant ("s", a11y));
    builder.add ("{sv}", "icon", icon.serialize());
    return builder.end ();
  }

  SimpleAction create_root_action ()
  {
    return new SimpleAction.stateful ("root-desktop", null, action_state_for_root());
  }

  void update_root_action_state ()
  {
    root_action.set_state (action_state_for_root ());
  }
}
