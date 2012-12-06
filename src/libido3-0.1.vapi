namespace Ido
{
    [CCode (cheader_filename = "libido/idoswitchmenuitem.h")]
    public class SwitchMenuItem : Gtk.CheckMenuItem
    {
        public SwitchMenuItem ();
        public Gtk.Container content_area { get; }
    }
}
