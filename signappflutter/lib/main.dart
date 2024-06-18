import 'package:camera/camera.dart';
import 'package:convert_native_img_stream/convert_native_img_stream.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';



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
  final convertNative = ConvertNativeImgStream();
  final ScreenshotController screenshotController = ScreenshotController();
  @override
  void initState() {
    int counter = 0;
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.low);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      /*controller.startImageStream((image) {
        if (counter % 2 == 0){
          convert(image);
        }
        counter++;
        //print(image.format.group.name);
      });*/
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
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traducir'),
      ),
      body: Center(
        child: Screenshot(controller: screenshotController, child: CameraPreview(controller!)),
      ),
      floatingActionButton: FloatingActionButton(child: Icon(Icons.camera),
        onPressed: (){
          screenshotController
              .capture(delay: Duration(milliseconds: 10))
              .then((capturedImage) async {
                convert(capturedImage);
            //ShowCapturedWidget(context, capturedImage!);
          }).catchError((onError) {
            print(onError);
          });

        }),
    );
  }

  void convert(/*CameraImage image*/ dynamic bytes) async{
    //int xd = 1;
     //dynamic bytes = await convertCameraImageToBytes(image);

     //dynamic bytes = await convertTojpeg(image);
     print('size ${bytes.length}');
     String base64img = base64Encode(bytes);

     Map<String, dynamic> json = {
       'image': base64img,
     };
     String jsonString = jsonEncode(json);
     //if (xd == 1){
     await http.post(
       Uri.parse('http://192.168.1.38:5000/test'),
         headers: {'Content-Type': 'application/json'},
         body: jsonString
     );
     //xd =2;
     //}
     //print(base64img);
  }
  Future<Uint8List?> convertTojpeg(CameraImage _image) async{
    final jpegByte = await convertNative.convertImgToBytes(_image.planes.first.bytes, _image.width, _image.height);
    return jpegByte;
  }

  Future<dynamic> convertCameraImageToBytes(CameraImage image) async {
    try {
      // Para este ejemplo, se asume que la imagen es en formato YUV420
      if (image.format.group != ImageFormatGroup.yuv420) {
        throw UnsupportedError('Solo se admite el formato YUV420');
      }
      //dynamic bytes = convertYUV420toRGBArray(image);
      //print(bytes);

      // Extraer los planos de la imagen
      final Plane plane = image.planes[0];
      final int width = image.width;
      final int height = image.height;

      // Crear un buffer para los datos de bytes
      final int size = width * height;
      Uint8List bytes = Uint8List(size);

      // Copiar los datos del plano a los bytes
      int offset = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int index = y * plane.bytesPerRow + x;
          bytes[offset++] = plane.bytes[index];
        }
      }

      // Opcional: Guarda la imagen en el dispositivo para verificar
      /*final directory = await getExternalStorageDirectory();
      final path = '${directory?.path}/image.jpg';
      File(path).writeAsBytesSync(bytes);
      print('Image saved to $path');*/

      return bytes;
    } catch (e) {
      print('Error al convertir CameraImage a bytes: $e');
      rethrow;
    }

  }


  List<List<List<int>>>?convertYUV420toRGBArray(CameraImage image){
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;

      List<List<List<int>>> rgbList = [];

      for (int y = 0; y < height; y++) {
        List<List<int>> row = [];
        for (int x = 0; x < width; x++) {
          final int uvIndex = (uvPixelStride! * (x / 2).floor()) + (uvRowStride * (y / 2).floor());
          final int index = y * width + x;

          final int yp = image.planes[0].bytes[index];
          final int up = image.planes[1].bytes[uvIndex];
          final int vp = image.planes[2].bytes[uvIndex];

          int r = (yp + (vp * 1436 / 1024 - 179)).round().clamp(0, 255);
          int g = (yp - (up * 46549 / 131072) + 44 - (vp * 93604 / 131072) + 91).round().clamp(0, 255);
          int b = (yp + (up * 1814 / 1024 - 227)).round().clamp(0, 255);

          row.add([r, g, b]);
        }
        rgbList.add(row);
      }
      return rgbList;
    } catch (e) {
      print("Error>>> $e");
      return null;
    }
  }

  Future<dynamic> ShowCapturedWidget(
      BuildContext context, Uint8List capturedImage) {
    return showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text("Captured widget screenshot"),
        ),
        body: Center(child: Image.memory(capturedImage)),
      ),
    );
  }

}


