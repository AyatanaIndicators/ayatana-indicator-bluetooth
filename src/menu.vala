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

class BluetoothMenu: Object
{
  protected Menu root;
  protected Menu menu;

  public virtual void add_actions_to_group (SimpleActionGroup group)
  {
  }

  public BluetoothMenu (string profile)
  {
    this.menu = new Menu ();

    var root_item = new MenuItem (null, "indicator.root-" + profile);
    root_item.set_attribute ("x-canonical-type", "s", "com.canonical.indicator.root");
    root_item.set_submenu (this.menu);

    this.root = new Menu ();
    this.root.append_item (root_item);
  }

  public void export (DBusConnection connection, string object_path)
  {
    try
      {
        message ("exporting on %s", object_path);
        connection.export_menu_model (object_path, this.root);
      }
    catch (Error e)
      {
        critical ("%s", e.message);
      }
  }
}
