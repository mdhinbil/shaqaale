import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';

/// Decode a base64 image, returning empty bytes on bad input (never throws).
Uint8List base64DecodeSafe(String s) {
  try {
    return base64Decode(s);
  } catch (_) {
    return Uint8List(0);
  }
}

Future<String?> _b64(ImageSource src) async {
  final x = await ImagePicker().pickImage(
      source: src, maxWidth: 320, maxHeight: 320, imageQuality: 60);
  if (x == null) return null;
  return base64Encode(await x.readAsBytes());
}

/// Lets the user take/choose a profile photo (or remove it). Returns a base64
/// string to set, '' to remove, or null for no change.
Future<String?> choosePhoto(BuildContext context, {required bool hasPhoto}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Wrap(children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined, color: kBlue),
          title: Text(t('Take photo', 'Sawir qaad')),
          onTap: () => Navigator.pop(context, 'camera'),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined, color: kBlue),
          title: Text(t('Choose from gallery', 'Ka dooro sawirada')),
          onTap: () => Navigator.pop(context, 'gallery'),
        ),
        if (hasPhoto)
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFD63B3B)),
            title: Text(t('Remove photo', 'Ka saar sawirka')),
            onTap: () => Navigator.pop(context, 'remove'),
          ),
      ]),
    ),
  );
  if (choice == null) return null;
  if (choice == 'remove') return '';
  return _b64(choice == 'camera' ? ImageSource.camera : ImageSource.gallery);
}

/// A circular avatar showing the base64 photo, or a coloured initial fallback.
Widget photoAvatar(String photo, String name,
    {double radius = 21, Color? bg, Color? fg}) {
  if (photo.isNotEmpty) {
    try {
      return CircleAvatar(
          radius: radius, backgroundImage: MemoryImage(base64Decode(photo)));
    } catch (_) {}
  }
  return CircleAvatar(
    radius: radius,
    backgroundColor: bg ?? const Color(0xFFEAF2FF),
    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: radius * .8,
            color: fg ?? kBlue)),
  );
}
