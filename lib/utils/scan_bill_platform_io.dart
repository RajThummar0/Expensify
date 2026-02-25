import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Mobile implementation - uses File for ML Kit OCR
Future<String?> processImageForOcr(XFile xFile) async {
  final path = xFile.path;
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!await file.exists()) return null;
  final inputImage = InputImage.fromFile(file);
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(inputImage);
    final text = result.text.trim();
    return text.isEmpty ? null : text;
  } finally {
    recognizer.close();
  }
}
