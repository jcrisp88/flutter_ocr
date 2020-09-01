import 'dart:convert';
import 'dart:io' as io;
import 'package:supercharged/supercharged.dart';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_ocr/utils/constants.dart';
import 'package:flutter/services.dart' show rootBundle;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  io.File _pickedImage;
  final _picker = ImagePicker();
  bool _isImageLoaded = false;
  List<String> imageText = [];
  VisionText visionText;
  String fileText;

  Future _pickImage() async {
    imageText.clear();
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _pickedImage = io.File(pickedFile.path);
      io.File cropped = await ImageCropper.cropImage(
        sourcePath: _pickedImage.path,
      );
      setState(() {
        _pickedImage = cropped;
        _isImageLoaded = true;
      });
    }
  }

  Future<void> _readImageText() async {
    final imageTextLocal = FirebaseVisionImage.fromFile(_pickedImage);
    final textScan = FirebaseVision.instance.textRecognizer();
    visionText = await textScan.processImage(imageTextLocal);

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          imageText.add(word.text);
        }
      }
    }
  }

  Future<List<String>> _readNamesFile() async {
    fileText = await rootBundle.loadString('assets/files/names.txt');
    return LineSplitter().convert(fileText);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                imageText.toString(),
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
              RaisedButton(
                child: Text('Read From file'),
                onPressed: _readNamesFile,
              ),
              SizedBox(height: 10),
              _buildTypeText(),
              _buildProductText(),
              Text(
                'BB:${imageText.where((element) => Constants.bbe.indexOf(element) >= 0)}',
                style: TextStyle(fontSize: 26),
              ),
              _buildWeightText(),
            ],
          ),
        ),
      ),
    );
  }

  Text _buildTypeText() {
    List<String> typeText = imageText
        .where((element) => Constants.types.indexOf(element.toLowerCase()) >= 0)
        .toList();
    return Text(
      'Type: ${typeText.elementAtOrElse(0, () => '').toLowerCase()}',
      style: TextStyle(fontSize: 20),
    );
  }

  Widget _buildProductText() {
    String productName = '';

    return FutureBuilder<List<String>>(
      future: _readNamesFile(),
      builder: (context, fileTextSnapshot) {
        if (fileTextSnapshot.hasData) {
          for (var word in fileTextSnapshot.data) {
            final regex = RegExp(word, caseSensitive: false);
            var iter = regex.allMatches(visionText?.text);
            for (var element in iter) {
              productName =
                  visionText.text.substring(element.start, element.end);
            }
          }
          // final loweredCaseFileList =
          //     fileTextSnapshot.data.map((e) => e.toLowerCase()).toList();
          // final matchedList = imageText
          //     .where((element) =>
          //         loweredCaseFileList.indexOf(element.toLowerCase()) >= 0)
          // .toList();
          return Text(
            'Product Name: ${productName.toLowerCase()}',
            style: TextStyle(fontSize: 20),
          );
        }
        return Text('Product:');
      },
    );
  }

  Text _buildWeightText() {
    String visionString;
    String weight;
    final regex = RegExp(r'\d.+?(?:g|kg)');
    if (visionText != null) {
      visionString = visionText.text;
      final iter = regex.allMatches(visionString);
      for (var element in iter) {
        weight = visionString.substring(element.start, element.end);
      }
    }

    return Text(
      'Weight: $weight',
      style: TextStyle(fontSize: 20),
    );
  }
}
