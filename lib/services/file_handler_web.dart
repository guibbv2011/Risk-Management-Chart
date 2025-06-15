import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'file_handler.dart';

/// Web-specific file handler using HTML File APIs
class WebFileHandler implements FileHandler {
  @override
  bool get isSupported => kIsWeb;

  @override
  Future<bool> saveFile(String fileName, String data) async {
    try {
      // Create blob with JSON data
      final blob = html.Blob([data], 'application/json');

      // Create download URL
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create anchor element for download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      // Add to DOM, click, and remove
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);

      // Clean up URL
      html.Url.revokeObjectUrl(url);

      debugPrint('File download initiated: $fileName');
      return true;
    } catch (e) {
      debugPrint('Web file save failed: $e');
      return false;
    }
  }

  @override
  Future<String?> pickAndReadFile() async {
    try {
      // Create file input element
      final input = html.FileUploadInputElement()
        ..accept = '.json,application/json'
        ..multiple = false;

      // Create a completer to handle async file selection
      final completer = Completer<String?>();

      // Handle file selection
      input.onChange.listen((event) async {
        final files = input.files;
        if (files == null || files.isEmpty) {
          completer.complete(null);
          return;
        }

        final file = files.first;
        debugPrint('Selected file: ${file.name} (${file.size} bytes)');

        try {
          // Read file content
          final reader = html.FileReader();

          reader.onLoad.listen((event) {
            final content = reader.result as String;
            completer.complete(content);
          });

          reader.onError.listen((event) {
            debugPrint('File read error: ${reader.error}');
            completer.completeError('Failed to read file: ${reader.error}');
          });

          // Start reading
          reader.readAsText(file);
        } catch (e) {
          debugPrint('File processing error: $e');
          completer.completeError('Failed to process file: $e');
        }
      });

      // Handle when the input is removed without selection
      // Note: onCancel is not available, so we rely on onChange handling null files

      // Add to DOM and trigger click
      html.document.body?.children.add(input);
      input.click();
      html.document.body?.children.remove(input);

      return await completer.future;
    } catch (e) {
      debugPrint('Web file pick failed: $e');
      rethrow;
    }
  }
}

/// Factory function to create web file handler
FileHandler createFileHandler() {
  return WebFileHandler();
}
