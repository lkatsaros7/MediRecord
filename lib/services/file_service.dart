// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

Future<(Uint8List, String)?> pickFile() async {
  final completer = Completer<(Uint8List, String)?>();
  final input = html.InputElement()
    ..type = 'file'
    ..accept = '.csv,.xlsx'
    ..style.display = 'none';
  html.document.body!.append(input);
  input.onChange.listen((event) async {
    final file = input.files?.first;
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      input.remove();
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final result = reader.result;
    final Uint8List bytes;
    if (result is ByteBuffer) {
      bytes = Uint8List.view(result);
    } else {
      bytes = result as Uint8List;
    }
    if (!completer.isCompleted) completer.complete((bytes, file.name));
    input.remove();
  });
  input.onAbort.listen((_) {
    if (!completer.isCompleted) completer.complete(null);
    input.remove();
  });
  input.click();
  return completer.future;
}

void downloadFile(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
