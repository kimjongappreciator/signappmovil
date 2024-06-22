import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:screenshot/screenshot.dart';
import 'package:signappflutter/api/logApi.dart';
import 'package:signappflutter/model/logModel.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

late List<CameraDescription> _cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: miCamara()
    );
  }
}

class miCamara extends StatefulWidget {
  const miCamara({super.key});

  @override
  State<miCamara> createState() => _miCamaraState();
}

class _miCamaraState extends State<miCamara> {
  late CameraController controller;
  List<CameraDescription>? cameras;

  final ScreenshotController screenshotController = ScreenshotController();

  final IO.Socket socket = IO.io('http://192.168.1.38:5000', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  bool status = false;
  Timer? _timer;
  String palabra = ' ';

  @override
  void initState() {
    super.initState();
    socket.connect();
    controller = CameraController(_cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
          // Handle access errors here.
            break;
          default:
          // Handle other errors here.
            break;
        }
      }
    });
    socket.on('prediction', (data) {
      print('Recibida predicción: ${data['prediction']}');
      setState(() {
        palabra = data['prediction'];
      });
    });
  }

  @override
  void dispose(){
    super.dispose();
    socket.disconnect();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traducir', style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white54,
      ),
      body: Center(
        child: Stack(
          children: [
            Screenshot(controller: screenshotController, child: CameraPreview(controller!)),
            Positioned(left: 100, bottom: 0, child: Text(palabra, style: const TextStyle(fontSize: 50, color: Colors.white)))

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(child: const Icon(Icons.camera),
        onPressed: (){
          if(_timer == null || !_timer!.isActive){
            _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
              startCapture();
            });
          }else{
            print('cancel');
            _timer?.cancel();
            _timer = null;
            setState(() {
              palabra = ' ';
            });
          }

          //initTranslation();

        }),
    );
  }

  void startCapture(){
    //if (status == true){
      initTranslation();
    //}
  }

  void initTranslation(){
    screenshotController
        .capture(delay: Duration(milliseconds: 5), pixelRatio: 0.5)
        .then((capturedImage) async {
      convert(capturedImage);
      //ShowCapturedWidget(context, capturedImage!);
    }).catchError((onError) {
      print(onError);
    });
  }

  void convert(/*CameraImage image*/ dynamic bytes) async{
     //print('size ${bytes.length}');
     String base64img = base64Encode(bytes);

     Map<String, dynamic> json = {
       'frames': base64img,
     };
     String jsonString = jsonEncode(json);
     //print("emit");
     socket.emit('message', {'frames': base64img});

     /*await http.post(
       Uri.parse('http://192.168.1.38:5000/test'),
         headers: {'Content-Type': 'application/json'},
         body: jsonString
     );*/

  }


  Future<dynamic> ShowCapturedWidget(
      BuildContext context, Uint8List capturedImage) {
    return showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text("Captured widget screenshot"),
        ),
        body: Center(child: Image.memory(capturedImage)),
      ),
    );
  }

  void showMessage(status){
    String titulo = '';
    String cuerpo = '';
    if(status == 200){
      titulo = 'Exito';
      cuerpo = 'Log guardado con exito';
    }
    else{
      titulo = 'Error';
      cuerpo = 'Error al intentar guardar';
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
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  Future<void> postLog(String log) async{
    DateTime now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);
    String str = date.toString();
    logmodel body = logmodel(log: log, date: str );
    var json = body.toJson();
    var res = await logApi.postLog(body);
    var decoded = jsonDecode(res);
    showMessage(res);
  }

}


