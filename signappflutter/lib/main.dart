import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:screenshot/screenshot.dart';
import 'package:signappflutter/api/logApi.dart';
import 'package:signappflutter/model/logModel.dart';
import 'package:signappflutter/screens/logs_view.dart';
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
    return MaterialApp(
      //home: miHome(idx: 0)
      home: const SplashScreen(),
      routes: {'/front': (context) => const miHome(idx: 0),
        '/back': (context) => const miHome(idx: 1)
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class miHome extends StatefulWidget {
  final int idx;
  const miHome({super.key, required this.idx});

  @override
  State<miHome> createState() => _miHomeState();
}

class _miHomeState extends State<miHome> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index){
          setState(() {
            //print(index);
            currentPageIndex = index;
          });
        },selectedIndex: currentPageIndex ,
          destinations: const<Widget>[
          NavigationDestination(icon: Icon(Icons.home), label: 'Captura'),
          NavigationDestination(icon: Icon(Icons.add_chart), label: 'logs')
      ],
      ),body:<Widget>[
        miCamara(cameraIndex: widget.idx),
        const LogsView()
    ][currentPageIndex],
    );
  }
}


class miCamara extends StatefulWidget {
  final int cameraIndex;
  const miCamara({super.key, required this.cameraIndex});
  @override
  State<miCamara> createState() => _miCamaraState();
}

class _miCamaraState extends State<miCamara> {
  late CameraController controller;
  List<CameraDescription>? cameras;

  final ScreenshotController screenshotController = ScreenshotController();

  final IO.Socket socket = IO.io('http://181.67.75.85:5000', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });
  Timer? _timer;
  String palabra = ' ';
  String oracion = '';

  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[widget.cameraIndex], ResolutionPreset.medium);
    //print('aqui: ${_cameras.toString()}');
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
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
    socket.connect();
    socket.on('prediction', (data) {
      //print('Recibida predicción: ${data['prediction']}');
      setState(() {
        palabra = data['prediction'];
        oracion = '$oracion $palabra';
      });
    });
  }

  @override
  void dispose(){
    super.dispose();
    socket.disconnect();
    socket.dispose();
    controller.dispose();
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
            const Positioned(left: 50, top: 300, child: Text('Para comenzar a capturar presiona el boton azul')),
            Screenshot(controller: screenshotController, child: CameraPreview(controller!)),
            Positioned(left: 100, bottom: 0, child: Text(palabra, style: const TextStyle(fontSize: 50, color: Colors.white))),
            Positioned(
              bottom: 15,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'post',
                onPressed: (){
                postLog(oracion);
              },
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.save),
              ),
            )

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          heroTag: 'camera',
          child: const Icon(Icons.camera_alt),
        onPressed: (){
          if(_timer == null || !_timer!.isActive){
            _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
              startCapture();
            });
          }else{
            //print('cancel');
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
      initTranslation();
  }

  void initTranslation(){
    screenshotController
        .capture(delay: const Duration(milliseconds: 5), pixelRatio: 0.5)
        .then((capturedImage) async {
      convert(capturedImage);
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
     //String jsonString = jsonEncode(json);
     //print("emit");
     socket.emit('message', {'frames': base64img});

     /*await http.post(
       Uri.parse('http://192.168.1.38:5000/test'),
         headers: {'Content-Type': 'application/json'},
         body: jsonString
     );*/

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
    //var json = body.toJson();
    var res = await logApi.postLog(body);
    showMessage(res);
  }

}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
    Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          const Text(
            'Bienvenido a SignApp',
                  style: TextStyle(
                  color: Colors.black54,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  ),
          ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
              //print('boton 1');
              Navigator.pushNamed(context, '/front');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black45,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
            child: const Text('Cam Principal  '),
                                ),
            const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/back');
          },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black45,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
            child: const Text('Cam Secundaria'),
          ),
          ],
          ),
        ),
        ],
        ),
    );
  }
}



