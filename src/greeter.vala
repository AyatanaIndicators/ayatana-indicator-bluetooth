/*
* Copyright 2025 Robert Tari <robert@tari.in>
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
*/

class Greeter: Profile
{
    GLib.SimpleActionGroup action_group;

    public Greeter (Bluetooth bluetooth, GLib.SimpleActionGroup action_group)
    {
        base (bluetooth, "greeter");
        this.bluetooth = bluetooth;
        this.action_group = action_group;
        GLib.Action[] actions = {};
        actions += root_action;
        actions += create_supported_action (bluetooth);
        actions += create_enabled_action (bluetooth);

        foreach (GLib.Action action in actions)
        {
            action_group.add_action (action);
        }

        GLib.Menu section = new GLib.Menu ();
        GLib.MenuItem menu_item = create_enabled_menuitem ();
        section.append_item (menu_item);
        menu.append_section (null, section);

        bluetooth.notify.connect (() => update_visibility ());
        update_visibility ();
        bluetooth.notify.connect (() => update_root_action_state ());
    }

    void update_visibility ()
    {
        visible = bluetooth.enabled;
    }
}
