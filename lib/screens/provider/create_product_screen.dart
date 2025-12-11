import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  XFile? _selectedImage;
  // FIX: New state variable to hold image bytes for Web preview
  Uint8List? _imageBytes; 
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // FIX: Handle Web preview by reading bytes immediately
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      } else {
        // Mobile can still rely on the XFile path for preview (File object)
        setState(() {
          _selectedImage = image;
          _imageBytes = null;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null; // Clear bytes state too
    });
  }

  Future<void> _submit() async {
    // 1. Validation
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Price are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final creativeId = await ApiService.getMyCreativeId();
      
      if (creativeId == null) {
        throw Exception("Profile not found. Please login again.");
      }

      // 2. API Call (Multipart upload handled in ApiService)
      final success = await ApiService.createProduct(
        _nameController.text,
        _descController.text,
        double.parse(_priceController.text),
        int.parse(_stockController.text),
        creativeId,
        _selectedImage,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Product Added Successfully!"),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to create product. Check server logs."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Product", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Image Picker UI
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: _selectedImage != null ? Colors.grey[100] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedImage != null ? Colors.blue : Colors.blue.withOpacity(0.3),
                    width: 2,
                    style: _selectedImage != null ? BorderStyle.solid : BorderStyle.none,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          // FIX 2: Conditional image display for preview
                          if (kIsWeb && _imageBytes != null)
                            Image.memory(
                              _imageBytes!, // Use Image.memory with bytes for Web
                              fit: BoxFit.cover,
                            )
                          else if (!kIsWeb)
                            Image.file(
                              File(_selectedImage!.path), // Use Image.file for Mobile
                              fit: BoxFit.cover,
                            ),
                          
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.blue),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Upload Product Image",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "PNG, JPG up to 5MB",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            TextField(
              controller: _nameController, 
              decoration: InputDecoration(
                labelText: "Product Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              )
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _descController, 
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ), 
              maxLines: 3
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController, 
                    keyboardType: TextInputType.number, 
                    decoration: InputDecoration(
                      labelText: "Price (\$)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    )
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _stockController, 
                    keyboardType: TextInputType.number, 
                    decoration: InputDecoration(
                      labelText: "Stock",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    )
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Text(
                      "List Item for Sale",
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            )
          ],
        ),
      ),
    );
  }
}