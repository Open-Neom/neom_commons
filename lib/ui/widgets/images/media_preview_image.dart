import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom_core/domain/use_cases/media_upload_service.dart';

/// Builds a preview widget for the currently selected media file.
///
/// On web, uses [Image.memory] with the service's [mediaBytes].
/// On mobile, uses [Image.file] with the service's [getMediaFile].
///
/// Returns null if no media is selected.
Widget? buildMediaPreview(
  MediaUploadService? service, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (service == null || !service.mediaFileExists()) return null;

  if (kIsWeb && service.mediaBytes != null) {
    return Image.memory(
      service.mediaBytes!,
      width: width,
      height: height,
      fit: fit,
    );
  }

  return Image.file(
    service.getMediaFile() as dynamic,
    width: width,
    height: height,
    fit: fit,
  );
}

/// Returns an [ImageProvider] for the currently selected media file.
///
/// On web, returns [MemoryImage] with the service's [mediaBytes].
/// On mobile, returns [FileImage] with the service's [getMediaFile].
///
/// Returns null if no media is selected.
ImageProvider? buildMediaImageProvider(MediaUploadService? service) {
  if (service == null || !service.mediaFileExists()) return null;

  if (kIsWeb && service.mediaBytes != null) {
    return MemoryImage(service.mediaBytes!);
  }

  return FileImage(service.getMediaFile() as dynamic);
}
