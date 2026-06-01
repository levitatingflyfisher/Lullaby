import 'dart:ffi';

import 'package:sqlite3/open.dart';

void ensureSqlite3() {
  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });
}
