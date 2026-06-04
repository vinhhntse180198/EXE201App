import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickedImageBytes {
  const PickedImageBytes({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

bool get _isMobileNative =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Chọn ảnh từ thư viện hoặc camera (mobile) / file picker (desktop & web).
Future<PickedImageBytes?> pickImageWithSheet(BuildContext context) async {
  if (!_isMobileNative) {
    return _pickWithFilePicker();
  }

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Thư viện ảnh'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Chụp ảnh'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  return _pickWithImagePicker(source);
}

Future<PickedImageBytes?> _pickWithImagePicker(ImageSource source) async {
  final xFile = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 85,
  );
  if (xFile == null) return null;

  final bytes = await xFile.readAsBytes();
  var name = xFile.name.trim();
  if (name.isEmpty) {
    name = source == ImageSource.camera ? 'camera.jpg' : 'photo.jpg';
  }
  return PickedImageBytes(bytes: bytes, filename: name);
}

Future<PickedImageBytes?> _pickWithFilePicker() async {
  final picked = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
  final file = picked?.files.single;
  if (file?.bytes == null) return null;
  final name = file!.name.trim().isNotEmpty ? file.name : 'photo.jpg';
  return PickedImageBytes(bytes: file.bytes!, filename: name);
}
