import 'package:flutter/material.dart';
import 'package:signappflutter/api/logApi.dart';
import 'package:signappflutter/api/logWrite.dart';

import '../model/logModel.dart';

class LogsView extends StatefulWidget {
  const LogsView({Key? key}) : super(key: key);

  @override
  _LogsViewState createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {

  List<logmodel> logs = [];
  logWrite writer = logWrite();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traducciones', style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white54,
      ),
      body: logs.isEmpty
          ? const Center(child: Text('No se encontraron registros'))
          :ListView.builder(itemCount: logs.length, itemBuilder: (context, index){
          return ListTile(title: Text("Traduccion del ${logs[index].date}"),
          subtitle: Text("${logs[index].log}"),
          trailing: IconButton(onPressed: () {
            showMessage(logs[index].date.toString(),logs[index].log.toString());
            //writer.writeCsv(logs[index].log.toString(), logs[index].date.toString());
          }, icon: const Icon(Icons.download),),);
        },),
    );
  }
  @override
  void initState(){
    super.initState();
    getLogs();
  }
  Future<void> getLogs() async{
    final response = await logApi.fetchLogs();
    //print(response);
    setState(() {
      logs = response;
    });
  }

  void showMessage(String title, String content){
    String titulo = 'Guardar';
    String cuerpo = 'Seleccione el tipo de archivo';

    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(titulo),
        content: Text(cuerpo),
        actions: <Widget>[
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  dynamic res = 0;
                  print('Downloads $title');
                  res = await saveFile(content, title, 0);
                  if(res == 1){
                    showPath(1);
                  }
                  else{
                  showPath(0);
                  }

                  //writer.writeCsv(content, title);
                  //print('Downloads $title');
                  //Navigator.pop(context);
                },
                child: const Text('CSV'),
              ),
              TextButton(
                onPressed: () async {
                  dynamic res = 0;
                  print('Downloads $title');
                  res = await saveFile(content, title, 1);
                  if(res == 1){
                    showPath(1);
                  }
                  else{
                    showPath(0);
                  }
                   //writer.writeTxt(content, title);
                   //print('Downloads $title');
                   //Navigator.pop(context);
                },
                child: const Text('TXT'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  void showPath(int status){
    String titulo = '';
    String cuerpo = '';
    if(status == 1){
      titulo = 'Exito';
      cuerpo = 'Archivo guardado con exito en Downloads';
    }
    else{
      titulo = 'Error';
      cuerpo = 'Error al intentar guardar archivo';
    }
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(titulo),
        content: Text(cuerpo),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'OK');
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  Future<int> saveFile(String content, String title, int type)async {
    try{
      if(type == 0){
          await writer.writeCsv(content, title);
          return 1;
      }
      else{
          await writer.writeTxt(content, title);
          return 1;
      }
    }
    catch(e){
      return 0;
    }
  }

}
