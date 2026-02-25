import 'dart:io';

Future<void> writePdfToFile(String path, List<int> bytes) async {
  final file = File(path);
  await file.writeAsBytes(bytes);
}
