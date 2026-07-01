import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native: write the bytes to a temp file and hand its PATH to the platform
/// share sheet (some share targets require a real file), deleting the temp
/// file once the share completes — the exact behavior the screens had before
/// this seam existed.
Future<void> shareExportBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  try {
    await Share.shareXFiles([XFile(file.path)]);
  } finally {
    if (await file.exists()) await file.delete();
  }
}
