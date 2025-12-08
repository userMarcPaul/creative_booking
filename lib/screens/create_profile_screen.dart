import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/sub_category.dart';
import '../models/industry.dart';
import 'provider_dashboard_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _bioController = TextEditingController();
  final _rateController = TextEditingController();
  final _portfolioController = TextEditingController();
  
  // Data for Dropdowns
  List<Industry> _industries = [];
  List<SubCategory> _roles = [];
  
  // Selections
  int? _selectedIndustryId;
  int? _selectedRoleId;
  
  bool _isLoading = false;
  bool _isRolesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIndustries();
  }

  // 1. Fetch Industries first
  Future<void> _loadIndustries() async {
    try {
      final industries = await ApiService.fetchIndustries();
      setState(() {
        _industries = industries;
      });
    } catch (e) {
      print("Error loading industries: $e");
    }
  }

  // 2. Fetch Roles when an Industry is selected
  Future<void> _loadRoles(int industryId) async {
    setState(() {
      _isRolesLoading = true;
      _selectedRoleId = null; // Reset role selection
      _roles = [];
    });

    try {
      final roles = await ApiService.fetchSubCategories(industryId);
      setState(() {
        _roles = roles;
      });
    } catch (e) {
      print("Error loading roles: $e");
    } finally {
      setState(() {
        _isRolesLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedRoleId == null || _bioController.text.isEmpty || _rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Ensure createCreativeProfile is implemented in ApiService
    // For now, assume it exists or needs to be added (See previous step)
    final success = await ApiService.createCreativeProfile(
      _selectedRoleId!,
      _bioController.text,
      double.tryParse(_rateController.text) ?? 0.0,
      _portfolioController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProviderDashboardScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create profile.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Complete Your Profile", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Tell clients about you", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            const Text("This information will be displayed on your public profile."),
            const SizedBox(height: 32),
            
            // 1. Industry Dropdown
            DropdownButtonFormField<int>(
              value: _selectedIndustryId,
              isExpanded: true,
              items: _industries.map((ind) {
                return DropdownMenuItem(value: ind.id, child: Text(ind.name));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedIndustryId = val);
                if (val != null) _loadRoles(val);
              },
              decoration: const InputDecoration(
                labelText: "Select Industry", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category)
              ),
            ),
            const SizedBox(height: 16),

            // 2. Role Dropdown (Dependent on Industry)
            DropdownButtonFormField<int>(
              value: _selectedRoleId,
              isExpanded: true,
              items: _roles.map((role) {
                return DropdownMenuItem(value: role.id, child: Text(role.name));
              }).toList(),
              onChanged: _isRolesLoading ? null : (val) => setState(() => _selectedRoleId = val),
              decoration: InputDecoration(
                labelText: _isRolesLoading ? "Loading roles..." : "Select Profession", 
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.work),
                enabled: _selectedIndustryId != null, // Disable until industry picked
              ),
            ),
            const SizedBox(height: 16),
            
            // 3. Hourly Rate
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Hourly Rate (₱)", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            
            // 4. Bio
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Bio / Description", 
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 5. Portfolio
            TextField(
              controller: _portfolioController,
              decoration: const InputDecoration(
                labelText: "Portfolio URL (Optional)", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 32),
            
            // Submit
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Save & Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}