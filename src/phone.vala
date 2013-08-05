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

class Phone: Profile
{
  Bluetooth bluetooth;
  SimpleActionGroup action_group;

  public Phone (Bluetooth bluetooth, SimpleActionGroup action_group)
  {
    base ("phone");

    this.bluetooth = bluetooth;
    this.action_group = action_group;

    // build the static actions
    Action[] actions = {};
    actions += new SimpleAction.stateful ("root-phone", null, action_state_for_root());
    actions += create_settings_action ();
    foreach (var a in actions)
      action_group.insert (a);

    var section = new Menu ();
    section.append (_("Sound settings…"), "indicator.phone-settings");
    menu.append_section (null, section);
  }

  Action create_settings_action ()
  {
    var action = new SimpleAction ("phone-settings", null);

    action.activate.connect ((action, param) => {
      try {
        Process.spawn_command_line_async ("system-settings bluetooth");
      } catch (Error e) {
        warning (@"unable to launch settings: $(e.message)");
      }
    });

    return action;
  }

  private Variant action_state_for_root ()
  {
    var label = "Hello World"; // FIXME
    var a11y = "Hello World"; // FIXME
    var visible = true; // FIXME

    string icon_name = "bluetooth"; // FIXME: enabled, disabled, connected, etc.
    var icon = new ThemedIcon.with_default_fallbacks (icon_name);

    var builder = new VariantBuilder (new VariantType ("a{sv}"));
    builder.add ("{sv}", "visible", new Variant ("b", visible));
    builder.add ("{sv}", "label", new Variant ("s", label));
    builder.add ("{sv}", "accessible-desc", new Variant ("s", a11y));
    builder.add ("{sv}", "icon", icon.serialize());
    return builder.end ();
  }
}
