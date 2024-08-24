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
      body: ListView.builder(itemCount: logs.length, itemBuilder: (context, index){
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
                onPressed: () {
                  writer.writeCsv(content, title);
                },
                child: const Text('CSV'),
              ),
              TextButton(
                onPressed: () {
                   writer.writeTxt(content, title);
                },
                child: const Text('TXT'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
