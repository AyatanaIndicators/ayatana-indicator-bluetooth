[DBus (name = "org.bluez.Agent1")]
public class Agent: Object
{
    public GLib.Menu menu;
    public GLib.SimpleActionGroup actions;
    private GLib.SimpleAction pin_action;
    public string menu_path;
    public string actions_path;

    private MainLoop loop;
    private Bluetooth bluetooth;
    private Notify.Notification? notification;
    private string passkey;

    public Agent (Bluetooth bluez)
    {
        // Menu
        menu = new GLib.Menu ();
        GLib.MenuItem item = new GLib.MenuItem ("", "notifications.pin");
        item.set_attribute_value ("x-canonical-type", new Variant.string ("com.canonical.snapdecision.textfield"));
        item.set_attribute_value ("x-echo-mode-password", new Variant.boolean (false));
        menu.append_item (item);

        // Actions
        actions = new GLib.SimpleActionGroup ();
        pin_action = new GLib.SimpleAction.stateful ("pin", null, new Variant.string (""));
        pin_action.change_state.connect ((value) => {
            this.passkey = value.get_string ();
        });
        actions.add_action (pin_action);

        loop = new MainLoop (null, false);
        bluetooth = bluez;
        Notify.init ("ayatana-indicator-bluetooth");
    }

    /* TODO: Add a better way to differentiate between rejected and cancelled errors, maybe with an enum */
    private bool sendNotification (string device_name, string body, bool need_input, bool have_actions)
    {
        bool accepted = !have_actions;

        notification = new Notify.Notification (@"Pair with $device_name?", body, "bluetooth-active");
        notification.closed.connect (() => {
            accepted = false;
            notification = null;

            if (loop.is_running ()) {
                loop.quit ();
            }
        });

        bool is_lomiri = AyatanaCommon.utils_is_lomiri ();

        if (is_lomiri) {
            if (have_actions) {
                notification.set_hint ("x-lomiri-snap-decisions", true);
                notification.set_hint ("x-lomiri-private-affirmative-tint", "true");
            }

            if (need_input) {
                VariantBuilder actions_builder = new VariantBuilder (new VariantType ("a{sv}"));
                actions_builder.add ("{sv}", "notifications", new Variant.string (actions_path));

                VariantBuilder builder = new VariantBuilder (new VariantType ("a{sv}"));
                builder.add ("{sv}", "busName", new Variant.string ("org.ayatana.indicator.bluetooth"));
                builder.add ("{sv}", "menuPath", new Variant.string (menu_path));
                builder.add ("{sv}", "actions", actions_builder.end ());

                notification.set_hint ("x-lomiri-private-menu-model", builder.end ());
            }
        }

        if (have_actions) {
            notification.add_action("yes_id", "Yes", (notif, action) => {
                loop.quit ();
                notification = null;
                accepted = true;
            });
            notification.add_action("no_id", "No", (notif, action) => {
                loop.quit ();
                notification = null;
                accepted = false;
            });
        }

        if (!have_actions && !need_input) {
            // Display-only notification. Make sure we don't time out.
            notification.set_hint ("urgency", 2);
        }

        try {
            notification.show ();
        }
        catch (Error e) {
            warning ("Panic: Failed showing notification: %s", e.message);
        }

        if (have_actions) {
            loop.run ();
        }

        return accepted;
    }

    public void AuthorizeService (GLib.ObjectPath object, string uuid) throws GLib.DBusError, GLib.IOError
    {
    }

    public void RequestConfirmation (GLib.ObjectPath object, uint32 passkey) throws RejectedError, GLib.DBusError, GLib.IOError
    {
        string body = "Are you sure you want to pair with passkey %06u?".printf (passkey);
        bool confirmed = sendNotification (bluetooth.get_device_name (object), body, false, true);

        if (!confirmed) {
            throw new RejectedError.ERROR ("Rejected by user");
        }
    }

    public void RequestAuthorization (GLib.ObjectPath object) throws RejectedError, GLib.DBusError, GLib.IOError
    {
        bool authorized = sendNotification (bluetooth.get_device_name (object), "Are you sure you want to pair with this device?", false, true);

        if (!authorized) {
            throw new RejectedError.ERROR ("Rejected by user");
        }
    }

    public string RequestPinCode (GLib.ObjectPath object) throws RejectedError, GLib.DBusError, GLib.IOError
    {
        bool accepted = sendNotification (bluetooth.get_device_name (object), "Enter PIN for this device", true, true);

        if (!accepted) {
            throw new RejectedError.ERROR ("Rejected by user");
        }

        return passkey;
    }

    public void DisplayPinCode (GLib.ObjectPath object, string pincode) throws GLib.DBusError, GLib.IOError
    {
        sendNotification (bluetooth.get_device_name (object), @"Enter the PIN code $pincode on the other device", false, false);
    }

    public uint32 RequestPasskey (GLib.ObjectPath object) throws RejectedError, GLib.DBusError, GLib.IOError
    {
        bool accepted = sendNotification (bluetooth.get_device_name (object), "Enter passkey for this device", true, true);

        if (!accepted) {
            throw new RejectedError.ERROR ("Rejected by user");
        }

        return passkey.to_int ();
    }

    public void DisplayPasskey (GLib.ObjectPath object, uint32 passkey, uint16 entered) throws GLib.DBusError, GLib.IOError
    {
        string body = "Enter the passkey %06u on the other device".printf (passkey);
        sendNotification (bluetooth.get_device_name (object), body, false, false);
    }

    public void Cancel () throws GLib.DBusError, GLib.IOError
    {
        if (loop.is_running ()) {
            loop.quit ();
        }

        if (notification != null) {
            notification.close ();
            notification = null;
        }
    }

    public void Release () throws GLib.DBusError, GLib.IOError
    {
    }
}

[DBus (name = "org.bluez.Error.Cancelled")]
public errordomain CancelledError {
    ERROR
}

[DBus (name = "org.bluez.Error.Rejected")]
public errordomain RejectedError {
    ERROR
}
