import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget{
  final ImageSource? initialImageSource;
  const CameraPage({super.key, this.initialImageSource});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>{
  File? image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialImageSource != null) {
      pickImage(widget.initialImageSource!);
    }
  }

  Future pickImage(ImageSource source) async{
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null){
      setState(() {
        image = File(pickedImage.path);
      });
    }
  }

  @override
Widget build (BuildContext context){
  return Scaffold(
    appBar: AppBar(
      title: const Text('Camera'),
      centerTitle: true,
    ),
    body:  Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Camera Page'),
      SizedBox(
        height: 200,
        width: 200,
        child: image != null ?
             Image.file(image!)
            :
           const Center (child: Text("no image selected "))
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: (){
              pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          ElevatedButton(
            onPressed: (){
              pickImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
        ],
      ),
    ),
  );
}
}