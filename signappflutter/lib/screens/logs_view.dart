import 'package:flutter/material.dart';
import 'package:signappflutter/api/logApi.dart';

import '../model/logModel.dart';

class LogsView extends StatefulWidget {
  const LogsView({Key? key}) : super(key: key);

  @override
  _LogsViewState createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {

  List<logmodel> logs = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traducciones', style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white54,
      ),
      body: ListView.builder(itemCount: logs.length, itemBuilder: (context, index){
        return ListTile(title: Text("Traduccion del ${logs[index].date}"),
        subtitle: Text("${logs[index].log}"));
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
    print(response);
    setState(() {
      logs = response;
    });
  }
}
