import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/industry.dart';
import '../../models/sub_category.dart';
import '../../services/api_service.dart';
import '../client/home_screen.dart';

class InterestSelectionScreen extends StatefulWidget {
  final bool isEditMode;

  const InterestSelectionScreen({super.key, this.isEditMode = false});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  late Future<List<Industry>> _futureIndustries;
  
  // Stores the selected SubCategory IDs
  final Set<int> _selectedSubCategoryIds = {}; 
  
  // Caches fetched subcategories to avoid repeated API calls: {industryId: List<SubCategory>}
  final Map<int, List<SubCategory>> _cachedSubCategories = {};
  
  // Tracks which industry is currently expanded
  int? _expandedIndustryId;
  bool _isLoadingSubCats = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _futureIndustries = ApiService.fetchIndustries();
  }

  // Fetch subcategories when an industry is tapped
  Future<void> _onIndustryExpanded(int industryId) async {
    setState(() {
      _expandedIndustryId = industryId == _expandedIndustryId ? null : industryId;
    });

    if (_expandedIndustryId != null && !_cachedSubCategories.containsKey(industryId)) {
      setState(() => _isLoadingSubCats = true);
      try {
        final subs = await ApiService.fetchSubCategories(industryId);
        setState(() {
          _cachedSubCategories[industryId] = subs;
        });
      } catch (e) {
        print("Error loading subcategories: $e");
      } finally {
        setState(() => _isLoadingSubCats = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_selectedSubCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one sub-category.")),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    // Save the SUBCATEGORY IDs
    bool success = await ApiService.saveUserInterests(_selectedSubCategoryIds.toList());

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        if (widget.isEditMode) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save. Try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEditMode ? "Edit Preferences" : "Personalize Feed"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Choose your interests",
                  style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Tap a category to see specific roles.",
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Industry>>(
              future: _futureIndustries,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final industries = snapshot.data!;
                
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: industries.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final industry = industries[index];
                    final isExpanded = _expandedIndustryId == industry.id;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: isExpanded ? const Color(0xFF4F46E5) : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isExpanded ? [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.1), blurRadius: 8)] : [],
                      ),
                      child: Column(
                        children: [
                          // Industry Header
                          ListTile(
                            onTap: () => _onIndustryExpanded(industry.id),
                            leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.category, color: const Color(0xFF4F46E5), size: 20),
                            ),
                            title: Text(industry.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                          ),
                          
                          // Subcategories List (Visible only if expanded)
                          if (isExpanded)
                            _isLoadingSubCats 
                              ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: _buildSubCategoryChips(industry.id),
                                ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Save Button Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text("Save & Continue (${_selectedSubCategoryIds.length})", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubCategoryChips(int industryId) {
    final subCats = _cachedSubCategories[industryId] ?? [];
    if (subCats.isEmpty) return const Text("No roles found.");

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subCats.map((sub) {
        final isSelected = _selectedSubCategoryIds.contains(sub.id);
        return FilterChip(
          label: Text(sub.name),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedSubCategoryIds.add(sub.id);
              } else {
                _selectedSubCategoryIds.remove(sub.id);
              }
            });
          },
          selectedColor: const Color(0xFF4F46E5).withOpacity(0.2),
          checkmarkColor: const Color(0xFF4F46E5),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.grey.shade50,
          side: BorderSide.none, // Removes default border
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }
}