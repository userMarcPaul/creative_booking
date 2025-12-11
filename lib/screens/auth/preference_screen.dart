import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../client/home_screen.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  List<String> _categories = [
    "Photography & Video",
    "Gaming / Digital Media",
    "Event Services",
    "Design",
    "Music & Live Performance",
    "Art & Graphics",
    "Crafts & Cultural Arts",
    "Venues & Locations",
  ];

  final Map<String, List<String>> _subCategories = {
    "Photography & Video": ["Photography", "Videography", "Drone", "Editing"],
    "Gaming / Digital Media": ["Esports", "Animation", "Graphic Design"],
    "Event Services": ["Event Planning", "Sound System", "Lights & FX"],
    "Design": ["Web Design", "Interior Design", "UI/UX"],
    "Music & Live Performance": ["Band", "Singer", "DJ"],
    "Art & Graphics": ["Illustration", "Tattoo", "Painting"],
    "Crafts & Cultural Arts": ["Handmade Crafts", "Weaving", "Sculpting"],
    "Venues & Locations": ["Wedding Venue", "Beach Venue", "Garden Venue"],
  };

  List<String> _selectedCategories = [];
  Map<String, List<String>> _selectedSubCats = {};

  double _budgetValue = 5000;
  final TextEditingController _locationController = TextEditingController();
  bool _saving = false;

  Future<void> _savePreferences() async {
    if (_selectedCategories.isEmpty ||
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please complete all fields"),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final success = await ApiService.savePreferences(
      categories: _selectedCategories,
      subCategories: _selectedSubCats,
      budget: _budgetValue.toInt(),
      location: _locationController.text.trim(),
    );

    setState(() => _saving = false);

    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool("hasPreferences", true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to save preferences"),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          "Personalize Experience",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: "Pick your interests",
              child: Column(
                children: _categories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChoiceChip(
                        selected: isSelected,
                        selectedColor: const Color(0xFF4F46E5),
                        label: Text(category),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                              _selectedSubCats[category] ??= [];
                            } else {
                              _selectedCategories.remove(category);
                              _selectedSubCats.remove(category);
                            }
                          });
                        },
                      ),

                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 12, left: 10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _subCategories[category]!.map((sub) {
                              final isSubSelected =
                                  _selectedSubCats[category]!.contains(sub);

                              return ChoiceChip(
                                selected: isSubSelected,
                                selectedColor: Colors.deepPurple,
                                label: Text(sub),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSubSelected
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 13,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    selected
                                        ? _selectedSubCats[category]!.add(sub)
                                        : _selectedSubCats[category]!
                                            .remove(sub);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Budget Range",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₱${_budgetValue.toInt()}",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                  Slider(
                    value: _budgetValue,
                    min: 1000,
                    max: 200000,
                    divisions: 40,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (value) {
                      setState(() => _budgetValue = value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Preferred Location",
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "City / Municipality",
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF4F46E5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saving ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Save & Continue",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
