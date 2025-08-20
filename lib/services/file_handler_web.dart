import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'file_handler.dart';

class WebFileHandler implements FileHandler {
  @override
  bool get isSupported => kIsWeb;

  @override
  Future<bool> saveFile(String fileName, String data) async {
    try {
      final blob = html.Blob([data], 'application/json');

      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);

      html.Url.revokeObjectUrl(url);

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> pickAndReadFile() async {
    try {
      final input = html.FileUploadInputElement()
        ..accept = '.json,application/json'
        ..multiple = false;

      final completer = Completer<String?>();

      input.onChange.listen((event) async {
        final files = input.files;
        if (files == null || files.isEmpty) {
          completer.complete(null);
          return;
        }

        final file = files.first;

        try {
          final reader = html.FileReader();

          reader.onLoad.listen((event) {
            final content = reader.result as String;
            completer.complete(content);
          });

          reader.onError.listen((event) {
            completer.completeError('Failed to read file: ${reader.error}');
          });

          reader.readAsText(file);
        } catch (e) {
          completer.completeError('Failed to process file: $e');
        }
      });

      html.document.body?.children.add(input);
      input.click();
      html.document.body?.children.remove(input);

      return await completer.future;
    } catch (e) {
      rethrow;
    }
  }
}

FileHandler createFileHandler() {
  return WebFileHandler();
}
