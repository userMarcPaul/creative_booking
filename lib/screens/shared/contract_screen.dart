import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart'; // Ensure you have this for baseUrl

class ContractScreen extends StatefulWidget {
  final int bookingId;
  final String userRole; // 'client' or 'creative'

  const ContractScreen({super.key, required this.bookingId, required this.userRole});

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  bool _isLoading = true;
  String _contractText = "";
  int? _contractId;
  bool _isSigned = false;

  @override
  void initState() {
    super.initState();
    _fetchContract();
  }

  Future<void> _fetchContract() async {
    final url = Uri.parse('${ApiService.baseUrl}/contract/booking/${widget.bookingId}/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _contractText = data['body_text'];
          _contractId = data['id'];
          // Check if already signed by this user
          if (widget.userRole == 'client') {
            _isSigned = data['is_client_signed'];
          } else {
            _isSigned = data['is_creative_signed'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching contract: $e");
    }
  }

  Future<void> _signContract() async {
    if (_contractId == null) return;
    
    setState(() => _isLoading = true);
    
    final url = Uri.parse('${ApiService.baseUrl}/contract/sign/$_contractId/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'role': widget.userRole}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Contract Signed Successfully!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Go back
        }
      }
    } catch (e) {
      print("Error signing: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Service Agreement", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _contractText,
                        style: GoogleFonts.spaceMono(fontSize: 14, height: 1.5, color: const Color(0xFF374151)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_isSigned)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text("You have signed this contract", style: GoogleFonts.plusJakartaSans(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _signContract,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Accept & Sign", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}