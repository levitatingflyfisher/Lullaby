// Facade for everything that touches a baby photo as a FILE: resolving a
// stored photoPath into an ImageProvider and persisting a freshly picked
// photo into permanent app storage.
//
// dart:io compiles on web but throws at runtime, so the native (dart:io)
// implementation is selected away on web builds, where every photo resolves
// to "no photo" (initial-letter avatar) and the pick affordance is hidden via
// [babyPhotoSupported]. Same conditional-import trio convention as this
// repo's database connection split and Sundial's backup_file_save.
export 'baby_photo_io.dart'
    if (dart.library.js_interop) 'baby_photo_web.dart';
