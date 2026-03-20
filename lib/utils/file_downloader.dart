import 'package:http/http.dart' as http;
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:path_provider/path_provider.dart';

import 'file_system_utilities.dart';

class FileDownloader {

  static Future<File> getPdfFromUrl(String pdfUrl) async {
    AppConfig.logger.d("getPdfFromUrl $pdfUrl");
    File file = File("");
    String filename = "";
    try {
      filename = pdfUrl.substring(pdfUrl.lastIndexOf("/") + 1);
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        var dir = await getApplicationDocumentsDirectory();
        AppConfig.logger.d("File loaded and buffered");
        AppConfig.logger.i("PDF Path: ${dir.path}/$filename");
        file = File("${dir.path}/$filename");
        await file.writeAsBytes(response.bodyBytes, flush: true);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'getPdfFromUrl');
      throw Exception('Error parsing asset file!');
    }

    return file;
  }

  static Future<String> downloadImage(String imgUrl, {String imgName = ''}) async {
    AppConfig.logger.d("Entering downloadImage method");
    String localPath = "";
    String name = imgName.isNotEmpty ? imgName : imgUrl;
    try {

      final response = await http.get(Uri.parse(imgUrl));
      if (response.statusCode == 200) {
        name = name.replaceAll(".", "").replaceAll(":", "").replaceAll("/", "");
        // Get the document directory path
        localPath = await FileSystemUtilities.getLocalPath();
        localPath = "$localPath/$name.jpeg";
        File jpegFileRef = File(localPath);
        await jpegFileRef.writeAsBytes(response.bodyBytes);
        AppConfig.logger.i("Image downloaded to path $localPath successfully.");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'downloadImage');
    }
    return localPath;
  }

}
