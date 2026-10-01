// Same-Wi-Fi sync screens: the real ones on Android, a one-line explanation in
// the browser, so the QR code and the LAN client stay out of the web bundle.
export 'wifi_sync_stub.dart' if (dart.library.io) 'wifi_sync_io.dart';
