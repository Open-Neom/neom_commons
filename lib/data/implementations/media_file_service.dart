import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/domain/use_cases/camera_service.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/app_file_from.dart';
import 'package:neom_core/utils/enums/upload_image_type.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/app_utilities.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/upload_utilities.dart';

class MediaFileService {

  static Future<void> handleMedia(XFile file) async {
    if (file.path.isEmpty) {
      AppConfig.logger.d('No se seleccionó ningún archivo.');
      return;
    }

    String fileExtension = file.path.split('.').last.toLowerCase();

    if (CoreConstants.imageExtensions.contains(fileExtension)) {
      AppConfig.logger.d('Archivo seleccionado es una imagen: ${file.path}');
      await getImageFile(imageFile: File(file.path));
    } else if (CoreConstants.videoExtensions.contains(fileExtension)) {
      AppConfig.logger.d('Archivo seleccionado es un video: ${file.path}');
      await getVideoFile(videoFile: File(file.path));
    } else {
      AppConfig.logger.w('Formato de archivo no soportado: ${file.path}');
    }
  }

  static Future<XFile?> getImageFile({AppFileFrom appFileFrom = AppFileFrom.gallery,
    UploadImageType imageType = UploadImageType.post, File? imageFile,
    double ratioX = 1, double ratioY = 1, bool crop = true, BuildContext? context}) async {

    XFile mediaFile = XFile('');

    try {

      if(imageFile == null) {
        switch (appFileFrom) {
          case AppFileFrom.gallery:
            mediaFile = (await ImagePicker().pickImage(source: ImageSource.gallery)) ?? XFile('');
            break;
          case AppFileFrom.camera:
            AppCameraService appCameraServiceImpl = Get.find<AppCameraService>();
            if(appCameraServiceImpl.isInitialized()) {
              if(context != null) Navigator.pop(context);

              ///THERE IS NO SOLUTION YET TO FRONTAL PHOTO MIRRORED - OCTOBER 2023
              // imageFile.value = await cameraController!.takePicture();
              // bool isFrontal = await isFrontCameraPhoto(File(imageFile.value.path));
              // if(isFrontal) {
              //   mirrorFrontCameraPhoto(File(imageFile.value.path));
              // }
              break;
            } else {
              await appCameraServiceImpl.initializeCameraController();
              if(context != null) Navigator.pop(context);
            }
        }
      } else {
        mediaFile = XFile(imageFile.path);
      }

      if(mediaFile.path.isNotEmpty) {
        XFile compressedFile = await UploadUtilities.compressImageFile(mediaFile);

        if(crop) {
          File croppedImage = await UploadUtilities.cropImage(compressedFile, ratioX: ratioX, ratioY: ratioY);
          if(croppedImage.path.isEmpty) {
            mediaFile = XFile(croppedImage.path);
          } else {
            if(context != null) Navigator.pop(context);
            return null;
          }
        }

      }
    }  catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return mediaFile;
  }

  static Future<XFile?> getVideoFile({AppFileFrom appFileFrom = AppFileFrom.gallery, File? videoFile,
    BuildContext? context, String profileId = ''}) async {
    AppConfig.logger.d("handleVideo");

    XFile? mediaFile;

    try {

      if(profileId.isNotEmpty && await PostFirestore().isVideoLimitReachedForUser(profileId)) {
        AppUtilities.showSnackBar(
            message: AppTranslationConstants.maxVideosPerWeekReachedMsg.tr,
            duration: const Duration(seconds: 5)
        );
        return null;
      } else if(videoFile == null) {
        switch (appFileFrom) {
          case AppFileFrom.gallery:
            mediaFile = (await ImagePicker().pickVideo(source: ImageSource.gallery))  ?? XFile('');
            break;
          case AppFileFrom.camera:
          ///NOT NEEDED YET
          /// file = (await ImagePicker().pickVideo(source: ImageSource.camera))!;
          /// break;
        }
      } else {
        mediaFile = XFile(videoFile.path);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return mediaFile;
  }

  static Future<XFile?> pickMediaFromDevice() async {
    AppConfig.logger.d("pickMediaFromDevice");

    XFile? mediaFile;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        mediaFile = XFile(file.path!);
      }
    }

    return mediaFile;
  }

}
