[DBus (name = "org.bluez.Agent1")]
public class Agent: Object
{
    private MainLoop loop;
    private Bluetooth bluetooth;

    public Agent (Bluetooth bluez)
    {
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
