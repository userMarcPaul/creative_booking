import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/creative.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import 'booking_form_screen.dart';

class CreativeDetailScreen extends StatefulWidget {
  final Creative creative;
  const CreativeDetailScreen({super.key, required this.creative});

  @override
  State<CreativeDetailScreen> createState() => _CreativeDetailScreenState();
}

class _CreativeDetailScreenState extends State<CreativeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _futureProducts = ApiService.fetchProducts(widget.creative.id);
  }

  // Helper to fix localhost image URLs
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

  void _buyProduct(Product product) async {
    bool success = await ApiService.createOrder(product.id, 1);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order Placed for ${product.name}!"),
          backgroundColor: const Color(0xFF10B981), // Emerald
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Construct the data correctly from the nested objects
    final displayName = "${widget.creative.user.firstName} ${widget.creative.user.lastName}";
    final roleName = widget.creative.subCategory.name;
    // Hardcoded rating for now as it's not in the model yet
    const rating = "5.0"; 

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF111827),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEEF2FF), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // 2. Updated Avatar Logic to use Profile Image
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                        image: (widget.creative.profileImageUrl != null)
                            ? DecorationImage(
                                image: NetworkImage(_fixImageUrl(widget.creative.profileImageUrl!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (widget.creative.profileImageUrl == null)
                          ? Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName, // Uses the variable defined above
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      roleName, // Uses the variable defined above
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: const Color(0xFF4F46E5),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "About"),
                Tab(text: "Shop"),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(rating),
            _buildShopTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingFormScreen(creative: widget.creative))),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              "Book Now • \$${widget.creative.hourlyRate.toStringAsFixed(0)}/hr",
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(String rating) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Rating", "⭐ $rating"),
              _buildStatItem("Experience", "Verified"),
              _buildStatItem("Response", "1 hr"),
            ],
          ),
          const SizedBox(height: 32),
          Text("Biography", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            widget.creative.bio.isNotEmpty ? widget.creative.bio : "No bio provided.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: const Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
          if (widget.creative.portfolioUrl != null && widget.creative.portfolioUrl!.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text("Portfolio", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // Launch URL logic here
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.creative.portfolioUrl!,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildShopTab() {
    return FutureBuilder<List<Product>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No products for sale", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final product = snapshot.data![index];
            final hasImage = product.imageUrl != null;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Product Image or Icon
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage 
                        ? Image.network(
                            _fixImageUrl(product.imageUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade400, size: 32),
                          )
                        : Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade400, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "\$${product.price.toStringAsFixed(2)}",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF10B981)), 
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _buyProduct(product),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      color: const Color(0xFF4F46E5),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFEEF2FF)),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}