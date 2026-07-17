import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Web: hand the bytes straight to share_plus — no dart:io, whose File stub
/// throws at runtime in a browser. On browsers with the Web Share API
/// (Android/iOS Chrome, Safari) this opens the native share sheet; elsewhere
/// share_plus's built-in fallback (Share.downloadFallbackEnabled, on by
/// default) downloads the file instead — either way the export WORKS and
/// nothing throws. fileNameOverrides carries the name; XFile.fromData's
/// `name` is ignored on web.
Future<void> shareExportBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  await Share.shareXFiles(
    [XFile.fromData(bytes, mimeType: mimeType)],
    fileNameOverrides: [fileName],
  );
}
