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
  private Settings settings;
  private Bluetooth bluetooth;

  private SimpleAction root_action;
  private Action[] all_actions;

  public override void add_actions_to_group (SimpleActionGroup group)
  {
    for (var i=0; i<all_actions.length; i++)
      group.insert (all_actions[i]);
  }

  public Desktop (Bluetooth bluetooth)
  {
    base ("desktop");

    this.bluetooth = bluetooth;

    settings = new Settings ("com.canonical.indicator.bluetooth");

    root_action = new SimpleAction.stateful ("root-desktop", null, action_state_for_root());

    all_actions = {};
    all_actions += root_action;
    all_actions += create_enabled_action (bluetooth);
    all_actions += create_discoverable_action (bluetooth);
    all_actions += create_settings_action ();
    all_actions += create_wizard_action ();

    bluetooth.notify.connect (() => update_root_action_state());
    settings.changed["visible"].connect (()=> update_root_action_state());

    Menu section;
    MenuItem item;

    section = new Menu ();
    item = new MenuItem ("Bluetooth", "indicator.desktop-enabled");
    item.set_attribute ("x-canonical-type", "s", "com.canonical.indicator.switch");
    section.append_item (item);
    item = new MenuItem ("Visible", "indicator.desktop-discoverable");
    item.set_attribute ("x-canonical-type", "s", "com.canonical.indicator.switch");
    section.append_item (item);
    menu.append_section (null, section);

    section = new Menu ();
    section.append (_("Set Up New Device…"), "indicator.desktop-wizard");
    section.append (_("Bluetooth Settings…"), "indicator.desktop-settings");
    menu.append_section (null, section);
  }

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

  void spawn_command_line_async (string command)
  {
    try {
      Process.spawn_command_line_async (command);
    } catch (Error e) {
      warning ("unable to launch '%s': %s", command, e.message);
    }
  }

  Action create_wizard_action ()
  {
    var action = new SimpleAction ("desktop-wizard", null);
    action.activate.connect (() => spawn_command_line_async ("bluetooth-wizard"));
    return action;
  }

  Action create_settings_action ()
  {
    var action = new SimpleAction ("desktop-settings", null);
    action.activate.connect (() => spawn_command_line_async ("gnome-control-center bluetooth"));
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

  void update_root_action_state ()
  {
    root_action.set_state (action_state_for_root ());
  }
}
