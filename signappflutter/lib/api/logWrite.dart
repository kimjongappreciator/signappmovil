import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';

class logWrite {


  Future<String?> get _localPath async {
    final directory = await getExternalStorageDirectory();
    return directory?.path;  }
  Future<PermissionStatus> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/my_file.txt');
  }

  Future<File?> writeTxt(String content, String title, String version) async {
    PermissionStatus status = PermissionStatus.granted;
    // Solicitar permiso
    if(version != '12'){
      status = PermissionStatus.granted;
    }
    else{
      status = await requestStoragePermission();
    }

    if (status.isGranted) {
      String newTitle = title.replaceAll("/", "-");
      newTitle = newTitle.substring(0, 10);
      final pathOfTheFileToWrite = "/storage/emulated/0/Download/$newTitle.txt";

      try {
        File file = File(pathOfTheFileToWrite);
        return await file.writeAsString(content);
      } catch (e) {
        print('Error al escribir el archivo: $e');
        return null;
      }
    } else {
      // El permiso fue denegado
      print('Permiso denegado. No se puede escribir el archivo.');
      return null;
    }
  }

  Future<File?> writeCsv(String content, String title, String version) async{
    PermissionStatus status = PermissionStatus.granted;
    // Solicitar permiso
    if(version != '12'){
      status = PermissionStatus.granted;
    }
    else{
      status = await requestStoragePermission();
    }
    if(status.isGranted){
      String newTitle = title.replaceAll("/", "-");
      newTitle = newTitle.substring(0,10);
      //final directory = await _localPath;
      final pathOfTheFileToWrite = "/storage/emulated/0/Download/$newTitle.csv";
      List<String> arr = content.split(' ');
      List<List<String>> data = [arr];
      String csv = const ListToCsvConverter().convert(data);
      try{
        File file = File(pathOfTheFileToWrite);
        return await file.writeAsString(csv);
      }catch (e) {
        print('Error al escribir el archivo: $e');
        return null;
      }
      }else{
        print('Permiso denegado. No se puede escribir el archivo.');
        return null;
      }
  }
}