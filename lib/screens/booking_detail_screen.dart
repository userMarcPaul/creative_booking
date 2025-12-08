import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking.dart';
import '../services/api_service.dart'; 
import 'chat_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;
  final bool isProvider; 

  const BookingDetailScreen({
    super.key, 
    required this.booking, 
    this.isProvider = false, 
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking.status ?? 'pending';
  }

  Future<void> _updateStatus(String newStatus) async {
    final success = await ApiService.updateBookingStatus(widget.booking.id!, newStatus);
    if (success) {
      setState(() => _currentStatus = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking marked as $newStatus"),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return Colors.redAccent;
      case 'completed':
        return Colors.blueAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  // Updated _buildDetailRow to accept icon or symbol
  Widget _buildDetailRow({IconData? icon, String? symbol, required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: icon != null
              ? Icon(icon, size: 22, color: Colors.grey.shade600)
              : Text(
                  symbol ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 12)),
            Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827))),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine target info based on role
    String targetName;
    String targetLabel;
    String buttonText;

    if (widget.isProvider) {
      targetName = widget.booking.clientName ?? "Client #${widget.booking.clientId ?? '?'}";
      targetLabel = "Client";
      buttonText = "Message Client";
    } else {
      targetName = widget.booking.creativeName ?? "Provider #${widget.booking.creativeId}";
      targetLabel = "Service Provider";
      buttonText = "Message Provider";
    }

    // Price display with Peso sign
    final double rawPrice = widget.booking.price ?? 1500.00;
    final String displayCost = rawPrice.toStringAsFixed(2);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          "Booking Details",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- STATUS CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentStatus.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: _getStatusColor(_currentStatus),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.booking.creativeRole ?? "Creative Service", 
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text("#${widget.booking.id}", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildDetailRow(icon: Icons.calendar_today_rounded, label: "Date", value: widget.booking.date),
                  const SizedBox(height: 16),
                  _buildDetailRow(icon: Icons.access_time_rounded, label: "Time", value: widget.booking.time),
                  const SizedBox(height: 16),
                  _buildDetailRow(symbol: '₱', label: "Total Cost", value: displayCost),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- PROFILE SECTION ---
            Text(targetLabel, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: widget.isProvider ? Colors.orange.shade50 : Colors.indigo.shade50,
                    child: Text(
                      targetName.isNotEmpty ? targetName[0].toUpperCase() : "?",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold, 
                        color: widget.isProvider ? Colors.orange : Colors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(targetName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(targetLabel, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (_currentStatus == 'pending' || (widget.isProvider && _currentStatus == 'confirmed'))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _updateStatus('cancelled'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text("Cancel Booking"),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  bookingId: widget.booking.id ?? 0,
                  providerName: targetName,
                ),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: Text(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
