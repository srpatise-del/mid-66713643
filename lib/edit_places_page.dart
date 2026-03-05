import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

const String baseUrl =
    "http://127.0.0.1/mid-66713643/php_api/";

class EditplacesPage extends StatefulWidget {
  final dynamic places;

  const EditplacesPage({super.key, required this.places});

  @override
  State<EditplacesPage> createState() => _EditplacesPageState();
}

class _EditplacesPageState extends State<EditplacesPage> {

  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController provinceController;
  late TextEditingController descController;

  XFile? selectedImage;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.places['name']);

    addressController =
        TextEditingController(text: widget.places['address']);

    provinceController =
        TextEditingController(text: widget.places['province']);

    descController =
        TextEditingController(text: widget.places['description']);
  }

  ////////////////////////////////////////////////////////////
  // ✅ PICK IMAGE
  ////////////////////////////////////////////////////////////

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = pickedFile;
      });
    }
  }

  ////////////////////////////////////////////////////////////
  // ✅ UPDATE places + IMAGE
  ////////////////////////////////////////////////////////////

  Future<void> updateplaces() async {
    try {

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${baseUrl}update_places_with_image.php"),
      );

      ////////////////////////////////////////////////////////
      // ✅ Fields
      ////////////////////////////////////////////////////////

      request.fields['id'] = widget.places['id'].toString();
      request.fields['name'] = nameController.text;
      request.fields['address'] = addressController.text;
      request.fields['province'] = provinceController.text;
      request.fields['description'] = descController.text;
      request.fields['old_image'] = widget.places['image'];

      ////////////////////////////////////////////////////////
      // ✅ Image (ถ้ามี)
      ////////////////////////////////////////////////////////

      if (selectedImage != null) {

        if (kIsWeb) {

          final bytes = await selectedImage!.readAsBytes();

          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: selectedImage!.name,
            ),
          );

        } else {

          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              selectedImage!.path,
            ),
          );
        }
      }

      ////////////////////////////////////////////////////////
      // ✅ Send
      ////////////////////////////////////////////////////////

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      final data = json.decode(responseData);

      if (data["success"] == true) {

        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("แก้ไขเรียบร้อย")),
        );
      }

    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  ////////////////////////////////////////////////////////////
  // ✅ UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    String imageUrl =
        "${baseUrl}images/${widget.places['image']}";

    return Scaffold(
      appBar: AppBar(title: const Text("แก้ไขสถานที่ท่องเที่ยว")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: SingleChildScrollView(
          child: Column(
            children: [

              //////////////////////////////////////////////////
              // 🖼 IMAGE PREVIEW
              //////////////////////////////////////////////////

              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: selectedImage == null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : kIsWeb
                          ? Image.network(
                              selectedImage!.path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "ชื่อสถานที่ท่องเที่ยว"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "ที่อยู่"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: provinceController,
                decoration: const InputDecoration(labelText: "จังหวัด"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "รายละเอียด"),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: updateplaces,
                  child: const Text("บันทึกสถานที่ท่องเที่ยว"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}