import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Foto capturada: bytes e nome do arquivo
typedef CapturedPhoto = ({Uint8List bytes, String name});

/// Abre a câmera ou a galeria; nos testes, substitui o seletor do sistema
typedef PhotoCapture = Future<CapturedPhoto?> Function(ImageSource source);

/// Seletor do sistema, já reduzido para não enviar fotos de 12 MP pela rede
Future<CapturedPhoto?> pickPhotoWithSystem(ImageSource source) async {
  final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1400);
  if (picked == null) return null;
  return (bytes: await picked.readAsBytes(), name: picked.name);
}
