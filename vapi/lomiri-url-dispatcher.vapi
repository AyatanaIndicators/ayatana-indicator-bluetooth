[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "liblomiri-url-dispatcher/lomiri-url-dispatcher.h")]

namespace LomiriUrlDispatch
{
  public delegate void DispatchCallback ();

  [CCode (cname = "lomiri_url_dispatch_send")]
  public static void send (string url, DispatchCallback? func = null);
}
