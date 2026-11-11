import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../core/demo/demo_mode.dart';
import '../../mocks/mock_atelier_store.dart';

/// Foto capturada: bytes e nome do arquivo
typedef CapturedPhoto = ({Uint8List bytes, String name});

/// Abre a câmera ou a galeria; no modo demo offline, se o emulador/desktop não
/// tiver câmera disponível, fornece uma captura sintética instantânea.
typedef PhotoCapture = Future<CapturedPhoto?> Function(ImageSource source);

/// Seletor do sistema, já reduzido para não enviar fotos de 12 MP pela rede
Future<CapturedPhoto?> pickPhotoWithSystem(ImageSource source) async {
  try {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1400);
    if (picked != null) {
      return (bytes: await picked.readAsBytes(), name: picked.name);
    }
  } catch (_) {}
  if (kDemoMode) {
    return (bytes: MockAtelierStore.syntheticPngBytes, name: 'atelier_demo_peca.png');
  }
  return null;
}

/// Selfie para o teste de colorimetria: abre a câmera frontal
Future<CapturedPhoto?> pickSelfieWithSystem(ImageSource source) async {
  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
      maxWidth: 1200,
    );
    if (picked != null) {
      return (bytes: await picked.readAsBytes(), name: picked.name);
    }
  } catch (_) {}
  if (kDemoMode) {
    return (bytes: MockAtelierStore.syntheticPngBytes, name: 'atelier_demo_selfie.png');
  }
  return null;
}
