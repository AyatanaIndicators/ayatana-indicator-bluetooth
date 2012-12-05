[CCode (cprefix = "Bluetooth", lower_case_cprefix = "bluetooth_")]
namespace GnomeBluetooth
{

[CCode (cheader_filename = "bluetooth-client.h")]
public class Client : GLib.Object
{
    public Client ();
    public Gtk.TreeModel model { get; }
    public Gtk.TreeModel adapter_model { get; }
    public Gtk.TreeModel device_model { get; }
    [CCode (finish_function = "bluetooth_client_connect_service_finish")]
    public async bool connect_service (string device, bool connect, GLib.Cancellable? cancellable = null) throws GLib.Error;
}

[CCode (cheader_filename = "bluetooth-enums.h", cprefix = "BLUETOOTH_COLUMN_")]
public enum Column
{
    PROXY,
    ADDRESS,
    ALIAS,
    NAME,
    TYPE,
    ICON,
    DEFAULT,
    PAIRED,
    TRUSTED,
    CONNECTED,
    DISCOVERABLE,
    DISCOVERING,
    LEGACYPAIRING,
    POWERED,
    SERVICES,
    UUIDS
}

[CCode (cheader_filename = "bluetooth-enums.h", cprefix = "BLUETOOTH_TYPE_")]
public enum Type
{
    ANY,
    PHONE,
    MODEM,
    COMPUTER,
    NETWORK,
    HEADSET,
    HEADPHONES,
    OTHER_AUDIO,
    KEYBOARD,
    MOUSE,
    CAMERA,
    PRINTER,
    JOYPAD,
    TABLET,
    VIDEO
}

[CCode (cheader_filename = "bluetooth-utils.h")]
public void browse_address (GLib.Object? object, string address, uint timestamp, GLib.AsyncReadyCallback? callback);

[CCode (cheader_filename = "bluetooth-utils.h")]
public void send_to_address (string address, string alias);

[CCode (cheader_filename = "bluetooth-killswitch.h", cprefix = "BLUETOOTH_KILLSWITCH_STATE_")]
public enum KillswitchState
{
    NO_ADAPTER,
    SOFT_BLOCKED,
    UNBLOCKED,
    HARD_BLOCKED
}

[CCode (cheader_filename = "bluetooth-killswitch.h")]
public class Killswitch : GLib.Object
{
    public Killswitch ();
    public signal void state_changed (KillswitchState state);
    public bool has_killswitches ();
    public KillswitchState state { get; set; }
    public unowned string state_to_string ();
}

}
