import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:neom_core/app_config.dart';
import 'package:path_provider/path_provider.dart';

import 'file_system_utilities.dart';

class FileDownloader {

  static Future<File> getPdfFromUrl(String pdfUrl) async {
    AppConfig.logger.d("getPdfFromUrl $pdfUrl");
    File file = File("");
    String filename = "";
    try {
      filename = pdfUrl.substring(pdfUrl.lastIndexOf("/") + 1);
      var request = await HttpClient().getUrl(Uri.parse(pdfUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      var dir = await getApplicationDocumentsDirectory();
      AppConfig.logger.d("File loaded and buffered");
      AppConfig.logger.i("PDF Path: ${dir.path}/$filename");
      file = File("${dir.path}/$filename");
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return localPath;
  }

}
