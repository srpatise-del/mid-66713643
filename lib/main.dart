import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'add_places_page.dart';
import 'edit_places_page.dart';

void main() => runApp(const MyApp());

//////////////////////////////////////////////////////////////
// ✅ CONFIG
//////////////////////////////////////////////////////////////

const String baseUrl =
    "http://127.0.0.1/mid-66713643/php_api/";

//////////////////////////////////////////////////////////////
// ✅ APP ROOT
//////////////////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: placesList(),
      debugShowCheckedModeBanner: false,
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ places LIST PAGE
//////////////////////////////////////////////////////////////

class placesList extends StatefulWidget {
  const placesList({super.key});

  @override
  State<placesList> createState() => _placesListState();
}

class _placesListState extends State<placesList> {
  List places = [];
  List filteredplaces = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchplaces();
  }

  ////////////////////////////////////////////////////////////
  // ✅ FETCH DATA
  ////////////////////////////////////////////////////////////

  Future<void> fetchplaces() async {
    try {
      final response =
          await http.get(Uri.parse("${baseUrl}show_data.php"));

      if (response.statusCode == 200) {
        setState(() {
          places = json.decode(response.body);
          filteredplaces = places;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  ////////////////////////////////////////////////////////////
  // ✅ SEARCH
  ////////////////////////////////////////////////////////////

  void filterplaces(String query) {
    setState(() {
      filteredplaces = places.where((places) {
        final name = places['name']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  ////////////////////////////////////////////////////////////
  // ✅ DELETE
  ////////////////////////////////////////////////////////////

  Future<void> deleteplaces(int id) async {
    try {
      final response = await http.get(
        Uri.parse("${baseUrl}delete_places.php?id=$id"),
      );

      final data = json.decode(response.body);

      if (data["success"] == true) {
        fetchplaces();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ลบเรียบร้อย")),
        );
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  ////////////////////////////////////////////////////////////
  // ✅ CONFIRM DELETE
  ////////////////////////////////////////////////////////////

  void confirmDelete(dynamic places) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("ต้องการลบ ${places['name']} ?"),
        actions: [
          TextButton(
            child: const Text("ยกเลิก"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("ลบ"),
            onPressed: () {
              Navigator.pop(context);
              deleteplaces(int.parse(places['id'].toString()));
            },
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  // ✅ OPEN EDIT PAGE
  ////////////////////////////////////////////////////////////

  void openEdit(dynamic places) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditplacesPage(places: places),
      ),
    ).then((value) => fetchplaces());
  }

  ////////////////////////////////////////////////////////////
  // ✅ UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Places List')),

      body: Column(
        children: [
          //////////////////////////////////////////////////////
          // 🔍 SEARCH
          //////////////////////////////////////////////////////

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search Places',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: filterplaces,
            ),
          ),

          //////////////////////////////////////////////////////
          // 📦 LIST
          //////////////////////////////////////////////////////

          Expanded(
            child: filteredplaces.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                   padding: const EdgeInsets.only(bottom: 80), // ✅ สำคัญมาก
                    itemCount: filteredplaces.length,
                    itemBuilder: (context, index) {
                      final places = filteredplaces[index];

                      String imageUrl =
                          "${baseUrl}images/${places['image']}";

                      return Card(
                        child: ListTile(

                          //////////////////////////////////////////////////
                          // 🖼 IMAGE
                          //////////////////////////////////////////////////

                          leading: SizedBox(
                            width: 70,
                            height: 70,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ),

                          //////////////////////////////////////////////////
                          // 🏷 NAME
                          //////////////////////////////////////////////////

                          title: Text(places['name'] ?? 'No Name'),

                          //////////////////////////////////////////////////
                          // 📝 DESC
                          //////////////////////////////////////////////////

                          subtitle:
                              Text(places['province'] ?? ''),

                          //////////////////////////////////////////////////
                          // 💰 PRICE
                          //////////////////////////////////////////////////

                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                openEdit(places);
                              } else if (value == 'delete') {
                                confirmDelete(places);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('แก้ไข'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('ลบ'),
                              ),
                            ],
                          ),

                          //////////////////////////////////////////////////
                          // 👉 DETAIL
                          //////////////////////////////////////////////////

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    placesDetail(places: places),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      ////////////////////////////////////////////////////////
      // ➕ ADD BUTTON
      ////////////////////////////////////////////////////////

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddplacesPage(),
            ),
          ).then((value) => fetchplaces());
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// ✅ places DETAIL PAGE
//////////////////////////////////////////////////////////////

class placesDetail extends StatelessWidget {
  final dynamic places;

  const placesDetail({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    String imageUrl =
        "${baseUrl}images/${places['image']}";

    return Scaffold(
      appBar: AppBar(
        title: Text(places['name'] ?? 'Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //////////////////////////////////////////////////////
            // 🖼 IMAGE
            //////////////////////////////////////////////////////

            Center(
              child: Image.network(
                imageUrl,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 100),
              ),
            ),

            const SizedBox(height: 20),

            //////////////////////////////////////////////////////
            // 🏷 NAME
            //////////////////////////////////////////////////////

            Text(
              places['name'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            //////////////////////////////////////////////////////
            // 📝 ADDRESS
            //////////////////////////////////////////////////////

            Text(places['province'] ?? ''),

            const SizedBox(height: 10),

            //////////////////////////////////////////////////////
            // 💰 PRICE
            //////////////////////////////////////////////////////

            Text(
              'address: ${places['address']}',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}