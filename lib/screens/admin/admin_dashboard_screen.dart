// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../services/api_service.dart';
import '../../models/creative.dart';
import '../../models/product.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Creative>> _futurePending;
  late Future<List<Creative>> _futureVerified;
  late Future<List<Product>> _futureProducts;
  late TabController _tabController;

  // Search State
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Debounce (optional)
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      // Futures for lists and products
      _futurePending = ApiService.fetchPendingCreatives();
      _futureVerified = ApiService.fetchAllVerifiedCreatives();
      _futureProducts = ApiService.fetchAllProducts();
    });
  }

  void _onSearchChanged(String q) {
    // Optional debounce to reduce rebuild churn
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() => _searchQuery = q.trim().toLowerCase());
    });
  }

  Future<void> _confirmAction(int id, String action, String name) async {
    final bool isApprove = action == 'approve';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApprove ? "Approve Provider?" : "Decline/Remove Provider?"),
        content: Text("Are you sure you want to ${isApprove ? 'approve' : 'remove'} $name?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF10B981) : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isApprove ? "Confirm Approve" : "Confirm Remove"),
          ),
        ],
      ),
    );

    if (confirmed == true) _handleAction(id, action);
  }

  Future<void> _handleAction(int id, String action) async {
    // Small processing snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Processing request..."), duration: Duration(milliseconds: 600)),
    );

    final success = await ApiService.manageCreativeProfile(id, action);

    if (!mounted) return;
    if (success) {
      final message = action == 'approve' ? "Provider Approved Successfully" : "Provider Request Declined";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(action == 'approve' ? Icons.check_circle : Icons.info, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))),
            ],
          ),
          backgroundColor: action == 'approve' ? const Color(0xFF10B981) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action failed. Please try again."), backgroundColor: Colors.red),
      );
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // Local dev -> emulator fix
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

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              elevation: 2,
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.black87),
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111827)),
                      decoration: InputDecoration(
                        hintText: "Search providers or products...",
                        border: InputBorder.none,
                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      ),
                      onChanged: _onSearchChanged,
                    )
                  : Text("Admin Panel",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.grey[700]),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = "";
                        _searchController.clear();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  onPressed: _logout,
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF4F46E5),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Pending"),
                  Tab(text: "Verified"),
                  Tab(text: "Products"),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Each tab contains a RefreshIndicator and scrollable ListView/Grid that
            // starts with the Stats header (so it scrolls with the content).
            _buildTabWithStatsAndList(isPending: true),
            _buildTabWithStatsAndList(isPending: false),
            _buildTabWithStatsAndProducts(),
          ],
        ),
      ),
    );
  }

  // --- Tab builders (Option B: stats header inside the scroll) ---

  Widget _buildTabWithStatsAndList({required bool isPending}) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF4F46E5),
      child: FutureBuilder<List<Creative>>(
        future: isPending ? _futurePending : _futureVerified,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];

          // Apply search filter (search across name and category)
          final filtered = list.where((c) {
            final name = "${c.user.firstName} ${c.user.lastName}".toLowerCase();
            final category = c.subCategory.name.toLowerCase();
            if (_searchQuery.isEmpty) return true;
            return name.contains(_searchQuery) || category.contains(_searchQuery);
          }).toList();

          // Build a ListView where the first item is the stats header
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.isEmpty ? 2 : filtered.length + 1, // +1 for stats header; keep at least 2 for empty state
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Stats header (scrolls with content)
                return _buildStatsHeaderWidget();
              }

              if (filtered.isEmpty) {
                // Empty state placeholder after stats header
                return _buildEmptyState(isPending ? "No pending requests" : "No verified providers", isPending ? Icons.assignment_turned_in_outlined : Icons.people_outline);
              }

              final creative = filtered[index - 1];
              return _buildProviderCard(creative, isPending);
            },
          );
        },
      ),
    );
  }

  Widget _buildTabWithStatsAndProducts() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF4F46E5),
      child: FutureBuilder<List<Product>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];

          // Apply search filter to products
          final filtered = list.where((p) {
            if (_searchQuery.isEmpty) return true;
            return p.name.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            // Build ListView with stats header and empty message
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatsHeaderWidget(),
                const SizedBox(height: 16),
                _buildEmptyState("No products found", Icons.search_off),
              ],
            );
          }

          // Build a slotted grid preceded by stats header as the first item
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsHeaderWidget(),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, idx) => _buildProductCard(filtered[idx]),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Reusable UI pieces ---

  Widget _buildStatsHeaderWidget() {
    return FutureBuilder<List<Creative>>(
      future: _futureVerified,
      builder: (context, creativeSnap) {
        final providerCount = creativeSnap.hasData ? creativeSnap.data!.length : 0;
        return FutureBuilder<List<Product>>(
          future: _futureProducts,
          builder: (context, productSnap) {
            final productCount = productSnap.hasData ? productSnap.data!.length : 0;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Expanded(child: _statCard("Active Providers", "$providerCount", Icons.people_alt_rounded, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard("Total Products", "$productCount", Icons.inventory_2_rounded, Colors.orange)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statCard(String title, String count, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(count, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: color.shade800)),
              Icon(icon, color: color.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: GoogleFonts.plusJakartaSans(color: color.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProviderCard(Creative creative, bool isPending) {
    final fullName = "${creative.user.firstName} ${creative.user.lastName}";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'avatar_${creative.id}',
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFEEF2FF),
                  backgroundImage: creative.profileImageUrl != null ? NetworkImage(_fixImageUrl(creative.profileImageUrl!)) : null,
                  child: creative.profileImageUrl == null
                      ? Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : "U",
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)))
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(fullName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                    child: Text(creative.subCategory.name, style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontSize: 12)),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isPending ? Colors.orange.withOpacity(0.25) : Colors.green.withOpacity(0.25)),
                ),
                child: Text(isPending ? "Pending" : "Verified",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: isPending ? Colors.orange[800] : Colors.green[800], fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.email_outlined, creative.user.email),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.info_outline, creative.bio, maxLines: 2),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isPending) ...[
                Expanded(
                    child: _buildActionButton(
                        label: "Decline", color: Colors.red, isOutlined: true, onTap: () => _confirmAction(creative.id, 'decline', fullName))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildActionButton(
                        label: "Approve", color: const Color(0xFF10B981), isOutlined: false, onTap: () => _confirmAction(creative.id, 'approve', fullName))),
              ] else ...[
                Expanded(
                    child: _buildActionButton(
                        label: "Remove Provider",
                        color: Colors.red,
                        isOutlined: true,
                        icon: Icons.delete_outline,
                        onTap: () => _confirmAction(creative.id, 'decline', fullName))),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required bool isOutlined,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isOutlined
              ? BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5)))
              : null,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: isOutlined ? color : Colors.white), const SizedBox(width: 8)],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(color: isOutlined ? color : Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontSize: 13),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.imageUrl != null
                  ? Image.network(
                      _fixImageUrl(product.imageUrl!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                    )
                  : Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text("\$${product.price.toStringAsFixed(2)}", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              ]),
            )
          ],
        ),
      ),
    );
  }
}
