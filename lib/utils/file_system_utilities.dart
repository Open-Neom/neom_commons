import 'dart:io';
import 'package:neom_core/app_config.dart';
import 'package:path_provider/path_provider.dart';

class FileSystemUtilities {

  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getFileFromPath(String filePath) async {
    AppConfig.logger.d("Getting File From Path: $filePath");
    File file = File("");

    try {
      AppConfig.logger.i("File Path: $filePath");

      if(Platform.isAndroid) {
        file = File(filePath);
      } else {
        file = await File.fromUri(Uri.parse(filePath)).create();
      }
    } catch (e) {
      AppConfig.logger.e('Error getting File');
    }

    return file;
  }

}
