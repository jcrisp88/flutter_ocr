import 'dart:convert';
import 'dart:io' as io;

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
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
          setState(() {});
        }
      }
    }
  }

  Future<List<String>> _readNamesFile(String fileName) async {
    fileText = await rootBundle.loadString('assets/files/$fileName.txt');
    return LineSplitter().convert(fileText);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
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
                SizedBox(height: 10),
                _buildTypeText(),
                _buildProductText(),
                _buildWeightText(),
                _buildCompanyText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Text _buildBbeText() {
  //   return Text(
  //     'BBE:',
  //     style: TextStyle(fontSize: 20),
  //   );
  // }

  Text _buildTypeText() {
    String visionString;
    String type = '';
    final regex = RegExp(r'(malt|yeast|hops)', caseSensitive: false);
    if (visionText != null) {
      visionString = visionText.text.replaceAll(RegExp(r"\s+\b|\b\s"), '');
      final regexMatches = regex.allMatches(visionString);
      for (var element in regexMatches) {
        type = visionString.substring(element.start, element.end).toLowerCase();
      }
    }

    return Text(
      'Type: $type',
      style: TextStyle(fontSize: 20),
    );
  }

  Widget _buildCompanyText() {
    var companyName = '';
    return FutureBuilder<List<String>>(
      future: _readNamesFile('company_names'),
      builder: (context, fileTextSnapshot) {
        if (fileTextSnapshot.hasData) {
          for (var word in fileTextSnapshot.data) {
            print('word => $word');
            final regex = RegExp(word, caseSensitive: false);
            if (visionText != null) {
              var regexMatches = regex.allMatches(visionText.text);
              for (var element in regexMatches) {
                companyName =
                    visionText.text.substring(element.start, element.end);
              }
            }
          }
          return Text(
            'Company: ${companyName.toLowerCase()}',
            style: TextStyle(fontSize: 20),
          );
        }
        return Text('Company:', style: TextStyle(fontSize: 20));
      },
    );
  }

  Widget _buildProductText() {
    var productName = ' ';

    return FutureBuilder<List<String>>(
      future: _readNamesFile('product_names'),
      builder: (context, fileTextSnapshot) {
        if (fileTextSnapshot.hasData) {
          for (var word in fileTextSnapshot.data) {
            final regex = RegExp(word, caseSensitive: false);
            if (visionText != null) {
              var iter = regex.allMatches(visionText.text);
              for (var element in iter) {
                productName =
                    visionText.text.substring(element.start, element.end);
              }
            }
          }

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
    final regex = RegExp(r'([0-9]+[.,]*)+(?:g|kg|lb|oz)', caseSensitive: false);
    if (visionText != null) {
      visionString = visionText.text.replaceAll(RegExp(r"\s+\b|\b\s"), '');
      final regexMatches = regex.allMatches(visionString);
      for (var element in regexMatches) {
        weight =
            visionString.substring(element.start, element.end).toLowerCase();
      }
    }
    if (weight != null) {
      return Text(
        'Weight: $weight',
        style: TextStyle(fontSize: 20),
      );
    }
    return Text(
      'Weight: ',
      style: TextStyle(fontSize: 20),
    );
  }
}
