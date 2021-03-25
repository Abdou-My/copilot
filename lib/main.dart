import 'dart:async';
//import 'dart:html';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  runApp(CameraApp());
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;
  bool isWorking = false;
  String result = "";
  CameraImage imgCamera;

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/mobilenet_v1_1.0_224.tflite",
      labels: "assets/mobilenet_v1_1.0_224.txt",
    );
  }

  @override
  void initState() {
    loadModel();
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        controller.startImageStream((imageFrontStream) =>
        {
          if(!isWorking){
            isWorking = true,
            imgCamera = imageFrontStream,
            runModelOnSTreamFrames(),
          }
        });
      });
    });
  }


  runModelOnSTreamFrames() async {
    if (imgCamera != null) {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: imgCamera.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: imgCamera.height,
        imageWidth: imgCamera.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      result = "";
      recognitions.forEach((response) {
        result += response["label"] + " " +
            (response["confidence"] as double).toStringAsFixed(2) + "\n\n";
      });
      setState(() {
        return;
      });
      isWorking = false;
    }
  }

  @override
  void dispose() async {
    controller?.dispose();
    super.dispose();
    await Tflite.close();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
        title: "ops cam",
        home: Scaffold(
            appBar: AppBar(
              title: Text("ops camera"),
            ),
            body: Material(
              child: CameraPreview(
                controller,
                child: new Align(
                  alignment: Alignment.bottomCenter,
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Text(
                        result,
                        style: TextStyle(fontSize: 30,
                            color: Colors.white,
                            backgroundColor: Colors.black),
                      )
                    ],
                  ),
                ),
              ),
            )
        )
    );
  }
}

