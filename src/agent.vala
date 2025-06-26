[DBus (name = "org.bluez.Agent1")]
public class Agent: Object
{
    public GLib.Menu menu;
    public GLib.SimpleActionGroup actions;

    private GLib.SimpleAction pin_action;
    private MainLoop loop;
    private Bluetooth bluetooth;

    public Agent (Bluetooth bluez)
    {
        // Menu
        menu = new GLib.Menu ();
        GLib.MenuItem item = new GLib.MenuItem ("PIN", "password");
        item.set_attribute_value ("x-canonical-type", new Variant.string ("com.canonical.snapdecision.textfield"));
        item.set_attribute_value ("x-echo-mode-password", new Variant.boolean (false));
        menu.append_item (item);

        // Actions
        actions = new GLib.SimpleActionGroup ();
        pin_action = new GLib.SimpleAction.stateful ("password", null, new Variant.string (""));
        pin_action.change_state.connect ((value) => {
            warning ("HELLO!");
        });
        actions.add_action (pin_action);

        loop = new MainLoop (null, false);
        bluetooth = bluez;
        Notify.init ("ayatana-indicator-bluetooth");
    }

    private bool sendNotification (string device_name, string body)
    {
        bool accepted = false;

        Notify.Notification notification = new Notify.Notification (@"Pair with $device_name?", body, "bluetooth-active");
        bool bLomiri = AyatanaCommon.utils_is_lomiri ();

        if (bLomiri)
        {
            notification.set_hint ("x-lomiri-snap-decisions", true);
            notification.set_hint ("x-lomiri-private-affirmative-tint", "true");

            VariantBuilder actions_builder = new VariantBuilder (new VariantType ("a{sv}"));
            actions_builder.add ("{sv}", "notifications", new Variant.string ("/agent/actions"));
            Variant actions = actions_builder.end ();

            VariantBuilder builder = new VariantBuilder (new VariantType ("a{sv}"));
            builder.add ("{sv}", "busName", new Variant.string ("org.ayatana.indicator.bluetooth"));
            builder.add ("{sv}", "menuPath", new Variant.string ("/agent/menu"));
            builder.add ("{sv}", "actions", actions);
            Variant stuff = builder.end ();

            notification.set_hint ("x-lomiri-private-menu-model", stuff);

            string some_shit = actions.print(true);
            string other_shit = stuff.print(true);
            warning (@"we got some stuff! $some_shit $other_shit");
        }

        notification.add_action("yes_id", "Yes", (notif, action) => {
            loop.quit ();
            accepted = true;
        });
        notification.add_action("no_id", "No", (notif, action) => {
            loop.quit ();
            accepted = false;
        });

        try
        {
            notification.show ();
        }
        catch (Error pError)
        {
            warning ("Panic: Failed showing notification: %s", pError.message);
        }

        loop.run ();

        return accepted;
    }

    public void AuthorizeService (GLib.ObjectPath object, string uuid) throws GLib.DBusError, GLib.IOError
    {
    }

    public void RequestConfirmation (GLib.ObjectPath object, uint32 passkey) throws RejectedError, GLib.DBusError, GLib.IOError
    {
        string body = "Are you sure you want to pair with passkey %06u?".printf (passkey);
        bool confirmed = sendNotification (bluetooth.get_device_name (object), body);

        if (confirmed) {
            return;
        } else {
            throw new RejectedError.ERROR ("Rejected by user");
        }
    }

    public void RequestAuthorization (GLib.ObjectPath object) throws RejectedError, GLib.DBusError, GLib.IOError
    {
        bool authorized = sendNotification (bluetooth.get_device_name (object), "Are you sure you want to pair with this device?");

        if (authorized) {
            return;
        } else {
            throw new RejectedError.ERROR ("Rejected by user");
        }
    }

    public string RequestPinCode (GLib.ObjectPath object) throws GLib.DBusError, GLib.IOError
    {
        return "123456";
    }

    public void DisplayPinCode (GLib.ObjectPath object, string pincode) throws GLib.DBusError, GLib.IOError
    {
    }

    public uint32 RequestPasskey (GLib.ObjectPath object) throws GLib.DBusError, GLib.IOError
    {
        return 123456;
    }

    public void DisplayPasskey (GLib.ObjectPath object, uint32 passkey, uint16 entered) throws GLib.DBusError, GLib.IOError
    {
    }

    public void Cancel () throws GLib.DBusError, GLib.IOError
    {
        if (loop.is_running ()) {
            loop.quit ();
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
