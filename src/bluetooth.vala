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

/**
 * Base class for the bluetooth backend.
 */
public class Bluetooth: Object
{
  /* whether or not our system can be seen by other bluetooth devices */
  public bool discoverable { get; protected set; default = false; }
  public virtual void try_set_discoverable (bool b) {}

  /* whether or not there are any bluetooth adapters powered up on the system */
  public bool powered { get; protected set; default = false; }

  /* whether or not bluetooth's been disabled,
     either by a software setting or physical hardware switch */
  public bool blocked { get; protected set; default = true; }
  public virtual void try_set_blocked (bool b) {
    killswitch.try_set_blocked (b);
  }

  public class Device: Object {
    public string name { get; construct; }
    public bool supports_browsing { get; construct; }
    public bool supports_file_transfer { get; construct; }
    public Device (string name,
                   bool supports_browsing,
                   bool supports_file_transfer) {
      Object (name: name,
              supports_browsing: supports_browsing,
              supports_file_transfer: supports_file_transfer);
    }
  }

  private static uint16 get_uuid16_from_uuid (string uuid)
  {
    uint16 uuid16;

    string[] tokens = uuid.split ("-", 1);
    if (tokens.length > 0)
      uuid16 = (uint16) uint64.parse ("0x"+tokens[0]);
    else
      uuid16 = 0;

    return uuid16;
  }
        
  protected static bool uuid_supports_file_transfer (string uuid)
  {
    return get_uuid16_from_uuid (uuid) == 0x1105; // OBEXObjectPush
  }

  protected static bool uuid_supports_browsing (string uuid)
  {
    return get_uuid16_from_uuid (uuid) == 0x1106; // OBEXFileTransfer
  }

  public enum DeviceType
  {
    COMPUTER,
    PHONE,
    MODEM,
    NETWORK,
    HEADSET,
    HEADPHONES,
    VIDEO,
    OTHER_AUDIO,
    JOYPAD,
    KEYPAD,
    KEYBOARD,
    TABLET,
    MOUSE,
    PRINTER,
    CAMERA
  }

  protected static DeviceType class_to_device_type (uint32 c)
  {
    switch ((c & 0x1f00) >> 8)
      {
        case 0x01:
          return DeviceType.COMPUTER;

        case 0x02:
          switch ((c & 0xfc) >> 2)
            {
              case 0x01:
              case 0x02:
              case 0x03:
              case 0x05:
                return DeviceType.PHONE;

              case 0x04:
                return DeviceType.MODEM;
            }
          break;

        case 0x03:
          return DeviceType.NETWORK;

        case 0x04:
          switch ((c & 0xfc) >> 2)
            {
              case 0x01:
              case 0x02:
                return DeviceType.HEADSET;

              case 0x06:
                return DeviceType.HEADPHONES;

              case 0x0b: // vcr
              case 0x0c: // video camera
              case 0x0d: // camcorder
                return DeviceType.VIDEO;

              default:
                return DeviceType.OTHER_AUDIO;
            }
          //break;

        case 0x05:
          switch ((c & 0xc0) >> 6)
            {
              case 0x00:
                switch ((c & 0x1e) >> 2)
                  {
                    case 0x01:
                    case 0x02:
                      return DeviceType.JOYPAD;
                  }
                break;

              case 0x01:
                return DeviceType.KEYBOARD;

              case 0x02:
                switch ((c & 0x1e) >> 2)
                  {
                    case 0x05:
                      return DeviceType.TABLET;

                    default:
                      return DeviceType.MOUSE;
                  }
            }
          break;

        case 0x06:
          if ((c & 0x80) != 0)
            return DeviceType.PRINTER;
          if ((c & 0x20) != 0)
            return DeviceType.CAMERA;
          break;
      }

    return 0;
  }


  /***
  ****  Killswitch Implementation 
  ***/

  private KillSwitch killswitch;

  public Bluetooth (KillSwitch killswitch)
  {
    this.killswitch = killswitch;
    blocked = killswitch.blocked;
    killswitch.notify["blocked"].connect (() => blocked = killswitch.blocked );
  }
}
