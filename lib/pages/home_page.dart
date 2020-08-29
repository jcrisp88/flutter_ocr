import 'dart:io';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_ocr/utils/constants.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File _pickedImage;
  final _picker = ImagePicker();
  bool _isImageLoaded = false;
  List<String> text = [];
  VisionText visionText;

  Future _pickImage() async {
    text.clear();
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _pickedImage = File(pickedFile.path);
      File cropped = await ImageCropper.cropImage(
        sourcePath: _pickedImage.path,
      );
      setState(() {
        _pickedImage = cropped;
        _isImageLoaded = true;
      });
    }
  }

  Future<void> _readImageText() async {
    final imageText = FirebaseVisionImage.fromFile(_pickedImage);
    final textScan = FirebaseVision.instance.textRecognizer();
    visionText = await textScan.processImage(imageText);
    print('VisionText => ${visionText.text}');

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          text.add(word.text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _isImageLoaded
                ? Center(
                    child: Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(_pickedImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                : Container(),
            Text(
              text.toString(),
              style: TextStyle(fontSize: 26),
            ),
            RaisedButton(
              child: Text('Pick an image'),
              onPressed: _pickImage,
            ),
            SizedBox(height: 10),
            RaisedButton(
              child: Text('Read Image Text'),
              onPressed: _readImageText,
            ),
            SizedBox(height: 10),
            Text('Type: ${text.where((element) => element.contains('wheat'))}',
                style: TextStyle(fontSize: 20)),
            _buildCompanyText(),
            Text(
              'BB:${text.where((element) => Constants.bbe.indexOf(element) >= 0)}',
              style: TextStyle(fontSize: 26),
            ),
            _buildWeightText(),
          ],
        ),
      ),
    );
  }

  Text _buildCompanyText() {
    var str = text.where(
        (element) => Constants.types.indexOf(element.toLowerCase()) >= 0);
    return Text(
      'Company: ${str.toString().toLowerCase().replaceAll('(', '')}',
      style: TextStyle(fontSize: 20),
    );
  }

  Text _buildWeightText() {
    var str = Iterable.empty();
    if (visionText != null) {
      str = visionText.text;
    }

    return Text(
      'Weight: ${str}',
      style: TextStyle(fontSize: 20),
    );
  }
}
