import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/industry.dart';
import '../../models/sub_category.dart';
import '../../services/api_service.dart';
import 'creative_list_screen.dart'; // Navigate to the list of people

class SubCategoryScreen extends StatefulWidget {
  final Industry industry;

  const SubCategoryScreen({super.key, required this.industry});

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  late Future<List<SubCategory>> futureSubCategories;

  @override
  void initState() {
    super.initState();
    futureSubCategories = ApiService.fetchSubCategories(widget.industry.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: Text(
          widget.industry.name,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.indigo[900],
      ),
      body: FutureBuilder<List<SubCategory>>(
        future: futureSubCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No roles found for this industry."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final subCategory = snapshot.data![index];
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.indigo.withOpacity(0.1)),
                ),
                child: ListTile(
                  title: Text(
                    subCategory.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, 
                    size: 16, 
                    color: Colors.indigo[300]
                  ),
                  onTap: () {
                    // Navigate to Creative List Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreativeListScreen(subCategory: subCategory),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}