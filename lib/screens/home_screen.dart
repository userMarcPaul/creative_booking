// ignore_for_file: prefer_const_constructors, deprecated_member_use, unused_element, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Required for favorites persistence
import '../services/api_service.dart';
import '../models/industry.dart';
import '../models/sub_category.dart';
import '../models/product.dart';
import '../models/creative.dart';
import '../models/booking.dart';
import '../models/order.dart';
import 'sub_category_screen.dart';
import 'my_bookings_screen.dart';
import 'creative_list_screen.dart';
import 'login_screen.dart';
import 'interest_selection_screen.dart';
import 'creative_detail_screen.dart';
import 'chat_screen.dart';

// Define theme colors for consistency
const kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
const kPrimaryLight = Color(0xFFEEF2FF); // Indigo 50
const kTextPrimary = Color(0xFF111827); // Gray 900
const kTextSecondary = Color(0xFF6B7280); // Gray 500
const kBgCanvas = Color(0xFFF9FAFB); // Gray 50
const kSuccessColor = Color(0xFF10B981); // Emerald 500

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Futures for data fetching
  late Future<List<Creative>> _futureRecommended;
  late Future<List<Industry>> _futureIndustries;
  late Future<List<Product>> _futureAllProducts;
  late Future<List<Booking>> _futureInbox;
  late Future<List<Order>> _futureOrders;

  List<SubCategory>? _searchResults;
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  bool _isSearching = false;
  bool _showAllCategories = false;
  
  // State variable to track unread messages count
  int _unreadMsgCount = 0;

  // --- FAVORITES STATE ---
  // Sets to store IDs of favorited items (Strings for SharedPreferences compatibility)
  Set<String> _favoriteProductIds = {}; 
  Set<String> _favoriteCreativeIds = {}; 

  // Lists to hold the full objects for the Favorites Screen lookup
  List<Product> _allProductsList = [];
  List<Creative> _allCreativesList = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites(); // Load saved favorites on startup
    _refreshData();
  }

  // --- PERSISTENCE LOGIC ---
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _favoriteProductIds = (prefs.getStringList('fav_products') ?? []).toSet();
        _favoriteCreativeIds = (prefs.getStringList('fav_creatives') ?? []).toSet();
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fav_products', _favoriteProductIds.toList());
    await prefs.setStringList('fav_creatives', _favoriteCreativeIds.toList());
  }

  void _toggleProductFavorite(int id) {
    setState(() {
      final strId = id.toString();
      if (_favoriteProductIds.contains(strId)) {
        _favoriteProductIds.remove(strId);
      } else {
        _favoriteProductIds.add(strId);
      }
    });
    _saveFavorites();
  }

  void _toggleCreativeFavorite(int id) {
    setState(() {
      final strId = id.toString();
      if (_favoriteCreativeIds.contains(strId)) {
        _favoriteCreativeIds.remove(strId);
      } else {
        _favoriteCreativeIds.add(strId);
      }
    });
    _saveFavorites();
  }

  void _refreshData() {
    setState(() {
      // Fetch and store locally for Favorites lookup
      _futureRecommended = ApiService.fetchRecommendedCreatives();
      _futureRecommended.then((data) {
        if(mounted) setState(() => _allCreativesList = data);
      });

      _futureIndustries = ApiService.fetchIndustries();
      
      _futureAllProducts = ApiService.fetchAllProducts();
      _futureAllProducts.then((data) {
        if(mounted) setState(() => _allProductsList = data);
      });

      _futureOrders = ApiService.fetchProviderOrders();
      _futureInbox = ApiService.fetchMyBookings();
      
      _futureInbox.then((bookings) {
        if (mounted) {
          setState(() {
            _unreadMsgCount = bookings.length; 
          });
        }
      }).catchError((e) {
        debugPrint("Error loading inbox count: $e");
      });
    });
  }

  // --- INBOX HELPERS ---
  String _formatChatDate(String? dateStr) {
    if (dateStr == null) return "Now";
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return "Today";
      } else if (diff.inDays == 1) {
        return "Yesterday";
      } else {
        return "${date.month}/${date.day}";
      }
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return kSuccessColor;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'completed': return kPrimaryColor;
      case 'delivered': return kSuccessColor;
      case 'shipped': return Colors.blue;
      default: return Colors.grey;
    }
  }

  // --- HOME SEARCH LOGIC ---
  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await ApiService.searchSubCategories(value);
      setState(() => _searchResults = results);
    } catch (e) {
      print("Search error: $e");
    }
  }

  // --- E-COMMERCE ORDER LOGIC ---
  void _showOrderDialog(Product product) {
    int quantity = 1;
    bool isAgreed = false; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Order ${product.name}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (product.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _fixImageUrl(product.imageUrl!),
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                    Text(
                      "Price per unit: ₱${product.price.toStringAsFixed(2)}",
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildQuantityButton(Icons.remove, () => quantity > 1 ? setStateDialog(() => quantity--) : null),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text("$quantity", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        _buildQuantityButton(Icons.add, () => quantity < product.stock ? setStateDialog(() => quantity++) : null),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Total: ₱${(product.price * quantity).toStringAsFixed(2)}",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: kPrimaryColor, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    Row(
                      children: [
                        Checkbox(
                          value: isAgreed,
                          activeColor: kPrimaryColor,
                          onChanged: (val) {
                            setStateDialog(() => isAgreed = val ?? false);
                          },
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text("I agree to the ", style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                              InkWell(
                                onTap: _showTermsDialog,
                                child: Text("Terms of Service Agreement", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kPrimaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.plusJakartaSans(color: kTextSecondary))),
                ElevatedButton(
                  onPressed: isAgreed
                      ? () {
                          Navigator.pop(context);
                          _processOrder(product, quantity);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text("Confirm Order", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Terms of Agreement"),
        content: const SingleChildScrollView(
          child: Text(
              "1. PAYMENT: You agree to pay the total amount shown.\n\n"
              "2. REFUNDS: Refunds are only available within 24 hours of purchase.\n\n"
              "3. DELIVERY: Physical goods will be shipped within 3 business days.\n\n"
              "4. LIABILITY: We are not liable for delays caused by third-party carriers.\n\n"
              "By proceeding, you enter into a binding contract with the provider."),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: IconButton(icon: Icon(icon), onPressed: onPressed, color: kTextPrimary, splashRadius: 24),
    );
  }

  Future<void> _processOrder(Product product, int quantity) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing order..."), duration: Duration(seconds: 1)));
    bool success = await ApiService.createOrder(product.id, quantity);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully ordered!"), backgroundColor: kSuccessColor));
        _refreshData(); // Refresh the order list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to place order."), backgroundColor: Colors.red));
      }
    }
  }

  String _fixImageUrl(String url) {
    if (url.startsWith('http')) {
      if (!kIsWeb) {
        if (url.contains('127.0.0.1')) return url.replaceFirst('127.0.0.1', '10.0.2.2');
        if (url.contains('localhost')) return url.replaceFirst('localhost', '10.0.2.2');
      }
      if (kIsWeb && url.contains('10.0.2.2')) return url.replaceFirst('10.0.2.2', '127.0.0.1');
      return url;
    } else {
      String base = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
      return '$base$url';
    }
  }

  // --- ICON LOGIC ---
  IconData _getIconData(String code) {
    final c = code.toLowerCase();
    if (c.contains('audio') || c.contains('camera') || c.contains('film')) return Icons.video_camera_back_rounded;
    else if (c.contains('digital') || c.contains('interactive') || c.contains('tech')) return Icons.touch_app_rounded;
    else if (c.contains('creative') || c.contains('consult')) return Icons.auto_awesome_rounded;
    else if (c.contains('design')) return Icons.design_services_rounded;
    else if (c.contains('publish') || c.contains('print') || c.contains('book')) return Icons.menu_book_rounded;
    else if (c.contains('perform') || c.contains('theater') || c.contains('music')) return Icons.theater_comedy_rounded;
    else if (c.contains('visual') || c.contains('paint') || c.contains('draw')) return Icons.palette_rounded;
    else if (c.contains('cultur') || c.contains('tradition') || c.contains('museum') || c.contains('site')) return Icons.museum_rounded;
    return Icons.grid_view_rounded;
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgCanvas,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          const MyBookingsScreen(), // Index 1
          _buildOrdersTab(),        // Index 2 
          _buildInboxTab(),         // Index 3
          _buildProfileTab(),       // Index 4
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
            const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
            
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _unreadMsgCount > 0, 
                label: Text(_unreadMsgCount > 99 ? '99+' : '$_unreadMsgCount'),
                backgroundColor: Colors.red,
                child: const Icon(Icons.chat_bubble_rounded),
              ), 
              label: 'Inbox'
            ),
            
            const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  //=========================================
  //  ORDERS TAB
  //=========================================
  Widget _buildOrdersTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            color: Colors.white,
            width: double.infinity,
            child: Text(
              "My Orders",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _futureOrders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                }
                
                if (snapshot.hasError) {
                   return Center(child: Text("Couldn't load orders", style: GoogleFonts.plusJakartaSans()));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
                          child: Icon(Icons.shopping_bag_outlined, size: 48, color: kPrimaryColor.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 16),
                        Text("No orders yet", style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text("Purchase products from creatives.", style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 14)),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  color: kPrimaryColor,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: orders.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final productName = order.productName;
                      final status = order.status;
                      final qty = order.quantity;
                      final total = order.totalPrice;
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: kBgCanvas,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.inventory_2_rounded, color: Colors.grey.shade400),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          productName,
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: kTextPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Quantity: $qty",
                                    style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Total: ₱${total.toStringAsFixed(2)}",
                                    style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  //=========================================
  //  INBOX TAB
  //=========================================
  Widget _buildInboxTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Messages",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                      ),
                    ),
                    if (_unreadMsgCount > 0)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
                        child: Text("$_unreadMsgCount", 
                            style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search conversations...",
                    hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                    filled: true,
                    fillColor: kBgCanvas,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Booking>>(
              future: _futureInbox,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
                          child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: kPrimaryColor.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 16),
                        Text("No messages yet", style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text("Book a creative to start chatting!", style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 14)),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  color: kPrimaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _buildChatTile(booking);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(Booking booking) {
    final name = booking.creativeName ?? "Unknown User";
    final status = booking.status ?? "Pending";
    final statusColor = _getStatusColor(status);
    final dateDisplay = _formatChatDate(booking.date);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              bookingId: booking.id ?? 0,
              providerName: name,
            ),
          ),
        ).then((_) => _refreshData());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: kPrimaryLight,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : "U", style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w800, fontSize: 20)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: kSuccessColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: kTextPrimary)),
                      Text(dateDisplay, style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Tap to view conversation...",
                          style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //===========================================
  //           Home TAB
  // ==========================================

  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (_isSearching)
                _buildSearchResults()
              else ...[
                const SizedBox(height: 24),
                _buildRecommendedSection(),
                const SizedBox(height: 32),
                _buildCategoriesSection(),
                const SizedBox(height: 32),
                _buildProductFeedSection(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  //=========================================
  //   Profile Tab
  //=========================================

  Widget _buildProfileTab() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 45,
            backgroundColor: kPrimaryLight,
            child: const Icon(Icons.person_rounded, size: 50, color: kPrimaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            "My Profile",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: kPrimaryColor),
            title: Text("Edit Profile", style: GoogleFonts.plusJakartaSans()),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {},
          ),
          
          // --- OPEN FAVORITES SCREEN ---
          ListTile(
            leading: const Icon(Icons.favorite_rounded, color: kPrimaryColor),
            title: Text("Favorites", style: GoogleFonts.plusJakartaSans()),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(
                    favProductIds: _favoriteProductIds,
                    favCreativeIds: _favoriteCreativeIds,
                    allProducts: _allProductsList,
                    allCreatives: _allCreativesList,
                  ),
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: kPrimaryColor),
            title: Text("Settings", style: GoogleFonts.plusJakartaSans()),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {},
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                "Logout",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: kPrimaryColor.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CreativeBook",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 26, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Find perfect talent & products",
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Search services...",
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onActionTap, {String actionText = "See All"}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          if (onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                child: Text(
                  actionText,
                  style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Recommended Providers", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InterestSelectionScreen(isEditMode: true))).then((_) => _refreshData());
        }, actionText: "Edit Prefs"),
        const SizedBox(height: 12),
        SizedBox(
          height: 215,
          child: FutureBuilder<List<Creative>>(
            future: _futureRecommended,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: kPrimaryColor)));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyStateCard();
              }

              final recommended = snapshot.data!;

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: recommended.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final creative = recommended[index];
                  return _buildProviderCard(creative);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InterestSelectionScreen(isEditMode: true))),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 180,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.add_reaction_rounded, color: kPrimaryColor, size: 32)),
              const SizedBox(height: 16),
              Text("Personalize your feed", style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text("Tap to select your interests", style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(Creative creative) {
    bool isFavorite = _favoriteCreativeIds.contains(creative.id.toString());

    return Container(
      width: 165,
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8), spreadRadius: -5),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreativeDetailScreen(creative: creative)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kPrimaryLight, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: kPrimaryLight,
                          backgroundImage: (creative.profileImageUrl != null) ? NetworkImage(_fixImageUrl(creative.profileImageUrl!)) : null,
                          child: (creative.profileImageUrl == null)
                              ? Text(creative.user.firstName.isNotEmpty ? creative.user.firstName[0].toUpperCase() : "U",
                                  style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontWeight: FontWeight.w800, fontSize: 20))
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${creative.user.firstName} ${creative.user.lastName}",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: kTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      creative.subCategory.name,
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      "₱${creative.hourlyRate.toStringAsFixed(0)}",
                      style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // --- FAVORITE ICON OVERLAY ---
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _toggleCreativeFavorite(creative.id),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.red : Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        _buildSectionHeader("All Categories", () {
          setState(() {
            _showAllCategories = !_showAllCategories;
          });
        }, actionText: _showAllCategories ? "Show Less" : "See All"),
        const SizedBox(height: 12),
        FutureBuilder<List<Industry>>(
          future: _futureIndustries,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            final allIndustries = snapshot.data!;
            final displayCount = _showAllCategories ? allIndustries.length : (allIndustries.length > 4 ? 4 : allIndustries.length);
            final displayList = allIndustries.take(displayCount).toList();

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.75,
              ),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final industry = displayList[index];
                return _buildCategoryCircle(industry);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCircle(Industry industry) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SubCategoryScreen(industry: industry)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, kPrimaryLight]),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: kPrimaryColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8), spreadRadius: -2),
              ],
            ),
            child: Icon(_getIconData(industry.name), color: kPrimaryColor, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            industry.name,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: kTextPrimary, height: 1.2),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProductFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Popular Products", null),
        const SizedBox(height: 16),
        FutureBuilder<List<Product>>(
          future: _futureAllProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: kPrimaryColor)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text("No products found.", style: GoogleFonts.plusJakartaSans(color: kTextSecondary)),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => _buildProductCard(snapshot.data![index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    bool hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    bool isFavorite = _favoriteProductIds.contains(product.id.toString());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8), spreadRadius: -5)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showOrderDialog(product),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kBgCanvas,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: hasImage
                          ? Image.network(
                              _fixImageUrl(product.imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_rounded, color: Colors.grey[300], size: 40),
                            )
                          : Icon(Icons.image_rounded, color: Colors.grey[300], size: 48),
                    ),
                    
                    // --- FAVORITE BUTTON OVERLAY ---
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => _toggleProductFavorite(product.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? Colors.red : Colors.grey.shade400,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: kTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₱${product.price.toStringAsFixed(2)}",
                          style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults == null) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: kPrimaryColor)));
    if (_searchResults!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200),
              const SizedBox(height: 24),
              Text("No services found", style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text("Try searching for something else.", style: GoogleFonts.plusJakartaSans(color: kTextSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _searchResults!.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final subCategory = _searchResults![index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CreativeListScreen(subCategory: subCategory)));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.work_outline_rounded, color: kPrimaryColor, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(subCategory.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: kTextPrimary)),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.construction_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontWeight: FontWeight.w600, fontSize: 18)),
      ],
    ));
  }
}

// =========================================================
//  FAVORITES SCREEN
// =========================================================
class FavoritesScreen extends StatelessWidget {
  final Set<String> favProductIds;
  final Set<String> favCreativeIds;
  final List<Product> allProducts;
  final List<Creative> allCreatives;

  const FavoritesScreen({
    super.key,
    required this.favProductIds,
    required this.favCreativeIds,
    required this.allProducts,
    required this.allCreatives,
  });

  @override
  Widget build(BuildContext context) {
    // Filter the lists based on IDs
    final favProducts = allProducts.where((p) => favProductIds.contains(p.id.toString())).toList();
    final favCreatives = allCreatives.where((c) => favCreativeIds.contains(c.id.toString())).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Favorites", style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          bottom: TabBar(
            labelColor: kPrimaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kPrimaryColor,
            tabs: const [
              Tab(text: "Services / Creatives"),
              Tab(text: "Products"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Creatives List
            favCreatives.isEmpty
                ? Center(child: Text("No favorite creatives yet", style: GoogleFonts.plusJakartaSans(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favCreatives.length,
                    itemBuilder: (context, index) {
                      final creative = favCreatives[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(creative.user.firstName[0])),
                          title: Text("${creative.user.firstName} ${creative.user.lastName}"),
                          subtitle: Text(creative.subCategory.name),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => CreativeDetailScreen(creative: creative)));
                          },
                        ),
                      );
                    },
                  ),

            // 2. Products List
            favProducts.isEmpty
                ? Center(child: Text("No favorite products yet", style: GoogleFonts.plusJakartaSans(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favProducts.length,
                    itemBuilder: (context, index) {
                      final product = favProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(width: 50, color: Colors.grey[200], child: Icon(Icons.shopping_bag)),
                          title: Text(product.name),
                          subtitle: Text("₱${product.price}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}