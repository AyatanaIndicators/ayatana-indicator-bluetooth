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

class Profile: Object
{
  protected string name;
  protected Menu root;
  protected Menu menu;

  public virtual void add_actions_to_group (SimpleActionGroup group) {}

  public Profile (string name)
  {
    this.name = name;

    menu = new Menu ();

    var root_item = new MenuItem (null, "indicator.root-" + name);
    root_item.set_attribute ("x-canonical-type", "s", "com.canonical.indicator.root");
    root_item.set_submenu (menu);

    root = new Menu ();
    root.append_item (root_item);
  }

  public void export_menu (DBusConnection connection, string object_path)
  {
    try
      {
        debug (@"exporting '$name' on $object_path");
        connection.export_menu_model (object_path, this.root);
      }
    catch (Error e)
      {
        critical (@"Unable to export menu on $object_path: $(e.message)");
      }
  }
}
