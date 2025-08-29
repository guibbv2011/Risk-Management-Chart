import 'dart:async';

class Directory {
  final String path;
  Directory(this.path);
}

Future<Directory> getApplicationDocumentsDirectory() async {
  throw UnsupportedError(
    'getApplicationDocumentsDirectory is not supported on web platform',
  );
}

Future<Directory> getApplicationSupportDirectory() async {
  throw UnsupportedError(
    'getApplicationSupportDirectory is not supported on web platform',
  );
}

Future<Directory> getTemporaryDirectory() async {
  throw UnsupportedError(
    'getTemporaryDirectory is not supported on web platform',
  );
}

Future<Directory?> getExternalStorageDirectory() async {
  throw UnsupportedError(
    'getExternalStorageDirectory is not supported on web platform',
  );
}
