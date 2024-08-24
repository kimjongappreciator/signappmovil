import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
class logWrite {
  Future<String?> get _localPath async {
    final directory = await getExternalStorageDirectory();
    return directory?.path;  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/my_file.txt');
  }

  Future<File> writeTxt(String content,String title) async {
    String newTitle = title.replaceAll("/", "-");
    final directory = await _localPath;
    final pathOfTheFileToWrite = "$directory/$newTitle.txt";
    File file = File(pathOfTheFileToWrite);
    // Write the file
    return file.writeAsString(content);
  }

  Future<void> writeCsv(String content, String title) async{
    String newTitle = title.replaceAll("/", "-");
    final directory = await _localPath;
    final pathOfTheFileToWrite = "$directory/$newTitle.csv";
    List<String> arr = content.split(' ');
    print(pathOfTheFileToWrite);
    List<List<String>> data = [arr];
    String csv = const ListToCsvConverter().convert(data);
    File file = File(pathOfTheFileToWrite);
    file.writeAsString(csv);
  }
}