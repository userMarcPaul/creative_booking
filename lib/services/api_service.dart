import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Import kIsWeb
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // For saving login info
import 'package:image_picker/image_picker.dart'; // Required for XFile
import '../models/industry.dart';
import '../models/sub_category.dart';
import '../models/creative.dart';
import '../models/booking.dart';
import '../models/product.dart';
import '../models/order.dart';

class ApiService {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  static String get baseUrl {
    if (isProduction) {
      // Running a built APK / Release Mode
      return 'https://biliran-booking-creative.onrender.com';
    } else if (kIsWeb) {
      // Running in the browser
      return 'http://127.0.0.1:8000/api';
    } else {
      // Running in Android Emulator Debug Mode
      return 'https://biliran-booking-creative.onrender.com'; 
    }
  }

  // ===========================================================================
  // OTP VERIFICATION
  // ===========================================================================

  static Future<bool> verifyOTP({required int userId, required String otp}) async {
    try {
      final url = Uri.parse('$baseUrl/verify-email/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user_id": userId,
          "otp": otp,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Verify OTP error: $e");
      return false;
    }
  }

  static Future<bool> resendOTP({required int userId}) async {
    try {
      final url = Uri.parse('$baseUrl/resend-otp/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user_id": userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Resend OTP error: $e");
      return false;
    }
  }

  // ===========================================================================
  // AUTHENTICATION
  // ===========================================================================

  static Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login/');
    try {
      final response = await http.post(
        url,
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', data['id']);
        await prefs.setString('username', data['username']);
        await prefs.setString('role', data['role']);
        return true;
      }
      return false;
    } catch (e) {
      print("Login Error: $e");
      return false;
    }
  }

  // ApiService.register
  static Future<Map<String, dynamic>?> register(
    String username,
    String email,
    String password,
    String firstName,
    String lastName,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/register/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body); // 👈 return user JSON
      } else {
        print("Register Failed: ${response.statusCode}");
        print("Server Response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Register Error: $e");
      return null;
    }
  
}

static Future<bool> isAdmin() async {
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString('role');
  return role == 'Platform Admin';
}

  
static Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

  // ===========================================================================
  // CHAT / MESSAGING (THIS WAS MISSING)
  // ===========================================================================

  static Future<List<Map<String, dynamic>>> fetchChatMessages(int bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('userId'); // To determine 'isMe'

    final url = Uri.parse('$baseUrl/bookings/$bookingId/messages/');
    
    try {
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Map backend data to UI format
        return data.map<Map<String, dynamic>>((msg) {
          // Check if the message sender ID matches the current logged-in user
          bool isMe = false;
          if (currentUserId != null && msg['sender'] != null) {
             // Assuming backend returns 'sender' as an ID (int)
             isMe = msg['sender'] == currentUserId; 
          }

          return {
            "text": msg['content'] ?? msg['message'] ?? "", 
            "isMe": isMe, 
            "timestamp": msg['created_at']
          };
        }).toList();
      }
    } catch (e) {
      print("Error fetching messages: $e");
    }
    return [];
  }

  static Future<bool> sendChatMessage(int bookingId, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) return false;

    final url = Uri.parse('$baseUrl/bookings/$bookingId/messages/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': message,
          'sender': userId, // Sending user ID so backend knows who sent it
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error sending message: $e");
      return false;
    }
  }

  // ===========================================================================
  // PREFERENCES & RECOMMENDATIONS
  // ===========================================================================

  static Future<bool> saveUserInterests(List<int> subCategoryIds) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return false;

    final url = Uri.parse('$baseUrl/save-interests/'); 
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'subcategory_ids': subCategoryIds,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error saving interests: $e");
      return false;
    }
  }

  static Future<List<Creative>> fetchRecommendedCreatives() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return [];

    final url = Uri.parse('$baseUrl/creatives/recommended/?user_id=$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Creative.fromJson(json)).toList();
      } else {
        return []; 
      }
    } catch (e) {
      print("Error fetching recommended creatives: $e");
      return [];
    }
  }

  // ===========================================================================
  // BROWSING & SEARCH
  // ===========================================================================

  static Future<List<Industry>> fetchIndustries({String? query}) async {
    String endpoint = '$baseUrl/industries/';
    if (query != null && query.isNotEmpty) {
      endpoint += '?search=$query';
    }
    final url = Uri.parse(endpoint);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final industries = data.map((json) => Industry.fromJson(json)).toList();
        final ids = <int>{};
        final uniqueIndustries =
            industries.where((ind) => ids.add(ind.id)).toList();
        return uniqueIndustries;
      } else {
        throw Exception('Failed to load industries');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  static Future<List<SubCategory>> fetchSubCategories(int industryId) async {
    final url = Uri.parse('$baseUrl/subcategories/?industry_id=$industryId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SubCategory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load subcategories');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  static Future<List<SubCategory>> searchSubCategories(String query) async {
    final url = Uri.parse('$baseUrl/subcategories/?search=$query');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SubCategory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search roles');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  static Future<List<Creative>> fetchCreatives(int subCategoryId) async {
    final url = Uri.parse('$baseUrl/creatives/?subcategory_id=$subCategoryId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Creative.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load creatives');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // --- NEW: Fetch ALL Verified Creatives (For Admin Stats) ---
  static Future<List<Creative>> fetchAllVerifiedCreatives() async {
    // Calling the endpoint without subcategory_id returns all verified
    final url = Uri.parse('$baseUrl/creatives/'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Creative.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching all creatives: $e");
      return [];
    }
  }

  // ===========================================================================
  // BOOKINGS
  // ===========================================================================

  static Future<List<Booking>> fetchMyBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final role = prefs.getString('role');

    if (userId == null) return [];

    String param = (role == 'creative' || role == 'Creative Professional')
        ? 'creative_user_id'
        : 'client_id';
    final url = Uri.parse('$baseUrl/my-bookings/?$param=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  static Future<bool> createBooking(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return false;

    final url = Uri.parse('$baseUrl/bookings/');
    final bookingData = booking.toJson();
    bookingData['client'] = userId;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bookingData),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Booking Failed: $e");
      return false;
    }
  }

  static Future<bool> updateBookingStatus(int bookingId, String status) async {
    final url = Uri.parse('$baseUrl/bookings/$bookingId/');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Status Error: $e");
      return false;
    }
  }

  // ===========================================================================
  // PROFILE MANAGEMENT
  // ===========================================================================

  static Future<bool> createCreativeProfile(
    int subCategoryId,
    String bio,
    double hourlyRate,
    String? portfolioUrl,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) return false;

    final url = Uri.parse('$baseUrl/create-profile/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sub_category_id': subCategoryId,
          'bio': bio,
          'hourly_rate': hourlyRate,
          'portfolio_url': portfolioUrl,
          'user': userId,
        }),
      );
      
      if (response.statusCode != 201) {
        print("Create Profile Error: ${response.statusCode}");
        print("Body: ${response.body}");
      }

      return response.statusCode == 201;
    } catch (e) {
      print("Profile Creation Error: $e");
      return false;
    }
  }

  static Future<bool> hasCreativeProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return false;

    final url = Uri.parse('$baseUrl/creative-profile/?user_id=$userId');
    try {
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<int?> getMyCreativeId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return null;

    final url = Uri.parse('$baseUrl/creative-profile/?user_id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // ===========================================================================
  // PRODUCT / E-COMMERCE
  // ===========================================================================

  static Future<List<Product>> fetchProducts(int creativeId) async {
    final url = Uri.parse('$baseUrl/products/?creative_id=$creativeId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  static Future<List<Product>> fetchAllProducts() async {
    final url = Uri.parse('$baseUrl/products/'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching all products: $e");
      return [];
    }
  }

  static Future<bool> createProduct(
    String name,
    String description,
    double price,
    int stock,
    int creativeProfileId,
    XFile? image,
  ) async {
    final url = Uri.parse('$baseUrl/products/');

    try {
      var request = http.MultipartRequest('POST', url);

      request.fields['creative'] = creativeProfileId.toString();
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'image_url', 
            bytes,
            filename: image.name,
          ),
        );
      }

      final response = await http.Response.fromStream(await request.send());
      print("Create Product Response: ${response.statusCode} ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      print("Error creating product: $e");
      return false;
    }
  }

  // ===========================================================================
  // ORDERS
  // ===========================================================================

  static Future<bool> createOrder(int productId, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return false;

    final url = Uri.parse('$baseUrl/orders/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'product': productId,
          'quantity': quantity,
          'client': userId,
          'status': 'pending',
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error creating order: $e");
      return false;
    }
  }

  static Future<bool> updateOrderStatus(int orderId, String status) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating order status: $e");
      return false;
    }
  }

  static Future<List<Order>> fetchProviderOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return [];

    final url = Uri.parse('$baseUrl/orders/?client_id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching orders: $e");
      return [];
    }
  }

  // ===========================================================================
  // ADMIN FUNCTIONS
  // ===========================================================================

  static Future<List<Creative>> fetchPendingCreatives() async {
    final url = Uri.parse('$baseUrl/admin/pending-creatives/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Creative.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching pending creatives: $e");
      return [];
    }
  }

  static Future<bool> manageCreativeProfile(int profileId, String action) async {
    // action should be 'approve' or 'decline'
    final url = Uri.parse('$baseUrl/admin/manage-creative/$profileId/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': action}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error managing creative: $e");
      return false;
    }
  }

  // ==============================
  // PREFERENCES
  // ==============================

  static Future<bool> savePreferences({
    required List<String> categories,
    required Map<String, List<String>> subCategories,
    required int budget,
    required String location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return false;

    final url = Uri.parse('$baseUrl/preferences/save/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user_id": userId,
          "categories": categories,
          "subCategories": subCategories,
          "budget": budget,
          "location": location,
        }),
      );

      print("Save Pref Response: ${response.statusCode} - ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Save Preferences Error: $e");
      return false;
    }
  }

  static Future<bool> checkPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return false;

    final url = Uri.parse('$baseUrl/preferences/check/?user_id=$userId');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['has_preferences'] ?? false;
      }
    } catch (e) {}

    return false;
  }
}
