// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import 'booking_detail_screen.dart'; 

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late Future<List<Booking>> _futureBookings;

  // Theme Colors
  final Color _primaryColor = const Color(0xFF4F46E5);
  final Color _backgroundColor = const Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _futureBookings = ApiService.fetchMyBookings();
    });
  }

  // Helper to format date nicely
  String _formatDateTime(String dateStr, String timeStr) {
    try {
      // Clean up inputs just in case
      final date = dateStr.trim();
      final time = timeStr.trim();
      
      // Attempt to combine. Note: precise parsing depends on your API format.
      // Assuming ISO format YYYY-MM-DD for date and HH:mm:ss or HH:mm for time
      DateTime dateTime;
      try {
         dateTime = DateTime.parse("$date $time");
      } catch (_) {
         // Fallback if direct concat fails (e.g. if time is "10:00 AM")
         // This is a basic fallback, ideally use specific DateFormat parsing
         return "$date • $time";
      }

      return DateFormat('MMM d, y • h:mm a').format(dateTime);
    } catch (e) {
      return "$dateStr • $timeStr";
    }
  }

  // Helper for status colors
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'confirmed': return const Color(0xFF10B981); // Emerald Green
      case 'pending': return const Color(0xFFF59E0B);   // Amber
      case 'cancelled': return const Color(0xFFEF4444); // Red
      case 'completed': return const Color(0xFF3B82F6); // Blue
      default: return Colors.grey;
    }
  }

  // Placeholder for sending receipt logic
  void _handleSendReceipt(int bookingId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.upload_file, color: Colors.white),
            SizedBox(width: 10),
            Text("Opening file picker..."),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _handleCancelBooking(int bookingId) async {
    // 1. Show Confirmation Dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Cancel Booking?",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to cancel this booking? This action cannot be undone.",
            style: GoogleFonts.plusJakartaSans(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Keep Booking",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), // Red
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                "Yes, Cancel",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    // 2. If confirmed, proceed with cancellation
    if (confirm == true) {
      // Show loading indicator overlay
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Call API
        await ApiService.updateBookingStatus(bookingId, 'cancelled'); // Ensure this method exists in your ApiService
        
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog

        // Show Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking cancelled successfully"),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh the list
        _loadBookings();

      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to cancel: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "My Bookings",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold, 
            fontSize: 20,
            color: const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade200,
            height: 1.0,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadBookings();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: _primaryColor,
        child: FutureBuilder<List<Booking>>(
          future: _futureBookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _primaryColor));
            } else if (snapshot.hasError) {
              return _buildErrorState();
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: snapshot.data!.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final booking = snapshot.data![index];
                return _buildBookingCard(booking);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_today_rounded, size: 64, color: _primaryColor.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              "No bookings yet",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20, 
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When you book a creative, it will show up here.",
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _loadBookings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Refresh"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            "Couldn't load bookings", 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800
            )
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadBookings,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: BorderSide(color: _primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Try Again"),
          )
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    // Null safety checks added
    final status = booking.status ?? 'pending';
    final statusColor = _getStatusColor(status);
    final isPending = status.toLowerCase() == 'pending';
    final creativeName = booking.creativeName ?? "Unknown";
    final creativeRole = booking.creativeRole ?? "Professional Service"; 

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailScreen(
                  booking: booking, 
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored Status Strip
                Container(
                  width: 6,
                  color: statusColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: ID and Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              "#${booking.id ?? '---'}",
                              style: GoogleFonts.firaCode(
                                color: Colors.grey[400], 
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Creative Details
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (creativeName.isNotEmpty) 
                                    ? creativeName[0].toUpperCase() 
                                    : "?",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: _primaryColor,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    creativeName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: const Color(0xFF111827),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    creativeRole,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey[500], 
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Date & Time Row
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            Text(
                              _formatDateTime(booking.date, booking.time),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),

                        // Message Section (Requirements)
                        if (booking.requirements != null && booking.requirements.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Text(
                              booking.requirements,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],

                        // Action Buttons for Pending Status
                        if (isPending) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: booking.id == null 
                                    ? null 
                                    : () => _handleCancelBooking(booking.id!),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: booking.id == null 
                                    ? null 
                                    : () => _handleSendReceipt(booking.id!),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                                  label: const Text("Upload Receipt"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}